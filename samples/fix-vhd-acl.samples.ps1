#requires -Version 5.1

<#$
.SYNOPSIS
  Sample usages for repairing VHD/VHDX permissions after restore/copy.

.DESCRIPTION
  Examples for `Repair-VhdAcl` and its alias `fix-vhd-acl`.

.NOTES
  - Run elevated on the Hyper-V host.
#>

Import-Module pshvtools

# List help and parameters
Get-Help Repair-VhdAcl -Full
Get-Help fix-vhd-acl -Examples

# 1) Preview ACL fixes for all VMs on the host
fix-vhd-acl -WhatIf

# 2) Apply ACL fixes for all VMs on the host
fix-vhd-acl

# 3) Fix ACLs for all VHD/VHDX files under a folder
fix-vhd-acl -VhdFolder "D:\RestoredVMs"

# 4) Fix ACLs using a CSV list of VHD paths
# CSV columns: Path (required), VMId (optional)
$csv = "C:\temp\vhds.csv"
"Path,VMId" | Out-File -FilePath $csv -Encoding utf8
'"D:\Hyper-V\MyVM\disk0.vhdx",""' | Add-Content -Path $csv

fix-vhd-acl -VhdListCsv $csv

# 5) Custom log file
Repair-VhdAcl -LogFile "C:\Logs\FixVhdAcl.log" -VhdFolder "D:\Hyper-V"
