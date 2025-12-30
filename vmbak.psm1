# vmbak.psm1
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
        - Per-job logs are written to the shared TempRoot (E:\vmbkp.tmp) to survive per-VM folder deletion.
        - Supports Ctrl+C cancellation: stops all background jobs, kills related 7z.exe processes, and removes temp contents.

    .PARAMETER NamePattern
      Wildcard pattern to match VM names (e.g., "*" for all VMs, "web-*" for VMs starting with "web-").

    .PARAMETER Destination
      Root destination folder for backups. A date-stamped subfolder (YYYYMMDD) is created automatically. Default: R:\vhd

    .PARAMETER ForceTurnOff
      If checkpoint creation fails for a running VM, force it off to allow export. Default: $true

    .PARAMETER GuestCredential
      PSCredential for in-guest WinRM shutdown attempts (not currently used in graceful shutdown logic). Optional.

    .EXAMPLE
      vmbak -NamePattern "*"
      Exports all VMs to R:\vhd\YYYYMMDD

    .EXAMPLE
      vm-bak -NamePattern "srv-*" -Destination "D:\backups"
      Exports VMs matching "srv-*" to D:\backups\YYYYMMDD using the hyphenated alias.

    .EXAMPLE
      vmbak -NamePattern "srv-*" -Destination "D:\backups" -ForceTurnOff:$false
      Exports VMs matching "srv-*" to D:\backups\YYYYMMDD without forcing power off on checkpoint failure.

    .NOTES
      - Run elevated (Administrator) on the Hyper-V host for best results.
      - Requires 7-Zip (7z.exe must be in PATH or installed in standard location).
      - Each per-VM job runs independently; exports can proceed in parallel without throttling.
      - Temp folder (E:\vmbkp.tmp) and destination (R:\vhd by default) must be accessible.
      - Graceful cleanup ensures VMs are restarted and checkpoints removed even on cancellation or failure.
      - Archives are created in 7z format with fast compression for better multithreading.
      - Available as both 'vmbak' and 'vm-bak' commands.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$NamePattern,

        [Parameter(Mandatory = $false)]
        [string]$Destination = "R:\vhd",

        [Parameter(Mandatory = $false)]
        [switch]$ForceTurnOff = $true,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$GuestCredential
    )

    # Display help if no NamePattern provided
    if ([string]::IsNullOrWhiteSpace($NamePattern)) {
        Get-Help Invoke-VMBackup -Full
        return
    }

    # Get the path to the actual script
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "vmbak.ps1"
    
    if (-not (Test-Path $scriptPath)) {
        Write-Error "vmbak.ps1 not found at: $scriptPath"
        return
    }

    # Build parameter splatting
    $params = @{
        NamePattern = $NamePattern
        Destination = $Destination
        ForceTurnOff = $ForceTurnOff
    }

    if ($GuestCredential) {
        $params.GuestCredential = $GuestCredential
    }

    # Execute the script
    & $scriptPath @params
}

# Create aliases for shorter commands
New-Alias -Name vmbak -Value Invoke-VMBackup -Force
New-Alias -Name vm-bak -Value Invoke-VMBackup -Force

# Export the function and aliases
Export-ModuleMember -Function Invoke-VMBackup -Alias vmbak, vm-bak
