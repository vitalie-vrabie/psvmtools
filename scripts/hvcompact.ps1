<#
.SYNOPSIS
  Compact all VHDs of VMs specified as a parameter with * wildcard in their names.

.DESCRIPTION
  For each VM matching the provided NamePattern this script:
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
  .\hvcompact.ps1 -NamePattern "*"
  Compacts all VHDs of all VMs (shuts down and restarts them automatically).

.EXAMPLE
  .\hvcompact.ps1 -NamePattern "srv-*"
  Compacts all VHDs of VMs matching "srv-*" (auto shutdown/startup).

.EXAMPLE
  .\hvcompact.ps1 "web-*" -NoAutoShutdown
  Compacts VHDs of VMs matching "web-*" (requires VMs to be already stopped).

.NOTES
  - Run elevated (Administrator) on the Hyper-V host.
  - By default, running VMs are automatically stopped before compaction and restarted after.
  - Use -NoAutoShutdown to manage VM state manually.
  - Compaction can be time-consuming depending on VHD size.
  - Compaction releases unused space from the VHD to the host storage.
  - Supports Ctrl+C cancellation.
#>

param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$NamePattern,
    
    [Parameter(Mandatory = $false)]
    [switch]$NoAutoShutdown = $false
)

# Allow passing VM name as first raw arg (e.g. from cmd files) even if caller forgets -NamePattern
if ([string]::IsNullOrWhiteSpace($NamePattern) -and $args.Count -ge 1 -and -not [string]::IsNullOrWhiteSpace([string]$args[0])) {
    $NamePattern = [string]$args[0]
}

# Display help if no NamePattern provided
if ([string]::IsNullOrWhiteSpace($NamePattern)) {
    Get-Help $PSCommandPath -Full
    exit
}

# Verify admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator."
    exit 1
}

try {
    # Get VMs matching the pattern
    Write-Host "Searching for VMs matching pattern: $NamePattern" -ForegroundColor Cyan
    $vms = @(Get-VM -Name $NamePattern -ErrorAction Stop)

    if ($vms.Count -eq 0) {
        Write-Host "No VMs found matching pattern: $NamePattern" -ForegroundColor Yellow
        exit 0
    }

    Write-Host "Found $($vms.Count) VM(s) to process" -ForegroundColor Green
    Write-Host ""

    # Track which VMs were running so we can restart them
    $runningVms = @()
    $totalDisksCompacted = 0
    $totalErrors = 0

    # Phase 1: Shutdown running VMs (if not -NoAutoShutdown)
    if (-not $NoAutoShutdown) {
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Phase 1: Shutting down running VMs..." -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        
        foreach ($vm in $vms) {
            if ($vm.State -eq "Running") {
                Write-Host "Stopping: $($vm.Name)" -ForegroundColor Yellow
                try {
                    Stop-VM -Name $vm.Name -Force -ErrorAction Stop
                    $runningVms += $vm.Name
                    Write-Host "  Stop command sent" -ForegroundColor Green
                } catch {
                    Write-Host "  ERROR: Failed to stop VM - $_" -ForegroundColor Red
                    $totalErrors++
                }
            }
        }
        
        # Wait for VMs to fully shutdown
        if ($runningVms.Count -gt 0) {
            Write-Host ""
            Write-Host "Waiting for VMs to stop..." -ForegroundColor Yellow
            $maxRetries = 30
            $retries = 0
            
            while ($retries -lt $maxRetries) {
                $allStopped = $true
                foreach ($vmName in $runningVms) {
                    $vmState = (Get-VM -Name $vmName).State
                    if ($vmState -ne "Off") {
                        $allStopped = $false
                        break
                    }
                }
                
                if ($allStopped) {
                    Write-Host "All VMs stopped successfully" -ForegroundColor Green
                    break
                }
                
                Write-Host "  Waiting... ($retries/$maxRetries)" -ForegroundColor Gray
                Start-Sleep -Seconds 1
                $retries++
            }
            
            if ($retries -ge $maxRetries) {
                Write-Host "WARNING: Some VMs did not stop within timeout" -ForegroundColor Yellow
            }
        }
        Write-Host ""
    }

    # Phase 2: Compact VHDs
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Phase 2: Compacting VHDs..." -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    foreach ($vm in $vms) {
        $vmName = $vm.Name
        
        # Refresh VM state from latest snapshot
        $currentVm = Get-VM -Name $vmName -ErrorAction Stop
        $vmState = $currentVm.State

        Write-Host "Processing VM: $vmName (State: $vmState)" -ForegroundColor Cyan

        # Check if VM is stopped (should be after Phase 1, or user passed -NoAutoShutdown with stopped VMs)
        if ($vmState -ne "Off") {
            Write-Host "  WARNING: VM is not in stopped state. Skipping compaction." -ForegroundColor Yellow
            continue
        }

        try {
            # Get all hard disk drives for this VM
            $disks = @(Get-VMHardDiskDrive -VMName $vmName -ErrorAction Stop)

            if ($disks.Count -eq 0) {
                Write-Host "  No VHDs attached to this VM" -ForegroundColor Gray
                continue
            }

            Write-Host "  Found $($disks.Count) disk(s) attached" -ForegroundColor Gray

            foreach ($disk in $disks) {
                $diskPath = $disk.Path
                $diskController = $disk.ControllerNumber
                $diskLocation = $disk.ControllerLocation

                if (-not $diskPath) {
                    Write-Host "    WARNING: Disk controller $diskController, location $diskLocation has no path. Skipping." -ForegroundColor Yellow
                    continue
                }

                if (-not (Test-Path $diskPath)) {
                    Write-Host "    WARNING: Disk path not found: $diskPath" -ForegroundColor Yellow
                    continue
                }

                Write-Host "    Compacting: $diskPath" -ForegroundColor Gray

                try {
                    # Compact the VHD using full reclamation
                    Optimize-VHD -Path $diskPath -Mode Full -ErrorAction Stop
                    Write-Host "      SUCCESS: Compaction completed" -ForegroundColor Green
                    $totalDisksCompacted++
                } catch {
                    Write-Host "      ERROR: Compaction failed - $_" -ForegroundColor Red
                    $totalErrors++
                }
            }
        } catch {
            Write-Host "  ERROR: Failed to process VM - $_" -ForegroundColor Red
            $totalErrors++
        }

        Write-Host ""
    }

    # Phase 3: Restart VMs that were running (if not -NoAutoShutdown)
    if (-not $NoAutoShutdown -and $runningVms.Count -gt 0) {
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Phase 3: Starting VMs..." -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        
        foreach ($vmName in $runningVms) {
            Write-Host "Starting: $vmName" -ForegroundColor Yellow
            try {
                Start-VM -Name $vmName -ErrorAction Stop
                Write-Host "  Started successfully" -ForegroundColor Green
            } catch {
                Write-Host "  ERROR: Failed to start VM - $_" -ForegroundColor Red
                $totalErrors++
            }
        }
        Write-Host ""
    }

    # Summary
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Compaction Summary:" -ForegroundColor Cyan
    Write-Host "  VMs processed: $($vms.Count)" -ForegroundColor Green
    Write-Host "  Disks compacted: $totalDisksCompacted" -ForegroundColor Green
    Write-Host "  VMs restarted: $($runningVms.Count)" -ForegroundColor Green
    Write-Host "  Errors: $totalErrors" -ForegroundColor $(if ($totalErrors -gt 0) { "Red" } else { "Green" })
    Write-Host "========================================" -ForegroundColor Cyan

    if ($totalErrors -gt 0) {
        exit 1
    }

} catch {
    Write-Error "Fatal error: $_"
    exit 1
}
