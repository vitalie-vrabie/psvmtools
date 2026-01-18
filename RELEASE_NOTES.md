# PSHVTools v1.1.0

Release date: 2026-01-18

> This is the release notes for the major release `v1.1.0`.
> For ongoing development toward the next release (e.g. v1.2.0), see `CHANGELOG.md` under **[Unreleased]**.

## Major Highlights

### ?? **Complete Rewrite & Professional Tooling**
- Transformed from basic PowerShell scripts to a full-featured PowerShell module
- Professional Windows installer with GUI wizard and system requirements checking
- Comprehensive CI/CD pipeline with automated testing and releases
- Module manifest with proper versioning and dependencies

### ?? **Enhanced Installer Experience**
- Intelligent development build detection with user consent
- Mandatory system requirements validation (PowerShell 5.1+, Hyper-V, 7-Zip)
- Complete cleanup of previous installations (removes entire directories)
- Professional UI with step-by-step guidance and error handling

### ?? **CI/CD & DevOps Integration**
- GitHub Actions workflow for automated build, test, and release
- Version consistency validation across all project files
- Automated test execution with Pester framework
- SHA256 checksum generation for build artifacts
- Automatic stable/pre-release classification based on version declarations

### ??? **New Features & Tools**
- **Configuration Management**: `Set-PSHVToolsConfig`, `Get-PSHVToolsConfig`, `Reset-PSHVToolsConfig`
- **Health Check**: `hvhealth` command for environment diagnostics
- **Enhanced Build Script**: Version validation, checksums, `-WhatIf` support, `-Clean` flag
- **VM Backup with Checkpoints**: Full Hyper-V checkpoint support
- **Compression**: 7-Zip integration for efficient backups
- **Restore Capabilities**: Restore orphaned VMs and backup archives

### ?? **Documentation & User Experience**
- Comprehensive documentation suite (README, QUICKSTART, TROUBLESHOOTING, etc.)
- CONTRIBUTING.md with development guidelines
- PROJECT_SUMMARY.md with architecture overview
- Improved error messages with actionable tips
- Quick start guide for immediate usage

### ?? **Quality & Reliability**
- Pester test framework with comprehensive coverage
- Module manifest validation
- Version consistency checks
- Professional error handling and logging

## Installation

### GUI Installer (Recommended)
```cmd
PSHVTools-Setup.exe
```

### Silent Install
```cmd
PSHVTools-Setup.exe /VERYSILENT /NORESTART
```

### PowerShell Gallery (Future)
```powershell
Install-Module PSHVTools
```

## Quick Start

    Import-Module pshvtools

    # Check environment health
    hvhealth

    # Configure defaults
    Set-PSHVToolsConfig -DefaultBackupPath "D:\Backups" -DefaultKeepCount 5

    # Backup all VMs
    hvbak -NamePattern "*"

    # Compact VHD files
    hvcompact -NamePattern "*" -WhatIf

    # View configuration
    Show-PSHVToolsConfig

## Key Links

• GitHub: https://github.com/vitalie-vrabie/pshvtools
• Documentation: https://github.com/vitalie-vrabie/pshvtools#readme
• Issues: https://github.com/vitalie-vrabie/pshvtools/issues
• Contributing: See CONTRIBUTING.md
• Troubleshooting: See TROUBLESHOOTING.md
