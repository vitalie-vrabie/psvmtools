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
    - All output from background jobs is streamed to the parent script via PowerShell pipelines (Receive-Job); no log files are created on disk.
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
  .\vmbak.ps1 -NamePattern "*"
  Exports all VMs to %USERPROFILE%\hvbak-archives\YYYYMMDD using default temp folder

.EXAMPLE
  .\vmbak.ps1 -NamePattern "srv-*" -Destination "D:\backups" -TempFolder "E:\temp"
  Exports VMs matching "srv-*" to D:\backups\YYYYMMDD using E:\temp as temporary folder

.EXAMPLE
  .\vmbak.ps1 -NamePattern "srv-*" -Destination "D:\backups" -ForceTurnOff:$false
  Exports VMs matching "srv-*" to D:\backups\YYYYMMDD without forcing power off on checkpoint failure.

.EXAMPLE
  .\vmbak.ps1 -NamePattern "web-*" -KeepCount 5
  Exports VMs matching "web-*" and keeps the 5 most recent backups, deleting older ones.

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
    Get-Help $MyInvocation.MyCommand.Path -Full
    exit 0
}

# --- Logging ---
function Log { param([string]$Text) $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); Write-Output "$ts  $Text" }

# --- Configuration ---
$ShutdownTimeoutSeconds = 180
$PollIntervalSeconds = 5
$TempRoot = $TempFolder

# Cancellation sentinel for this run (shared with child jobs)
$RunId = [guid]::NewGuid().ToString('N')
$script:CancelFile = Join-Path $TempRoot ("hvbak_cancel_{0}.flag" -f $RunId)
if (Test-Path -LiteralPath $script:CancelFile) { Remove-Item -LiteralPath $script:CancelFile -Force -ErrorAction SilentlyContinue }

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

    $perVmJob = Start-Job -ArgumentList $vmName, $safeVmName, $DateDestination, $TempRoot, $sevenZip, $ForceTurnOff, $GuestCredential, $PollIntervalSeconds, $ShutdownTimeoutSeconds, $KeepCount, $script:CancelFile -ScriptBlock {
        param(
            $vmName, $safeVmName, $DateDestination, $TempRoot, $sevenZip, $ForceTurnOff, $GuestCredential, $PollIntervalSeconds, $ShutdownTimeoutSeconds, $KeepCount, $CancelFile
        )

        # Do not create any log files; write messages to console only
        function LocalLog {
            param($t)
            $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            # Sanitize the message to avoid XML serialization issues
            $sanitized = $t -replace '[^\x20-\x7E\r\n\t]', '?'
            Write-Output "$ts  $sanitized"
        }

        function Assert-NotCancelled {
            param([string]$Phase)
            if (Test-Path -LiteralPath $CancelFile) {
                LocalLog ("Cancellation detected ({0}); aborting {1}" -f (Split-Path -Leaf $CancelFile), $Phase)
                throw "Operation cancelled by user"
            }
        }

        LocalLog ("Per-vm job started for {0}" -f $vmName)

        $result = [PSCustomObject]@{ VMName = $vmName; TempPath = $null; DestArchive = $null; Success = $false; Message = $null }

        # Track resources that need cleanup
        $snapshotName = $null
        $wasRunning = $false
        $vmTemp = $null
        $checkpointTs = (Get-Date).ToString("yyyyMMddHHmmss")
        $vmWasTurnedOff = $false

        try {
            Assert-NotCancelled "startup"

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

            Assert-NotCancelled "before checkpoint"

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

            Assert-NotCancelled "before export"

            # Export VM to per-vm folder
            try {
                LocalLog ("Exporting VM {0} to {1}" -f $vmName, $vmTemp)
                Export-VM -Name $vmName -Path $vmTemp -ErrorAction Stop
                LocalLog ("Export completed for {0}" -f $vmName)
                
                # Check if we were cancelled during export
                if ($script:JobCancelled) {
                    LocalLog ("Cancellation detected after export, aborting for {0}" -f $vmName)
                    throw "Operation cancelled by user"
                }
            } catch {
                LocalLog ("Export-VM failed or was cancelled for {0}: {1}" -f $vmName, $_)
                throw
            }

            Assert-NotCancelled "after export"

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
            
            Assert-NotCancelled "before snapshot removal / restart"

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

            Assert-NotCancelled "before 7z"

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
                # Add -bsp1 to get progress percentage updates
                $args = @("a","-t7z","-mx=1","-mmt=on","-bsp1",$tempArchive,"*")

                # Start 7z as a separate process with redirected output to capture progress
                $proc = $null
                $sevenZipPid = $null
                try {
                    $psi = New-Object System.Diagnostics.ProcessStartInfo
                    $psi.FileName = $sevenZip
                    $psi.Arguments = $args -join ' '
                    $psi.UseShellExecute = $false
                    $psi.RedirectStandardOutput = $true
                    $psi.RedirectStandardError = $true
                    $psi.CreateNoWindow = $true
                    $psi.WorkingDirectory = $vmTemp
                    
                    $proc = New-Object System.Diagnostics.Process
                    $proc.StartInfo = $psi
                    $proc.Start() | Out-Null
                    $sevenZipPid = $proc.Id
                    
                    LocalLog ("Started 7z process (PID: {0})" -f $sevenZipPid)
                    
                    # Set process priority to Idle
                    try {
                        $proc.PriorityClass = 'Idle'
                        LocalLog ("Set 7z process to Idle priority")
                    } catch {
                        LocalLog ("Failed to set 7z process priority: {0}" -f $_)
                    }
                    
                    # Read output asynchronously and parse for progress
                    $lastProgress = -1
                    while (-not $proc.HasExited) {
                        $line = $proc.StandardOutput.ReadLine()
                        if ($line) {
                            # Parse progress: 7z outputs lines like "  5%" or " 15%"
                            if ($line -match '^\s*(\d+)%') {
                                $currentProgress = [int]$Matches[1]
                                # Only log progress in 10% increments to reduce output spam
                                if ($currentProgress -ge ($lastProgress + 10)) {
                                    LocalLog ("[7z] Archiving progress: {0}%" -f $currentProgress)
                                    $lastProgress = $currentProgress
                                }
                            }
                        }
                        Start-Sleep -Milliseconds 100
                    }
                    
                    # Read any remaining output
                    $remainingOutput = $proc.StandardOutput.ReadToEnd()
                    $errorOutput = $proc.StandardError.ReadToEnd()
                    
                    if ($errorOutput) {
                        LocalLog ("7z stderr: {0}" -f $errorOutput)
                    }
                    
                    $exit = $proc.ExitCode
                    LocalLog ("7z process (PID: {0}) exited with code: {1}" -f $sevenZipPid, $exit)
                    
                    # Check if archive was created
                    if (Test-Path $tempArchive) {
                        $archiveSize = (Get-Item $tempArchive).Length
                        LocalLog ("7z archive created: {0} (size: {1} bytes)" -f $tempArchive, $archiveSize)
                    } else {
                        LocalLog ("WARNING: 7z archive not found at: {0}" -f $tempArchive)
                    }
                    
                    # Only throw if exit code is non-zero
                    if ($exit -ne 0) {
                        throw "7z exited with non-zero code $exit"
                    }
                    
                } catch {
                    LocalLog ("Error while running 7z process: {0}" -f $_)
                    LocalLog ("7z command was: {0} {1}" -f $sevenZip, ($args -join ' '))
                    LocalLog ("Working directory was: {0}" -f $vmTemp)
                    LocalLog ("Target archive: {0}" -f $tempArchive)
                    throw
                } finally {
                    if ($proc) {
                        try { 
                            if (-not $proc.HasExited) { 
                                $proc.Kill() 
                            }
                            $proc.Dispose() 
                        } catch {}
                    }
                }
            } finally {
                if ($pushed) { Pop-Location }
            }

            # Move archive to final destination
            try {
                $destArchiveLeaf = Split-Path -Path $tempArchive -Leaf
                $destArchivePath = Join-Path -Path $DateDestination -ChildPath $destArchiveLeaf

                LocalLog ("Moving archive from temp {0} -> destination {1}" -f $tempArchive, $destArchivePath)
                
                # Verify source archive exists before attempting move
                if (-not (Test-Path -Path $tempArchive)) {
                    throw "Source archive not found at: $tempArchive"
                }
                
                # Verify destination directory exists
                if (-not (Test-Path -Path $DateDestination)) {
                    LocalLog ("Destination directory does not exist, creating: {0}" -f $DateDestination)
                    New-Item -Path $DateDestination -ItemType Directory -Force -ErrorAction Stop | Out-Null
                }
                
                # Attempt the move with detailed error capture
                try {
                    Move-Item -Path $tempArchive -Destination $destArchivePath -Force -ErrorAction Stop
                    LocalLog ("Moved archive to destination: {0}" -f $destArchivePath)
                } catch {
                    # Capture detailed error information
                    $errorMsg = "Move-Item failed. Error: $($_.Exception.Message)"
                    if ($_.Exception.InnerException) {
                        $errorMsg += " Inner: $($_.Exception.InnerException.Message)"
                    }
                    LocalLog ("MOVE ERROR: {0}" -f $errorMsg)
                    LocalLog ("Source exists: {0}, Size: {1} bytes" -f (Test-Path $tempArchive), (if (Test-Path $tempArchive) { (Get-Item $tempArchive).Length } else { "N/A" }))
                    LocalLog ("Destination dir exists: {0}" -f (Test-Path $DateDestination))
                    LocalLog ("Destination path: {0}" -f $destArchivePath)
                    throw $errorMsg
                }

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
                $errorDetail = $_.ToString()
                LocalLog ("Failed to move archive to destination: {0}" -f $errorDetail)
                $result.Success = $false
                $result.Message = "Archive created but Move-Item failed: $errorDetail"
            }
        } catch {
            LocalLog ("Per-vm job error for {0}: {1}" -f $vmName, $_)
            $result.Success = $false
            if (-not $result.Message) { $result.Message = $_.ToString() }
        } finally {
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

            # --- CLEANUP OLD PER-VM ARCHIVES: Keep current + (KeepCount-1) previous archives for this VM ---
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

                if ($allVmArchives.Count -gt $KeepCount) {
                    $sorted = $allVmArchives | Sort-Object SortKey -Descending
                    $keepArchives = $sorted | Select-Object -First $KeepCount
                    $deleteArchives = $sorted | Select-Object -Skip $KeepCount
                  
                    if ($KeepCount -eq 1) {
                        LocalLog ("Found {0} archives for {1}. Keeping {2}. Deleting {3} older archives..." -f 
                            $allVmArchives.Count, $vmName, $keepArchives[0].Name, $deleteArchives.Count)
                    } elseif ($KeepCount -eq 2) {
                        LocalLog ("Found {0} archives for {1}. Keeping {2} and {3}. Deleting {4} older archives..." -f 
                            $allVmArchives.Count, $vmName, $keepArchives[0].Name, $keepArchives[1].Name, $deleteArchives.Count)
                    } else {
                        $keepNames = ($keepArchives | Select-Object -First 3 | ForEach-Object { $_.Name }) -join ', '
                        if ($KeepCount -gt 3) { $keepNames += ", ..." }
                        LocalLog ("Found {0} archives for {1}. Keeping {2} most recent ({3}). Deleting {4} older archives..." -f 
                            $allVmArchives.Count, $vmName, $KeepCount, $keepNames, $deleteArchives.Count)
                    }
                
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
                } elseif ($allVmArchives.Count -eq $KeepCount) {
                    if ($KeepCount -eq 1) {
                        LocalLog ("Found 1 archive for {0}: {1}. No cleanup needed." -f $vmName, $allVmArchives[0].Name)
                    } elseif ($KeepCount -eq 2) {
                        LocalLog ("Found 2 archives for {0}: {1} and {2}. No cleanup needed." -f 
                            $vmName, $allVmArchives[0].Name, $allVm Archives[1].Name)
                    } else {
                        LocalLog ("Found {0} archives for {1}. No cleanup needed." -f $KeepCount, $vmName)
                    }
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
            
            # 4. Verify and delete temp directory if empty
            if ($vmTemp -and (Test-Path $vmTemp)) {
                try {
                    $tempContents = Get-ChildItem -Path $vmTemp -Force -ErrorAction SilentlyContinue
                    if (-not $tempContents -or $tempContents.Count -eq 0) {
                        LocalLog ("Cleanup: Temp directory {0} is empty, deleting..." -f $vmTemp)
                        Remove-Item -LiteralPath $vmTemp -Force -ErrorAction Stop
                        LocalLog ("Cleanup: Successfully deleted empty temp directory: {0}" -f $vmTemp)
                    } else {
                        LocalLog ("Cleanup: Temp directory {0} still contains {1} items, keeping it" -f $vmTemp, $tempContents.Count)
                    }
                } catch {
                    LocalLog ("Cleanup: Failed to check/delete temp directory {0}: {1}" -f $vmTemp, $_)
                }
            }
        }

        # Ensure result object only contains safe, serializable types before returning
        # This prevents XML serialization errors when returning from background jobs
        [PSCustomObject]@{
            VMName = [string](if ($result.VMName) { $result.VMName } else { "" })
            TempPath = [string](if ($result.TempPath) { $result.TempPath } else { "" })
            DestArchive = [string](if ($result.DestArchive) { $result.DestArchive } else { "" })
            Success = [bool]$result.Success
            Message = [string](if ($result.Message) { $result.Message } else { "" })
        }

    }

    $perVmJobs += $perVmJob
}

if ($perVmJobs.Count -eq 0) {
    Log "No per-vm jobs queued. Exiting."
    exit 0
}

# --- MONITOR JOBS AND STREAM OUTPUT VIA PIPELINE ---
$global:VmbkpCancelled = $false

# Store these in script scope so they're accessible in the event handler
$script:TempRootForCleanup = $TempRoot
$script:DateDestinationForCleanup = $DateDestination

$consoleHandler = [ConsoleCancelEventHandler]{
    param($sender, $e)
    try {
        $global:VmbkpCancelled = $true
        # Signal cancellation for all child jobs
        try { New-Item -Path $script:CancelFile -ItemType File -Force | Out-Null } catch {}

        Write-Output ""
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  *** Ctrl+C received: Initiating graceful shutdown ***"
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Stopping all background jobs and triggering cleanup..."

        foreach ($j in $perVmJobs) {
            try {
                $jobState = $j.State
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Stopping job: $($j.Name) (ID: $($j.Id), State: $jobState)"
                Stop-Job -Job $j -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 500
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Job stop requested: $($j.Name)"
            } catch {
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Error stopping job $($j.Id): $_"
            }
        }
        
        # Wait a bit more for cleanup operations to complete in the jobs
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Waiting for job cleanup to complete..."
        Start-Sleep -Seconds 2
        
        # Collect any output from the jobs' cleanup operations
        foreach ($j in $perVmJobs) {
            try {
                $cleanupOutput = Receive-Job -Job $j -ErrorAction SilentlyContinue
                if ($cleanupOutput) {
                    $cleanupOutput | ForEach-Object { Write-Output $_ }
                }
            } catch {}
        }
        
        # Kill all 7z.exe processes that might be running from this script
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Terminating any running 7z.exe processes..."
        try {
            $sevenZipProcesses = Get-Process -Name "7z" -ErrorAction SilentlyContinue
            if ($sevenZipProcesses) {
                foreach ($proc in $sevenZipProcesses) {
                    try {
                        # Check if the process command line contains our temp or destination paths to avoid killing unrelated 7z processes
                        $procCmd = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction SilentlyContinue).CommandLine
                        if ($procCmd -and ($procCmd -like "*$script:TempRootForCleanup*" -or $procCmd -like "*$script:DateDestinationForCleanup*")) {
                            $proc.Kill()
                            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Killed 7z.exe process (PID: $($proc.Id))"
                        }
                    } catch {
                        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Failed to kill 7z.exe (PID: $($proc.Id)): $_"
                    }
                }
            } else {
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  No 7z.exe processes found"
            }
        } catch {
            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Error checking for 7z processes: $_"
        }
        
        # Clean up temp folders - this catches any incomplete exports
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Cleaning up temporary folders..."
        try {
            $tempPattern = Join-Path $script:TempRootForCleanup '*'
            $tempItems = Get-ChildItem -Path $script:TempRootForCleanup -ErrorAction SilentlyContinue
            if ($tempItems) {
                $itemCount = $tempItems.Count
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Found $itemCount temp items to remove..."
                foreach ($item in $tempItems) {
                    try {
                        Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Removed: $($item.Name)"
                    } catch {}
                }
            } else {
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  No temp items to clean up"
            }
        } catch {
            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Error during temp cleanup: $_"
        }
        
        # Additional VM cleanup - ensure any export snapshots are removed and VMs are restarted
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Checking for orphaned export snapshots..."
        try {
            # Get all VMs that match the original pattern
            $allVms = Get-VM -Name $NamePattern -ErrorAction SilentlyContinue
            if ($allVms) {
                foreach ($vm in $allVms) {
                    try {
                        # Look for export snapshots (they start with "export_")
                        $exportSnapshots = Get-VMSnapshot -VMName $vm.Name -ErrorAction SilentlyContinue | 
                            Where-Object { $_.Name -like "export_*" }
                        
                        if ($exportSnapshots) {
                            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Found orphaned snapshot(s) for VM: $($vm.Name)"
                            foreach ($snap in $exportSnapshots) {
                                try {
                                    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Removing snapshot: $($snap.Name)"
                                    Remove-VMSnapshot -VMSnapshot $snap -ErrorAction Stop
                                    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Snapshot removed: $($snap.Name)"
                                } catch {
                                    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Failed to remove snapshot $($snap.Name): $_"
                                }
                            }
                        }
                        
                        # Check if VM needs to be restarted (if it's Off but was likely running)
                        if ($vm.State -eq 'Off') {
                            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  VM $($vm.Name) is Off, attempting to start..."
                            try {
                                Start-VM -Name $vm.Name -ErrorAction Stop
                                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  VM $($vm.Name) started"
                            } catch {
                                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Could not start VM $($vm.Name): $_"
                            }
                        }
                    } catch {
                        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Error processing VM $($vm.Name): $_"
                    }
                }
            }
        } catch {
            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Error during VM cleanup: $_"
        }
        
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  *** Shutdown complete - Exiting ***"
        Write-Output ""
    } catch {
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Error in Ctrl+C handler: $_"
    }
    $e.Cancel = $true
}

[Console]::add_CancelKeyPress($consoleHandler)

Log ("Monitoring {0} jobs and streaming output..." -f $perVmJobs.Count)

try {
    while ($true) {
        if ($global:VmbkpCancelled) { break }

        # Get running jobs
        $runningJobs = $perVmJobs | Where-Object { $_.State -eq 'Running' }
        $runningCount = ($runningJobs | Measure-Object).Count
        
        # Receive and display output from all jobs (running and completed)
        foreach ($job in $perVmJobs) {
            try {
                # Receive available output without removing it from the job yet
                $output = Receive-Job -Job $job -ErrorAction SilentlyContinue
                if ($output) {
                    # Stream output directly to console
                    $output | ForEach-Object { Write-Output $_ }
                }
            } catch {
                # Silently ignore receive errors during monitoring
            }
        }
        
        if (-not $runningJobs -or $runningCount -eq 0) { break }

        # Pump job state without blocking
        if (-not $global:VmbkpCancelled -and $runningJobs) {
            try { Wait-Job -Job $runningJobs -Timeout 1 -ErrorAction SilentlyContinue | Out-Null } catch {}
        }

        Start-Sleep -Milliseconds 750
    }
} finally {
    try { [Console]::remove_CancelKeyPress($consoleHandler) } catch {}

    try { if (Test-Path -LiteralPath $script:CancelFile) { Remove-Item -LiteralPath $script:CancelFile -Force -ErrorAction SilentlyContinue } } catch {}

    # If cancelled, do final cleanup
    if ($global:VmbkpCancelled) {
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  Performing final cleanup after cancellation..."
        
        # Remove any remaining jobs
        foreach ($j in $perVmJobs) {
            try { Remove-Job -Job $j -Force -ErrorAction SilentlyContinue } catch {}
        }
        
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  All background jobs removed"
        Log "Operation cancelled by user. Exiting."
        exit 130  # Standard exit code for Ctrl+C termination
    }
}

# Final processing - get results and any remaining output
foreach ($j in $perVmJobs) {
    # First, get any remaining output
    try {
        $remainingOutput = Receive-Job -Job $j -ErrorAction SilentlyContinue
        if ($remainingOutput) {
            $remainingOutput | ForEach-Object { Write-Output $_ }
        }
    } catch {
        # Output already received in monitoring loop
    }
    
    # Then try to get the result object
    try {
        $res = Receive-Job -Job $j -ErrorAction Stop -Keep
        
        try { $remaining = ($perVmJobs | Where-Object { $_.State -eq 'Running' }).Count } catch { $remaining = 'N/A' }

        if ($res -and $res.Success -eq $true) {
            Log ("SUMMARY: Job completed successfully for {0} -> {1}" -f $res.VMName, $res.DestArchive)
        } else {
            if ($res) {
                Log ("SUMMARY: Job failed for {0}: {1}" -f $res.VMName, $res.Message)
            }
        }
    } catch {
        # If we can't get the result object, check job state
        $jobState = $j.State
        if ($jobState -eq 'Failed') {
            Log ("SUMMARY: Job Id {0} FAILED. See output above for details." -f $j.Id)
        } elseif ($jobState -eq 'Completed') {
            Log ("SUMMARY: Job Id {0} completed. See output above for details." -f $j.Id)
        }
    }

    try { Remove-Job -Job $j -Force -ErrorAction SilentlyContinue } catch {}
}

Log "All operations completed."
exit 0
