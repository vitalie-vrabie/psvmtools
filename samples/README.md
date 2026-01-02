# PSHVTools Samples

This folder contains practical examples for using the `pshvtools` module cmdlets and aliases.

## Prerequisites

- Run in an elevated PowerShell session on a Hyper-V host.
- Ensure `pshvtools` is installed/available.
- Ensure `7z.exe` is installed (required for `hvbak` and `hvrestore`).

Import the module:

```powershell
Import-Module pshvtools
```

## Contents

- `samples/hvbak.samples.ps1` — backup examples (`Invoke-VMBackup` / `hvbak`)
- `samples/hvrestore.samples.ps1` — restore/import examples (`Restore-VMBackup` / `hvrestore`)
- `samples/fix-vhd-acl.samples.ps1` — VHD ACL repair examples (`Repair-VhdAcl` / `fix-vhd-acl`)
- `samples/hvrecover.samples.ps1` — orphaned VM recovery examples (`Restore-OrphanedVMs` / `hvrecover`)

