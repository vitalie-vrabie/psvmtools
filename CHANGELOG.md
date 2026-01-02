# Changelog

All notable changes to this project will be documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `Restore-VMBackup` command (alias: `hvrestore`) to extract and import VMs from `hvbak` `.7z` backups.
- Include archive file name in 7-Zip progress output for concurrent backup jobs.
- `Restore-OrphanedVMs` command (alias: `hvrecover`) to scan the Hyper-V `Virtual Machines` config folder for orphaned VMs and re-register them.

### Changed
- Retention cleanup explicitly includes the freshly created archive in the per-VM archive list before counting/sorting/deleting.
- Orphaned VM recovery is non-interactive by default (lowered `ConfirmImpact`; `-Confirm` still supported).

## [1.0.2] - 2026-03-15

### Changed
- Restore: `-Latest` now supports archives stored directly under `BackupRoot` (not only `BackupRoot\\YYYYMMDD`).
- Restore: Improved `Import-VM` path detection, including GUID subfolders and `.vmcx` candidates, with per-attempt logging.
- Restore: Fixed StrictMode cleanup issue when failing early (ensures staging variables are defined before `finally`).

## [1.0.1] - 2025-12-31

### Added
- Inno Setup installer build output: `dist/PSHVTools-Setup-1.0.1.exe`.

### Changed
- Backup script archive progress output now identifies the archive file.
- Backup retention scan now accounts for just-created archives even if directory enumeration lags.
