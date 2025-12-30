# PSHVTools - Build Guide
## Building Release Packages (MSBuild - No WiX Required!)

---

## ?? Quick Start

### Prerequisites

**MSBuild** (via one of these):
- Visual Studio 2022 (any edition)
- .NET SDK 6.0 or later
- Build Tools for Visual Studio 2022

**PowerShell 5.1+** (included with Windows)

**No WiX Toolset required!** ?

### Build Release Package

```cmd
Build-Release.bat
```

This creates:
- ?? Source ZIP package
- ?? Installer package with PowerShell install script
- ?? Output in `release\` and `dist\` folders

---

## ?? Build Options

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

### MSBuild Direct

```batch
# Build default target
msbuild PSHVTools.csproj

# Build specific target
msbuild PSHVTools.csproj /t:Package

# Clean
msbuild PSHVTools.csproj /t:Clean
```

---

## ?? Build Output

### Directory Structure

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
    ??? PSHVTools-Setup-1.0.0/     # Installer package
    ?   ??? Install.ps1            # Installer script
    ?   ??? README.txt             # Install instructions
    ?   ??? Module/                # Module files
    ?   ?   ??? hvbak.ps1
    ?   ?   ??? hvbak.psm1
    ?   ?   ??? hvbak.psd1
    ?   ??? README.md
    ?   ??? QUICKSTART.md
    ?   ??? LICENSE.txt
    ??? PSHVTools-Setup-1.0.0.zip  # Installer ZIP
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

## ?? Distribution

### For GitHub Releases

Create a release with both packages:

1. **PSHVTools-v1.0.0.zip** - Source package
2. **PSHVTools-Setup-1.0.0.zip** - Installer package

### Release Notes Template

```markdown
## PSHVTools v1.0.0

### Installation

Download the installer package:
- **PSHVTools-Setup-1.0.0.zip**

Extract and run Install.ps1 as Administrator.

#### Interactive Installation
```powershell
.\Install.ps1
```

#### Silent Installation
```powershell
.\Install.ps1 -Silent
```

### Requirements
- Windows with Hyper-V
- PowerShell 5.1 or later
- Administrator privileges

### Uninstallation
```powershell
.\Install.ps1 -Uninstall
```
```

---

## ?? Summary

### Quick Build

```cmd
# Build everything
Build-Release.bat package
```

### Output

```
release/PSHVTools-v1.0.0.zip          # Source package
dist/PSHVTools-Setup-1.0.0.zip        # Installer package
```

### Install

```powershell
powershell -ExecutionPolicy Bypass -File Install.ps1
```

**Simple, dependency-free build and installation!** ?

---

## ?? Migration from WiX

This build system replaces the previous WiX-based MSI installer with a simpler PowerShell approach.

**Benefits:**
- ? No WiX Toolset dependency
- ? Simpler build process
- ? Easier to maintain
- ? Works on any system with PowerShell
- ? Faster builds
- ? More transparent installation

See `WIX_TO_MSBUILD_MIGRATION.md` for details.

---

## ?? Additional Resources

- **Migration Guide:** WIX_TO_MSBUILD_MIGRATION.md
- **Quick Start:** QUICKSTART.md
- **Project Summary:** PROJECT_SUMMARY.md
- **License:** LICENSE.txt

---

**Need help?** Check the GitHub repository: https://github.com/vitalie-vrabie/pshvtools
