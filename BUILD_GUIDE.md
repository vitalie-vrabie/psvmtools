# PSVMTools - Build Guide
## Building the MSI Installer

---

## ?? Quick Start

### Prerequisites

Install WiX Toolset v3.14.1 or later:

**Option 1: WinGet (Recommended)**
```powershell
winget install --id WiXToolset.WiXToolset --accept-package-agreements --accept-source-agreements
```

**Option 2: Direct Download**
Download from https://wixtoolset.org/releases/

**Option 3: Chocolatey**
```powershell
choco install wixtoolset
```

### Build the MSI Installer

```powershell
# From the repository root directory
.\Build-WixInstaller.ps1
```

This will create:
- ? WiX MSI installer
- ?? Output in the `dist` folder

**Output:** `dist/PSVMTools-Setup-1.0.0.msi`

---

## ?? MSI Installer (Professional)

**Best for:** Professional deployment, traditional Windows installer experience

**File:**
- `dist/PSVMTools-Setup-1.0.0.msi` - Windows Installer (MSI) package

**Size:** ~300 KB

**Build Command:**
```powershell
# Using build script
.\Build-WixInstaller.ps1

# With custom output path
.\Build-WixInstaller.ps1 -OutputPath "C:\Release"

# Manual WiX build
candle.exe PSVMTools-Installer.wxs
light.exe -ext WixUIExtension -out dist\PSVMTools-Setup-1.0.0.msi PSVMTools-Installer.wixobj
```

**To Install:**
1. Copy `PSVMTools-Setup-1.0.0.msi` to target machine
2. Double-click the MSI
3. Follow the installation wizard
4. Done!

**Advantages:**
- ? Industry-standard Windows Installer
- ? Full MSI feature support
- ? Transactional installation (rollback on failure)
- ? Add/Remove Programs integration
- ? Group Policy deployment support
- ? SCCM/Intune compatible
- ? Start Menu shortcuts
- ? Silent install: `msiexec /i PSVMTools-Setup-1.0.0.msi /quiet`
- ? Silent uninstall: `msiexec /x PSVMTools-Setup-1.0.0.msi /quiet`

---

## ?? Build Options

### Custom Output Path
```powershell
.\Build-WixInstaller.ps1 -OutputPath "C:\MyBuilds"
```

### Skip WiX Check (if WiX path is custom)
```powershell
.\Build-WixInstaller.ps1 -SkipWixCheck
```

---

## ?? Usage After Installation

After installation, the module is available system-wide:

```powershell
# Display help
vmbak

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

## ? Uninstallation

### Using Add/Remove Programs
- Open **Settings ? Apps**
- Find **PSVMTools**
- Click **Uninstall**

### Using Start Menu
- Open Start Menu
- Find **PSVMTools**
- Click **Uninstall PSVMTools**

### Using Command Line
```cmd
# Silent uninstall
msiexec /x PSVMTools-Setup-1.0.0.msi /quiet /norestart

# Interactive uninstall
msiexec /x PSVMTools-Setup-1.0.0.msi
```

---

## ?? Silent Installation (Automated Deployment)

### Basic Silent Install
```cmd
msiexec /i PSVMTools-Setup-1.0.0.msi /quiet /norestart
```

### Silent Install with Logging
```cmd
msiexec /i PSVMTools-Setup-1.0.0.msi /quiet /norestart /l*v install.log
```

### Network Installation
```cmd
msiexec /i \\server\share\PSVMTools-Setup-1.0.0.msi /quiet /norestart
```

### Properties
```cmd
# Install to custom location (if supported)
msiexec /i PSVMTools-Setup-1.0.0.msi /quiet INSTALLDIR="C:\CustomPath"
```

---

## ?? Enterprise Deployment

### Group Policy Deployment

1. **Prepare MSI:**
   - Place MSI on network share
   - Ensure domain computers have read access

2. **Create GPO:**
   - Open Group Policy Management
   - Create new GPO or edit existing
   - Link to target OU

3. **Add Software:**
   - Navigate to: `Computer Configuration ? Policies ? Software Settings ? Software Installation`
   - Right-click ? New ? Package
   - Browse to network share and select MSI
   - Choose **Assigned** deployment method

4. **Apply:**
   - GPO will apply on next computer startup
   - Software installs automatically

### SCCM/ConfigMgr Deployment

1. **Import MSI:**
   - Import MSI into Software Library
   - Create Application

2. **Configure:**
   - **Install command:** `msiexec /i PSVMTools-Setup-1.0.0.msi /quiet /norestart`
   - **Uninstall command:** `msiexec /x PSVMTools-Setup-1.0.0.msi /quiet /norestart`
   - **Detection method:** Check for file or registry key

3. **Deploy:**
   - Deploy to device collections
   - Set deployment schedule
   - Monitor installation status

### Intune Deployment

1. **Upload:**
   - Go to Apps ? All apps ? Add
   - Select Line-of-business app
   - Upload MSI file

2. **Configure:**
   - Set install/uninstall commands
   - Configure detection rules
   - Set requirements

3. **Assign:**
   - Assign to groups (Required/Available)
   - Set deployment schedule
   - Track installation status

### PowerShell DSC

```powershell
Configuration InstallPSVMTools {
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    
    Node "localhost" {
        Package PSVMTools {
            Ensure = "Present"
            Path = "\\server\share\PSVMTools-Setup-1.0.0.msi"
            Name = "PSVMTools"
            ProductId = "{A3C5E8F1-9D4B-4A2C-B6E7-8F3D9C1A5B2E}"
        }
    }
}
```

---

## ?? Troubleshooting Build Issues

### "WiX not found"
**Solution:** 
- Install WiX Toolset from https://wixtoolset.org/releases/
- Or use WinGet: `winget install WiXToolset.WiXToolset`

### "File not found" errors
**Solution:**
- Run build from repository root directory
- Ensure all required files are present:
  - vmbak.ps1
  - vmbak.psm1
  - vmbak.psd1
  - QUICKSTART.md
  - PSVMTools-Installer.wxs

### "Access denied" during build
**Solution:**
- Close any files in `dist` folder
- Delete `dist` folder and try again
- Run PowerShell as Administrator if building to protected location

### WiX build errors
**Solution:**
```powershell
# Clean build
Remove-Item -Path "dist" -Recurse -Force -ErrorAction SilentlyContinue
.\Build-WixInstaller.ps1
```

---

## ?? Version Updates

When updating to a new version:

1. **Update module manifest** (`vmbak.psd1`):
   ```powershell
   ModuleVersion = '1.1.0'
   ```

2. **Update WiX installer** (`PSVMTools-Installer.wxs`):
   ```xml
   <Product Id="*" 
            Name="PSVMTools" 
            Version="1.1.0" 
            ...>
   ```

3. **Update build script** (`Build-WixInstaller.ps1`):
   ```powershell
   $msiFile = Join-Path -Path $OutputPath -ChildPath "PSVMTools-Setup-1.1.0.msi"
   ```

4. **Rebuild installer:**
   ```powershell
   Remove-Item -Path "dist" -Recurse -Force -ErrorAction SilentlyContinue
   .\Build-WixInstaller.ps1
   ```

---

## ?? Testing the Installer

### Test Installation
```powershell
# Build
.\Build-WixInstaller.ps1

# Install
cd dist
msiexec /i PSVMTools-Setup-1.0.0.msi

# Verify
vmbak
Get-Module vmbak -ListAvailable

# Check Start Menu
explorer "shell:programs\PSVMTools"

# Check Add/Remove Programs
appwiz.cpl
```

### Test Uninstallation
```powershell
# Uninstall via command
msiexec /x PSVMTools-Setup-1.0.0.msi

# Verify removal
Get-Module vmbak -ListAvailable
# Should return nothing
```

### Test Silent Installation
```powershell
# Silent install
msiexec /i PSVMTools-Setup-1.0.0.msi /quiet /norestart /l*v install.log

# Check log
Get-Content install.log -Tail 20

# Verify
vmbak
```

---

## ?? MSI Properties

### Product Information
- **Product Name:** PSVMTools
- **Manufacturer:** Vitalie Vrabie
- **Version:** 1.0.0
- **Upgrade Code:** A3C5E8F1-9D4B-4A2C-B6E7-8F3D9C1A5B2E (constant)
- **Product Code:** Auto-generated per version

### Installation Paths
- **Program Files:** `C:\Program Files\PSVMTools`
- **PowerShell Module:** `C:\Program Files\WindowsPowerShell\Modules\vmbak`
- **Start Menu:** `Start Menu\Programs\PSVMTools`

### Features
- Transactional installation
- Rollback on failure
- Add/Remove Programs integration
- Start Menu shortcuts
- Silent install/uninstall
- Upgrade support

---

## ?? Distribution

### For GitHub Releases

Create a release with:
- **PSVMTools-Setup-1.0.0.msi** - MSI installer

### Release Notes Template
```markdown
## PSVMTools v1.0.0

### Installation

Download and run the MSI installer:
- **PSVMTools-Setup-1.0.0.msi** (300 KB)

#### Interactive Installation
Double-click the MSI file

#### Silent Installation
```cmd
msiexec /i PSVMTools-Setup-1.0.0.msi /quiet /norestart
```

### Requirements
- Windows Server 2016+ or Windows 10+
- Hyper-V installed
- 7-Zip installed
- Administrator privileges
```

---

## ?? Additional Resources

- **Module Documentation:** README_VMBAK_MODULE.md
- **Quick Start Guide:** QUICKSTART.md
- **Package Details:** PACKAGE_README.md
- **License:** LICENSE.txt

---

## ?? Summary

**Build Command:**
```powershell
.\Build-WixInstaller.ps1
```

**Output:**
```
dist/
??? PSVMTools-Setup-1.0.0.msi
```

**Install Command:**
```cmd
msiexec /i PSVMTools-Setup-1.0.0.msi /quiet /norestart
```

**Distribute the MSI installer for professional Windows deployments!** ?

---

**Need help?** Check the GitHub repository: https://github.com/vitalie-vrabie/psvmtools
