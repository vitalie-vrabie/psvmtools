# Quick Start Guide - PSHVTools

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

## Available Commands

After installation, the **pshvtools** module provides:

### Core Commands
- `Invoke-VMBackup` / `hvbak` - Backup VMs with checkpoints and compression
- `Invoke-VHDCompact` / `hvcompact` - Compact VHD/VHDX files to reclaim space
- `Repair-VhdAcl` / `hvfixacl` - Fix VHD/VHDX permission issues
- `Restore-VMBackup` / `hvrestore` - Restore VMs from backup archives
- `Restore-OrphanedVMs` / `hvrecover` - Recover unregistered VMs from disk
- `Clone-VM` / `hvclone` - Clone existing VMs with new IDs

### Configuration & Health
- `Set-PSHVToolsConfig` - Configure default settings
- `Get-PSHVToolsConfig` - View current configuration
- `Reset-PSHVToolsConfig` - Reset to defaults
- `hvhealth` - Check environment health and requirements

### Legacy Commands
- `Remove-GpuPartitions` / `hvnogpup` - Remove GPU partition adapters

## Quick Start

### 1. Import the Module (Usually automatic)
```powershell
Import-Module pshvtools
```

### 2. Check Environment Health
```powershell
hvhealth
```
This verifies PowerShell, Hyper-V, and 7-Zip are properly configured.

### 3. Configure Defaults (Optional)
```powershell
# Set default backup location and retention
Set-PSHVToolsConfig -DefaultBackupPath "D:\VMBackups" -DefaultKeepCount 7

# View current settings
Get-PSHVToolsConfig
```

### 4. Backup Your VMs
```powershell
# Backup all VMs
hvbak -NamePattern "*"

# Backup specific VMs
hvbak -NamePattern "WebServer*"

# Backup with custom settings
hvbak -NamePattern "*" -DestinationPath "E:\Backups" -Keep 10 -CompressionLevel 5
```

### 5. Maintain Your VHDs
```powershell
# Compact VHD files to reclaim space (preview first)
hvcompact -NamePattern "*" -WhatIf

# Execute compaction
hvcompact -NamePattern "*"

# Fix permission issues
hvfixacl -Path "D:\VMs\*.vhdx"
```

### 6. Restore When Needed
```powershell
# Restore from backup
hvrestore -BackupPath "D:\Backups\WebServer.7z" -DestinationPath "D:\VMs"

# Recover orphaned VMs
hvrecover
```

## Advanced Usage

### Parallel Backups
```powershell
# Backup multiple VMs concurrently (default)
hvbak -NamePattern "*" -MaxParallel 4
```

### Custom Compression
```powershell
# High compression for archival
hvbak -NamePattern "*" -CompressionLevel 9

# Fast compression for frequent backups
hvbak -NamePattern "*" -CompressionLevel 1
```

### Scheduled Backups
Create a scheduled task to run backups automatically:

```powershell
# Example: Daily backup at 2 AM
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command hvbak -NamePattern '*'"
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -TaskName "VMBackup" -Action $action -Trigger $trigger -RunLevel Highest
```

## Troubleshooting

If you encounter issues:
1. Run `hvhealth` to check your environment
2. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common solutions
3. Review the logs in `%TEMP%\PSHVTools\`
4. Open an issue on [GitHub](https://github.com/vitalie-vrabie/pshvtools/issues)

## Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Check [CHANGELOG.md](CHANGELOG.md) for version history
- See [CONTRIBUTING.md](CONTRIBUTING.md) if you'd like to contribute
