# Changelog

All notable changes to this project will be documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `Restore-VMBackup` command (alias: `hvrestore`) to extract and import VMs from `hvbak` `.7z` backups.
- Include archive file name in 7-Zip progress output for concurrent backup jobs.

### Changed
- Retention cleanup explicitly includes the freshly created archive in the per-VM archive list before counting/sorting/deleting.

## [1.0.1] - 2025-12-31

### Added
- Inno Setup installer build output: `dist/PSHVTools-Setup-1.0.1.exe`.

### Changed
- Backup script archive progress output now identifies the archive file.
- Backup retention scan now accounts for just-created archives even if directory enumeration lags.
