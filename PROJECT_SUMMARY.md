# ?? PSHVTools - Project Summary

## What We've Built

A PowerShell module + Inno Setup GUI installer for **PSHVTools**  Hyper-V VM backup and restore utilities.

---

## ?? Package Components

### 1. Core Module Files
- `scripts\hvbak.ps1` - Main backup script
- `scripts\pshvtools.psm1` - PowerShell module wrapper
- `scripts\pshvtools.psd1` - Module manifest
- `scripts\fix-vhd-acl.ps1` - VHD/VHDX permission repair utility
- `scripts\restore-vmbackup.ps1` - Restore/import from `hvbak` backups

### 2. Build System (Inno Setup)
- `installer\PSHVTools-Installer.iss` - Inno Setup installer script
- `installer\Build-InnoSetupInstaller.bat` - Builds the GUI installer EXE

### 3. Documentation
- `README.md` - Main project overview
- `QUICKSTART.md` - Quick start guide for users
- `BUILD_GUIDE.md` - Build instructions
- `LICENSE.txt` - MIT license

---

## ?? How to Build

### Prerequisites

- Inno Setup 6
- PowerShell 5.1+

### Build Command

```cmd
installer\Build-InnoSetupInstaller.bat
```

**Output:**
- `dist\PSHVTools-Setup-1.0.1.exe`

---

## ?? Module Commands

- Backup: `Invoke-VMBackup` (aliases: `hvbak`, `hv-bak`)
- Restore: `Restore-VMBackup` (alias: `hvrestore`)
- VHD ACL repair: `Repair-VhdAcl` (alias: `fix-vhd-acl`)

---

## ?? Next Steps

1) Build installer:
```cmd
installer\Build-InnoSetupInstaller.bat
```

2) Install and test:
```powershell
Import-Module pshvtools
hvbak -NamePattern "*"
# restore latest for a VM
hvrestore -VmName "MyVM" -Latest -NoNetwork
```

---
