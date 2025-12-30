# PSHVTools - PowerShell Hyper-V Tools

**Version:** 1.0.0  
**Product Name:** PSHVTools (PowerShell Hyper-V Tools)  
**Module Name:** pshvtools  
**Commands:** `Invoke-VMBackup`, `Repair-VhdAcl`, and aliases: `hvbak`, `hv-bak`, `fix-vhd-acl`  
**License:** MIT

---

## ?? What is PSHVTools?

PSHVTools is a professional PowerShell module for backing up and managing Hyper-V virtual machines. It provides cmdlets for automated, parallel VM backups with checkpoint support, 7-Zip compression, and VHD permission repair utilities.

### Key Features:
- ? Live VM backups using Production checkpoints
- ? Parallel processing of multiple VMs
- ??? 7-Zip compression with multithreading
- ?? Configurable backup retention (keep 1-100 copies per VM)
- ?? Progress tracking with real-time status
- ? Graceful cancellation (Ctrl+C support)
- ??? Low-priority compression (Idle CPU class)
- ?? VHD/VHDX permission repair utility
- ?? Improved error diagnostics

---

## ?? Installation

### GUI Installer (Recommended for End Users)

1. Download `PSHVTools-Setup-1.0.0.exe`
2. Double-click to run the installer
3. Follow the wizard
4. Done!

**Features:**
- Professional Windows wizard
- System requirements check
- Start Menu shortcuts
- Add/Remove Programs integration
- Silent installation support

**Silent install:**
```cmd
PSHVTools-Setup-1.0.0.exe /VERYSILENT /NORESTART
```

### PowerShell Installer (Alternative)

1. Download and extract `PSHVTools-Setup-1.0.0.zip`
2. Right-click `Install.ps1` ? "Run with PowerShell" (as Administrator)
3. Done!

**Command line install:**
```powershell
powershell -ExecutionPolicy Bypass -File Install.ps1
```

**Silent install:**
```powershell
powershell -ExecutionPolicy Bypass -File Install.ps1 -Silent
```

After installation:
```powershell
# Import module
Import-Module pshvtools

# Get help
Get-Help Invoke-VMBackup -Full
Get-Help Repair-VhdAcl -Full

# Backup VMs
hvbak -NamePattern "*"

# Fix VHD permissions
fix-vhd-acl -WhatIf
```

**Full user documentation:** See [QUICKSTART.md](QUICKSTART.md)

---

## ?? Quick Start

### Backing Up VMs

```powershell
# Import the module
Import-Module pshvtools

# Backup all VMs
hvbak -NamePattern "*"

# Backup specific VMs
hvbak -NamePattern "srv-*" -Destination "D:\Backups"

# Keep 5 most recent backups per VM
hvbak -NamePattern "*" -KeepCount 5

# Without forcing VM power off
hvbak -NamePattern "web-*" -ForceTurnOff:$false
```

### Fixing VHD Permissions

```powershell
# Preview fixes for all VMs
fix-vhd-acl -WhatIf

# Fix all VMs on host
fix-vhd-acl

# Fix VHDs in a folder
fix-vhd-acl -VhdFolder "D:\Restores"

# Fix VHDs from CSV list
fix-vhd-acl -VhdListCsv "C:\temp\vhds.csv"
```

---

## ??? Building from Source

### Prerequisites

**For GUI EXE Installer:**
- Inno Setup 6 (https://jrsoftware.org/isdl.php)
- Or install via WinGet: `winget install JRSoftware.InnoSetup`

**For PowerShell Installer:**
- MSBuild (Visual Studio 2022 or .NET SDK 6.0+)
- PowerShell 5.1+

### Build Commands

```cmd
# Build GUI EXE installer (recommended)
Build-InnoSetupInstaller.bat

# Build PowerShell installer packages
Build-Release.bat package

# Clean build outputs
Build-Release.bat clean
```

**Output:**
- `dist\PSHVTools-Setup-1.0.0.exe` - GUI installer (1.9 MB)
- `release\PSHVTools-v1.0.0.zip` - Source package
- `dist\PSHVTools-Setup-1.0.0\` - PowerShell installer

**Full build documentation:** See [BUILD_GUIDE.md](BUILD_GUIDE.md)

---

## ?? Repository Structure

```
PSHVTools/
??? hvbak.ps1                          # Core backup script
??? pshvtools.psm1                     # PowerShell module
??? pshvtools.psd1                     # Module manifest
??? fix-vhd-acl.ps1                    # VHD permission repair utility
??? Install-PSHVTools.ps1              # PowerShell installation script
??? Uninstall-PSHVTools.ps1            # Uninstallation script
?
??? PSHVTools.csproj                   # MSBuild project
??? PSHVTools-Installer.iss            # Inno Setup script
??? Build-InnoSetupInstaller.bat       # GUI installer builder
??? Build-Release.bat                  # PowerShell installer builder
??? Build-Installer.bat                # Installer package builder
??? Create-InstallerScript.ps1         # Script generator
?
??? QUICKSTART.md                      # Quick start guide
??? BUILD_GUIDE.md                     # Build instructions
??? PROJECT_SUMMARY.md                 # Project overview
??? LICENSE.txt                        # MIT license
?
??? release/                           # Build output (generated)
?   ??? PSHVTools-v1.0.0/             # Source package
?   ??? PSHVTools-v1.0.0.zip          # Source ZIP
??? dist/                              # Installer output (generated)
    ??? PSHVTools-Setup-1.0.0.exe     # GUI installer
    ??? PSHVTools-Setup-1.0.0/        # PowerShell installer
    ??? PSHVTools-Setup-1.0.0.zip     # PowerShell installer ZIP
```

---

## ?? Distribution

### For GitHub Releases

Distribute:
1. **PSHVTools-Setup-1.0.0.exe** - GUI installer (recommended for end users)
2. **PSHVTools-v1.0.0.zip** - Source package (for developers)
3. **PSHVTools-Setup-1.0.0.zip** - PowerShell installer (alternative)

### For Enterprise IT Departments

**Both installers support:**
- ? Silent installation
- ? Administrator privileges verification
- ? System requirements check
- ? Clean uninstallation
- ? No dependencies (except Hyper-V and 7-Zip)

**Installation Commands:**
```powershell
# GUI installer (silent)
PSHVTools-Setup-1.0.0.exe /VERYSILENT /NORESTART

# PowerShell installer (silent)
.\Install.ps1 -Silent

# Uninstall
.\Install.ps1 -Uninstall
```

---

## ?? Available Commands

### Invoke-VMBackup (aliases: hvbak, hv-bak)
Backs up Hyper-V VMs using checkpoints and 7-Zip compression.

**Parameters:**
- `NamePattern` - VM name wildcard pattern (required)
- `Destination` - Backup destination folder (default: `$env:USERPROFILE\hvbak-archives`)
- `TempFolder` - Temporary export folder (default: `$env:TEMP\hvbak`)
- `ForceTurnOff` - Force VM power off if checkpoint fails (default: $true)
- `KeepCount` - Number of backups to keep per VM (default: 2, range: 1-100)

**Examples:**
```powershell
hvbak -NamePattern "*"
hv-bak -NamePattern "srv-*" -Destination "D:\Backups"
hvbak -NamePattern "web-*" -KeepCount 5
```

### Repair-VhdAcl (alias: fix-vhd-acl)
Repairs file permissions on VHD/VHDX files for Hyper-V access.

**Parameters:**
- `WhatIf` - Preview changes without applying them
- `VhdFolder` - Path to folder with VHD/VHDX files
- `VhdListCsv` - CSV file with VHD paths
- `LogFile` - Log file path (default: `$env:TEMP\FixVhdAcl.log`)

**Examples:**
```powershell
fix-vhd-acl -WhatIf
fix-vhd-acl
Repair-VhdAcl -VhdFolder "D:\Restores"
```

---

## ?? Quick Reference

### Build Commands
```cmd
# Build GUI installer
Build-InnoSetupInstaller.bat

# Build PowerShell installer
Build-Release.bat package

# Clean outputs
Build-Release.bat clean
```

### Installation Commands
```powershell
# GUI installer (interactive)
.\PSHVTools-Setup-1.0.0.exe

# PowerShell installer (interactive)
.\Install.ps1

# Silent install
.\Install.ps1 -Silent

# Uninstall
.\Install.ps1 -Uninstall
```

### Usage Commands
```powershell
# Import module
Import-Module pshvtools

# List available commands
Get-Command -Module pshvtools

# Backup VMs
hvbak -NamePattern "*"

# Fix VHD permissions
fix-vhd-acl -WhatIf

# Get detailed help
Get-Help Invoke-VMBackup -Full
Get-Help Repair-VhdAcl -Full
```

---

## ?? Documentation Index

| Document | Description | Target Audience |
|----------|-------------|-----------------|
| [QUICKSTART.md](QUICKSTART.md) | Quick start guide | End Users |
| [BUILD_GUIDE.md](BUILD_GUIDE.md) | Building packages | Developers |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | Project overview | Everyone |
| [LICENSE.txt](LICENSE.txt) | MIT license | Everyone |

---

## ?? System Requirements

### Minimum Requirements
- Windows Server 2016 or Windows 10 (with Hyper-V)
- PowerShell 5.1 or later
- Hyper-V PowerShell module
- 7-Zip installed (7z.exe in PATH)
- Administrator privileges for installation

### Recommended
- Windows Server 2019 or later
- PowerShell 7+
- Fast storage for temp folder
- Sufficient disk space for backups

---

## ?? Support

- **GitHub Issues:** https://github.com/vitalie-vrabie/pshvtools/issues
- **GitHub Repository:** https://github.com/vitalie-vrabie/pshvtools
- **Discussions:** https://github.com/vitalie-vrabie/pshvtools/discussions

---

## ?? License

MIT License - See [LICENSE.txt](LICENSE.txt) for full details

Copyright (c) 2025 Vitalie Vrabie

---

## ?? Getting Started

### For End Users
1. Download `PSHVTools-Setup-1.0.0.exe`
2. Run the installer
3. Import the module: `Import-Module pshvtools`
4. Start backing up VMs: `hvbak -NamePattern "*"`

### For Developers
1. Clone the repository
2. Run `Build-InnoSetupInstaller.bat`
3. Find installer in `dist\` folder
4. Test and distribute!

---

## ?? Version History

### Version 1.0.0 (2025)
- Initial release
- Core backup functionality with parallel processing
- Configurable backup retention (KeepCount parameter)
- VHD/VHDX permission repair utility
- GUI installer with Inno Setup
- PowerShell installer alternative
- Improved error diagnostics
- Complete documentation
- Enterprise deployment support

---

## ? Highlights

- **Zero Configuration:** Works out of the box
- **Professional:** Enterprise-ready features
- **Well Documented:** Comprehensive guides
- **Open Source:** MIT licensed
- **Flexible Installation:** GUI or PowerShell installer
- **Powerful:** Parallel backups with checkpoints
- **Reliable:** Graceful error handling and cleanup
- **Utilities Included:** VHD permission repair tool

---

## ? Uninstallation

### GUI Installer
- Use "Add or Remove Programs" in Windows
- Or run `unins000.exe` from installation folder
- Or use Start Menu uninstaller shortcut

### PowerShell Installer
```powershell
# Run from installer directory
.\Install.ps1 -Uninstall

# Or manually delete:
Remove-Item "C:\Program Files\WindowsPowerShell\Modules\pshvtools" -Recurse -Force
```

---

**Thank you for using PSHVTools!** ??

For questions, issues, or contributions, visit:  
https://github.com/vitalie-vrabie/pshvtools
