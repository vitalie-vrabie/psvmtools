# Repository Rename Summary: psvmtools ? pshvtools

## ? Completed Successfully!

The repository has been successfully renamed from `psvmtools` to `pshvtools`.

---

## ?? What Was Changed

### 1. Product Branding
- **Old:** PSVMTools (PowerShell VM Tools)
- **New:** PSHVTools (PowerShell Hyper-V Tools)

### 2. Repository URL
- **Old:** https://github.com/vitalie-vrabie/psvmtools
- **New:** https://github.com/vitalie-vrabie/pshvtools

### 3. Files Updated

**Code Files:**
- ? `vmbak.psd1` - Module manifest (CompanyName, Description, Tags, ProjectUri, ReleaseNotes)
- ? `README.md` - All references and URLs
- ? `QUICKSTART.md` - Product name and URLs
- ? `LICENSE.txt` - Product name and URL
- ? `PSVMTools-Installer.wxs` ? `PSHVTools-Installer.wxs` (renamed and updated)
- ? `Build-WixInstaller.bat` - File names and output messages

**Installer Files:**
- ? `PSVMTools-Setup-1.0.0.msi` ? `PSHVTools-Setup-1.0.0.msi`
- ? WiX Product Name updated to "PSHVTools"
- ? Installation folder changed to `C:\Program Files\PSHVTools`
- ? Start Menu folder changed to `PSHVTools`
- ? Registry key changed to `Software\PSHVTools`

**Git Configuration:**
- ? Remote URL updated to pshvtools
- ? All changes committed
- ? Changes pushed to GitHub

---

## ?? Current State

### Repository Information
- **GitHub URL:** https://github.com/vitalie-vrabie/pshvtools
- **Local Path:** C:\Users\vvrab\source\repos\psvmtools (folder name unchanged)
- **Branch:** master
- **Last Commit:** 438690e - "Rename repository from psvmtools to pshvtools"

### Product Information
- **Product Name:** PSHVTools (PowerShell Hyper-V Tools)
- **Version:** 1.0.0
- **Module Name:** vmbak
- **Commands:** `vmbak` and `vm-bak`
- **MSI Installer:** PSHVTools-Setup-1.0.0.msi (304 KB)

---

## ?? MSI Installer Details

**File:** `dist\PSHVTools-Setup-1.0.0.msi`

**Installation:**
```cmd
# Interactive
msiexec /i PSHVTools-Setup-1.0.0.msi

# Silent
msiexec /i PSHVTools-Setup-1.0.0.msi /quiet /norestart
```

**Installs To:**
- Program Files: `C:\Program Files\PSHVTools`
- PowerShell Module: `C:\Program Files\WindowsPowerShell\Modules\vmbak`
- Start Menu: `Start Menu\Programs\PSHVTools`

---

## ?? Verification

### Check Git Remote
```cmd
git remote get-url origin
# Should show: https://github.com/vitalie-vrabie/pshvtools.git
```

### Check Module Manifest
```powershell
Import-PowerShellDataFile .\vmbak.psd1 | Select-Object CompanyName, Description, ProjectUri
# CompanyName: PSHVTools
# Description: PSHVTools - PowerShell tools for backing up Hyper-V VMs...
# ProjectUri: https://github.com/vitalie-vrabie/pshvtools
```

### Check WiX Installer
```cmd
# Build produces: PSHVTools-Setup-1.0.0.msi
.\Build-WixInstaller.bat
```

---

## ?? Next Steps

### Optional: Rename Local Folder
If you want to rename the local folder to match:
```cmd
cd C:\Users\vvrab\source\repos
Rename-Item -Path "psvmtools" -NewName "pshvtools"
cd pshvtools
```

### Update Release Notes
The RELEASE_NOTES_v1.0.0.md file should be updated to use PSHVTools branding before creating a GitHub release.

### Test Installation
```cmd
cd dist
msiexec /i PSHVTools-Setup-1.0.0.msi
# Verify installation
vmbak
vm-bak
# Check Start Menu for PSHVTools folder
# Check Add/Remove Programs for PSHVTools entry
```

---

## ?? Files That Reference the New Name

All these files now use "PSHVTools" and "pshvtools":

1. ? vmbak.psd1
2. ? README.md
3. ? QUICKSTART.md
4. ? LICENSE.txt
5. ? PSHVTools-Installer.wxs
6. ? Build-WixInstaller.bat
7. ? dist/PSHVTools-Setup-1.0.0.msi

---

## ? GitHub Repository Behavior

GitHub automatically:
- ? Redirects old URLs (psvmtools) to new URLs (pshvtools)
- ? Updates all existing issues/PRs
- ? Maintains all commit history
- ? Preserves all stars and watchers
- ? Updates clone URLs

---

## ?? Summary

**The rename is complete!**

- Product: **PSVMTools** ? **PSHVTools**
- Repository: **psvmtools** ? **pshvtools**
- URLs: All updated to pshvtools
- MSI: Now builds as PSHVTools-Setup-1.0.0.msi
- Git: Remote updated and changes pushed

**Everything is ready for the v1.0.0 release!** ??

---

**Date:** 2025-01-XX  
**Commit:** 438690e  
**Status:** ? Complete
