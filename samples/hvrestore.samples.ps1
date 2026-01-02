#requires -Version 5.1

<#$
.SYNOPSIS
  Sample usages for restoring/importing VMs from hvbak archives with PSHVTools.

.DESCRIPTION
  Examples for `Restore-VMBackup` and its alias `hvrestore`.

.NOTES
  - Run elevated on the Hyper-V host.
  - Requires 7-Zip (7z.exe).
  - `ImportMode Copy` is usually safest (new VM ID, avoids collisions).
  - `DestinationRoot` can be used as a single "where should it go" root.
#>

Import-Module pshvtools

# List help and parameters
Get-Help Restore-VMBackup -Full
Get-Help hvrestore -Examples

# Common inputs
$vmName = "MyVM"
$backupRoot = "D:\hvbak-archives"

# 1) Restore latest backup for a VM (Copy is default). Files will be copied to VmStorageRoot.
hvrestore -VmName $vmName -BackupRoot $backupRoot -Latest -ImportMode Copy -VmStorageRoot "D:\Hyper-V"

# 2) Restore latest backup for a VM using DestinationRoot as the storage root (Copy mode)
hvrestore -VmName $vmName -BackupRoot $backupRoot -Latest -ImportMode Copy -DestinationRoot "D:\Hyper-V"

# 3) In-place restore: extract under DestinationRoot and register from there (no separate staging).
#    If ImportMode is omitted, DestinationRoot implies Register.
hvrestore -VmName $vmName -BackupRoot $backupRoot -Latest -DestinationRoot "E:\RestoredVMs" -NoNetwork

# 4) Restore from an explicit archive path
hvrestore -BackupPath "D:\hvbak-archives\20260101\MyVM_20260101123456.7z" -ImportMode Copy -DestinationRoot "D:\Hyper-V"

# 5) Replace an existing VM with the same name
hvrestore -VmName $vmName -BackupRoot $backupRoot -Latest -Force -ImportMode Copy -DestinationRoot "D:\Hyper-V"

# 6) Connect VM networking after import
hvrestore -VmName $vmName -BackupRoot $backupRoot -Latest -ImportMode Copy -DestinationRoot "D:\Hyper-V" -VSwitchName "vSwitch"

# 7) Start VM after restore
hvrestore -VmName $vmName -BackupRoot $backupRoot -Latest -ImportMode Copy -DestinationRoot "D:\Hyper-V" -StartAfterRestore

# 8) Keep extracted staging folder (useful for debugging)
hvrestore -VmName $vmName -BackupRoot $backupRoot -Latest -ImportMode Copy -DestinationRoot "D:\Hyper-V" -KeepStaging

# 9) Register/Restore modes (advanced)
# Register: registers VM in-place from extracted location (no copy)
hvrestore -VmName $vmName -BackupRoot $backupRoot -Latest -ImportMode Register -DestinationRoot "E:\RestoredVMs" -NoNetwork

# Restore: attempts to keep original VM ID (can conflict if VM exists)
hvrestore -VmName $vmName -BackupRoot $backupRoot -Latest -ImportMode Restore -DestinationRoot "D:\Hyper-V" -NoNetwork
