# Inno Setup EXE Installer

## Overview

PSHVTools includes a professional GUI wizard installer built with Inno Setup. This creates a native Windows EXE installer with a modern wizard interface.

**Supported installation method:** the Inno Setup EXE installer.

## Prerequisites

- **Inno Setup 6** (for building the installer)
- **PowerShell 5.1+** (runtime)
- **7-Zip** (runtime; `7z.exe` in PATH or standard install location)

### Installing Inno Setup (build requirement)

**Option 1: WinGet (Recommended)**
```powershell
winget install JRSoftware.InnoSetup
```

**Option 2: Chocolatey**
```powershell
choco install innosetup
```

**Option 3: Direct Download**
Download from: https://jrsoftware.org/isdl.php

## Building the EXE Installer

### Quick Build

```cmd
Build-InnoSetupInstaller.bat
```

### Output

- **File:** `dist\PSHVTools-Setup-1.0.1.exe`
- **Type:** Native Windows EXE with GUI wizard

## Installer Features

### Professional GUI Wizard
- Modern Windows installer interface
- Welcome screen with product information
- License agreement display
- Installation directory selection
- Progress bar during installation
- Completion screen with summary

### System Requirements Check
- **PowerShell Version Check:** Validates PowerShell 5.1+
- **Hyper-V Detection:** Checks for Hyper-V availability (recommended)
- **7-Zip Detection:** Checks for `7z.exe` (required)

### Installation Features
- Installs module to: `C:\Program Files\WindowsPowerShell\Modules\pshvtools\`
- Creates Start Menu shortcuts
- Adds to Add/Remove Programs
- Includes uninstaller

## Installation for End Users

### Interactive Installation

1. Double-click `PSHVTools-Setup-1.0.1.exe`
2. Click "Next" through the wizard
3. Review system requirements check
4. Accept license agreement
5. Click "Install"
6. Done

### Silent Installation

```cmd
PSHVTools-Setup-1.0.1.exe /VERYSILENT /NORESTART
```

## Uninstallation

### Via Add/Remove Programs
- Settings -> Apps -> PSHVTools -> Uninstall

### Via Start Menu
- Start Menu -> PSHVTools -> Uninstall

### Silent Uninstall
```cmd
"C:\Program Files\PSHVTools\unins000.exe" /VERYSILENT /NORESTART
```

## Troubleshooting

### Requirements check fails
- Install PowerShell 5.1 or later
- Install 7-Zip and ensure `7z.exe` is available (PATH or standard location)
- Hyper-V is required on hosts where you will run the Hyper-V commands

## Files

| File | Description |
|------|-------------|
| `PSHVTools-Installer.iss` | Inno Setup script |
| `Build-InnoSetupInstaller.bat` | Build script |
| `dist\PSHVTools-Setup-1.0.1.exe` | Output installer |
