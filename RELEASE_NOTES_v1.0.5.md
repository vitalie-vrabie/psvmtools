# PSHVTools v1.0.5

Release date: 2026-01-09

## Highlights

- Backup: temp folder creation aligned to checkpoint timestamp and de-duplicated to improve export/cleanup reliability.
- Utility: added GPU partition adapter removal helper and module alias (`nogpup`).

## Changes

### Added
- Utility: `scripts/remove-gpu-partitions.ps1` to remove GPU partition adapters from VMs matched by wildcard name.
- Module: `nogpup` alias to run GPU-partition removal through `pshvtools`.

### Fixed
- Backup: avoid duplicate per-VM temp export folder creation which could interfere with cleanup.

## Installer / packaging

- GUI installer (Inno Setup): `dist\PSHVTools-Setup-1.0.5.exe`
