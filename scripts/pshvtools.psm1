# hvbak.psm1
# PowerShell module for VM backup operations

function Invoke-VMBackup {
    <#
    .SYNOPSIS
      Export Hyper-V VMs using checkpoints (live export), archive each VM export, and clean up.

    .DESCRIPTION
      For each VM matching the provided NamePattern this script:
        - Attempts a Production checkpoint (falls back to a standard checkpoint).
        - Exports VM configuration, checkpoints/snapshots, and VHD/VHDX disks to a per-VM temp folder.
        - Archives the per-VM export using 7z format and removes the per-VM temp folder as soon as that VM's archive completes.
        - Uses per-vm background jobs (named/perVmJob) to run each VM's workflow concurrently.
        - No throttling: all per-vm jobs are started immediately. Only the external 7z process is set to Idle priority.
        - Implements graceful cleanup in a finally block: removes checkpoints, restarts VMs, and cleans up incomplete exports even if the export is cancelled via Hyper-V Manager or Ctrl+C.
        - Per-job logs are written to the shared TempRoot to survive per-VM folder deletion.
        - Supports Ctrl+C cancellation: stops all background jobs, kills related 7z.exe processes, and removes temp contents.
        - Supports optional 7-Zip thread capping via ThreadCap (uses 7z -mmt=<n>).

    .PARAMETER NamePattern
      Wildcard pattern to match VM names (e.g., "*" for all VMs, "web-*" for VMs starting with "web-").

    .PARAMETER Destination
      Root destination folder for backups. A date-stamped subfolder (YYYYMMDD) is created automatically. Default: %USERPROFILE%\hvbak-archives

    .PARAMETER TempFolder
      Temporary folder for VM exports during backup processing. Default: %TEMP%\hvbak

    .PARAMETER ForceTurnOff
      If checkpoint creation fails for a running VM, force it off to allow export. Default: $true

    .PARAMETER GuestCredential
      PSCredential for in-guest WinRM shutdown attempts (not currently used in graceful shutdown logic). Optional.

    .PARAMETER KeepCount
      Number of backup copies to keep per VM (older backups are deleted). Default: 2

    .PARAMETER ThreadCap
      Optional maximum number of threads for 7-Zip compression (1-1024). Default: uses 7z defaults.

    .EXAMPLE
      hvbak -NamePattern "*"
      Exports all VMs to %USERPROFILE%\hvbak-archives\YYYYMMDD using default temp folder

    .EXAMPLE
      hv -bak -NamePattern "srv-*" -Destination "D:\backups" -TempFolder "E:\temp"
      Exports VMs matching "srv-*" to D:\backups\YYYYMMDD using E:\temp as temporary folder

    .EXAMPLE
      hvbak -NamePattern "srv-*" -Destination "D:\backups" -ForceTurnOff:$false
      Exports VMs matching "srv-*" to D:\backups\YYYYMMDD without forcing power off on checkpoint failure.

    .EXAMPLE
      hvbak -NamePattern "web-*" -KeepCount 5
      Exports VMs matching "web-*" and keeps the 5 most recent backups, deleting older ones.

    .NOTES
      - Run elevated (Administrator) on the Hyper-V host for best results.
      - Requires 7-Zip (7z.exe must be in PATH or installed in standard location).
      - Each per-VM job runs independently; exports can proceed in parallel without throttling.
      - Temp folder and destination must be accessible and have sufficient space.
      - Graceful cleanup ensures VMs are restarted and checkpoints removed even on cancellation or failure.
      - Archives are created in 7z format with fast compression for better multithreading.
      - Available as both 'hvbak' and 'hv-bak' commands.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$NamePattern,

        [Parameter(Mandatory = $false)]
        [string]$Destination = "$env:USERPROFILE\hvbak-archives",

        [Parameter(Mandatory = $false)]
        [string]$TempFolder = "$env:TEMP\hvbak",

        [Parameter(Mandatory = $false)]
        [switch]$ForceTurnOff = $true,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$GuestCredential,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [int]$KeepCount = 2,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1024)]
        [int]$ThreadCap
    )

    # Display help if no NamePattern provided
    if ([string]::IsNullOrWhiteSpace($NamePattern)) {
        Get-Help Invoke-VMBackup -Full
        return
    }

function Clone-VM {
    <#
    .SYNOPSIS
      Clone a Hyper-V VM into a new VM in a specified folder.

    .DESCRIPTION
      Exports the source VM to a temporary folder, then imports it using Copy mode with a new VM Id
      and renames the imported VM to NewName.

      The clone is placed under DestinationRoot (a new subfolder named after NewName is created).

    .PARAMETER SourceVmName
      Name of the existing VM to clone.

    .PARAMETER NewName
      Name of the new cloned VM.

    .PARAMETER DestinationRoot
      Folder where the new VM files will be stored.

    .PARAMETER TempFolder
      Temporary folder used for the Hyper-V export step.

    .PARAMETER Force
      If a VM named NewName already exists, remove it before importing.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$SourceVmName,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$NewName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationRoot,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$TempFolder = "$env:TEMP\\hvclone",

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    Set-StrictMode -Version Latest

    try {
        Import-Module Hyper-V -ErrorAction Stop | Out-Null
    } catch {
        throw "Hyper-V module is required. Run on a Hyper-V host with the Hyper-V PowerShell module installed. $_"
    }

    $src = Get-VM -Name $SourceVmName -ErrorAction Stop

    if ($SourceVmName -eq $NewName) {
        throw "NewName must be different from SourceVmName."
    }

    $existing = Get-VM -Name $NewName -ErrorAction SilentlyContinue
    if ($existing -and -not $Force) {
        throw "A VM named '$NewName' already exists. Use -Force to remove it before cloning."
    }

    if ($existing -and $Force) {
        try {
            if ($existing.State -ne 'Off') {
                Stop-VM -VM $existing -TurnOff -Force -ErrorAction SilentlyContinue
            }
        } catch {}

        Remove-VM -VM $existing -Force -ErrorAction Stop
    }

    $destVmRoot = Join-Path -Path $DestinationRoot -ChildPath $NewName
    if (-not (Test-Path -LiteralPath $destVmRoot)) {
        New-Item -Path $destVmRoot -ItemType Directory -Force | Out-Null
    }

    $exportRoot = Join-Path -Path $TempFolder -ChildPath ("{0}_{1}" -f ($SourceVmName -replace '[\\/:*?\"<>|]', '_'), (Get-Date).ToString('yyyyMMddHHmmss'))
    if (Test-Path -LiteralPath $exportRoot) {
        Remove-Item -LiteralPath $exportRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -Path $exportRoot -ItemType Directory -Force | Out-Null

    $importedVm = $null
    try {
        Export-VM -VM $src -Path $exportRoot -ErrorAction Stop

        $importedVm = Import-VM -Path $exportRoot -Copy -GenerateNewId -VhdDestinationPath $destVmRoot -VirtualMachinePath $destVmRoot -SnapshotFilePath $destVmRoot -ErrorAction Stop

        if ($importedVm) {
            Rename-VM -VM $importedVm -NewName $NewName -ErrorAction Stop
        }

        if ($importedVm) {
            $importedVm | Get-VM
        }
    } finally {
        try {
            if (Test-Path -LiteralPath $exportRoot) {
                Remove-Item -LiteralPath $exportRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }
}

    # Get the path to the actual script
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "hvbak.ps1"
    
    if (-not (Test-Path $scriptPath)) {
        Write-Error "hvbak.ps1 not found at: $scriptPath"
        return
    }

    # Build parameter splatting
    $params = @{
        NamePattern = $NamePattern
        Destination = $Destination
        TempFolder = $TempFolder
        ForceTurnOff = $ForceTurnOff
        KeepCount = $KeepCount
    }

    if ($GuestCredential) {
        $params.GuestCredential = $GuestCredential
    }

    if ($ThreadCap) {
        $params.ThreadCap = $ThreadCap
    }

    # Execute the script
    & $scriptPath @params
}

function Clone-VM {
    <#
    .SYNOPSIS
      Clone a Hyper-V VM into a new VM in a specified folder.

    .DESCRIPTION
      Exports the source VM to a temporary folder, then imports it using Copy mode with a new VM Id
      and renames the imported VM to NewName.

      The clone is placed under DestinationRoot (a new subfolder named after NewName is created).

    .PARAMETER SourceVmName
      Name of the existing VM to clone.

    .PARAMETER NewName
      Name of the new cloned VM.

    .PARAMETER DestinationRoot
      Folder where the new VM files will be stored.

    .PARAMETER TempFolder
      Temporary folder used for the Hyper-V export step.

    .PARAMETER Force
      If a VM named NewName already exists, remove it before importing.

    .EXAMPLE
      hvclone -SourceVmName 'BaseWin11' -NewName 'Win11-Dev01' -DestinationRoot 'D:\\Hyper-V'
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$SourceVmName,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$NewName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationRoot,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$TempFolder = "$env:TEMP\\hvclone",

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    Set-StrictMode -Version Latest

    try {
        Import-Module Hyper-V -ErrorAction Stop | Out-Null
    } catch {
        throw "Hyper-V module is required. Run on a Hyper-V host with the Hyper-V PowerShell module installed. $_"
    }

    if ($SourceVmName -eq $NewName) {
        throw "NewName must be different from SourceVmName."
    }

    $src = Get-VM -Name $SourceVmName -ErrorAction Stop

    $existing = Get-VM -Name $NewName -ErrorAction SilentlyContinue
    if ($existing -and -not $Force) {
        throw "A VM named '$NewName' already exists. Use -Force to remove it before cloning."
    }

    if ($existing -and $Force) {
        try {
            if ($existing.State -ne 'Off') {
                Stop-VM -VM $existing -TurnOff -Force -ErrorAction SilentlyContinue
            }
        } catch {}

        Remove-VM -VM $existing -Force -ErrorAction Stop
    }

    $destVmRoot = Join-Path -Path $DestinationRoot -ChildPath $NewName
    if (-not (Test-Path -LiteralPath $destVmRoot)) {
        New-Item -Path $destVmRoot -ItemType Directory -Force | Out-Null
    }

    $safeSrcName = $SourceVmName -replace '[\\/:*?\"<>|]', '_'
    $exportRoot = Join-Path -Path $TempFolder -ChildPath ("{0}_{1}" -f $safeSrcName, (Get-Date).ToString('yyyyMMddHHmmss'))
    if (Test-Path -LiteralPath $exportRoot) {
        Remove-Item -LiteralPath $exportRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -Path $exportRoot -ItemType Directory -Force | Out-Null

    $importedVm = $null
    try {
        Export-VM -VM $src -Path $exportRoot -ErrorAction Stop

        $importedVm = Import-VM -Path $exportRoot -Copy -GenerateNewId -VhdDestinationPath $destVmRoot -VirtualMachinePath $destVmRoot -SnapshotFilePath $destVmRoot -ErrorAction Stop

        if ($importedVm) {
            Rename-VM -VM $importedVm -NewName $NewName -ErrorAction Stop
        }

        if ($importedVm) {
            $importedVm | Get-VM
        }
    } finally {
        try {
            if (Test-Path -LiteralPath $exportRoot) {
                Remove-Item -LiteralPath $exportRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }
}

function Repair-VhdAcl {
    <#
    .SYNOPSIS
      Fix VHD/VHDX ACLs for Hyper-V after copy/restore from backup.

    .DESCRIPTION
      Repairs file permissions on VHD/VHDX files to allow Hyper-V VMs to access them.
      
      Modes:
        - Default (no VhdFolder or VhdListCsv): enumerate Get-VM and fix attached VHDs.
        - -VhdFolder <path>: recursively process *.vhd, *.vhdx under the folder.
        - -VhdListCsv <path>: CSV with columns Path and optional VMId (GUID without braces).
      

    .PARAMETER VhdFolder
      Path to folder containing VHD/VHDX files to fix recursively.

    .PARAMETER VhdListCsv
      Path to CSV file with columns: Path (required), VMId (optional GUID without braces).

    .PARAMETER LogFile
      Path to log file. Default: %TEMP%\hvfixacl.log

    .EXAMPLE
      Repair-VhdAcl -VhdFolder "D:\Restores"
      Fix ACLs for all VHD/VHDX files in D:\Restores recursively

    .EXAMPLE
      Repair-VhdAcl -VhdListCsv "C:\temp\vhds.csv"
      Fix ACLs for VHDs listed in CSV file

    .EXAMPLE
      Repair-VhdAcl
      Fix ACLs for all VHDs attached to VMs on this host

    .NOTES
      - Run elevated (Administrator) required
      - Takes ownership and grants permissions to SYSTEM, Administrators, and VM account
      - Available as 'hvfixacl', 'hv-fixacl' or 'Repair-VhdAcl'
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$VhdFolder,

        [Parameter(Mandatory = $false)]
        [string]$VhdListCsv,

        [Parameter(Mandatory = $false)]
        [string]$LogFile = "$env:TEMP\hvfixacl.log"
    )

    # Get the path to the actual script
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "hvfixacl.ps1"
    
    if (-not (Test-Path $scriptPath)) {
        Write-Error "hvfixacl.ps1 not found at: $scriptPath"
        return
    }

    # Build parameter splatting
    $params = @{
        LogFile = $LogFile
    }

    if ($VhdFolder) {
        $params.VhdFolder = $VhdFolder
    }

    if ($VhdListCsv) {
        $params.VhdListCsv = $VhdListCsv
    }

    # Execute the script
    & $scriptPath @params
}

function Restore-VMBackup {
    <#
    .SYNOPSIS
      Restore a Hyper-V VM from a hvbak .7z backup.

    .DESCRIPTION
      Wrapper around restore-vmbackup.ps1.
      Use -BackupPath to restore a specific archive, or -VmName to restore the most recent archive for that VM.

    .EXAMPLE
      # Copy restore into a specific Hyper-V storage root
      Restore-VMBackup -BackupPath "D:\hvbak-archives\20260101\MyVM_20260101123456.7z" -ImportMode Copy -DestinationRoot "D:\Hyper-V"

    .EXAMPLE
      # In-place restore into a specific folder (extract + register)
      hvrestore -VmName "MyVM" -BackupRoot "D:\hvbak-archives" -Latest -DestinationRoot "D:\RestoredVMs" -NoNetwork
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$BackupPath,

        [Parameter(Mandatory = $false)]
        [string]$VmName,

        [Parameter(Mandatory = $false)]
        [string]$BackupRoot = "$env:USERPROFILE\hvbak-archives",

        [Parameter(Mandatory = $false)]
        [switch]$Latest,

        [Parameter(Mandatory = $false)]
        [string]$StagingRoot = "$env:TEMP\hvbak-restore",

        [Parameter(Mandatory = $false)]
        [string]$VmStorageRoot = "$env:ProgramData\Microsoft\Windows\Hyper-V",

        [Parameter(Mandatory = $false)]
        [string]$DestinationRoot,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Copy', 'Register', 'Restore')]
        [string]$ImportMode = 'Copy',

        [Parameter(Mandatory = $false)]
        [string]$VSwitchName,

        [Parameter(Mandatory = $false)]
        [switch]$NoNetwork,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$StartAfterRestore,

        [Parameter(Mandatory = $false)]
        [switch]$KeepStaging
    )

    if ($PSBoundParameters.Count -eq 0) {
        Get-Help Restore-VMBackup -Full
        return
    }

    $useLatest = $Latest -or (-not [string]::IsNullOrWhiteSpace($VmName) -and [string]::IsNullOrWhiteSpace($BackupPath))

    if ($useLatest -and [string]::IsNullOrWhiteSpace($VmName)) {
        Write-Error "VmName is required to select the latest archive. Example: hvrestore -VmName 'MyVM' [-Latest]"
        return
    }

    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'restore-vmbackup.ps1'
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Write-Error "restore-vmbackup.ps1 not found at: $scriptPath"
        return
    }

    # Only pass parameters that were explicitly provided (and computed Latest)
    $params = @{}

    if ($PSBoundParameters.ContainsKey('BackupPath')) { $params.BackupPath = $BackupPath }
    if ($PSBoundParameters.ContainsKey('VmName')) { $params.VmName = $VmName }
    if ($PSBoundParameters.ContainsKey('BackupRoot')) { $params.BackupRoot = $BackupRoot }
    if ($useLatest) { $params.Latest = $true }

    if ($PSBoundParameters.ContainsKey('StagingRoot')) { $params.StagingRoot = $StagingRoot }
    if ($PSBoundParameters.ContainsKey('VmStorageRoot')) { $params.VmStorageRoot = $VmStorageRoot }
    if ($PSBoundParameters.ContainsKey('DestinationRoot')) { $params.DestinationRoot = $DestinationRoot }
    if ($PSBoundParameters.ContainsKey('ImportMode')) { $params.ImportMode = $ImportMode }
    if ($PSBoundParameters.ContainsKey('VSwitchName')) { $params.VSwitchName = $VSwitchName }

    if ($NoNetwork.IsPresent) { $params.NoNetwork = $true }
    if ($Force.IsPresent) { $params.Force = $true }
    if ($StartAfterRestore.IsPresent) { $params.StartAfterRestore = $true }
    if ($KeepStaging.IsPresent) { $params.KeepStaging = $true }

    & $scriptPath @params
}

function Restore-OrphanedVMs {
    <#
    .SYNOPSIS
      Scan Hyper-V VM configuration folders for orphaned VMs and register them.

    .DESCRIPTION
      Wrapper around restore-orphaned-vms.ps1.

    .EXAMPLE
      # Preview what would be registered
      Restore-OrphanedVMs -VmConfigRoot "$env:ProgramData\Microsoft\Windows\Hyper-V" -WhatIf

    .EXAMPLE
      # Scan custom storage roots
      hvrecover -VmConfigRoot "D:\Hyper-V","E:\Hyper-V"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$VmConfigRoot = @("$env:ProgramData\Microsoft\Windows\Hyper-V"),

        [Parameter(Mandatory = $false)]
        [switch]$IncludeXml,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Register', 'Copy')]
        [string]$Mode = 'Register',

        [Parameter(Mandatory = $false)]
        [string]$VmStorageRoot = "$env:ProgramData\Microsoft\Windows\Hyper-V",

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if ($PSBoundParameters.Count -eq 0) {
        Get-Help Restore-OrphanedVMs -Full
        return
    }

    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'restore-orphaned-vms.ps1'
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Write-Error "restore-orphaned-vms.ps1 not found at: $scriptPath"
        return
    }

    $params = @{
    }
    if ($PSBoundParameters.ContainsKey('VmConfigRoot')) { $params.VmConfigRoot = $VmConfigRoot }
    if ($IncludeXml.IsPresent) { $params.IncludeXml = $true }
    if ($PSBoundParameters.ContainsKey('Mode')) { $params.Mode = $Mode }
    if ($PSBoundParameters.ContainsKey('VmStorageRoot')) { $params.VmStorageRoot = $VmStorageRoot }
    if ($Force.IsPresent) { $params.Force = $true }

    & $scriptPath @params
}

function Remove-GpuPartitions {
    <#
    .SYNOPSIS
      Remove GPU partition adapters from VMs matching a wildcard name pattern.

    .DESCRIPTION
      Enumerates all VMs matching NamePattern and removes all GPU partition adapters (RemoteFX 3D Video) from each.
      No action is taken if a VM has no GPU partitions.

    .PARAMETER NamePattern
      Wildcard pattern matching VM names (e.g. "*", "lab-*", "win11*").

    .EXAMPLE
      hvnogpup -NamePattern "lab-*"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$NamePattern
    )

    if ([string]::IsNullOrWhiteSpace($NamePattern)) {
        Get-Help Remove-GpuPartitions -Full
        return
    }

    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'remove-gpu-partitions.ps1'
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Write-Error "remove-gpu-partitions.ps1 not found at: $scriptPath"
        return
    }

    $params = @{
        NamePattern = $NamePattern
    }

    & $scriptPath @params
}

function Invoke-VHDCompact {
    <#
    .SYNOPSIS
      Compact all VHDs of VMs specified as a parameter with * wildcard in their names.

    .DESCRIPTION
      For each VM matching the provided NamePattern this function:
        - Automatically shuts down the VM (unless -NoAutoShutdown is specified).
        - Retrieves all VHD/VHDX disks attached to the VM.
        - Compacts each disk using Optimize-VHD with full reclamation mode.
        - Automatically starts the VM back up after compaction.
        - Reports progress and status for each compaction operation.

    .PARAMETER NamePattern
      Wildcard pattern to match VM names (e.g., "*" for all VMs, "web-*" for VMs starting with "web-").

    .PARAMETER NoAutoShutdown
      If specified, do not automatically shut down running VMs. VMs must be stopped manually.
      Default is to automatically shut down any running VMs before compaction.

    .EXAMPLE
      hvcompact "*"
      Compacts all VHDs of all VMs (shuts down and restarts them automatically).

    .EXAMPLE
      hvcompact "srv-*"
      Compacts all VHDs of VMs matching "srv-*" (auto shutdown/startup).

    .EXAMPLE
      hvcompact "web-*" -NoAutoShutdown
      Compacts VHDs of VMs matching "web-*" (requires VMs to be already stopped).

    .NOTES
      - Run elevated (Administrator) on the Hyper-V host.
      - By default, running VMs are automatically stopped before compaction and restarted after.
      - Use -NoAutoShutdown to manage VM state manually.
      - Compaction can be time-consuming depending on VHD size.
      - Compaction releases unused space from the VHD to the host storage.
      - Available as 'hvcompact' command.
    #>

    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$NamePattern,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoAutoShutdown = $false
    )

    # Dot-source the hvcompact.ps1 script with parameters
    $hvcompactScript = Join-Path -Path $PSScriptRoot -ChildPath 'hvcompact.ps1'
    if (Test-Path -LiteralPath $hvcompactScript) {
        & $hvcompactScript -NamePattern $NamePattern -NoAutoShutdown:$NoAutoShutdown
    } else {
        Write-Error "hvcompact.ps1 not found at $hvcompactScript"
    }
}

# Import additional module components
$configModule = Join-Path -Path $PSScriptRoot -ChildPath 'PSHVTools.Config.psm1'
if (Test-Path -LiteralPath $configModule) {
    Import-Module $configModule -Force
}

$healthCheckScript = Join-Path -Path $PSScriptRoot -ChildPath 'Test-PSHVToolsEnvironment.ps1'
if (Test-Path -LiteralPath $healthCheckScript) {
    . $healthCheckScript
}

# Create aliases for shorter commands
New-Alias -Name hvbak -Value Invoke-VMBackup -Force
New-Alias -Name hv-bak -Value Invoke-VMBackup -Force
New-Alias -Name hvfixacl -Value Repair-VhdAcl -Force
New-Alias -Name hv-fixacl -Value Repair-VhdAcl -Force
New-Alias -Name hvrestore -Value Restore-VMBackup -Force
New-Alias -Name hv-restore -Value Restore-VMBackup -Force
New-Alias -Name hvrecover -Value Restore-OrphanedVMs -Force
New-Alias -Name hv-recover -Value Restore-OrphanedVMs -Force
New-Alias -Name hvnogpup -Value Remove-GpuPartitions -Force
New-Alias -Name hv-nogpup -Value Remove-GpuPartitions -Force
New-Alias -Name hvclone -Value Clone-VM -Force
New-Alias -Name hv-clone -Value Clone-VM -Force
New-Alias -Name hvhealth -Value Test-PSHVToolsEnvironment -Force
New-Alias -Name hv-health -Value Test-PSHVToolsEnvironment -Force
New-Alias -Name hvcompact -Value Invoke-VHDCompact -Force
New-Alias -Name hv-compact -Value Invoke-VHDCompact -Force

# Export the functions and aliases
Export-ModuleMember -Function @(
    'Invoke-VMBackup',
    'Repair-VhdAcl',
    'Restore-VMBackup',
    'Restore-OrphanedVMs',
    'Remove-GpuPartitions',
    'Clone-VM',
    'Invoke-VHDCompact',
    'Test-PSHVToolsEnvironment',
    'Get-PSHVToolsConfig',
    'Set-PSHVToolsConfig',
    'Reset-PSHVToolsConfig',
    'Show-PSHVToolsConfig'
) -Alias @(
    'hvbak',
    'hv-bak',
    'hvfixacl',
    'hv-fixacl',
    'hvrestore',
    'hv-restore',
    'hvrecover',
    'hv-recover',
    'hvnogpup',
    'hv-nogpup',
    'hvclone',
    'hv-clone',
    'hvhealth',
    'hv-health',
    'hvcompact',
    'hv-compact'
)
