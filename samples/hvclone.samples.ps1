#requires -Version 5.1

<#$
.SYNOPSIS
  Sample usages for cloning VMs with PSHVTools.

.DESCRIPTION
  Examples for `Clone-VM` and its aliases `hvclone` / `hv-clone`.

.NOTES
  - Run in an elevated PowerShell session on a Hyper-V host.
  - Cloning uses Hyper-V Export-VM + Import-VM -Copy -GenerateNewId.
  - The cloned VM files are placed under DestinationRoot\<NewName>.
#>

Import-Module pshvtools

# List help and parameters
Get-Help Clone-VM -Full
Get-Help hvclone -Examples

# 1) Clone a VM into D:\Hyper-V\Win11-Dev01
hvclone -SourceVmName 'BaseWin11' -NewName 'Win11-Dev01' -DestinationRoot 'D:\Hyper-V'

# 2) Same, using the dashed alias
hv-clone -SourceVmName 'BaseWin11' -NewName 'Win11-Dev02' -DestinationRoot 'D:\Hyper-V'

# 3) Use a custom temp folder (use fast local storage)
hvclone -SourceVmName 'BaseWin11' -NewName 'Win11-Dev03' -DestinationRoot 'D:\Hyper-V' -TempFolder 'E:\hvclone-temp'

# 4) Overwrite an existing VM with the same NewName (DANGEROUS)
#    - Stops (turns off) the existing VM if needed
#    - Removes the existing VM registration
#    - Imports the new clone
hvclone -SourceVmName 'BaseWin11' -NewName 'Win11-Dev03' -DestinationRoot 'D:\Hyper-V' -Force

# 5) Preview actions without changing anything
hvclone -SourceVmName 'BaseWin11' -NewName 'Win11-WhatIf' -DestinationRoot 'D:\Hyper-V' -WhatIf
