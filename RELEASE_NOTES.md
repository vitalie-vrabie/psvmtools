# PSHVTools v1.0.6

Release date: 2026-01-12

> This is the release notes for the tagged release `v1.0.6`.
> For ongoing development toward the next release (e.g. v1.0.7), see `CHANGELOG.md` under **[Unreleased]**.

## Highlights

- Backup: retry export by turning off VM when export fails due to GPU-P (GPU partition adapter assignment).
- Backup: fixed a PowerShell parse error in `Get-VM` error handling.

## Changes

### Fixed
- Backup: retry export by turning off VM when export fails due to GPU-P (GPU partition adapter assignment).
- Backup: fixed PowerShell parse error in `Get-VM` error handling.

## Installer / packaging

- GUI installer (Inno Setup): `dist\PSHVTools-Setup-1.0.6.exe`
