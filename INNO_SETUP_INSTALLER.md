# Inno Setup EXE Installer

## Overview

PSHVTools now includes a professional GUI wizard installer built with Inno Setup. This creates a native Windows EXE installer with a modern wizard interface.

## Prerequisites

**Inno Setup 6** (free, open source)

### Installation Options:

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

- **File:** `dist\PSHVTools-Setup-1.0.0.exe`
- **Size:** ~2-3 MB (includes compression)
- **Type:** Native Windows EXE with GUI wizard

## Installer Features

### ?? Professional GUI Wizard
- Modern Windows installer interface
- Welcome screen with product information
- License agreement display
- Installation directory selection
- Progress bar during installation
- Completion screen with summary

### ? System Requirements Check
- **PowerShell Version Check:** Validates PowerShell 5.1+
- **Hyper-V Detection:** Checks for Hyper-V availability
- **Interactive Results:** Shows check results before installation
- **Smart Warnings:** Warns if requirements not met, allows override

### ?? Installation Features
- Installs module to: `C:\Program Files\WindowsPowerShell\Modules\hvbak\`
- Creates Start Menu shortcuts
- Adds to Add/Remove Programs
- Includes uninstaller
- Registry entries for version tracking

### ??? Clean Uninstallation
- Proper uninstaller included
- Removes all files and registry entries
- Accessible from Start Menu
- Accessible from Add/Remove Programs

## Installation for End Users

### Interactive Installation

1. Double-click `PSHVTools-Setup-1.0.0.exe`
2. Click "Next" through the wizard
3. Review system requirements check
4. Accept license agreement
5. Choose installation directory (or use default)
6. Click "Install"
7. Done!

### Silent Installation

```cmd
# Completely silent
PSHVTools-Setup-1.0.0.exe /VERYSILENT /NORESTART

# Silent with progress
PSHVTools-Setup-1.0.0.exe /SILENT /NORESTART

# Silent with log file
PSHVTools-Setup-1.0.0.exe /VERYSILENT /NORESTART /LOG="C:\Temp\install.log"

# Silent with custom directory
PSHVTools-Setup-1.0.0.exe /VERYSILENT /DIR="C:\MyPrograms\PSHVTools"
```

### Command Line Options

| Option | Description |
|--------|-------------|
| `/SILENT` | Silent mode with progress window |
| `/VERYSILENT` | Completely silent (no UI) |
| `/NORESTART` | Prevent automatic restart |
| `/LOG="file.log"` | Create installation log |
| `/DIR="path"` | Custom installation directory |
| `/NOICONS` | Don't create Start Menu icons |
| `/TASKS="task1,task2"` | Specify tasks to run |
| `/? ` | Show command line help |

## Uninstallation

### Via Add/Remove Programs
1. Open Settings ? Apps
2. Find "PSHVTools"
3. Click Uninstall

### Via Start Menu
1. Open Start Menu
2. Navigate to PSHVTools folder
3. Click "Uninstall PSHVTools"

### Silent Uninstall
```cmd
# Find uninstaller path (typically in installation folder)
"C:\Program Files\PSHVTools\unins000.exe" /VERYSILENT /NORESTART
```

## Customization

### Custom Icon

Add a file named `icon.ico` to the project root. The installer will automatically use it for:
- Installer executable icon
- Installed application icon
- Uninstaller icon
- Start Menu shortcuts

### Modify Installation

Edit `PSHVTools-Installer.iss` to customize:
- Company/publisher information
- Installation directories
- Files to include
- Registry entries
- Start Menu items
- Installation checks
- UI messages

## Enterprise Deployment

### Group Policy

1. Place EXE on network share
2. Create GPO for software installation
3. Use startup script:
   ```batch
   \\server\share\PSHVTools-Setup-1.0.0.exe /VERYSILENT /NORESTART
   ```

### SCCM/ConfigMgr

**Install Command:**
```cmd
PSHVTools-Setup-1.0.0.exe /VERYSILENT /NORESTART /LOG="C:\Windows\Temp\pshvtools-install.log"
```

**Uninstall Command:**
```cmd
"C:\Program Files\PSHVTools\unins000.exe" /VERYSILENT /NORESTART
```

**Detection Method:**
- Check for file: `C:\Program Files\WindowsPowerShell\Modules\hvbak\hvbak.psd1`
- Or check registry: `HKLM\Software\Vitalie Vrabie\PSHVTools\Version`

### PowerShell Remote Deployment

```powershell
$computers = @("server1", "server2", "server3")
$installerPath = "\\server\share\PSHVTools-Setup-1.0.0.exe"

foreach ($computer in $computers) {
    Invoke-Command -ComputerName $computer -ScriptBlock {
        param($path)
        Start-Process -FilePath $path -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
    } -ArgumentList $installerPath
}
```

## Comparison: EXE vs PowerShell Installer

| Feature | EXE (Inno Setup) | PowerShell |
|---------|------------------|------------|
| GUI Wizard | ? Yes | ? No |
| Silent Install | ? Yes | ? Yes |
| Progress Bar | ? Yes | ?? Console only |
| Requirements Check | ? Automated | ?? Manual |
| Uninstaller | ? Built-in | ?? Separate script |
| Add/Remove Programs | ? Yes | ? No |
| Start Menu | ? Shortcuts | ? No |
| File Size | ~2-3 MB | ~50 KB |
| Build Tool | Inno Setup | None |
| Professional Look | ??? | ?? |
| Ease of Use | ??? | ?? |

## Advantages of EXE Installer

### For End Users
- ? Familiar Windows installer experience
- ? Professional GUI wizard
- ? Clear installation progress
- ? Easy uninstallation
- ? Start Menu integration
- ? Add/Remove Programs support

### For Administrators
- ? Silent installation support
- ? Full command-line control
- ? Detailed logging options
- ? Enterprise deployment ready
- ? Professional appearance
- ? Standard Windows installer behavior

### For Developers
- ? Free and open source (Inno Setup)
- ? Easy to customize
- ? Good documentation
- ? Active community
- ? Version control friendly (text-based script)

## Troubleshooting

### Build Issues

**Inno Setup not found:**
```cmd
winget install JRSoftware.InnoSetup
```

**Missing files error:**
- Ensure all source files are present
- Check file paths in PSHVTools-Installer.iss

**Icon not found:**
- Add icon.ico file (optional)
- Or remove icon references from .iss file

### Installation Issues

**Requirements check fails:**
- Install PowerShell 5.1 or later
- Install Hyper-V (optional, but recommended)

**Access denied:**
- Run installer as Administrator
- Check UAC settings

**Silent install not working:**
- Use `/VERYSILENT` flag
- Check log file with `/LOG` flag

## Files

| File | Description |
|------|-------------|
| `PSHVTools-Installer.iss` | Inno Setup script |
| `Build-InnoSetupInstaller.bat` | Build script |
| `icon.ico` | Custom icon (optional) |
| `dist\PSHVTools-Setup-1.0.0.exe` | Output installer |

## Next Steps

1. **Install Inno Setup** (if not already installed)
2. **Add custom icon** (optional): `icon.ico`
3. **Build installer:** `Build-InnoSetupInstaller.bat`
4. **Test installation:** Double-click the EXE
5. **Distribute:** Upload to GitHub releases

## Resources

- **Inno Setup Website:** https://jrsoftware.org/isinfo.php
- **Inno Setup Documentation:** https://jrsoftware.org/ishelp/
- **Script Reference:** https://jrsoftware.org/ishelp/index.php?topic=scriptintro

---

**PSHVTools now has a professional Windows installer!** ??
