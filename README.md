# PSHVTools - PowerShell Hyper-V Tools

**Version:** 1.0.6  
**Product Name:** PSHVTools (PowerShell Hyper-V Tools)  
**Module Name:** pshvtools  
**Commands:** `Invoke-VMBackup`, `Repair-VhdAcl`, `Restore-VMBackup`, `Restore-OrphanedVMs` and aliases: `hvbak`, `hv-bak`, `fix-vhd-acl`, `hvrestore`, `hvrecover`  
**License:** MIT

---

## What is PSHVTools?

PSHVTools is a PowerShell module for backing up and managing Hyper-V virtual machines. It provides cmdlets for automated, parallel VM backups with checkpoint support, 7-Zip compression, VHD permission repair utilities, and VM recovery tools.

### Key Features
- Live VM backups using Production checkpoints
- Parallel processing of multiple VMs
- 7-Zip compression with multithreading
- Configurable backup retention (keep 1-100 copies per VM)
- Progress tracking with real-time status
- Graceful cancellation (Ctrl+C support)
- Low-priority compression (Idle CPU class)
- VHD/VHDX permission repair utility
- Restore/import from `hvbak` `.7z` backups (with optional network switch mapping)
- Recover orphaned VMs by re-registering configs found on disk (scan `Virtual Machines` folder)
- Utility script to remove GPU partition adapters from VMs (see `scripts/remove-gpu-partitions.ps1`)

---

## Installation

### GUI Installer (Recommended for End Users)

1. Download `PSHVTools-Setup-1.0.6.exe`
2. Double-click to run the installer
3. Follow the wizard
4. Done

**Silent install:**
```cmd
PSHVTools-Setup-1.0.6.exe /VERYSILENT /NORESTART
```

### PowerShell Installer (Alternative)

1. Download and extract `PSHVTools-Setup-1.0.6.zip`
2. Right-click `Install.ps1` -> "Run with PowerShell" (as Administrator)

**Command line install:**
```powershell
powershell -ExecutionPolicy Bypass -File Install.ps1
```

**Silent install:**
```powershell
powershell -ExecutionPolicy Bypass -File Install.ps1 -Silent
```

After installation:
```powershell
Import-Module pshvtools

# Backup VMs
hvbak -NamePattern "*"

# Restore VMs
hvrestore -VmName "MyVM" -Latest

# Fix VHD permissions
fix-vhd-acl -WhatIf

# Recover orphaned VMs
hvrecover -WhatIf
```

**Full user documentation:** See [QUICKSTART.md](QUICKSTART.md)

---

## Utility Scripts

### Remove GPU partition adapters

File: `scripts/remove-gpu-partitions.ps1`

Removes all GPU partition adapters from Hyper-V VMs matching a wildcard pattern. This is intended to work even if the host has no compatible GPU currently present.

```powershell
# Script
.\scripts\remove-gpu-partitions.ps1 -NamePattern "lab-*"
.\scripts\remove-gpu-partitions.ps1 -NamePattern "*" -WhatIf

# Module alias (after: Import-Module pshvtools)
nogpup -NamePattern "lab-*"
```

---

## Building from Source

### Prerequisites

**For GUI EXE Installer:**
- Inno Setup 6 (https://jrsoftware.org/isdl.php)
- Or install via WinGet: `winget install JRSoftware.InnoSetup`

**For PowerShell Installer:**
- PowerShell 5.1+

### Build Commands

```cmd
# Build GUI EXE installer (recommended)
installer\Build-InnoSetupInstaller.bat
```

**Full build documentation:** See [BUILD_GUIDE.md](BUILD_GUIDE.md)

---

## ?? Available Commands

### Invoke-VMBackup (aliases: hvbak, hv-bak)
Backs up Hyper-V VMs using checkpoints and 7-Zip compression.

**Parameters:**
- `NamePattern` - VM name wildcard pattern (required)
- `Destination` - Backup destination folder (default: `$env:USERPROFILE\hvbak-archives`)
- `TempFolder` - Temporary export folder (default: `$env:TEMP\hvbak`)
- `ForceTurnOff` - Force VM power off if checkpoint fails (default: $true)
- `KeepCount` - Number of backups to keep per VM (default: 2, range: 1-100)

**Examples:**
```powershell
hvbak -NamePattern "*"
hv-bak -NamePattern "srv-*" -Destination "D:\Backups"
hvbak -NamePattern "web-*" -KeepCount 5
```

### Restore-VMBackup (alias: hvrestore)
Restores a VM from an `hvbak` `.7z` archive by extracting to a staging folder and importing into Hyper-V.

**Parameters (common):**
- `BackupPath` - Path to a `.7z` archive
- `VmName`, `BackupRoot`, `Latest` - Restore most recent archive for a VM
- `ImportMode` - `Copy` (default), `Register`, or `Restore`
- `DestinationRoot` - Single "where should it go" root:
  - with `ImportMode=Register` (or if `ImportMode` omitted): extract under `DestinationRoot` and register **in-place**
  - with `ImportMode=Copy`/`Restore`: treated as `VmStorageRoot` (final Hyper-V storage root)
- `StagingRoot` - Extraction root used when staging is needed (e.g., Copy/Restore)
- `VmStorageRoot` - Destination root for VM files in `Copy`/`Restore` mode
- `VSwitchName` - Connect adapters to a switch after import
- `NoNetwork` - Disconnect adapters after import
- `Force` - Remove existing VM with the same name before import
- `StartAfterRestore` - Start the VM after restore

**Examples:**
```powershell
# In-place restore into a specific folder (extract + register from DestinationRoot)
hvrestore -VmName "MyVM" -BackupRoot "D:\hvbak-archives" -Latest -DestinationRoot "D:\RestoredVMs" -NoNetwork

# Restore a specific archive (recommended: Copy + GenerateNewId) to a specific Hyper-V storage root
hvrestore -BackupPath "D:\hvbak-archives\20260101\MyVM_20260101123456.7z" `
  -ImportMode Copy -DestinationRoot "D:\Hyper-V" -VSwitchName "vSwitch" -StartAfterRestore
```

### Restore-OrphanedVMs (alias: hvrecover)
Scans Hyper-V VM configuration folders (`Virtual Machines`) for VM configs present on disk but not registered, and re-registers them in-place.

**Parameters:**
- `WhatIf` - Preview changes without applying them
- `VmConfigRoot` - Path to root folder for VM configs (default: `C:\ProgramData\Microsoft\Windows\Hyper-V\Virtual Machines`)
- `LogFile` - Log file path (default: `$env:TEMP\RecoverOrphanedVMs.log`)

**Examples:**
```powershell
# Preview orphaned VM recovery actions
hvrecover -WhatIf

# Recover orphaned VMs found in default location
hvrecover

# Recover orphaned VMs from a custom folder
hvrecover -VmConfigRoot "D:\Hyper-V\Custom VMs"
```

### Repair-VhdAcl (alias: fix-vhd-acl)
Repairs file permissions on VHD/VHDX files for Hyper-V access.

**Parameters:**
- `WhatIf` - Preview changes without applying them
- `VhdFolder` - Path to folder with VHD/VHDX files
- `VhdListCsv` - CSV file with VHD paths
- `LogFile` - Log file path (default: `$env:TEMP\FixVhdAcl.log`)

**Examples:**
```powershell
fix-vhd-acl -WhatIf
fix-vhd-acl
Repair-VhdAcl -VhdFolder "D:\Restores"
```

---

## ?? Quick Reference

### Build Commands
```cmd
# Build GUI installer
Build-InnoSetupInstaller.bat

# Build PowerShell installer
Build-Release.bat package

# Clean outputs
Build-Release.bat clean
```

### Installation Commands
```powershell
# GUI installer (silent)
PSHVTools-Setup-1.0.6.exe /VERYSILENT /NORESTART

# PowerShell installer (silent)
.\Install.ps1 -Silent

# Uninstall
.\Install.ps1 -Uninstall
```

### Usage Commands
```powershell
# Import module
Import-Module pshvtools

# List available commands
Get-Command -Module pshvtools

# Backup VMs
hvbak -NamePattern "*"

# Restore from backup
hvrestore -VmName "MyVM" -Latest

# Recover orphaned VMs
hvrecover -WhatIf

# Fix VHD permissions
fix-vhd-acl -WhatIf

# Get detailed help
Get-Help Invoke-VMBackup -Full
Get-Help Repair-VhdAcl -Full
Get-Help Restore-VMBackup -Full
Get-Help Restore-OrphanedVMs -Full
```

---

## ?? Documentation Index

| Document | Description | Target Audience |
|----------|-------------|-----------------|
| [QUICKSTART.md](QUICKSTART.md) | Quick start guide | End Users |
| [BUILD_GUIDE.md](BUILD_GUIDE.md) | Building packages | Developers |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | Project overview | Everyone |
| [LICENSE.txt](LICENSE.txt) | MIT license | Everyone |

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

## ?? Support

- **GitHub Issues:** https://github.com/vitalie-vrabie/pshvtools/issues
- **GitHub Repository:** https://github.com/vitalie-vrabie/pshvtools
- **Discussions:** https://github.com/vitalie-vrabie/pshvtools/discussions

---

## ?? License

MIT License - See [LICENSE.txt](LICENSE.txt) for full details

Copyright (c) 2026 Vitalie Vrabie

---

## ?? Getting Started

### For End Users
1. Download `PSHVTools-Setup-1.0.6.exe`
2. Run the installer
3. Import the module: `Import-Module pshvtools`
4. Start backing up VMs: `hvbak -NamePattern "*"`

### For Developers
1. Clone the repository
2. Run `Build-InnoSetupInstaller.bat`
3. Find installer in `dist\` folder
4. Test and distribute!

---

## ?? Version History

### Version 1.0.6 (2026)
- See `CHANGELOG.md`.
