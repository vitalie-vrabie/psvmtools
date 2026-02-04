# Quick Start Guide - PSHVTools

## Installation

### GUI Installer (Recommended)
1. Download `PSHVTools-Setup.exe` from [GitHub Releases](https://github.com/vitalie-vrabie/pshvtools/releases)
2. Run as Administrator
3. Follow the installation wizard
4. The module will be available system-wide

**Silent Installation:**
```powershell
PSHVTools-Setup.exe /VERYSILENT /NORESTART
```

Note: The CI installer workflow requires a manual dispatch to mark a build as `stable` if desired. See the repository Actions page to run the workflow with `markStable=true`.

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

## Advanced Usage Examples

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

### VM Cloning
```powershell
# Clone a VM with a new name
hvclone -SourceVM "TemplateVM" -NewVMName "NewVM" -Path "D:\VMs"
```

### Configuration Management
```powershell
# Set comprehensive defaults
Set-PSHVToolsConfig -DefaultBackupPath "E:\Backups" -DefaultKeepCount 5 -DefaultCompressionLevel 5 -MaxParallelBackups 3

# Reset to defaults
Reset-PSHVToolsConfig

# View all settings
Show-PSHVToolsConfig
```

### Scheduled Backups
Create a scheduled task to run backups automatically:

```powershell
# Example: Daily backup at 2 AM
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command hvbak -NamePattern '*'"
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -TaskName "VMBackup" -Action $action -Trigger $trigger -RunLevel Highest
```

### Batch Operations
```powershell
# Backup multiple VM patterns
hvbak -NamePattern "Prod*", "Test*"

# Compact specific VHDs
hvcompact -Path "D:\VMs\*.vhdx" -WhatIf

# Fix ACLs on multiple paths
hvfixacl -Path "D:\VMs\*.vhd*", "E:\VMs\*.vhd*"
```

### Monitoring and Logging
```powershell
# View backup progress (in another PowerShell window)
Get-Job | Where-Object {$_.Name -like "*VMBackup*"} | Format-Table

# Check logs
Get-Content "$env:TEMP\PSHVTools\*.log" -Tail 20
```

## Troubleshooting Examples

### Common Issues
```powershell
# If backups fail due to permissions
hvfixacl -Path "D:\VMs\*.vhdx"

# If Hyper-V module not found
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell

# If 7-Zip not detected
choco install 7zip  # Install via Chocolatey
# Or add to PATH: $env:Path += ";C:\Program Files\7-Zip"
```

### Diagnostic Commands
```powershell
# Full environment check
hvhealth -Verbose

# Test backup with dry run
hvbak -NamePattern "TestVM" -WhatIf

# Check VM status
Get-VM | Where-Object {$_.Name -like "*"} | Select-Object Name, State, Status
```

