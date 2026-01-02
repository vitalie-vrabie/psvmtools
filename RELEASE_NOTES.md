# PSHVTools v1.0.2

Release date: 2026-03-15

> This is the release notes for the tagged release `v1.0.2`.
> For ongoing development toward the next release (e.g. v1.0.3), see `CHANGELOG.md` under **[Unreleased]**.
> When cutting `v1.0.3`, update this file (or add a new `RELEASE_NOTES_v1.0.3.md`) and update checksums.

## Highlights

- Added orphaned VM recovery: `Restore-OrphanedVMs` (alias: `hvrecover`) to scan the Hyper-V `Virtual Machines` configuration folder for VMs present on disk but missing from `Get-VM`, and re-register them.
- Improved restore/import (`Restore-VMBackup` / `hvrestore`) to better locate valid `Import-VM` paths and to support selecting latest `.7z` archives stored directly under `BackupRoot`.

## New command: Recover orphaned VMs

Use this when Hyper-V Manager does not list a VM, but the VM configuration (`*.vmcx`) still exists on disk.

```powershell
Import-Module pshvtools

# Preview actions (recommended)
hvrecover -WhatIf

# Scan a custom root (auto-resolves to its 'Virtual Machines' subfolder when present)
hvrecover -VmConfigRoot "D:\Hyper-V"
```

Notes:
- Requires Admin + Hyper-V PowerShell module
- Default scan path: `C:\ProgramData\Microsoft\Windows\Hyper-V\Virtual Machines`

## Changes

### Added
- `Restore-OrphanedVMs` / `hvrecover`.

### Changed
- `Restore-VMBackup`: `-Latest` now supports archives directly under `BackupRoot`.
- `Restore-VMBackup`: improved `Import-VM` path detection and per-attempt logging.
- `Restore-OrphanedVMs`: reduced default confirmation prompting (still supports `-Confirm` and `-WhatIf`).

## Installer / packaging

- GUI installer (Inno Setup): `dist\PSHVTools-Setup-1.0.2.exe`

## Checksums

- `dist\PSHVTools-Setup-1.0.2.exe` (SHA256):
  `CA704525BE5324FD47EDC59853916CD118394D3A43341CBCBEE8F022B9B5C94B`

```powershell
Get-FileHash .\dist\PSHVTools-Setup-1.0.2.exe -Algorithm SHA256
