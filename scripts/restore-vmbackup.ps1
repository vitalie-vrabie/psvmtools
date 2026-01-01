<#
.SYNOPSIS
  Restores a Hyper-V VM from a hvbak 7z backup archive.

.DESCRIPTION
  This script extracts a .7z archive created by `hvbak` to a staging folder, locates the Hyper-V export contents,
  and imports the VM into Hyper-V.

  Recommended mode is Copy + GenerateNewId to avoid collisions.

.PARAMETER BackupPath
  Path to a .7z backup archive.

.PARAMETER VmName
  VM name used for selecting a backup when -Latest is used.

.PARAMETER BackupRoot
  Root folder that contains date folders (YYYYMMDD) created by hvbak.

.PARAMETER Latest
  Select newest backup archive for the provided VmName under BackupRoot\YYYYMMDD.

.PARAMETER StagingRoot
  Folder used to extract the archive. A per-run subfolder is created.

.PARAMETER VmStorageRoot
  Destination root for imported VM files when using Copy mode.

.PARAMETER ImportMode
  Import strategy:
   - Copy (default): Copies VM to VmStorageRoot and generates new ID.
   - Register: Registers the VM in-place from the extracted location.
   - Restore: Restores the VM with original ID (can conflict with existing VM).

.PARAMETER VSwitchName
  Virtual switch to connect VM network adapters to after import.

.PARAMETER NoNetwork
  Disconnect VM network adapters after import.

.PARAMETER Force
  If a VM with the same name exists, remove it before importing.

.PARAMETER StartAfterRestore
  Start the VM after successful restore.

.PARAMETER KeepStaging
  Do not delete extracted staging folder.

.EXAMPLE
  Restore-VMBackup -BackupPath "D:\hvbak-archives\20260101\MyVM_20260101123456.7z" -ImportMode Copy -VmStorageRoot "D:\Hyper-V"

.EXAMPLE
  Restore-VMBackup -VmName "MyVM" -BackupRoot "D:\hvbak-archives" -Latest -VSwitchName "vSwitch" -StartAfterRestore
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $false)]
    [string]$BackupPath,

    [Parameter(Mandatory = $false)]
    [string]$VmName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$BackupRoot = "$env:USERPROFILE\hvbak-archives",

    [Parameter(Mandatory = $false)]
    [switch]$Latest,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$StagingRoot = "$env:TEMP\hvbak-restore",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$VmStorageRoot = "$env:ProgramData\Microsoft\Windows\Hyper-V",

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

Set-StrictMode -Version Latest

# Display help if no parameters provided
if ($PSBoundParameters.Count -eq 0) {
    Get-Help $MyInvocation.MyCommand.Path -Full
    return
}

function Resolve-BackupPathInput {
    param(
        [Parameter(Mandatory = $true)][string]$InputPath
    )

    $resolved = $null
    try { $resolved = (Resolve-Path -LiteralPath $InputPath -ErrorAction Stop).Path } catch {}

    if (-not $resolved) {
        throw "BackupPath not found: $InputPath"
    }

    $item = Get-Item -LiteralPath $resolved -ErrorAction Stop

    if ($item.PSIsContainer) {
        $latestArchive = Get-ChildItem -LiteralPath $item.FullName -Recurse -File -Filter '*.7z' -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if (-not $latestArchive) {
            throw "BackupPath points to a folder but no .7z archives were found under: $($item.FullName)"
        }

        Write-Log "BackupPath is a folder. Selected newest archive: $($latestArchive.FullName)"
        return $latestArchive.FullName
    }

    return $item.FullName
}

# Implicitly use -Latest when VmName is provided and BackupPath is not.
$useLatest = $Latest -or (-not [string]::IsNullOrWhiteSpace($VmName) -and [string]::IsNullOrWhiteSpace($BackupPath))

if ($useLatest -and [string]::IsNullOrWhiteSpace($VmName)) {
    throw "VmName is required to select the latest archive. Example: hvrestore -VmName 'MyVM' [-Latest]"
}

function Write-Log {
    param([Parameter(Mandatory = $true)][string]$Message)
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Write-Output "$ts  $Message"
}

function Get-SevenZipPath {
    $cmd = Get-Command 7z.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Path }

    $candidates = @(
        "$env:ProgramFiles\7-Zip\7z.exe",
        "$env:ProgramFiles(x86)\7-Zip\7z.exe"
    )

    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { return $c }
    }

    return $null
}

function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Administrator privileges are required to restore/import Hyper-V VMs."
    }
}

function Resolve-LatestBackup {
    param(
        [Parameter(Mandatory = $true)][string]$VmName,
        [Parameter(Mandatory = $true)][string]$BackupRoot
    )

    if (-not (Test-Path -LiteralPath $BackupRoot)) {
        throw "BackupRoot not found: $BackupRoot"
    }

    $safeVmName = $VmName -replace '[\\/:*?"<>|]', '_'
    $archiveRegex = ('^{0}_(\d{{14}})\.7z$' -f [regex]::Escape($safeVmName))

    $dateFolders = Get-ChildItem -LiteralPath $BackupRoot -Directory -ErrorAction Stop |
        Where-Object { $_.Name -match '^\d{8}$' } |
        Sort-Object Name -Descending

    $matches = foreach ($folder in $dateFolders) {
        $files = Get-ChildItem -LiteralPath $folder.FullName -File -Filter '*.7z' -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            if ($f.Name -match $archiveRegex) {
                $dt = $f.LastWriteTime
                try { $dt = [datetime]::ParseExact($Matches[1], 'yyyyMMddHHmmss', $null) } catch {}

                [PSCustomObject]@{
                    FullName = $f.FullName
                    SortKey  = $dt
                }
            }
        }
    }

    $latest = $matches | Sort-Object SortKey -Descending | Select-Object -First 1
    if (-not $latest) {
        throw "No backups found for VM '$VmName' under '$BackupRoot'."
    }

    return $latest.FullName
}

function Expand-BackupArchive {
    param(
        [Parameter(Mandatory = $true)][string]$SevenZip,
        [Parameter(Mandatory = $true)][string]$BackupPath,
        [Parameter(Mandatory = $true)][string]$OutDir
    )

    if (-not (Test-Path -LiteralPath $BackupPath)) {
        throw "Backup archive not found: $BackupPath"
    }

    if (-not (Test-Path -LiteralPath $OutDir)) {
        New-Item -Path $OutDir -ItemType Directory -Force | Out-Null
    }

    Write-Log "Extracting archive to staging: $OutDir"

    $args = @('x', '-y', "-o$OutDir", $BackupPath)
    $p = Start-Process -FilePath $SevenZip -ArgumentList $args -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -ne 0) {
        throw "7z extraction failed with exit code $($p.ExitCode)."
    }
}

function Find-ExportRoot {
    param([Parameter(Mandatory = $true)][string]$StagingDir)

    $vmcx = Get-ChildItem -LiteralPath $StagingDir -Recurse -File -Filter '*.vmcx' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($vmcx) { return $vmcx.Directory.FullName }

    $xml = Get-ChildItem -LiteralPath $StagingDir -Recurse -File -Filter '*.xml' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ieq 'Virtual Machines.xml' -or $_.Name -like '*.xml' } |
        Select-Object -First 1

    if ($xml) { return $xml.Directory.FullName }

    throw "Unable to locate a Hyper-V export root in staging directory: $StagingDir"
}

function Remove-ExistingVmIfNeeded {
    param(
        [Parameter(Mandatory = $true)][string]$TargetName,
        [Parameter(Mandatory = $true)][switch]$Force
    )

    $existing = Get-VM -Name $TargetName -ErrorAction SilentlyContinue
    if (-not $existing) { return }

    if (-not $Force) {
        throw "A VM named '$TargetName' already exists. Re-run with -Force to remove it before restore."
    }

    if ($PSCmdlet.ShouldProcess($TargetName, 'Remove existing VM')) {
        try {
            if ($existing.State -ne 'Off') {
                Stop-VM -Name $TargetName -TurnOff -Force -ErrorAction SilentlyContinue
            }
        } catch {}

        Remove-VM -Name $TargetName -Force -ErrorAction Stop
        Write-Log "Removed existing VM: $TargetName"
    }
}

function Import-FromExport {
    param(
        [Parameter(Mandatory = $true)][string]$ExportRoot,
        [Parameter(Mandatory = $true)][string]$ImportMode,
        [Parameter(Mandatory = $true)][string]$VmStorageRoot
    )

    $importParams = @{ Path = $ExportRoot; ErrorAction = 'Stop' }

    switch ($ImportMode) {
        'Copy' {
            $importParams.Copy = $true
            $importParams.GenerateNewId = $true
            $importParams.VirtualMachinePath = $VmStorageRoot
            $importParams.VhdDestinationPath = $VmStorageRoot
            $importParams.SnapshotFilePath = $VmStorageRoot
        }
        'Register' {
            $importParams.Register = $true
        }
        'Restore' {
            $importParams.Restore = $true
        }
    }

    if ($PSCmdlet.ShouldProcess($ExportRoot, "Import VM ($ImportMode)")) {
        return Import-VM @importParams
    }

    return $null
}

function Configure-Network {
    param(
        [Parameter(Mandatory = $true)][Microsoft.HyperV.PowerShell.VirtualMachine]$Vm,
        [Parameter(Mandatory = $false)][string]$VSwitchName,
        [Parameter(Mandatory = $false)][switch]$NoNetwork
    )

    if ($NoNetwork) {
        $adapters = Get-VMNetworkAdapter -VMName $Vm.Name -ErrorAction SilentlyContinue
        foreach ($a in $adapters) {
            if ($PSCmdlet.ShouldProcess($Vm.Name, "Disconnect network adapter '$($a.Name)'")) {
                Disconnect-VMNetworkAdapter -VMNetworkAdapter $a -ErrorAction SilentlyContinue
            }
        }
        return
    }

    if ($VSwitchName) {
        $sw = Get-VMSwitch -Name $VSwitchName -ErrorAction Stop
        $adapters = Get-VMNetworkAdapter -VMName $Vm.Name -ErrorAction SilentlyContinue
        foreach ($a in $adapters) {
            if ($PSCmdlet.ShouldProcess($Vm.Name, "Connect adapter '$($a.Name)' to switch '$VSwitchName'")) {
                Connect-VMNetworkAdapter -VMNetworkAdapter $a -SwitchName $sw.Name -ErrorAction Stop
            }
        }
    }
}

try {
    Assert-Admin

    Import-Module Hyper-V -ErrorAction Stop

    $sevenZip = Get-SevenZipPath
    if (-not $sevenZip) {
        throw "7-Zip (7z.exe) not found. Install 7-Zip or ensure 7z.exe is in PATH."
    }

    if ($useLatest) {
        $BackupPath = Resolve-LatestBackup -VmName $VmName -BackupRoot $BackupRoot
    }

    if ([string]::IsNullOrWhiteSpace($BackupPath)) {
        throw "BackupPath is required. Specify -BackupPath, or specify -VmName to restore the latest backup."
    }

    $BackupPath = Resolve-BackupPathInput -InputPath $BackupPath
    Write-Log "Using backup: $BackupPath"

    $leaf = Split-Path -Path $BackupPath -Leaf
    $restoreId = (Get-Date).ToString('yyyyMMddHHmmss')
    $stagingDir = Join-Path -Path $StagingRoot -ChildPath ("restore_{0}_{1}" -f ($leaf -replace '\.7z$',''), $restoreId)

    if (-not (Test-Path -LiteralPath $StagingRoot)) {
        New-Item -Path $StagingRoot -ItemType Directory -Force | Out-Null
    }

    Expand-BackupArchive -SevenZip $sevenZip -BackupPath $BackupPath -OutDir $stagingDir

    $exportRoot = Find-ExportRoot -StagingDir $stagingDir
    Write-Log "Detected export root: $exportRoot"

    # Determine imported VM name from export (best-effort). If multiple, Import-VM returns the actual object.
    # For collision checks, use -VmName if provided, else try to infer from archive name.
    $targetName = $VmName
    if (-not $targetName) {
        $targetName = ($leaf -split '_\d{14}\.7z$')[0]
    }

    if ($targetName) {
        Remove-ExistingVmIfNeeded -TargetName $targetName -Force:$Force
    }

    $vm = Import-FromExport -ExportRoot $exportRoot -ImportMode $ImportMode -VmStorageRoot $VmStorageRoot
    if (-not $vm) {
        Write-Log "WhatIf: import skipped."
        return
    }

    Write-Log "Imported VM: $($vm.Name) (Id: $($vm.Id))"

    Configure-Network -Vm $vm -VSwitchName $VSwitchName -NoNetwork:$NoNetwork

    # Best-effort ACL repair on imported VHDs (if function exists in the module scope)
    try {
        $vhdDrives = Get-VMHardDiskDrive -VMName $vm.Name -ErrorAction SilentlyContinue
        $paths = @($vhdDrives | Where-Object { $_.Path } | Select-Object -ExpandProperty Path)
        if ($paths.Count -gt 0 -and (Get-Command Repair-VhdAcl -ErrorAction SilentlyContinue)) {
            $csv = Join-Path -Path $stagingDir -ChildPath 'restored-vhds.csv'
            $paths | ForEach-Object { [PSCustomObject]@{ Path = $_ } } | Export-Csv -NoTypeInformation -Path $csv -Force
            Write-Log "Repairing VHD ACLs (best-effort) via Repair-VhdAcl using list: $csv"
            Repair-VhdAcl -VhdListCsv $csv -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Log "WARNING: VHD ACL repair step failed: $_"
    }

    if ($StartAfterRestore) {
        if ($PSCmdlet.ShouldProcess($vm.Name, 'Start VM')) {
            Start-VM -Name $vm.Name -ErrorAction Stop
        }
    }

    Write-Log "Restore completed."
}
finally {
    if (-not $KeepStaging) {
        try {
            if ($stagingDir -and (Test-Path -LiteralPath $stagingDir)) {
                Remove-Item -LiteralPath $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Removed staging directory: $stagingDir"
            }
        } catch {
        }
    } else {
        if ($stagingDir) {
            Write-Log "Keeping staging directory: $stagingDir"
        }
    }
}
