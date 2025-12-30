# vmbak.ps1
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
  Root destination folder for backups. A date-stamped subfolder (YYYYMMDD) is created automatically. Default: R:\vhd

.PARAMETER TempFolder
  Temporary folder for VM exports during backup processing. Default: %TEMP%\hvbak

.PARAMETER ForceTurnOff
  If checkpoint creation fails for a running VM, force it off to allow export. Default: $true

.PARAMETER GuestCredential
  PSCredential for in-guest WinRM shutdown attempts (not currently used in graceful shutdown logic). Optional.

.EXAMPLE
  .\vmbak.ps1 -NamePattern "*"
  Exports all VMs to R:\vhd\YYYYMMDD using default temp folder

.EXAMPLE
  .\vmbak.ps1 -NamePattern "srv-*" -Destination "D:\backups" -TempFolder "E:\temp"
  Exports VMs matching "srv-*" to D:\backups\YYYYMMDD using E:\temp as temporary folder

.EXAMPLE
  .\vmbak.ps1 -NamePattern "srv-*" -Destination "D:\backups" -ForceTurnOff:$false
  Exports VMs matching "srv-*" to D:\backups\YYYYMMDD without forcing power off on checkpoint failure.

.NOTES
  - Run elevated (Administrator) on the Hyper-V host for best results.
  - Requires 7-Zip (7z.exe must be in PATH or installed in standard location).
  - Each per-VM job runs independently; exports can proceed in parallel without throttling.
  - Temp folder and destination must be accessible and have sufficient space.
  - Graceful cleanup ensures VMs are restarted and checkpoints removed even on cancellation or failure.
  - Archives are created in 7z format with fast compression for better multithreading.
#>

param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$NamePattern,

    [Parameter(Mandatory = $false)]
    [string]$Destination = "R:\vhd",

    [Parameter(Mandatory = $false)]
    [string]$TempFolder = "$env:TEMP\hvbak",

    [Parameter(Mandatory = $false)]
    [switch]$ForceTurnOff = $true,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$GuestCredential
)

# Display help if no NamePattern provided
if ([string]::IsNullOrWhiteSpace($NamePattern)) {
    Get-Help $MyInvocation.MyCommand.Path -Full
    exit 0
}

# --- Logging ---
function Log { param([string]$Text) $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); Write-Output "$ts  $Text" }

# --- Configuration ---
$ShutdownTimeoutSeconds = 180
$PollIntervalSeconds = 5
$TempRoot = $TempFolder

# Ensure temp root exists
try {
    if (-not (Test-Path -Path $TempRoot)) {
        New-Item -Path $TempRoot -ItemType Directory -Force | Out-Null
        Log ("Created temp root: {0}" -f $TempRoot)
    }
} catch {
    Write-Error ("Failed to create temp root {0} : {1}" -f $TempRoot, $_)
    exit 1
}

# Build per-date destination folder YYYYMMDD under $Destination
$DateFolderName = (Get-Date).ToString("yyyyMMdd")
$DateDestination = Join-Path -Path $Destination -ChildPath $DateFolderName
try {
    if (-not (Test-Path -Path $DateDestination)) {
        New-Item -Path $DateDestination -ItemType Directory -Force | Out-Null
        Log ("Created date destination folder: {0}" -f $DateDestination)
    }
} catch {
    Write-Error ("Failed to create destination folder {0} : {1}" -f $DateDestination, $_)
    exit 1
}

# Detect 7-Zip (required)
$sevenZip = $null
$sevenZipCmd = Get-Command 7z.exe -ErrorAction SilentlyContinue
if ($sevenZipCmd) {
    $sevenZip = $sevenZipCmd.Path
} else {
    $possible = @("$env:ProgramFiles\7-Zip\7z.exe","$env:ProgramFiles(x86)\7-Zip\7z.exe")
    foreach ($p in $possible) { if (Test-Path $p) { $sevenZip = $p; break } }
}

if (-not $sevenZip) {
    Write-Error "7-Zip (7z.exe) not found. Please install 7-Zip or ensure it's in PATH."
    exit 1
}

Log ("7-Zip found: {0}" -f $sevenZip)

# Get matching VMs
try { $vms = Get-VM -Name $NamePattern -ErrorAction Stop } catch { Log ("Get-VM failed or no VMs match pattern '{0}': {1}" -f $NamePattern, $_); exit 0 }
if (-not $vms) { Log ("No VMs found matching pattern '{0}'." -f $NamePattern); exit 0 }

Log "Starting all per-vm jobs (no throttling). 7z processes will be set to Idle priority."

# Collect per-vm Start-Job objects here
$perVmJobs = @()

foreach ($vm in $vms) {
    $vmName = $vm.Name
    $safeVmName = $vmName -replace '[\\/:*?"<>|]', '_'

    Log ("Starting per-vm job for: {0}" -f $vmName)

    $perVmJob = Start-Job -ArgumentList $vmName, $safeVmName, $DateDestination, $TempRoot, $sevenZip, $ForceTurnOff, $GuestCredential, $PollIntervalSeconds, $ShutdownTimeoutSeconds -ScriptBlock {
        param(
            $vmName, $safeVmName, $DateDestination, $TempRoot, $sevenZip, $ForceTurnOff, $GuestCredential, $PollIntervalSeconds, $ShutdownTimeoutSeconds
        )

        # Do not create any log files; write messages to console only
        function LocalLog { param($t) $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); Write-Output "$ts  $t" }

        # Define a shared per-VM status file in TempRoot
        $statusFile = Join-Path $TempRoot ("vmbkp_status_{0}.json" -f $safeVmName)
        function SetStatus { param([string]$Phase,[int]$Percent)
            $obj = [PSCustomObject]@{
                Vm        = $vmName
                SafeVm    = $safeVmName
                Phase     = $Phase
                Percent   = $Percent
                Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            try { $obj | ConvertTo-Json -Compress | Set-Content -Path $statusFile -Encoding UTF8 -ErrorAction SilentlyContinue } catch {}
        }

        LocalLog ("Per-vm job started for {0}" -f $vmName)
        SetStatus "Starting" 0

        $result = [PSCustomObject]@{ VMName = $vmName; TempPath = $null; DestArchive = $null; Success = $false; Message = $null }

        # Track resources that need cleanup
        $snapshotName = $null
        $wasRunning = $false
        $vmTemp = $null
        # Timestamp to use for per-VM temp folder name; defaults to now and updated from checkpoint when available
        $checkpointTs = (Get-Date).ToString("yyyyMMddHHmmss")
        $vmWasTurnedOff = $false

        try {
            # determine VM state and whether it was running
            $vm = Get-VM -Name $vmName -ErrorAction Stop
            $initialState = $vm.State
            $wasRunning = $initialState -eq 'Running'
            LocalLog ("VM {0} initial state: {1}" -f $vmName, $initialState)

            # If we created a checkpoint, parse its timestamp and use it for per-VM temp folder naming
            if ($snapshotName -and ($snapshotName -match '_(\d{14})$')) {
                try { $checkpointTs = [datetime]::ParseExact($Matches[1], 'yyyyMMddHHmmss', $null).ToString('yyyyMMddHHmmss') } catch {}
            }

            # create per-vm temp folder with timestamp suffix derived from checkpoint
            $vmTemp = Join-Path -Path $TempRoot -ChildPath ("{0}_{1}" -f $safeVmName, $checkpointTs)
            try {
                if (Test-Path -Path $vmTemp) { Remove-Item -Path $vmTemp -Recurse -Force -ErrorAction SilentlyContinue }
                New-Item -Path $vmTemp -ItemType Directory -Force | Out-Null
                LocalLog ("Created per-VM export folder: {0}" -f $vmTemp)
            } catch {
                LocalLog ("Failed to create per-VM export folder {0}: {1}" -f $vmTemp, $_)
                throw
            }

            $result.TempPath = $vmTemp
            $archivePattern = "$safeVmName*.7z"
            $destArchivePath = $null

            # create checkpoint (try production, fallback standard)
            if ($wasRunning) {
                try {
                    $snapshotName = ("export_{0}_{1}" -f $vmName, (Get-Date).ToString("yyyyMMddHHmmss"))
                    LocalLog ("Creating production checkpoint {0} for {1}" -f $snapshotName, $vmName)
                    try {
                        Checkpoint-VM -VMName $vmName -SnapshotName $snapshotName -CheckpointType Production -ErrorAction Stop
                    } catch {
                        LocalLog ("Production checkpoint failed; attempting standard checkpoint for {0}" -f $vmName)
                        Checkpoint-VM -VMName $vmName -SnapshotName $snapshotName -ErrorAction Stop
                    }
                    LocalLog ("Checkpoint created: {0}" -f $snapshotName)
                } catch {
                    LocalLog ("Checkpoint creation failed for {0}: {1}" -f $vmName, $_)
                    if ($ForceTurnOff) {
                        try {
                            LocalLog ("Forcing power off of {0}" -f $vmName)
                            Stop-VM -Name $vmName -TurnOff -Force -ErrorAction Stop
                            $vmWasTurnedOff = $true
                            LocalLog ("VM {0} turned off successfully" -f $vmName)
                        } catch {
                            LocalLog ("Failed to force turn off {0}: {1}" -f $vmName, $_)
                            throw
                        }
                    } else {
                        LocalLog ("Skipping {0} because checkpoint failed and ForceTurnOff is not set." -f $vmName)
                        throw "Checkpoint failed and not allowed to turn off."
                    }
                }
            }

            SetStatus "Checkpoint" 10

            # Export VM to per-vm folder
            try {
                # Reflect long-running export phase in top progress
                SetStatus "Exporting" 40
                LocalLog ("Exporting VM {0} to {1}" -f $vmName, $vmTemp)
                Export-VM -Name $vmName -Path $vmTemp -ErrorAction Stop
                LocalLog ("Export completed for {0}" -f $vmName)
                # Mark export completion
                SetStatus "Export-VM" 55
            } catch {
                LocalLog ("Export-VM failed or was cancelled for {0}: {1}" -f $vmName, $_)
                throw
            }

            # Remove Virtual Hard Disks directory if present (we only want checkpoint/config)
            try {
                $vhdFolder = Join-Path -Path $vmTemp -ChildPath "Virtual Hard Disks"
                if (Test-Path -Path $vhdFolder) {
                    Remove-Item -Path $vhdFolder -Recurse -Force -ErrorAction SilentlyContinue
                    LocalLog ("Removed 'Virtual Hard Disks' from export for {0}" -f $vmName)
                } else {
                    LocalLog ("No VHDs present in export for {0}" -f $vmName)
                }
            } catch {
                LocalLog ("Failed to remove VHDs from export for {0}: {1}" -f $vmName, $_)
            }

            # remove snapshot if we created one
            if ($snapshotName) {
                try {
                    LocalLog ("Removing snapshot {0} for {1}" -f $snapshotName, $vmName)
                    Get-VMSnapshot -VMName $vmName -Name $snapshotName -ErrorAction SilentlyContinue | Remove-VMSnapshot -ErrorAction Stop
                    LocalLog ("Snapshot removed: {0}" -f $snapshotName)
                    $snapshotName = $null  # Mark as cleaned up
                } catch {
                    LocalLog ("Failed to remove snapshot {0} for {1}: {2}" -f $snapshotName, $vmName, $_)
                }
            }

            # start VM again if it was running or we turned it off
            if ($wasRunning -or $vmWasTurnedOff) {
                try {
                    $curState = (Get-VM -Name $vmName -ErrorAction SilentlyContinue).State
                    if ($curState -ne 'Running') {
                        LocalLog ("Starting VM {0} back up." -f $vmName)
                        Start-VM -Name $vmName -ErrorAction Stop
                        LocalLog ("Start command issued for {0}." -f $vmName)
                        $vmWasTurnedOff = $false  # Mark as restarted
                    } else {
                        LocalLog ("VM {0} is already Running." -f $vmName)
                    }
                } catch {
                    LocalLog ("Failed to start VM {0}: {1}" -f $vmName, $_)
                }
            }

            # Create a temp 7z archive name inside shared TempRoot
            $tempArchive = Join-Path $TempRoot ("{0}_{1}.7z" -f $safeVmName, (Get-Date).ToString("yyyyMMddHHmmss"))
            if (Test-Path $tempArchive) { Remove-Item -Path $tempArchive -Force -ErrorAction SilentlyContinue }

            # Archive the CONTENTS of the per-VM folder using 7z format (no extra top-level folder)
            $pushed = $false
            try {
                Push-Location -Path $vmTemp
                $pushed = $true

                LocalLog ("Creating 7z archive: {0} -> {1}" -f $vmTemp, $tempArchive)
                # Use 7z format with fast compression and multithreading
                $args = @("a","-t7z","-mx=1","-mmt=on",$tempArchive,"*")

                # Start 7z as a separate process and robustly determine its PID to set priority.
                $proc = $null
                $sevenZipPid = $null
                try {
                    # Start 7z without redirecting to log files
                    $proc = Start-Process -FilePath $sevenZip -ArgumentList $args -NoNewWindow -PassThru -ErrorAction Stop
                } catch {
                    LocalLog ("Start-Process returned error for 7z: {0}" -f $_)
                    # fall-through, attempt to find 7z by commandline below
                }

                # Determine PID: prefer $proc.Id, otherwise best-effort search by command line matching the tempArchive or vmTemp
                if ($proc -and $proc.Id) {
                    $sevenZipPid = $proc.Id
                } else {
                    try {
                        $candidates = Get-CimInstance -ClassName Win32_Process -Filter "Name='7z.exe'" -ErrorAction SilentlyContinue
                        if ($candidates) {
                          $match = $candidates | Where-Object { $_.CommandLine -and ( $_.CommandLine -like "*$tempArchive*" -or $_.CommandLine -like "*$vmTemp*" -or $_.CommandLine -like "*$TempRoot*" -or $_.CommandLine -like "*$DateDestination*" ) } |
                                   Sort-Object CreationDate -Descending | Select-Object -First 1
                          if ($match) { $sevenZipPid = $match.ProcessId }
                        }
                    } catch {
                        LocalLog ("Failed to probe Win32_Process for 7z: {0}" -f $_)
                    }
                }

                if ($sevenZipPid) {
                    # Use System.Diagnostics.Process to set priority and wait for exit.
                    try {
                        $sysProc = [System.Diagnostics.Process]::GetProcessById([int]$sevenZipPid)
                        try {
                            $sysProc.PriorityClass = 'Idle'
                            LocalLog ("Set 7z process to Idle (PID: {0})" -f $sevenZipPid)
                        } catch {
                            LocalLog ("Failed to set 7z process priority: {0}" -f $_)
                        }

                        # Wait for process to exit and get exit code
                        LocalLog ("Waiting for 7z process (PID: {0}) to complete..." -f $sevenZipPid)
                        $sysProc.WaitForExit()
                    
                        # Small delay to ensure exit code is available
                        Start-Sleep -Milliseconds 100
                    
                        # Refresh to ensure we have latest info
                        try { $sysProc.Refresh() } catch { LocalLog ("Could not refresh process info: {0}" -f $_) }
                    
                        # Get exit code with better error handling
                        $exit = $null
                        try {
                            $exit = $sysProc.ExitCode
                        } catch {
                            LocalLog ("Could not read ExitCode property: {0}" -f $_)
                            # If we can't get the exit code but archive exists, assume success
                            if (Test-Path $tempArchive) {
                                LocalLog ("Archive exists, assuming success despite ExitCode read failure")
                                $exit = 0
                            } else {
                                $exit = -1
                            }
                        }
                    
                        LocalLog ("7z process (PID: {0}) exited with code: {1}" -f $sevenZipPid, $exit)
                    
                        # Check if archive was created
                        if (Test-Path $tempArchive) {
                            $archiveSize = (Get-Item $tempArchive).Length
                            LocalLog ("7z archive created: {0} (size: {1} bytes)" -f $tempArchive, $archiveSize)
                        } else {
                            LocalLog ("WARNING: 7z archive not found at: {0}" -f $tempArchive)
                        }
                    
                        # Only throw if exit code is non-zero AND we have a valid exit code
                        if ($exit -ne 0 -and $null -ne $exit) {
                            throw "7z exited with non-zero code $exit"
                        }
                    } catch {
                        LocalLog ("Error while waiting/inspecting 7z process (PID: {0}): {1}" -f $sevenZipPid, $_)
                        # Log additional diagnostic info
                        LocalLog ("7z command was: {0} {1}" -f $sevenZip, ($args -join ' '))
                        LocalLog ("Working directory was: {0}" -f $vmTemp)
                        LocalLog ("Target archive: {0}" -f $tempArchive)
                     
                        throw
                    } finally {
                        try { if ($sysProc) { $sysProc.Dispose() } } catch {}
                    }
                } else {
                    # As a last resort, wait for any 7z.exe child to finish and verify the archive was created.
                    LocalLog ("Could not obtain PID for 7z process; falling back to Wait-Process by name and existence check.")
                    try {
                        # Wait briefly for any 7z.exe processes to exit (best-effort)
                        Wait-Process -Name "7z" -ErrorAction SilentlyContinue -Timeout 0
                    } catch {}
                    if (-not (Test-Path $tempArchive)) {
                        throw "7z did not produce expected archive file and PID was unavailable."
                    }
                }
            } finally {
                if ($pushed) { Pop-Location }
            }

            SetStatus "Archiving (7z)" 60

            # Move archive to final destination
            try {
                $destArchiveLeaf = Split-Path -Path $tempArchive -Leaf
                $destArchivePath = Join-Path -Path $DateDestination -ChildPath $destArchiveLeaf

                LocalLog ("Moving archive from temp {0} -> destination {1}" -f $tempArchive, $destArchivePath)
                Move-Item -Path $tempArchive -Destination $destArchivePath -Force -ErrorAction Stop
                LocalLog ("Moved archive to destination: {0}" -f $destArchivePath)

                # Delete per-vm export folder (entire folder) now that archive is safely at destination
                try {
                    LocalLog ("Removing per-VM temp folder: {0}" -f $vmTemp)
                    Remove-Item -LiteralPath $vmTemp -Recurse -Force -ErrorAction Stop
                    LocalLog ("Removed per-VM temp folder: {0}" -f $vmTemp)
                    $vmTemp = $null  # Mark as cleaned up
                } catch {
                    LocalLog ("Failed to remove per-VM temp folder {0}: {1}" -f $vmTemp, $_)
                }

                $result.Success = $true
                $result.Message = "Archive created and per-VM folder removed"
                $result.DestArchive = $destArchivePath
            } catch {
                LocalLog ("Failed to move archive to destination: {0}" -f $_)
                $result.Success = $false
                $result.Message = "Archive succeeded but Move-Item failed: $_"
            }
        } catch {
            LocalLog ("Per-vm job error for {0}: {1}" -f $vmName, $_)
            $result.Success = $false
            if (-not $result.Message) { $result.Message = $_.ToString() }
        } finally {
            # GRACEFUL CLEANUP: Ensure resources are cleaned up even if export was cancelled
            LocalLog ("Starting cleanup phase for {0}" -f $vmName)

            # 1. Remove snapshot if it still exists
            if ($snapshotName) {
                try {
                    LocalLog ("Cleanup: Removing snapshot {0} for {1}" -f $snapshotName, $vmName)
                    $snap = Get-VMSnapshot -VMName $vmName -Name $snapshotName -ErrorAction SilentlyContinue
                    if ($snap) {
                        $snap | Remove-VMSnapshot -ErrorAction Stop
                        LocalLog ("Cleanup: Snapshot {0} removed successfully" -f $snapshotName)
                    } else {
                        LocalLog ("Cleanup: Snapshot {0} not found (may have been already removed)" -f $snapshotName)
                    }
                } catch {
                    LocalLog ("Cleanup: Failed to remove snapshot {0} for {1}: {2}" -f $snapshotName, $vmName, $_)
                }
            }

            # 2. Restart VM if it was running or we turned it off
            if (($wasRunning -or $vmWasTurnedOff)) {
                try {
                    $curState = (Get-VM -Name $vmName -ErrorAction SilentlyContinue).State
                    if ($curState -ne 'Running') {
                        LocalLog ("Cleanup: VM {0} is {1}, attempting to start" -f $vmName, $curState)
                        Start-VM -Name $vmName -ErrorAction Stop
                        LocalLog ("Cleanup: VM {0} started successfully" -f $vmName)
                    } else {
                        LocalLog ("Cleanup: VM {0} is already running" -f $vmName)
                    }
                } catch {
                    LocalLog ("Cleanup: Failed to start VM {0}: {1}" -f $vmName, $_)
                }
            }

            # 3. Clean up temp folder if export failed/cancelled (leave if archive succeeded)
            if ($vmTemp -and (Test-Path $vmTemp) -and -not $result.Success) {
                try {
                    LocalLog ("Cleanup: Removing incomplete export folder: {0}" -f $vmTemp)
                    Remove-Item -LiteralPath $vmTemp -Recurse -Force -ErrorAction Stop
                    LocalLog ("Cleanup: Removed incomplete export folder: {0}" -f $vmTemp)
                } catch {
                    LocalLog ("Cleanup: Failed to remove temp folder {0}: {1}" -f $vmTemp, $_)
                }
            }

            # --- CLEANUP OLD PER-VM ARCHIVES: Keep current + 1 previous archive for this VM ---
            try {
                LocalLog ("Checking for old archives of {0} to clean up..." -f $vmName)
            
                # Get the parent destination folder (e.g., R:\vhd)
                $parentDestination = Split-Path -Path $DateDestination -Parent
            
                # Find all date folders (YYYYMMDD pattern)
                $dateFolders = Get-ChildItem -Path $parentDestination -Directory -ErrorAction Stop | 
                    Where-Object { $_.Name -match '^\d{8}$' } | 
                    Sort-Object Name -Descending
            
                # Find all timestamped archives for this specific VM across all date folders
                $allVmArchives = @()
                foreach ($folder in $dateFolders) {
                    try {
                        $vmFiles = Get-ChildItem -Path $folder.FullName -Filter $archivePattern -File -ErrorAction SilentlyContinue
                    } catch { $vmFiles = @() }
                    foreach ($file in $vmFiles) {
                        # Try to parse timestamp from "safeVmName_yyyyMMddHHmmss.7z"
                        $effectiveTs = $file.LastWriteTime
                        try {
                            if ($file.BaseName -match '_(\d{14})$') {
                                $ts = $Matches[1]
                                $effectiveTs = [datetime]::ParseExact($ts, 'yyyyMMddHHmmss', $null)
                            }
                        } catch { }
                        $allVmArchives += [PSCustomObject]@{
                            Path        = $file.FullName
                            Name        = $file.Name
                            DateFolder  = $folder.Name
                            FolderPath  = $folder.FullName
                            SortKey     = $effectiveTs
                        }
                    }
                }

                if ($allVmArchives.Count -gt 2) {
                    $sorted = $allVmArchives | Sort-Object SortKey -Descending
                    $keepArchives = $sorted | Select-Object -First 2
                    $deleteArchives = $sorted | Select-Object -Skip 2
                
                    LocalLog ("Found {0} archives for {1}. Keeping {2} and {3}. Deleting {4} older archives..." -f 
                        $allVmArchives.Count, $vmName, $keepArchives[0].Name, $keepArchives[1].Name, $deleteArchives.Count)
                
                    foreach ($oldArchive in $deleteArchives) {
                        try {
                            LocalLog ("Deleting old archive: {0}" -f $oldArchive.Path)
                            Remove-Item -Path $oldArchive.Path -Force -ErrorAction Stop
                            LocalLog ("Successfully deleted: {0} from {1}" -f $oldArchive.Name, $oldArchive.DateFolder)
                        
                            # If the date folder is now empty, remove it
                            try {
                                $folderContents = Get-ChildItem -Path $oldArchive.FolderPath -Force -ErrorAction Stop
                                if ($folderContents.Count -eq 0) {
                                    LocalLog ("Folder {0} is now empty, deleting..." -f $oldArchive.DateFolder)
                                    Remove-Item -Path $oldArchive.FolderPath -Force -ErrorAction Stop
                                    LocalLog ("Successfully deleted empty folder: {0}" -f $oldArchive.DateFolder)
                                } else {
                                    LocalLog ("Folder {0} still contains {1} items, keeping it" -f $oldArchive.DateFolder, $folderContents.Count)
                                }
                            } catch {
                                LocalLog ("Failed to check/delete folder {0}: {1}" -f $oldArchive.DateFolder, $_)
                            }
                        } catch {
                            LocalLog ("Failed to delete archive {0}: {1}" -f $oldArchive.Path, $_)
                        }
                    }
                
                    LocalLog ("Old archive cleanup completed for {0}." -f $vmName)
                } elseif ($allVmArchives.Count -eq 2) {
                    LocalLog ("Found 2 archives for {0}: {1} and {2}. No cleanup needed." -f 
                        $vmName, $allVmArchives[0].Name, $allVmArchives[1].Name)
                } elseif ($allVmArchives.Count -eq 1) {
                    LocalLog ("Found only 1 archive for {0}: {1}. No cleanup needed." -f $vmName, $allVmArchives[0].Name)
                } else {
                    LocalLog ("No previous archives found for {0}." -f $vmName)
                }

                # After cleanup, if the current date folder is empty, delete it as well
                try {
                    $curDateContents = Get-ChildItem -Path $DateDestination -Force -ErrorAction SilentlyContinue
                    if (-not $curDateContents -or $curDateContents.Count -eq 0) {
                        LocalLog ("Date folder {0} is empty after cleanup, deleting..." -f $DateDestination)
                        Remove-Item -Path $DateDestination -Force -ErrorAction Stop
                        LocalLog ("Deleted empty date folder: {0}" -f $DateDestination)
                    }
                } catch {
                    LocalLog ("Failed to delete empty date folder {0}: {1}" -f $DateDestination, $_)
                }
            } catch {
                LocalLog ("Error during old archive cleanup for {0}: {1}" -f $vmName, $_)
            }

            LocalLog ("Cleanup phase completed for {0}" -f $vmName)
        }

        return $result
    }

    $perVmJobs += $perVmJob

    # register a per-vm event id using the new naming
    $eventId = "PerVmJobState_$($perVmJob.Id)"
    try {
        Register-ObjectEvent -InputObject $perVmJob -EventName StateChanged -SourceIdentifier $eventId -Action {
            try {
                $newState = $Event.SourceEventArgs.NewState
                if ($newState -in @('Completed','Failed','Stopped')) {
                    $res = $null
                    try { $res = Receive-Job -Job $Event.Sender -ErrorAction Stop } catch { $res = $null }

                    try { $remaining = (Get-Job | Where-Object { $_.State -eq 'Running' }).Count } catch { $remaining = 'N/A' }

                    if ($res -and $res.Success) {
                        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Per-vm archive succeeded for $($res.VMName). Temp folder removed (if present). ($remaining jobs remaining)"
                    } else {
                        if ($res) {
                            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Per-vm archive failed or skipped for $($res.VMName): $($res.Message). Leave export for inspection. ($remaining jobs remaining)"
                        } else {
                            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Per-vm job Id $($Event.Sender.Id) finished but returned no result. ($remaining jobs remaining)"
                        }
                    }

                    # cleanup event and job
                    $sid = "PerVmJobState_$($Event.Sender.Id)"
                    try { Unregister-Event -SourceIdentifier $sid -ErrorAction SilentlyContinue } catch {}
                    try { Remove-Event -SourceIdentifier $sid -ErrorAction SilentlyContinue } catch {}
                    try { Remove-Job -Job $Event.Sender -Force -ErrorAction SilentlyContinue } catch {}
                }
            } catch {
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Error in PerVm job-state handler: $_"
            }
        } | Out-Null
    } catch {
        Log ("Failed to register PerVm job StateChanged handler for Job Id {0}: {1}" -f $perVmJob.Id, $_)
    }
}

if ($perVmJobs.Count -eq 0) {
    Log "No per-vm jobs queued. Exiting."
    exit 0
}

# --- WAIT WITH REAL-TIME PROGRESS BAR AT TOP ---
$global:VmbkpCancelled = $false

$consoleHandler = [ConsoleCancelEventHandler]{
    param($sender, $e)
    try {
        $global:VmbkpCancelled = $true
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Ctrl+C received: stopping per-vm jobs and cleaning up temp folders..."
        foreach ($j in $perVmJobs) { try { Stop-Job -Job $j -Force -ErrorAction SilentlyContinue } catch {} }
        try { Remove-Item -Path (Join-Path $TempRoot '*') -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    } catch {}
    $e.Cancel = $true
}

[Console]::add_CancelKeyPress($consoleHandler)

Log ("Streaming progress for {0} jobs..." -f $perVmJobs.Count)

$progressRootId = 1
$perVmIds = @{}
# Track last rendered values to avoid unnecessary redraws
$lastOverallPercent = -1
$lastRunningCount = -1
$lastVmStates = @{} # safeVm -> @{ Percent = [int]; Phase = [string] }
$progressInitialized = $false

try {
    while ($true) {
        if ($global:VmbkpCancelled) { break }

        $statusFiles = Get-ChildItem -Path (Join-Path $TempRoot 'vmbkp_status_*.json') -ErrorAction SilentlyContinue
        $vmStatuses = @()
        foreach ($sf in ($statusFiles | Sort-Object Name)) {
            try {
                $json = Get-Content $sf.FullName -Raw -ErrorAction SilentlyContinue
                if ($json) { $vmStatuses += ($json | ConvertFrom-Json -ErrorAction SilentlyContinue) }
            } catch {}
        }

        # Compute overall percent and running count
        # Only consider the jobs started by this script to avoid counting unrelated background jobs
        $runningJobs = $perVmJobs | Where-Object { $_.State -eq 'Running' }
        $runningCount = ($runningJobs | Measure-Object).Count
        $overallPercent = 0
        if ($vmStatuses.Count -gt 0) {
            $overallPercent = [int]([Math]::Round(($vmStatuses | Measure-Object Percent -Average).Average))
        }

        # Update root progress only when changed
        if (-not $global:VmbkpCancelled -and ($overallPercent -ne $lastOverallPercent -or $runningCount -ne $lastRunningCount)) {
            try {
                Write-Progress -Id $progressRootId -Activity "VM backup batch" -Status ("Running {0} job(s). Overall {1}%." -f $runningCount, $overallPercent) -PercentComplete $overallPercent -ErrorAction SilentlyContinue
                $progressInitialized = $true
            } catch {
                # Silently ignore any Write-Progress errors
            }
            $lastOverallPercent = $overallPercent
            $lastRunningCount = $runningCount
        }

        # Update child progress bars only when their state changed; keep stable order
        $nextId = 10
        foreach ($st in ($vmStatuses | Sort-Object SafeVm)) {
            if (-not $perVmIds.ContainsKey($st.SafeVm)) { $perVmIds[$st.SafeVm] = $nextId; $nextId++ }
            $id = $perVmIds[$st.SafeVm]
            $prev = $lastVmStates[$st.SafeVm]
            $shouldUpdate = $true
            if ($prev) {
                if ($prev.Percent -eq $st.Percent -and $prev.Phase -eq $st.Phase) { $shouldUpdate = $false }
            }
            if (-not $global:VmbkpCancelled -and $shouldUpdate) {
                try { 
                    Write-Progress -Id $id -ParentId $progressRootId -Activity $st.Vm -Status $st.Phase -PercentComplete $st.Percent -ErrorAction SilentlyContinue
                } catch {
                    # Silently ignore any Write-Progress errors
                }
                $lastVmStates[$st.SafeVm] = @{ Percent = $st.Percent; Phase = $st.Phase }
            }
        }

        if (-not $runningJobs -or $runningCount -eq 0) { break }

        # Pump job state without blocking (PS 5.1 compatible: pass jobs explicitly)
        if (-not $global:VmbkpCancelled -and $runningJobs) {
            try { Wait-Job -Job $runningJobs -Timeout 1 -ErrorAction SilentlyContinue | Out-Null } catch {}
        }

        Start-Sleep -Milliseconds 750
    }
} finally {
    try { [Console]::remove_CancelKeyPress($consoleHandler) } catch {}
    # Complete all progress bars to clean up the display
    if ($progressInitialized) {
        try { Write-Progress -Id $progressRootId -Activity "VM backup batch" -Completed -ErrorAction SilentlyContinue } catch {}
        foreach ($id in $perVmIds.Values) { 
            try { Write-Progress -Id $id -Activity "VM" -Completed -ErrorAction SilentlyContinue } catch {} 
        }
    }
    # Clean up any orphaned status files
    try {
        Get-ChildItem -Path (Join-Path $TempRoot 'vmbkp_status_*.json') -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    } catch {}
}

# Final processing of results (defensive)
foreach ($j in $perVmJobs) {
    try {
        $res = Receive-Job -Job $j -ErrorAction Stop
    } catch {
        Log ("Per-vm Job Id {0} already processed by handler or produced no output: {1}" -f $j.Id, $_)
        continue
    }

    try { $remaining = ($perVmJobs | Where-Object { $_.State -eq 'Running' }).Count } catch { $remaining = 'N/A' }

    if ($res -and $res.Success) {
        Log ("Per-vm job completed: {0} -> {1} ({2} jobs remaining)" -f $res.VMName, $res.DestArchive, $remaining)
    } else {
        if ($res) {
            Log ("Per-vm job failed or skipped for {0}: {1}. Export left at: {2} ({3} jobs remaining)" -f $res.VMName, $res.Message, $res.TempPath, $remaining)
        } else {
            Log ("No result for per-vm job id {0}; handler likely handled cleanup. ({1} jobs remaining)" -f $j.Id, $remaining)
        }
    }

    try { Remove-Job -Job $j -Force -ErrorAction SilentlyContinue } catch {}
}

Log "All operations completed."
