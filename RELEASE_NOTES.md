# PSHVTools v1.0.12

Release date: 2026-01-18

> This is the release notes for the tagged release `v1.0.12`.
> For ongoing development toward the next release (e.g. v1.1.0), see `CHANGELOG.md` under **[Unreleased]**.

## Highlights

### ?? **Installer Improvements**
- Fixed critical bugs in the installer script
- Added development build detection and consent page for pre-release versions
- Enforced mandatory system requirements (PowerShell 5.1+ and 7-Zip)
- Improved user experience with better error messages and requirement checks
- Added option to download latest stable release directly from dev builds

### ?? **CI/CD & DevOps**
- Automated GitHub Actions workflow for build, test, and release
- Version consistency validation across all project files
- Automated test result publishing
- Build artifacts automatically uploaded to releases

### ?? **Testing & Quality**
- Comprehensive Pester test framework
- Module manifest validation
- Version consistency checks
- Ready for PowerShell Gallery publishing

### ??? **New Tools & Features**
- **Configuration Management**: `Set-PSHVToolsConfig`, `Get-PSHVToolsConfig`, `Reset-PSHVToolsConfig`
- **Health Check**: `hvhealth` command to diagnose environment issues
- **Enhanced Build Script**: Version validation, checksums, `-WhatIf` support, `-Clean` flag

### ?? **Documentation**
- CONTRIBUTING.md - Complete development guidelines
- TROUBLESHOOTING.md - Solutions for common issues
- Updated README with new commands and features
- IMPROVEMENTS_SUMMARY.md - Detailed changelog of improvements

### ?? **Improvements**
- Better error messages with actionable tips and documentation links
- SHA256 checksum generation for build artifacts
- Improved module organization with separate config and health check modules
- PowerShell Gallery publish script for automated distribution

## Installation

### GUI Installer
```cmd
PSHVTools-Setup.exe
```

### Silent Install
```cmd
PSHVTools-Setup.exe /VERYSILENT /NORESTART
```

## Quick Start

    Import-Module pshvtools

    # Check environment
    hvhealth

    # Configure defaults
    Set-PSHVToolsConfig -DefaultBackupPath "D:\Backups" -DefaultKeepCount 5

    # Backup VMs
    hvbak -NamePattern "*"

    # View configuration
    Show-PSHVToolsConfig

## Key Links

• GitHub: https://github.com/vitalie-vrabie/pshvtools
• Documentation: https://github.com/vitalie-vrabie/pshvtools#readme
• Issues: https://github.com/vitalie-vrabie/pshvtools/issues
• Contributing: See CONTRIBUTING.md
• Troubleshooting: See TROUBLESHOOTING.md
