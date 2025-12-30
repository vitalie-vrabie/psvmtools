# PSHVTools v1.0.0 - Initial Release

## ?? First Official Release

PSHVTools is a professional PowerShell module for backing up Hyper-V virtual machines with checkpoint support and 7-Zip compression.

---

## ?? Installation

### Download and Install

**Option 1: Interactive Installation**
1. Download **PSHVTools-Setup-1.0.0.zip**
2. Extract the archive
3. Right-click `Install.ps1` ? "Run with PowerShell" (as Administrator)
4. Done!

**Option 2: Command Line Installation**
```powershell
# Extract the ZIP file, then:
powershell -ExecutionPolicy Bypass -File Install.ps1
```

### Silent Installation (Enterprise)

```powershell
# Silent install
powershell -ExecutionPolicy Bypass -File Install.ps1 -Silent
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
- ? **PowerShell Installer** - Simple, transparent installation
- ? **No Dependencies** - No WiX or special tools required
- ? **Silent Install Support** - Perfect for enterprise deployment
- ? **Works Everywhere** - Any Windows with PowerShell 5.1+
- ? **Clean Uninstall** - Easy removal via same script
- ? **No Registry Changes** - Just copies files to module directory

---

## ?? Quick Start

After installation:

```powershell
# Import the module
Import-Module hvbak

# Backup a VM
Backup-HyperVVM -VMName "MyVM" -Destination "D:\Backups"

# Restore a VM
Restore-HyperVVM -BackupPath "D:\Backups\MyVM_20250101_120000.7z"

# Get detailed help
Get-Help Backup-HyperVVM -Full
Get-Help Restore-HyperVVM -Full
```

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

## ?? Enterprise Deployment

### Network Deployment
```powershell
# Copy installer to network share
Copy-Item "PSHVTools-Setup-1.0.0.zip" "\\server\share\"

# Deploy via script
$computers = @("server1", "server2", "server3")
foreach ($computer in $computers) {
    Invoke-Command -ComputerName $computer -ScriptBlock {
        $source = "\\server\share\PSHVTools-Setup-1.0.0"
        & "$source\Install.ps1" -Silent
    }
}
```

### Group Policy Startup Script
```batch
@echo off
if not exist "C:\Program Files\WindowsPowerShell\Modules\hvbak" (
    powershell -ExecutionPolicy Bypass -File "\\server\share\PSHVTools-Setup-1.0.0\Install.ps1" -Silent
)
```

### PowerShell DSC
```powershell
Configuration InstallPSHVTools {
    Script InstallPSHVTools {
        GetScript = {
            $module = Get-Module -ListAvailable hvbak
            return @{ Result = ($null -ne $module) }
        }
        TestScript = {
            $module = Get-Module -ListAvailable hvbak
            return ($null -ne $module)
        }
        SetScript = {
            $source = "\\server\share\PSHVTools-Setup-1.0.0"
            & "$source\Install.ps1" -Silent
        }
    }
}
```

---

## ?? Documentation

- **Quick Start Guide**: QUICKSTART.md
- **Build Instructions**: BUILD_GUIDE.md
- **Project Summary**: PROJECT_SUMMARY.md
- **GitHub Repository**: https://github.com/vitalie-vrabie/pshvtools

---

## ?? Building from Source

### Prerequisites
- MSBuild (via Visual Studio 2022 or .NET SDK 6.0+)
- PowerShell 5.1+

**No WiX Toolset required!**

### Build
```cmd
# Build all packages
Build-Release.bat package
```

Output:
- `release\PSHVTools-v1.0.0.zip` - Source package
- `dist\PSHVTools-Setup-1.0.0.zip` - Installer package

---

## ?? What's Included

- **hvbak.ps1** - Core backup script
- **hvbak.psm1** - PowerShell module
- **hvbak.psd1** - Module manifest
- **Install.ps1** - PowerShell installer script
- **Documentation** - Complete user guides

---

## ?? Known Limitations

- Requires 7-Zip to be installed and in PATH
- Only supports Hyper-V Production checkpoints
- Windows-only (Hyper-V requirement)

---

## ??? Uninstallation

```powershell
# Navigate to installer folder
cd path\to\PSHVTools-Setup-1.0.0

# Run uninstaller
powershell -ExecutionPolicy Bypass -File Install.ps1 -Uninstall
```

---

## ?? Support

- **Issues**: https://github.com/vitalie-vrabie/pshvtools/issues
- **Discussions**: https://github.com/vitalie-vrabie/pshvtools/discussions
- **Documentation**: See docs in repository

---

## ?? License

MIT License - See [LICENSE.txt](LICENSE.txt) for details

Copyright (c) 2025 Vitalie Vrabie

---

## ?? Acknowledgments

Built with:
- MSBuild for packaging
- PowerShell for automation and installation
- 7-Zip for compression

---

## ?? Release Assets

- **PSHVTools-v1.0.0.zip** - Source package
- **PSHVTools-Setup-1.0.0.zip** - Installer package (recommended)

---

**Thank you for using PSHVTools!** ??

For questions or issues, please visit the GitHub repository.
