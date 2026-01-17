# Changelog

All notable changes to this project will be documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

### Changed

### Fixed

## [1.0.9] - 2026-01-17

### Added
- CI/CD: GitHub Actions workflows for automated build, test, and release
- CI/CD: Automated test result publishing
- Testing: Pester test framework with module validation tests
- Testing: Version consistency validation across all files
- Configuration: Configuration management module (PSHVTools.Config)
  - `Get-PSHVToolsConfig` - Read current configuration
  - `Set-PSHVToolsConfig` - Update settings
  - `Reset-PSHVToolsConfig` - Reset to defaults
  - `Show-PSHVToolsConfig` - Display current configuration
- Diagnostics: Health check command (`hvhealth`, `hv-health`)
  - `Test-PSHVToolsEnvironment` - System diagnostics and environment validation
- Build: Enhanced build script with version validation and checksums
- Build: SHA256 checksum generation for installers
- Documentation: CONTRIBUTING.md - Developer guidelines
- Documentation: TROUBLESHOOTING.md - Common issues and solutions
- Documentation: IMPROVEMENTS_SUMMARY.md - Project improvements summary
- Publishing: PowerShell Gallery publish script

### Changed
- Build: Improved error messages with actionable tips
- Build: Added `-WhatIf` support for dry runs
- Build: Added `-Clean` flag for clean builds
- Build: Added `-SkipVersionCheck` for quick rebuilds
- Module: Reorganized for better maintainability with separate modules
- Documentation: Updated README with new features and commands

### Fixed
- Build: Fixed default ISS file path resolution
- Build: Fixed param block placement for proper PowerShell execution
- CI/CD: Fixed Pester test execution in GitHub Actions
- CI/CD: Added proper permissions for test result publishing

## [1.0.8] - 2026-01-17

### Added
- Installer: dev-build installs now require explicit acknowledgement via a wizard checkbox page.

### Fixed
- Installer: fixed semantic version comparisons and startup checks so dev/stable detection behaves reliably.

## [1.0.7] - 2026-01-16

### Added
- Module: `Clone-VM` command (aliases: `hvclone`, `hv-clone`) to clone a VM using export + import copy.
- Docs: added clone examples in `samples/` and refreshed primary documentation.

## [1.0.6] - 2026-01-12

### Fixed
- Backup: retry export by turning off VM when export fails due to GPU-P (GPU partition adapter assignment).
- Backup: fixed PowerShell parse error in `Get-VM` error handling.

## [1.0.5] - 2026-01-09

### Added
- Utility: `scripts/remove-gpu-partitions.ps1` to remove all GPU partition adapter assignments from VMs matched by wildcard name.
- Module: `nogpup` alias (wrapper in `pshvtools.psm1`) to run GPU-partition removal via `Import-Module pshvtools`.

### Fixed
- Backup: improved temp folder handling to avoid duplicate per-VM export folder creation.

## [1.0.4] - 2026-01-02

### Added
- Restore: reliable 7-Zip extraction runner with captured output logs.
- Restore: extraction progress in console during restore.

### Changed
- Restore: improved cancellation handling and prevented orphaned 7z processes.
- Restore: when using `-DestinationRoot` with in-place register, extraction can skip per-run staging folder.
- Logs: 7z extraction log file name is prefixed with VM/archive name.

### Fixed
- Restore: fixed formatting bug that could throw while writing the 7z header log line.
- Repair: fixed `Repair-VhdAcl` wrapper `-WhatIf` parameter conflict.

## [1.0.3] - 2026-01-02

### Added
- Restore: `Restore-VMBackup` / `hvrestore` supports `-DestinationRoot` for simpler restore targeting.
- Docs: added `samples/` folder with end-to-end examples.

### Changed
- Restore: corrected staging/extraction path handling when using `-DestinationRoot` (in-place registration and Copy/Restore mapping).

## [1.0.2] - 2026-03-15

### Added
- `Restore-VMBackup` command (alias: `hvrestore`) to extract and import VMs from `hvbak` `.7z` backups.
- Include archive file name in 7-Zip progress output for concurrent backup jobs.
- `Restore-OrphanedVMs` command (alias: `hvrecover`) to scan the Hyper-V `Virtual Machines` config folder for orphaned VMs and re-register them.

### Changed
- Retention cleanup explicitly includes the freshly created archive in the per-VM archive list before counting/sorting/deleting.
- Orphaned VM recovery is non-interactive by default (lowered `ConfirmImpact`; `-Confirm` still supported).
- Restore: `-Latest` now supports archives stored directly under `BackupRoot` (not only `BackupRoot\\YYYYMMDD`).
- Restore: Improved `Import-VM` path detection, including GUID subfolders and `.vmcx` candidates, with per-attempt logging.
- Restore: Fixed StrictMode cleanup issue when failing early (ensures staging variables are defined before `finally`).

## [1.0.1] - 2025-12-31

### Added
- Inno Setup installer build output: `dist/PSHVTools-Setup.exe`.

### Changed
- Backup script archive progress output now identifies the archive file.
- Backup retention scan now accounts for just-created archives even if directory enumeration lags.
