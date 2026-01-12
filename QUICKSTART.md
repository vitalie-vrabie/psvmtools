# Quick Start Guide - PSHVTools

## Installation

### GUI Installer (Recommended)
1. Download `PSHVTools-Setup.exe`
2. Double-click to run
3. Follow the wizard
4. Done!

## Available Commands

After installation, the **pshvtools** module provides:

### Backup Commands
- `Invoke-VMBackup` - Full cmdlet name
- `hvbak` - Short alias
- `hv-bak` - Hyphenated alias

### VHD Repair Commands
- `Repair-VhdAcl` - Full cmdlet name
- `fix-vhd-acl` - Short alias

### Restore Commands
- `Restore-VMBackup` - Full cmdlet name
- `hvrestore` - Short alias

### Recovery Commands
- `Restore-OrphanedVMs` - Full cmdlet name
- `hvrecover` - Short alias

All commands work identically!

## Quick Start

### Importing the Module

```powershell
# Import the module (usually auto-loaded)
Import-Module pshvtools

# Verify it's loaded
Get-Module pshvtools

# List all commands
Get-Command -Module pshvtools
```

### Display Help

```powershell
# Display help for backup command
hvbak
Get-Help Invoke-VMBackup -Full
Get-Help hvbak -Examples

# Display help for VHD repair
fix-vhd-acl
Get-Help Repair-VhdAcl -Full
Get-Help fix-vhd-acl -Examples

# Display help for restore (from .7z backups)
hvrestore
Get-Help Restore-VMBackup -Full
Get-Help hvrestore -Examples

# Display help for orphaned VM recovery (re-register)
hvrecover
Get-Help Restore-OrphanedVMs -Full
Get-Help hvrecover -Examples
```

## Backing Up VMs

### Basic Usage

```powershell
# Backup all VMs
hvbak -NamePattern "*"

# Backup specific VMs
hvbak -NamePattern "MyVM"
hv-bak -NamePattern "srv-*"
hvbak -NamePattern "web-?"

# Specify custom destination
hvbak -NamePattern "*" -Destination "D:\backups"

# Use custom temp folder
hvbak -NamePattern "*" -TempFolder "E:\temp"
```

### Advanced Options

```powershell
# Keep 5 most recent backups per VM (default is 2)
hvbak -NamePattern "*" -KeepCount 5

# Disable force turn off on checkpoint failure
hv-bak -NamePattern "*" -ForceTurnOff:$false

# Full control
hvbak -NamePattern "prod-*" `
      -Destination "D:\Backups" `
      -TempFolder "E:\Temp" `
      -KeepCount 3 `
      -ForceTurnOff:$false
```

### Backup Behavior

**What gets backed up:**
- VM configuration
- VM checkpoints/snapshots
- **VHD/VHDX files**

**How backups work:**
1. Creates checkpoint (Production or Standard)
2. Exports VM (configuration + checkpoints + VHDs)
3. Compresses to 7z archive
4. Removes checkpoint
5. Restarts VM if it was running
6. Cleans up old backups based on KeepCount

**Archive naming:**
- Format: `VMName_yyyyMMddHHmmss.7z`
- Stored in: `Destination\yyyyMMdd\VMName_timestamp.7z`
- Example: `D:\backups\20251230\MyVM_20251230075500.7z`

## Fixing VHD Permissions

### Basic Usage

```powershell
# Preview what would be fixed
fix-vhd-acl -WhatIf

# Fix all VMs on the host
fix-vhd-acl

# Fix VHDs in a specific folder
fix-vhd-acl -VhdFolder "D:\Restores"

# Fix VHDs from a CSV list
fix-vhd-acl -VhdListCsv "C:\temp\vhds.csv"

# Specify custom log file
Repair-VhdAcl -LogFile "C:\Logs\vhd-fix.log"
```

### CSV Format for VhdListCsv

Create a CSV file with these columns:
```csv
Path,VMId
"D:\VMs\MyVM\disk.vhdx","12345678-1234-1234-1234-123456789abc"
"D:\VMs\OtherVM\disk.vhdx",
```

- `Path` - Required: Full path to VHD/VHDX file
- `VMId` - Optional: VM GUID without braces

### What It Does

The `fix-vhd-acl` command:
1. Takes ownership of VHD/VHDX files
2. Grants permissions to:
   - **SYSTEM** - Full Control
   - **Administrators** - Full Control
   - **NT VIRTUAL MACHINE\{VM-GUID}** - Full Control (if VM specified)
3. Logs all actions to file

**Use cases:**
- After restoring VHDs from backup
- After copying VHDs between hosts
- When VMs can't start due to permission errors
- After moving VHDs to different folders

## Restoring VMs

### Basic Usage

```powershell
# Restore from a specific archive (copy into Hyper-V storage)
hvrestore -BackupPath "D:\backups\20260101\MyVM_20260101123456.7z" -ImportMode Copy -DestinationRoot "D:\Hyper-V"

# Restore latest backup for a VM
hvrestore -VmName "MyVM" -BackupRoot "D:\backups" -Latest

# In-place restore (extract + register from DestinationRoot)
hvrestore -VmName "MyVM" -BackupRoot "D:\backups" -Latest -DestinationRoot "D:\RestoredVMs" -NoNetwork
```

### Common Options

```powershell
# Restore and connect networking
hvrestore -VmName "MyVM" -BackupRoot "D:\backups" -Latest -VSwitchName "vSwitch" -StartAfterRestore

# Restore for investigation / avoid network collisions
hvrestore -VmName "MyVM" -BackupRoot "D:\backups" -Latest -NoNetwork

# Replace an existing VM with the same name
hvrestore -VmName "MyVM" -BackupRoot "D:\backups" -Latest -Force
```

**ImportMode notes:**
- `Copy` (default): safest for test restores; uses new VM ID and copies files to `VmStorageRoot` (or `DestinationRoot` when provided).
- `Register`: registers the extracted VM in-place (no copy). If `DestinationRoot` is provided (and `ImportMode` is omitted), it defaults to in-place registration.
- `Restore`: attempts an in-place restore keeping the original VM ID (may conflict if VM already exists).

**DestinationRoot notes:**
- With `ImportMode=Register` (or omitted ImportMode): extract under `DestinationRoot` and register the VM in-place.
- With `ImportMode=Copy`/`Restore`: `DestinationRoot` is treated as the final Hyper-V storage root (same as `VmStorageRoot`).


## Recovering Orphaned VMs (re-register)

Use this when VM files exist on disk, but the VM is missing from Hyper-V Manager / `Get-VM`.

```powershell
# Preview what would be registered (default scans ProgramData\...\Hyper-V\Virtual Machines)
hvrecover -WhatIf

# Scan a custom storage root (auto-detects the 'Virtual Machines' folder if present)
hvrecover -VmConfigRoot "D:\Hyper-V"

# Include legacy XML configs if you have very old VMs
hvrecover -VmConfigRoot "D:\Hyper-V" -IncludeXml
```

## Testing the Installation

```powershell
# Check if module is loaded
Get-Module pshvtools

# If not loaded, import it
Import-Module pshvtools

# Verify all commands are available
Get-Command -Module pshvtools

# Check aliases
Get-Alias hvbak, hv-bak, fix-vhd-acl, hvrestore, hvrecover

# Display help for each command
hvbak
fix-vhd-acl
hvrestore
hvrecover
```

## Understanding Progress

When running backups, you'll see:
- **Root progress bar:** Overall batch progress
- **Child progress bars:** Individual VM progress
- **Console output:** Timestamped log messages
- **Real-time updates:** Progress updates every 750ms

**Progress phases:**
1. **Starting** (0%)
2. **Checkpoint** (10%)
3. **Exporting** (40%)
4. **Export-VM** (55%)
5. **Archiving (7z)** (60%)
6. **Complete** (100%)

## Configuration

### Default Settings

| Setting | Default Value | Description |
|---------|---------------|-------------|
| Destination | `%USERPROFILE%\hvbak-archives` | Backup root folder |
| TempFolder | `%TEMP%\hvbak` | Temporary export folder |
| ForceTurnOff | `$true` | Force VM off if checkpoint fails |
| KeepCount | `2` | Number of backups to keep per VM |

### Backup Retention

The `KeepCount` parameter controls how many backups to keep:
```powershell
# Keep only the most recent backup
hvbak -NamePattern "*" -KeepCount 1

# Keep 10 backups (max: 100)
hvbak -NamePattern "*" -KeepCount 10
```

**How cleanup works:**
- Scans all date folders for each VM's archives
- Sorts by timestamp (from filename)
- Keeps the N most recent archives
- Deletes older archives
- Removes empty date folders

## Common Usage Patterns

### Daily Backup Script

```powershell
# Create a scheduled task script
Import-Module pshvtools

# Backup all VMs, keep 7 days
hvbak -NamePattern "*" -Destination "D:\Backups" -KeepCount 7

# Or backup specific groups
hvbak -NamePattern "prod-*" -Destination "D:\Backups\Prod" -KeepCount 14
hvbak -NamePattern "dev-*" -Destination "D:\Backups\Dev" -KeepCount 3
```

### After Restoring VMs

```powershell
# Import module
Import-Module pshvtools

# Fix permissions for all restored VMs
fix-vhd-acl

# Or just for a specific folder
fix-vhd-acl -VhdFolder "D:\Restored\VMs"

# Check the log for any issues
Get-Content "$env:TEMP\FixVhdAcl.log" -Tail 50
```

### Maintenance Script

```powershell
# Weekly maintenance
Import-Module pshvtools

# Backup all VMs
hvbak -NamePattern "*" -KeepCount 4

# Fix any permission issues
fix-vhd-acl

# Report
Write-Host "Maintenance complete!" -ForegroundColor Green
```

## Uninstallation

### GUI Installer Method
1. Open **Settings** ? **Apps**
2. Find **PSHVTools**
3. Click **Uninstall**

Or use **Start Menu** ? **PSHVTools** ? **Uninstall PSHVTools**

### PowerShell Installer Method

```powershell
# From installer directory
.\Install.ps1 -Uninstall

# Or manually
Remove-Module pshvtools -ErrorAction SilentlyContinue
Remove-Item "C:\Program Files\WindowsPowerShell\Modules\pshvtools" -Recurse -Force
```

## Troubleshooting

### Commands Not Found

```powershell
# Check if module is available
Get-Module pshvtools -ListAvailable

# If found but not loaded, import it
Import-Module pshvtools

# Verify commands
Get-Command hvbak, fix-vhd-acl
```

### Module Not Loading Automatically

```powershell
# Check PowerShell module path
$env:PSModulePath -split ';'

# Module should be in one of these locations:
# C:\Program Files\WindowsPowerShell\Modules\pshvtools

# Verify files exist
Test-Path "C:\Program Files\WindowsPowerShell\Modules\pshvtools\pshvtools.psd1"
Test-Path "C:\Program Files\WindowsPowerShell\Modules\pshvtools\pshvtools.psm1"
Test-Path "C:\Program Files\WindowsPowerShell\Modules\pshvtools\hvbak.ps1"
Test-Path "C:\Program Files\WindowsPowerShell\Modules\pshvtools\fix-vhd-acl.ps1"
```

### Backup Job Failed

Check the error diagnostics in the console output:
```
Per-vm Job Id 1 FAILED with error: <detailed error message>
```

Common issues:
- **Checkpoint failed:** VM may not support Production checkpoints
- **Export failed:** Insufficient permissions or disk space
- **7z not found:** Install 7-Zip and ensure it's in PATH
- **Permission denied:** Run PowerShell as Administrator

### VHD Permission Fix Not Working

```powershell
# Must run as Administrator
# Check current privileges
whoami /groups | findstr /i "S-1-16-12288"  # Should show High Mandatory Level

# Check the log for details
Get-Content "$env:TEMP\FixVhdAcl.log"

# Try with -WhatIf first
fix-vhd-acl -WhatIf
```

## Pro Tips

1. **Tab completion:** Type `hvbak -` and press Tab to cycle through parameters
2. **Use aliases:** Choose whichever you prefer - `hvbak`, `hv-bak`, or `Invoke-VMBackup`
3. **Check help anytime:** Run `hvbak` or `fix-vhd-acl` without parameters
4. **Wildcards work:** Use patterns like `"web-*"`, `"*-prod"`, `"server-?"`
5. **Ctrl+C to cancel:** Gracefully stops backups and cleans up resources
6. **Monitor progress:** Watch real-time progress bars for each VM
7. **Check logs:** VHD fix operations log to `$env:TEMP\FixVhdAcl.log`
8. **Use -WhatIf:** Preview VHD permission fixes before applying
9. **Adjust retention:** Change `KeepCount` based on storage capacity
10. **Schedule it:** Create scheduled tasks for automated backups

## Additional Resources

- **Full Documentation:** See README.md in the repository
- **Build Guide:** See BUILD_GUIDE.md for developers
- **Project Summary:** See PROJECT_SUMMARY.md for overview
- **GitHub Repository:** https://github.com/vitalie-vrabie/pshvtools
- **Issues & Support:** https://github.com/vitalie-vrabie/pshvtools/issues

## Learning More

```powershell
# Explore all parameters
Get-Help Invoke-VMBackup -Parameter *
Get-Help Repair-VhdAcl -Parameter *
Get-Help Restore-VMBackup -Parameter *
Get-Help Restore-OrphanedVMs -Parameter *

# See examples
Get-Help hvbak -Examples
Get-Help fix-vhd-acl -Examples
Get-Help hvrestore -Examples
Get-Help hvrecover -Examples

# View online help (if available)
Get-Help Invoke-VMBackup -Online
```

---

**Happy backing up!** ??

For questions or issues, visit: https://github.com/vitalie-vrabie/pshvtools

## Utility Scripts

### Remove GPU partition adapters

File: `scripts/remove-gpu-partitions.ps1`

```powershell
# Remove GPU partition adapters from matching VMs
.\scripts\remove-gpu-partitions.ps1 -NamePattern "lab-*"

# Or, after importing the module, use the short alias
Import-Module pshvtools
nogpup -NamePattern "lab-*"

# Preview
.\scripts\remove-gpu-partitions.ps1 -NamePattern "*" -WhatIf
