# GitHub Release v1.0.9 - Published! ??

## ? Release Successfully Published

**Release URL:** https://github.com/vitalie-vrabie/pshvtools/releases/tag/v1.0.9

**Published:** 2026-01-17 (just now)

---

## ?? Release Artifacts

### Downloads Available:

1. **PSHVTools-Setup.exe** (2.04 MB)
   - SHA256: `5dd7852d86ccdb3893f4f3aecb1c51d319e0aebc34a083cfe17b2ebe98cc2e33`
   - Ready for installation

2. **PSHVTools-Setup.exe.sha256** (87 B)
   - Checksum file for verification
   - Verify with: `Get-FileHash PSHVTools-Setup.exe -Algorithm SHA256`

---

## ?? Release Highlights

### Major Features Added:

? **CI/CD Automation**
- GitHub Actions workflows for automated build, test, and release
- Automated test result publishing
- Build artifact generation

? **Testing & Quality**
- Pester test framework with module validation
- Version consistency validation across all files
- PowerShell Gallery publish support

? **New Tools**
- **Configuration Management:** `Set-PSHVToolsConfig`, `Get-PSHVToolsConfig`, `Reset-PSHVToolsConfig`, `Show-PSHVToolsConfig`
- **Health Check:** `hvhealth` / `Test-PSHVToolsEnvironment` command
- **Enhanced Build Script:** Version validation, checksums, `-WhatIf` support

? **Documentation**
- `CONTRIBUTING.md` - Developer guidelines
- `TROUBLESHOOTING.md` - Solutions for common issues
- Updated README with new features
- `IMPROVING_SUMMARY.md` - Detailed improvements

---

## ?? Installation Options

### GUI Installer (Recommended)
```cmd
PSHVTools-Setup.exe
```

### Silent Install
```cmd
PSHVTools-Setup.exe /VERYSILENT /NORESTART
```

### PowerShell
```powershell
powershell -ExecutionPolicy Bypass -File Install.ps1
```

---

## ?? Quick Start (After Installation)

```powershell
Import-Module pshvtools

# Check environment health
hvhealth

# Configure your defaults
Set-PSHVToolsConfig -DefaultBackupPath "D:\Backups" -DefaultKeepCount 5

# Backup all VMs
hvbak -NamePattern "*"

# View your configuration
Show-PSHVToolsConfig
```

---

## ?? Release Notes

**Title:** PSHVTools 1.0.9 - CI/CD & DevOps Release

**Date:** 2026-01-17

### Key Improvements:

#### ?? Build & DevOps
- Enhanced build script with version validation
- SHA256 checksum generation
- `-WhatIf`, `-Clean`, `-SkipVersionCheck` support
- Better error messages with actionable tips

#### ?? Testing
- Comprehensive Pester test framework
- Module validation tests
- Version consistency checks
- CI/CD integration

#### ??? New Features
- Configuration management system
- Health check command (`hvhealth`)
- PowerShell Gallery publish script
- Modular architecture improvements

#### ?? Documentation
- CONTRIBUTING.md with development guidelines
- TROUBLESHOOTING.md with solutions
- Updated README with new commands
- Release summaries

---

## ?? Important Links

- **Release Page:** https://github.com/vitalie-vrabie/pshvtools/releases/tag/v1.0.9
- **Repository:** https://github.com/vitalie-vrabie/pshvtools
- **Issues:** https://github.com/vitalie-vrabie/pshvtools/issues
- **Contributing:** https://github.com/vitalie-vrabie/pshvtools/blob/master/CONTRIBUTING.md
- **Troubleshooting:** https://github.com/vitalie-vrabie/pshvtools/blob/master/TROUBLESHOOTING.md

---

## ?? Release Status

| Component | Status |
|-----------|--------|
| **Release Title** | ? Published |
| **Release Tag** | ? v1.0.9 |
| **Installer** | ? Available (2.04 MB) |
| **Checksum** | ? Available |
| **Release Notes** | ? Published |
| **Marked as Latest** | ? Yes |

---

## ? What's Next?

Development on **v1.0.10** is already underway:
- Current version: 1.0.10
- All files updated and ready
- CI/CD pipeline fully operational

---

**? Release v1.0.9 is live and ready for download!** ??
