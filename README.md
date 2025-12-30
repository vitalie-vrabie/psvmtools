# PSHVTools - PowerShell Hyper-V Tools

**Version:** 1.0.0  
**Product Name:** PSHVTools (PowerShell Hyper-V Tools)  
**Module Name:** vmbak  
**Commands:** `hvbak` or `hv-bak`  
**License:** MIT

---

## ?? What is PSHVTools?

PSHVTools is a professional PowerShell module for backing up Hyper-V virtual machines. It provides the `hvbak` and `hv-bak` cmdlets for automated, parallel VM backups with checkpoint support and 7-Zip compression.

### Key Features:
- ?? Live VM backups using Production checkpoints
- ?? Parallel processing of multiple VMs
- ??? 7-Zip compression with multithreading
- ?? Automatic cleanup (keeps 2 most recent backups)
- ?? Progress tracking with real-time status
- ?? Graceful cancellation (Ctrl+C support)
- ?? Low-priority compression (Idle CPU class)

---

## ?? Installation

### MSI Installer

1. Download `PSHVTools-Setup-1.0.0.msi`
2. Double-click to install
3. Follow the wizard
4. Done!

**Silent install:**
```cmd
msiexec /i PSHVTools-Setup-1.0.0.msi /quiet /norestart
```

After installation:
```powershell
# Display help (use either command)
hvbak
hv-bak

# Backup all VMs
hvbak -NamePattern "*"
# or
hv-bak -NamePattern "*"
```

**Full user documentation:** See [QUICKSTART.md](QUICKSTART.md)

---

## ??? Building the MSI Installer

### Prerequisites

Install WiX Toolset v3.14.1 or later:

**Option 1: WinGet**
```powershell
winget install --id WiXToolset.WiXToolset --accept-package-agreements --accept-source-agreements
```

**Option 2: Direct Download**
Download from https://wixtoolset.org/releases/

**Option 3: Chocolatey**
```powershell
choco install wixtoolset
```

### Build the MSI

```cmd
Build-WixInstaller.bat
```

The MSI installer will be created at: `dist\PSHVTools-Setup-1.0.0.msi`

**Full build documentation:** See [BUILD_GUIDE.md](BUILD_GUIDE.md)

---

## ?? Repository Structure

```
PSHVTools/
??? vmbak.ps1                          # Core backup script
??? vmbak.psm1                         # PowerShell module
??? vmbak.psd1                         # Module manifest
?
??? Build-WixInstaller.bat             # Builds MSI installer
??? PSHVTools-Installer.wxs            # WiX installer definition
?
??? README_VMBAK_MODULE.md             # Module documentation
??? QUICKSTART.md                      # Quick start guide
??? BUILD_GUIDE.md                     # Build instructions
??? PACKAGE_README.md                  # Package documentation
??? LICENSE.txt                        # MIT license
?
??? dist/                              # Build output (created by scripts)
    ??? PSHVTools-Setup-1.0.0.msi     # MSI installer
```

---

## ?? Distribution

### For GitHub Releases

Distribute the MSI installer:
- **PSHVTools-Setup-1.0.0.msi** - Windows Installer package

### For Enterprise IT Departments

**MSI Installer Benefits:**
- Industry-standard Windows Installer
- Add/Remove Programs integration
- Silent install: `msiexec /i PSHVTools-Setup-1.0.0.msi /quiet`
- Silent uninstall: `msiexec /x PSHVTools-Setup-1.0.0.msi /quiet`
- Group Policy deployment ready
- SCCM/Intune compatible
- Transactional installation with rollback support

---

## ?? Quick Reference

### Build Commands
```cmd
# Build MSI installer
Build-WixInstaller.bat

# Specify custom output path
Build-WixInstaller.bat "C:\Release"
```

### Installation Commands
```cmd
# Interactive install
msiexec /i PSHVTools-Setup-1.0.0.msi

# Silent install
msiexec /i PSHVTools-Setup-1.0.0.msi /quiet /norestart

# Silent install with logging
msiexec /i PSHVTools-Setup-1.0.0.msi /quiet /norestart /l*v install.log

# Silent uninstall
msiexec /x PSHVTools-Setup-1.0.0.msi /quiet /norestart
```

### Usage Commands
```powershell
# Display help (either command works)
hvbak
hv-bak

# Backup all VMs
hvbak -NamePattern "*"

# Backup specific VMs (using hyphenated alias)
hv-bak -NamePattern "srv-*"

# Custom destination
hvbak -NamePattern "*" -Destination "D:\backups"

# Detailed help
Get-Help Invoke-VMBackup -Full
```

---

## ?? Documentation Index

| Document | Description | Target Audience |
|----------|-------------|-----------------|
| [README_VMBAK_MODULE.md](README_VMBAK_MODULE.md) | Module features and usage | End Users |
| [QUICKSTART.md](QUICKSTART.md) | Quick start guide | End Users |
| [BUILD_GUIDE.md](BUILD_GUIDE.md) | Building the MSI installer | Developers |
| [PACKAGE_README.md](PACKAGE_README.md) | Package overview | Distributors |
| [LICENSE.txt](LICENSE.txt) | MIT license | Everyone |

---

## ?? System Requirements

### Minimum Requirements
- Windows Server 2016 or Windows 10 (with Hyper-V)
- PowerShell 5.1 or later
- Hyper-V PowerShell module
- 7-Zip installed (7z.exe in PATH)
- Administrator privileges

### Recommended
- Windows Server 2019 or later
- PowerShell 7+
- Fast storage for temp folder
- Sufficient disk space for backups

---

## ?? Support

- **GitHub Issues:** https://github.com/vitalie-vrabie/pshvtools/issues
- **GitHub Repository:** https://github.com/vitalie-vrabie/pshvtools
- **Documentation:** See docs folder after installation

---

## ?? License

MIT License - See [LICENSE.txt](LICENSE.txt) for full details

Copyright (c) 2025 Vitalie Vrabie

---

## ?? Getting Started

### For End Users
1. Download the MSI installer
2. Run as Administrator
3. Type `hvbak` or `hv-bak` to see help
4. Start backing up VMs!

### For Developers
1. Clone the repository
2. Install WiX Toolset
3. Run `Build-WixInstaller.bat`
4. Find MSI installer in `dist/` folder
5. Test and distribute!

---

## ? Version History

### Version 1.0.0 (2025)
- Initial release
- Core backup functionality
- MSI installer with WiX Toolset
- Complete documentation
- PowerShell module integration
- Both `hvbak` and `hv-bak` command aliases

---

## ?? Highlights

- **Zero Configuration:** Works out of the box
- **Professional:** Enterprise-ready features
- **Well Documented:** Comprehensive guides
- **Open Source:** MIT licensed
- **Enterprise Ready:** MSI installer with Group Policy support
- **Flexible Commands:** Use either `hvbak` or `hv-bak`

---

**Thank you for using PSHVTools!** ??

For questions, issues, or contributions, visit:  
https://github.com/vitalie-vrabie/pshvtools
