# PSHVTools - PowerShell Hyper-V Tools

**Version:** 1.0.0  
**Product Name:** PSHVTools (PowerShell Hyper-V Tools)  
**Module Name:** hvbak  
**Commands:** `Backup-HyperVVM`, `Restore-HyperVVM`  
**License:** MIT

---

## ?? What is PSHVTools?

PSHVTools is a professional PowerShell module for backing up Hyper-V virtual machines. It provides cmdlets for automated, parallel VM backups with checkpoint support and 7-Zip compression.

### Key Features:
- ? Live VM backups using Production checkpoints
- ? Parallel processing of multiple VMs
- ??? 7-Zip compression with multithreading
- ??? Automatic cleanup (keeps 2 most recent backups)
- ?? Progress tracking with real-time status
- ? Graceful cancellation (Ctrl+C support)
- ?? Low-priority compression (Idle CPU class)

---

## ?? Installation

### PowerShell Installer (Recommended)

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
Import-Module hvbak

# Get help
Get-Help Backup-HyperVVM -Full
Get-Help Restore-HyperVVM -Full

# Backup a VM
Backup-HyperVVM -VMName "MyVM" -Destination "D:\Backups"
```

**Full user documentation:** See [QUICKSTART.md](QUICKSTART.md)

---

## ?? Building Release Packages

### Prerequisites

**MSBuild** (via one of these):
- Visual Studio 2022 (any edition)
- .NET SDK 6.0 or later
- Build Tools for Visual Studio 2022

**PowerShell 5.1+** (included with Windows)

**No WiX Toolset required!** ?

### Build Commands

```cmd
# Build release and installer packages
Build-Release.bat

# Build everything + create installer ZIP
Build-Release.bat package

# Build installer package only
Build-Installer.bat

# Clean build outputs
Build-Release.bat clean
```

**Output:**
- `release\PSHVTools-v1.0.0.zip` - Source package
- `dist\PSHVTools-Setup-1.0.0\` - Installer package
- `dist\PSHVTools-Setup-1.0.0.zip` - Distributable installer

**Full build documentation:** See [BUILD_GUIDE.md](BUILD_GUIDE.md)

---

## ?? Repository Structure

```
PSHVTools/
??? hvbak.ps1                          # Core backup script
??? hvbak.psm1                         # PowerShell module
??? hvbak.psd1                         # Module manifest
??? Install-PSHVTools.ps1              # Installation script
??? Uninstall-PSHVTools.ps1            # Uninstallation script
?
??? PSHVTools.csproj                   # MSBuild project
??? Build-Release.bat                  # Main build script
??? Build-Installer.bat                # Installer builder
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
    ??? PSHVTools-Setup-1.0.0/        # Installer package
    ??? PSHVTools-Setup-1.0.0.zip     # Installer ZIP
```

---

## ?? Distribution

### For GitHub Releases

Distribute both packages:
1. **PSHVTools-v1.0.0.zip** - Source package
2. **PSHVTools-Setup-1.0.0.zip** - Installer package (recommended)

### For Enterprise IT Departments

**PowerShell Installer Benefits:**
- ? No WiX Toolset dependency
- ? No special tools required to install
- ? Works on all Windows versions with PowerShell 5.1+
- ? Simple, transparent installation
- ? Silent install support
- ? Easy to customize
- ? Clean uninstallation

**Installation Commands:**
```powershell
# Interactive
.\Install.ps1

# Silent
.\Install.ps1 -Silent

# Uninstall
.\Install.ps1 -Uninstall
```

---

## ?? Quick Reference

### Build Commands
```cmd
# Build all packages
Build-Release.bat package

# Build installer only
Build-Installer.bat

# Clean outputs
Build-Release.bat clean
```

### Installation Commands
```powershell
# Interactive install
.\Install.ps1

# Silent install
.\Install.ps1 -Silent

# Uninstall
.\Install.ps1 -Uninstall
```

### Usage Commands
```powershell
# Import module
Import-Module hvbak

# Backup a VM
Backup-HyperVVM -VMName "MyVM" -Destination "D:\Backups"

# Restore a VM
Restore-HyperVVM -BackupPath "D:\Backups\MyVM_20250101_120000.7z"

# List available commands
Get-Command -Module hvbak

# Get detailed help
Get-Help Backup-HyperVVM -Full
Get-Help Restore-HyperVVM -Full
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
1. Download `PSHVTools-Setup-1.0.0.zip`
2. Extract and run `Install.ps1` as Administrator
3. Import the module: `Import-Module hvbak`
4. Start backing up VMs!

### For Developers
1. Clone the repository
2. Run `Build-Release.bat package`
3. Find packages in `release/` and `dist/` folders
4. Test and distribute!

---

## ?? Version History

### Version 1.0.0 (2025)
- Initial release
- Core backup and restore functionality
- MSBuild-based packaging
- PowerShell installer
- Complete documentation
- Enterprise deployment support

---

## ? Highlights

- **Zero Configuration:** Works out of the box
- **Professional:** Enterprise-ready features
- **Well Documented:** Comprehensive guides
- **Open Source:** MIT licensed
- **Simple Installation:** PowerShell-based installer
- **No Dependencies:** No WiX or special tools required

---

## ??? Uninstallation

```powershell
# Run from installer directory
.\Install.ps1 -Uninstall

# Or manually delete:
Remove-Item "C:\Program Files\WindowsPowerShell\Modules\hvbak" -Recurse -Force
```

---

**Thank you for using PSHVTools!** ??

For questions, issues, or contributions, visit:  
https://github.com/vitalie-vrabie/pshvtools
