# PSHVTools - Build Guide
## Building Release Packages

---

## ?? Quick Start

### Build Options

PSHVTools offers **two installer types**:

1. **PowerShell Installer** (Simple, no dependencies)
2. **GUI EXE Installer** (Professional wizard with Inno Setup)

### Quick Build Commands

```cmd
# PowerShell Installer (MSBuild - no dependencies)
Build-Release.bat package

# GUI EXE Installer (Inno Setup - professional wizard)
Build-InnoSetupInstaller.bat
```

---

## ?? Option 1: PowerShell Installer (Recommended for Development)

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

### Output

- `release/PSHVTools-v1.0.0.zip` - Source package (~19 KB)
- `dist/PSHVTools-Setup-1.0.0/Install.ps1` - PowerShell installer
- `dist/PSHVTools-Setup-1.0.0.zip` - Distributable installer

### Advantages
- ? No additional tools required
- ? Fast builds (< 5 seconds)
- ? Small size (~19 KB)
- ? Easy to customize
- ? Silent install support

---

## ?? Option 2: GUI EXE Installer (Recommended for Distribution)

### Prerequisites

**Inno Setup 6** (free, open source)

```powershell
# Install via WinGet (recommended)
winget install JRSoftware.InnoSetup

# Or via Chocolatey
choco install innosetup

# Or download from:
# https://jrsoftware.org/isdl.php
```

### Build Command

```cmd
Build-InnoSetupInstaller.bat
```

### Output

- `dist/PSHVTools-Setup-1.0.0.exe` - Professional GUI installer (~2-3 MB)

### Features

? **Professional GUI Wizard**
- Modern Windows installer interface
- Welcome screen
- License agreement display
- Installation directory selection
- Progress bar
- Completion screen

? **System Requirements Check**
- PowerShell version validation
- Hyper-V detection
- Interactive results display

?? **Full Windows Integration**
- Start Menu shortcuts
- Add/Remove Programs entry
- Built-in uninstaller
- Registry integration

### Advantages
- ? Professional appearance
- ? Familiar Windows installer experience
- ? Full GUI wizard
- ? Automated requirements check
- ? Silent install support
- ? Easy uninstallation

### Silent Installation

```cmd
# Completely silent
PSHVTools-Setup-1.0.0.exe /VERYSILENT /NORESTART

# Silent with log
PSHVTools-Setup-1.0.0.exe /VERYSILENT /NORESTART /LOG="install.log"
```

**Full documentation:** See [INNO_SETUP_INSTALLER.md](INNO_SETUP_INSTALLER.md)

---

## ?? Comparison: PowerShell vs GUI EXE

| Feature | PowerShell Installer | GUI EXE Installer |
|---------|---------------------|-------------------|
| **Build Tool** | MSBuild (built-in) | Inno Setup |
| **File Size** | ~19 KB | ~2-3 MB |
| **Build Time** | < 5 seconds | ~10 seconds |
| **GUI Wizard** | ? No | ? Yes |
| **Progress Bar** | ?? Console only | ? GUI |
| **Requirements Check** | ?? During install | ? Before install |
| **Uninstaller** | Separate script | ? Built-in |
| **Add/Remove Programs** | ? No | ? Yes |
| **Start Menu** | ? No | ? Yes |
| **Silent Install** | ? Yes | ? Yes |
| **Professional Look** | ?? Basic | ??? |
| **Ease of Build** | ??? | ?? |
| **Customization** | ??? | ?? |

### When to Use Each

**Use PowerShell Installer when:**
- Quick development/testing
- Internal deployment
- Minimal size matters
- No GUI needed
- Maximum simplicity

**Use GUI EXE Installer when:**
- Public distribution
- Professional appearance matters
- End-user friendly installation
- Requirements checking important
- Windows integration desired

---

## ?? Build Output Structure

```
pshvtools/
??? release/
?   ??? PSHVTools-v1.0.0/          # Source package
?   ?   ??? hvbak.ps1
?   ?   ??? hvbak.psm1
?   ?   ??? hvbak.psd1
?   ?   ??? Install-PSHVTools.ps1
?   ?   ??? Uninstall-PSHVTools.ps1
?   ?   ??? README.md
?   ?   ??? QUICKSTART.md
?   ?   ??? LICENSE.txt
?   ??? PSHVTools-v1.0.0.zip       # Source ZIP
?
??? dist/
    ??? PSHVTools-Setup-1.0.0/     # PowerShell installer
    ?   ??? Install.ps1
    ?   ??? README.txt
    ?   ??? Module/
    ??? PSHVTools-Setup-1.0.0.zip  # PowerShell installer ZIP
    ??? PSHVTools-Setup-1.0.0.exe  # GUI EXE installer
```

---

## ?? Installer Package

**Best for:** Easy distribution and installation

**Location:** `dist/PSHVTools-Setup-1.0.0/`

**Installation:**
```powershell
# Interactive
Right-click Install.ps1 ? "Run with PowerShell" (as Administrator)

# Command line
powershell -ExecutionPolicy Bypass -File Install.ps1

# Silent
powershell -ExecutionPolicy Bypass -File Install.ps1 -Silent
```

**Advantages:**
- ? No WiX Toolset required to build
- ? No special tools required to install
- ? Works on all Windows versions with PowerShell 5.1+
- ? Simple PowerShell script installation
- ? Easy to customize and maintain
- ? Clean uninstallation
- ? No registry modifications

---

## ?? Installation Process

### For Users

1. **Extract** the installer package:
   ```
   PSHVTools-Setup-1.0.0.zip
   ```

2. **Run Install.ps1** as Administrator:
   ```powershell
   # Interactive
   .\Install.ps1
   
   # Silent
   .\Install.ps1 -Silent
   ```

3. **Verify** installation:
   ```powershell
   Get-Module -ListAvailable hvbak
   Import-Module hvbak
   Get-Command -Module hvbak
   ```

### Installation Location

Module installed to:
```
C:\Program Files\WindowsPowerShell\Modules\hvbak\
```

---

## ??? Uninstallation

```powershell
# Interactive
powershell -ExecutionPolicy Bypass -File Install.ps1 -Uninstall

# Silent
powershell -ExecutionPolicy Bypass -File Install.ps1 -Uninstall -Silent
```

---

## ?? Enterprise Deployment

### Network Distribution

1. **Build** the installer package:
   ```cmd
   Build-Installer.bat
   ```

2. **Place** on network share:
   ```
   \\server\share\PSHVTools-Setup-1.0.0.zip
   ```

3. **Deploy** via script:
   ```powershell
   # Copy to local system
   Copy-Item "\\server\share\PSHVTools-Setup-1.0.0.zip" "$env:TEMP"
   
   # Extract
   Expand-Archive "$env:TEMP\PSHVTools-Setup-1.0.0.zip" "$env:TEMP\PSHVTools-Setup"
   
   # Install silently
   powershell -ExecutionPolicy Bypass -File "$env:TEMP\PSHVTools-Setup\Install.ps1" -Silent
   ```

### PowerShell DSC

```powershell
Configuration InstallPSHVTools {
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    
    Node "localhost" {
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
}
```

### Group Policy Startup Script

```batch
@echo off
if not exist "C:\Program Files\WindowsPowerShell\Modules\hvbak" (
    powershell -ExecutionPolicy Bypass -File "\\server\share\PSHVTools-Setup-1.0.0\Install.ps1" -Silent
)
```

---

## ?? Troubleshooting Build Issues

### MSBuild not found

**Solution:**
```powershell
# Install .NET SDK
winget install Microsoft.DotNet.SDK.8

# Or install Visual Studio 2022
winget install Microsoft.VisualStudio.2022.Community
```

### PowerShell execution policy

**Solution:**
```powershell
# Allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Build fails

**Solution:**
```cmd
# Clean and rebuild
Build-Release.bat clean
Build-Release.bat
```

### Missing files

**Solution:**
Ensure all required files are present:
- hvbak.ps1
- hvbak.psm1
- hvbak.psd1
- QUICKSTART.md
- README.md
- LICENSE.txt
- Install-PSHVTools.ps1
- Uninstall-PSHVTools.ps1

---

## ?? Version Updates

When updating to a new version:

1. **Update module manifest** (`hvbak.psd1`):
   ```powershell
   ModuleVersion = '1.1.0'
   ```

2. **Update project file** (`PSHVTools.csproj`):
   ```xml
   <Version>1.1.0</Version>
   ```

3. **Rebuild:**
   ```cmd
   Build-Release.bat clean
   Build-Release.bat package
   ```

---

## ? Testing

### Test Installation
```powershell
# Build
.\Build-Release.bat package

# Test install
cd dist\PSHVTools-Setup-1.0.0
.\Install.ps1

# Verify
Get-Module -ListAvailable hvbak
Import-Module hvbak -Force
Get-Command -Module hvbak

# Test functionality
Backup-HyperVVM -Help
```

### Test Uninstallation
```powershell
# Uninstall
cd dist\PSHVTools-Setup-1.0.0
.\Install.ps1 -Uninstall

# Verify removal
Get-Module -ListAvailable hvbak
# Should return nothing
```

---

## ?? Distribution Recommendations

### For GitHub Releases

Upload all three packages:

1. **PSHVTools-v1.0.0.zip** - Source package
2. **PSHVTools-Setup-1.0.0.zip** - PowerShell installer (internal/dev)
3. **PSHVTools-Setup-1.0.0.exe** - GUI installer (recommended for users)

### Release Notes Template

```markdown
## PSHVTools v1.0.0

### Installation

**For most users (recommended):**
Download and run: **PSHVTools-Setup-1.0.0.exe**

**For PowerShell users:**
Download and extract: **PSHVTools-Setup-1.0.0.zip**
Then run: `Install.ps1` as Administrator

**For developers:**
Download source: **PSHVTools-v1.0.0.zip**

### Requirements
- Windows with Hyper-V
- PowerShell 5.1 or later
- Administrator privileges
```

---

## ?? Summary

### Build Everything

```cmd
# PowerShell installer
Build-Release.bat package

# GUI EXE installer
Build-InnoSetupInstaller.bat
```

### Outputs

```
? release/PSHVTools-v1.0.0.zip          (Source - 19 KB)
? dist/PSHVTools-Setup-1.0.0.zip        (PowerShell - 19 KB)
? dist/PSHVTools-Setup-1.0.0.exe        (GUI EXE - 2-3 MB)
```

**Professional installers for every use case!** ?

---

## ?? Additional Resources

- **Inno Setup Guide:** [INNO_SETUP_INSTALLER.md](INNO_SETUP_INSTALLER.md)
- **Quick Start:** [QUICKSTART.md](QUICKSTART.md)
- **Project Summary:** [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
- **License:** [LICENSE.txt](LICENSE.txt)

---

**Need help?** Check the GitHub repository: https://github.com/vitalie-vrabie/pshvtools
