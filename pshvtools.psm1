# hvbak.psm1
# PowerShell module for VM backup operations

function Invoke-VMBackup {
    <#
    .SYNOPSIS
      Export Hyper-V VMs using checkpoints (live export), archive each VM export, and clean up.

    .DESCRIPTION
      For each VM matching the provided NamePattern this script:
        - Attempts a Production checkpoint (falls back to a standard checkpoint).
        - Exports VM configuration and snapshots to a per-VM temp folder.
        - Exports only the checkpoint/config (VHDs removed if present).
        - Archives the per-VM export using 7z format and removes the per-VM temp folder as soon as that VM's archive completes.
        - Uses per-vm background jobs (named/perVmJob) to run each VM's workflow concurrently.
        - No throttling: all per-vm jobs are started immediately. Only the external 7z process is set to Idle priority.
        - Implements graceful cleanup in a finally block: removes checkpoints, restarts VMs, and cleans up incomplete exports even if the export is cancelled via Hyper-V Manager or Ctrl+C.
        - Per-job logs are written to the shared TempRoot to survive per-VM folder deletion.
        - Supports Ctrl+C cancellation: stops all background jobs, kills related 7z.exe processes, and removes temp contents.

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

    .EXAMPLE
      hvbak -NamePattern "*"
      Exports all VMs to %USERPROFILE%\hvbak-archives\YYYYMMDD using default temp folder

    .EXAMPLE
      hv-bak -NamePattern "srv-*" -Destination "D:\backups" -TempFolder "E:\temp"
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
        [int]$KeepCount = 2
    )

    # Display help if no NamePattern provided
    if ([string]::IsNullOrWhiteSpace($NamePattern)) {
        Get-Help Invoke-VMBackup -Full
        return
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

    # Execute the script
    & $scriptPath @params
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
      
      Use -WhatIf to preview actions without making changes.

    .PARAMETER WhatIf
      Preview actions without making changes.

    .PARAMETER VhdFolder
      Path to folder containing VHD/VHDX files to fix recursively.

    .PARAMETER VhdListCsv
      Path to CSV file with columns: Path (required), VMId (optional GUID without braces).

    .PARAMETER LogFile
      Path to log file. Default: C:\Temp\FixVhdAcl.log

    .EXAMPLE
      Repair-VhdAcl -WhatIf
      Preview ACL fixes for all VMs on the host

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
      - Available as 'Repair-VhdAcl' and 'fix-vhd-acl' commands
    #>

    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf,

        [Parameter(Mandatory = $false)]
        [string]$VhdFolder,

        [Parameter(Mandatory = $false)]
        [string]$VhdListCsv,

        [Parameter(Mandatory = $false)]
        [string]$LogFile = "$env:TEMP\FixVhdAcl.log"
    )

    # Get the path to the actual script
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "fix-vhd-acl.ps1"
    
    if (-not (Test-Path $scriptPath)) {
        Write-Error "fix-vhd-acl.ps1 not found at: $scriptPath"
        return
    }

    # Build parameter splatting
    $params = @{
        LogFile = $LogFile
    }

    if ($WhatIf) {
        $params.WhatIf = $true
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

# Create aliases for shorter commands
New-Alias -Name hvbak -Value Invoke-VMBackup -Force
New-Alias -Name hv-bak -Value Invoke-VMBackup -Force
New-Alias -Name fix-vhd-acl -Value Repair-VhdAcl -Force

# Export the functions and aliases
Export-ModuleMember -Function Invoke-VMBackup, Repair-VhdAcl -Alias hvbak, hv-bak, fix-vhd-acl
