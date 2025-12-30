# PSHVTools Setup v1.0.0

## Installation

### Option 1: Interactive Installation
Right-click 'Install.ps1' and select "Run with PowerShell" (as Administrator)

### Option 2: Command Line Installation
```powershell
# Run as Administrator
powershell -ExecutionPolicy Bypass -File Install.ps1
```

### Option 3: Silent Installation
```powershell
# Run as Administrator
powershell -ExecutionPolicy Bypass -File Install.ps1 -Silent
```

## Uninstallation

```powershell
# Run as Administrator
powershell -ExecutionPolicy Bypass -File Install.ps1 -Uninstall
```

## Requirements

- Windows with Hyper-V
- PowerShell 5.1 or later
- Administrator privileges for installation

## What Gets Installed

The installer will:
- Copy the hvbak PowerShell module to: C:\Program Files\WindowsPowerShell\Modules\hvbak
- Make the module available system-wide
- No registry changes or system modifications required

## More Information

- Quick Start Guide: See QUICKSTART.md
- Full Documentation: See README.md
- License: See LICENSE.txt
- Project: https://github.com/vitalie-vrabie/pshvtools

## Replacing the WiX MSI Installer

This PowerShell-based installer replaces the previous WiX MSI installer with a simpler,
dependency-free solution that works on any Windows system with PowerShell 5.1+.

Benefits:
- No WiX Toolset required to build
- No special tools required to install
- Simple PowerShell script installation
- Easy to customize and maintain
- Works on all Windows versions with PowerShell 5.1+
