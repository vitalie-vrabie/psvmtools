# PSHVTools v1.0.4

Release date: 2026-01-02

> This is the release notes for the tagged release `v1.0.4`.
> For ongoing development toward the next release (e.g. v1.0.5), see `CHANGELOG.md` under **[Unreleased]**.

## Highlights

- Restore: shows 7-Zip extraction progress in the restore console output.
- Restore: can extract directly into `-DestinationRoot` when using in-place registration (`ImportMode=Register`).
- Logging: 7-Zip extraction output is written to a log file prefixed with the VM/archive name.

## Changes

### Added
- Restore: 7-Zip extraction progress output (`-bsp1`) during `hvrestore`.
- Restore: 7-Zip extraction log file `*-7z-extract.log` (prefixed with VM/archive name).

### Changed
- Restore: improved cancellation handling (Ctrl+C) to avoid orphaned 7z processes.
- Restore: in-place restore can skip a per-run staging folder when `-DestinationRoot` is specified.

### Fixed
- Restore: fixed a string-formatting error that could crash before extraction.
- Repair: fixed `Repair-VhdAcl` `-WhatIf` duplicate parameter conflict.

## Installer / packaging

- GUI installer (Inno Setup): `dist\PSHVTools-Setup-1.0.4.exe`

## Checksums

- `dist\PSHVTools-Setup-1.0.4.exe` (SHA256):
  `TBD`
