#requires -Version 5.1

<#$
.SYNOPSIS
  Sample usages for backing up VMs with PSHVTools.

.DESCRIPTION
  Examples for `Invoke-VMBackup` and its aliases `hvbak` / `hv-bak`.

.NOTES
  - Run elevated on the Hyper-V host.
  - Requires 7-Zip (7z.exe).
#>

Import-Module pshvtools

# List help and parameters
Get-Help Invoke-VMBackup -Full
Get-Help hvbak -Examples

# 1) Backup all VMs to default destination (%USERPROFILE%\hvbak-archives\YYYYMMDD)
hvbak -NamePattern "*"

# 2) Backup a single VM
hvbak -NamePattern "MyVM"

# 3) Backup a set of VMs using wildcard
hv-bak -NamePattern "srv-*"

# 4) Use a custom backup destination (a date folder is created under it)
hvbak -NamePattern "*" -Destination "D:\hvbak-archives"

# 5) Use a custom temp folder (faster disk recommended)
hvbak -NamePattern "*" -Destination "D:\hvbak-archives" -TempFolder "E:\hvbak-temp"

# 6) Keep more backups per VM (default is 2)
hvbak -NamePattern "*" -KeepCount 7

# 7) Disable force turn-off fallback if checkpoint creation fails
hvbak -NamePattern "*" -ForceTurnOff:$false

# 8) Cap 7-Zip compression threads (optional)
hvbak -NamePattern "*" -ThreadCap 4
