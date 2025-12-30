# PSHVTools v1.0.0 - Initial Release

## ?? First Official Release

PSHVTools is a professional PowerShell module for backing up Hyper-V virtual machines with checkpoint support and 7-Zip compression.

---

## ?? Installation

### Download and Install

1. Download **PSHVTools-Setup-1.0.0.msi** (304 KB)
2. Double-click to install
3. Follow the installation wizard
4. Done!

### Silent Installation (Enterprise)

```cmd
# Silent install
msiexec /i PSHVTools-Setup-1.0.0.msi /quiet /norestart

# Silent install with logging
msiexec /i PSHVTools-Setup-1.0.0.msi /quiet /norestart /l*v install.log
```

---

## ? Features

### Core Backup Features
- ? **Live VM Backups** - Uses Production checkpoints for safe, online backups
- ? **Parallel Processing** - Backup multiple VMs simultaneously
- ? **7-Zip Compression** - Efficient multithreaded compression
- ? **Automatic Cleanup** - Keeps the 2 most recent backups
- ? **Progress Tracking** - Real-time status and progress bars
- ? **Graceful Cancellation** - Ctrl+C support with proper cleanup
- ? **Low-Priority Compression** - Uses Idle CPU class to minimize impact

### Installation Features
- ? **MSI Installer** - Professional Windows Installer package
- ? **Add/Remove Programs** - Full Windows integration
- ? **Start Menu Shortcuts** - Quick access to documentation
- ? **Silent Install Support** - Perfect for enterprise deployment
- ? **Group Policy Ready** - Deploy via GPO, SCCM, or Intune
- ? **Transactional Install** - Automatic rollback on failure

---

## ?? Quick Start

After installation:

```powershell
# Display help
hvbak

# Backup all VMs
hvbak -NamePattern "*"

# Backup specific VMs
hv-bak -NamePattern "srv-*"

# Custom destination
hvbak -NamePattern "*" -Destination "D:\backups"

# Get detailed help
Get-Help Invoke-VMBackup -Full
```

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

## ?? Enterprise Deployment

### Group Policy Deployment
1. Place MSI on network share
2. Create GPO for software installation
3. Assign to target computers
4. Automatic deployment on startup

### SCCM/ConfigMgr
```cmd
Install: msiexec /i PSHVTools-Setup-1.0.0.msi /quiet /norestart
Uninstall: msiexec /x PSHVTools-Setup-1.0.0.msi /quiet /norestart
```

### Intune
Upload as Line-of-Business app and assign to groups

---

## ?? Documentation

- **Quick Start Guide**: See QUICKSTART.md in installation folder
- **Module Documentation**: README_VMBAK_MODULE.md
- **Build Instructions**: BUILD_GUIDE.md
- **GitHub Repository**: https://github.com/vitalie-vrabie/pshvtools

---

## ?? Building from Source

### Prerequisites
Install WiX Toolset v3.14.1 or later:
```powershell
winget install --id WiXToolset.WiXToolset
```

### Build
```cmd
Build-WixInstaller.bat
```

Output: `dist\PSHVTools-Setup-1.0.0.msi`

---

## ?? What's Included

- **vmbak.ps1** - Core backup script
- **vmbak.psm1** - PowerShell module
- **vmbak.psd1** - Module manifest
- **Documentation** - Complete user guides
- **MSI Installer** - Professional Windows Installer package

---

## ?? Known Limitations

- Requires 7-Zip to be installed and in PATH
- Only supports Hyper-V Production checkpoints
- Windows-only (Hyper-V requirement)

---

## ?? Support

- **Issues**: https://github.com/vitalie-vrabie/pshvtools/issues
- **Discussions**: https://github.com/vitalie-vrabie/pshvtools/discussions
- **Documentation**: See docs in installation folder

---

## ?? License

MIT License - See [LICENSE.txt](LICENSE.txt) for details

Copyright (c) 2025 Vitalie Vrabie

---

## ?? Acknowledgments

Built with:
- WiX Toolset for MSI packaging
- PowerShell for automation
- 7-Zip for compression

---

## ?? Release Assets

- **PSHVTools-Setup-1.0.0.msi** (304 KB) - Windows Installer package

---

**Thank you for using PSHVTools!** ??

For questions or issues, please visit the GitHub repository.
