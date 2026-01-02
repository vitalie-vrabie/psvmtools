#requires -Version 5.1

<#$
.SYNOPSIS
  Sample usages for recovering orphaned Hyper-V VMs (configs on disk but not registered).

.DESCRIPTION
  Examples for `Restore-OrphanedVMs` and its alias `hvrecover`.

.NOTES
  - Run elevated on the Hyper-V host.
#>

Import-Module pshvtools

# List help and parameters
Get-Help Restore-OrphanedVMs -Full
Get-Help hvrecover -Examples

# 1) Preview what would be registered (default scans ProgramData\...\Hyper-V\Virtual Machines)
hvrecover -WhatIf

# 2) Scan a custom Hyper-V storage root (auto-detects 'Virtual Machines' subfolder if present)
hvrecover -VmConfigRoot "D:\Hyper-V" -WhatIf

# 3) Include legacy XML configs (only if you expect very old VMs)
hvrecover -VmConfigRoot "D:\Hyper-V" -IncludeXml -WhatIf

# 4) Register in-place (default)
hvrecover -VmConfigRoot "D:\Hyper-V"

# 5) Copy to a new storage root and generate a new ID
Restore-OrphanedVMs -VmConfigRoot "D:\Hyper-V" -Mode Copy -VmStorageRoot "E:\Hyper-V" -Force
