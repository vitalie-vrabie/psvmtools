# PSHVTools - PowerShell Hyper-V Tools

**Version:** 1.1.1  
**Product Name:** PSHVTools (PowerShell Hyper-V Tools)  
**Module Name:** pshvtools  
**License:** MIT

---

## What is PSHVTools?

PSHVTools is a comprehensive PowerShell module for backing up and managing Hyper-V virtual machines. It provides professional-grade cmdlets for automated VM operations with enterprise features like parallel processing, checkpoint support, compression, and recovery tools.

### Key Features
- **Live VM Backups**: Production checkpoint-based backups with zero downtime
- **Parallel Processing**: Concurrent backup of multiple VMs for efficiency
- **Advanced Compression**: 7-Zip integration with multithreading and low-priority processing
- **Flexible Retention**: Configurable backup policies (1-100 copies per VM)
- **Progress Tracking**: Real-time status with graceful cancellation support
- **VHD Management**: Permission repair, compaction, and optimization utilities
- **Recovery Tools**: Restore from backups and recover orphaned VMs
- **Configuration Management**: Persistent settings and environment health checks
- **Professional Installer**: GUI setup with system requirements validation

### Commands Available
- `Invoke-VMBackup` / `hvbak` - Backup VMs with checkpoints and compression
- `Invoke-VHDCompact` / `hvcompact` - Compact VHD/VHDX files
- `Repair-VhdAcl` / `hvfixacl` - Fix VHD permissions
- `Restore-VMBackup` / `hvrestore` - Restore from backup archives
- `Restore-OrphanedVMs` / `hvrecover` - Recover unregistered VMs
- `Clone-VM` / `hvclone` - Clone existing VMs
- `Set-PSHVToolsConfig` - Configure default settings
- `Get-PSHVToolsConfig` - View current configuration
- `hvhealth` - Check environment health

---

## Installation

### GUI Installer (Recommended)

1. Download `PSHVTools-Setup.exe` from [GitHub Releases](https://github.com/vitalie-vrabie/pshvtools/releases)
2. Run as Administrator
3. Follow the installation wizard
4. The module will be available system-wide

**Silent Installation:**
```cmd
PSHVTools-Setup.exe /VERYSILENT /NORESTART
```

### System Requirements

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or later
- Hyper-V role enabled (recommended)
- 7-Zip installed (will be detected automatically)

### Post-Installation

After installation, the module is automatically imported. You can verify with:

```powershell
Get-Module pshvtools
Get-Command -Module pshvtools
```

---

## Quick Start

### 1. Check Environment
```powershell
hvhealth
```

### 2. Configure Defaults (Optional)
```powershell
Set-PSHVToolsConfig -DefaultBackupPath "D:\Backups" -DefaultKeepCount 5
```

### 3. Backup All VMs
```powershell
hvbak -NamePattern "*"
```

### 4. Compact VHD Files
```powershell
hvcompact -NamePattern "*" -WhatIf  # Preview first
hvcompact -NamePattern "*"          # Execute
```

### 5. View Configuration
```powershell
Show-PSHVToolsConfig
```

## Sample Commands

### Backup Operations
```powershell
# Backup all VMs with defaults
hvbak

# Backup specific VMs
hvbak -NamePattern "Web*", "DB*"

# Custom backup location and settings
hvbak -NamePattern "*" -DestinationPath "E:\VMBackups" -Keep 10 -CompressionLevel 7
```

### Maintenance Tasks
```powershell
# Compact all VHD files
hvcompact -NamePattern "*"

# Fix permissions on VHD files
hvfixacl -Path "D:\VMs\*.vhdx"

# Clone a VM
hvclone -SourceVM "Template" -NewVMName "NewVM"
```

### Recovery Operations
```powershell
# Restore from backup
hvrestore -BackupPath "D:\Backups\VM.7z"

# Recover orphaned VMs
hvrecover
```

### Configuration
```powershell
# Set backup defaults
Set-PSHVToolsConfig -DefaultBackupPath "F:\Backups" -DefaultKeepCount 7

# View current settings
Get-PSHVToolsConfig
```

---

## Documentation

- **[Quick Start Guide](QUICKSTART.md)** - Step-by-step usage examples
- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues and solutions
- **[Contributing](CONTRIBUTING.md)** - Development guidelines
- **[Changelog](CHANGELOG.md)** - Version history and changes

---

## Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/vitalie-vrabie/pshvtools/issues)
- **Documentation**: Comprehensive guides included with installation
- **Community**: Open source project - contributions welcome!

---

*PSHVTools is developed and maintained by Vitalie Vrabie. Licensed under MIT License.*
