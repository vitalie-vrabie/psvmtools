# PSVMTools - PowerShell VM Backup Tools
## MSI Installation Package

Version 1.0.0

### Overview

PSVMTools is a comprehensive PowerShell module for backing up Hyper-V virtual machines using checkpoints and 7-Zip compression. This MSI installer provides a professional Windows Installer package for enterprise deployment.

---

## Package Contents

This MSI installer includes:

- **vmbak.ps1** - Main backup script
- **vmbak.psm1** - PowerShell module
- **vmbak.psd1** - Module manifest
- **Documentation** - Quick start guide and comprehensive documentation
- **Start Menu Shortcuts** - Easy access to documentation and uninstaller

---

## Installation

### MSI Installer (Windows Installer)

Professional Windows Installer package built with WiX Toolset.

**To Install:**
1. Double-click `PSVMTools-Setup-1.0.0.msi`
2. Follow the installation wizard
3. Module will be automatically registered

**Features:**
- ? Industry-standard Windows Installer (MSI)
- ? Transactional installation with rollback
- ? Start Menu shortcuts
- ? Add/Remove Programs integration
- ? Group Policy deployment support
- ? SCCM/Intune compatible
- ? Silent install support

**Silent Installation:**
```cmd
# Basic silent install
msiexec /i PSVMTools-Setup-1.0.0.msi /quiet /norestart

# Silent install with logging
msiexec /i PSVMTools-Setup-1.0.0.msi /quiet /norestart /l*v install.log
```

---

## Quick Start

After installation, the `vmbak` cmdlet is available system-wide:

### Display Help
```powershell
vmbak
```

### Basic Usage
```powershell
# Backup all VMs
vmbak -NamePattern "*"

# Backup specific VMs
vmbak -NamePattern "srv-*"

# Custom destination
vmbak -NamePattern "*" -Destination "D:\backups"

# Get detailed help
Get-Help vmbak -Full
```

---

## System Requirements

### Minimum Requirements:
- Windows Server 2016 or Windows 10 (with Hyper-V)
- PowerShell 5.1 or later
- Hyper-V PowerShell module
- 7-Zip installed (7z.exe in PATH)
- Administrator privileges

### Recommended:
- Windows Server 2019 or later
- PowerShell 7+
- Sufficient disk space for backups
- Fast storage for temp folder (E:\vmbkp.tmp)

---

## Uninstallation

### Using Add/Remove Programs:
1. Open Settings ? Apps
2. Find "PSVMTools"
3. Click Uninstall

### Using Start Menu:
1. Open Start Menu
2. Navigate to PSVMTools folder
3. Click "Uninstall PSVMTools"

### Using Command Line:
```cmd
# Interactive uninstall
msiexec /x PSVMTools-Setup-1.0.0.msi

# Silent uninstall
msiexec /x PSVMTools-Setup-1.0.0.msi /quiet /norestart
```

---

## Package Structure

```
PSVMTools/
??? Build-WixInstaller.ps1             # Builds the MSI installer
??? PSVMTools-Installer.wxs            # WiX installer definition
??? dist/                              # Output folder for built installers
?   ??? PSVMTools-Setup-1.0.0.msi     # MSI installer
??? vmbak.ps1                          # Main backup script
??? vmbak.psm1                         # PowerShell module
??? vmbak.psd1                         # Module manifest
??? README_VMBAK_MODULE.md             # Module documentation
??? QUICKSTART.md                      # Quick start guide
??? LICENSE.txt                        # License information
??? PACKAGE_README.md                  # This file
```

---

## Building the MSI Installer

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

### Build Command

```powershell
# Run from the repository root
.\Build-WixInstaller.ps1

# Output will be in ./dist folder
# File created: PSVMTools-Setup-1.0.0.msi
```

---

## Distribution

Distribute the MSI file:
- **PSVMTools-Setup-1.0.0.msi** - Windows Installer package

### Enterprise Deployment

**Group Policy:**
1. Place MSI on network share
2. Create GPO for software installation
3. Assign to computers
4. Automatic deployment on startup

**SCCM/ConfigMgr:**
1. Import MSI into Software Library
2. Create Application
3. Deploy to collections
4. Monitor installation status

**Intune:**
1. Upload MSI as Line-of-Business app
2. Configure install/uninstall commands
3. Assign to groups
4. Track installation status

---

## Silent Installation Examples

### Basic Silent Install
```cmd
msiexec /i PSVMTools-Setup-1.0.0.msi /quiet /norestart
```

### Silent Install with Logging
```cmd
msiexec /i PSVMTools-Setup-1.0.0.msi /quiet /norestart /l*v "%TEMP%\psvmtools-install.log"
```

### Network Installation
```cmd
msiexec /i \\fileserver\share\PSVMTools-Setup-1.0.0.msi /quiet /norestart
```

### PowerShell Remote Deployment
```powershell
$computers = @("server1", "server2", "server3")
$msiPath = "\\fileserver\share\PSVMTools-Setup-1.0.0.msi"

foreach ($computer in $computers) {
    Invoke-Command -ComputerName $computer -ScriptBlock {
        param($path)
        Start-Process msiexec.exe -ArgumentList "/i `"$path`" /quiet /norestart" -Wait
    } -ArgumentList $msiPath
}
```

---

## Troubleshooting

### "Access denied" errors:
- Ensure you're running as Administrator
- Check antivirus hasn't blocked the installer
- Verify you have write access to Program Files

### Module not found after installation:
```powershell
# Check installation
Get-Module vmbak -ListAvailable

# Manually import if needed
Import-Module vmbak -Force

# Verify installation path
$env:PSModulePath -split ';'
```

### 7-Zip not found:
```powershell
# Install 7-Zip from https://www.7-zip.org/
# Or ensure 7z.exe is in your PATH
```

### Installation Logs:
```cmd
# Install with verbose logging
msiexec /i PSVMTools-Setup-1.0.0.msi /l*v "%TEMP%\install.log"

# View log
notepad "%TEMP%\install.log"
```

---

## Support

- GitHub: https://github.com/vitalie-vrabie/psvmtools
- Documentation: See README_VMBAK_MODULE.md
- Quick Start: See QUICKSTART.md

---

## License

MIT License - See LICENSE.txt for details

Copyright (c) 2025 Vitalie Vrabie

---

## Version History

### Version 1.0.0 (2025)
- Initial release
- WiX-based MSI installer (Windows Installer)
- Complete documentation
- Automatic module registration
- Start Menu integration
- Add/Remove Programs support
- Enterprise deployment ready

---

**Thank you for using PSVMTools!**
