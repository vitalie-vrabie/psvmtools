# Quick Start Guide - PSVMTools

## Available Commands

After installation, you can use either of these commands:
- `vmbak` - Original command name
- `vm-bak` - Hyphenated alias

Both commands work identically!

## Usage

### Display Help and Syntax
Simply run the cmdlet without parameters:

```powershell
vmbak
# or
vm-bak
```

This will display the full help documentation including:
- Synopsis
- Description
- Parameters
- Examples
- Notes

### Quick Examples

```powershell
# Get detailed help
Get-Help Invoke-VMBackup -Full

# See only examples
Get-Help vmbak -Examples

# Backup all VMs (using either command)
vmbak -NamePattern "*"
vm-bak -NamePattern "*"

# Backup specific VMs
vmbak -NamePattern "MyVM"
vm-bak -NamePattern "srv-*"

# Specify custom destination
vmbak -NamePattern "*" -Destination "D:\backups"

# Disable force turn off
vm-bak -NamePattern "*" -ForceTurnOff:$false
```

## Testing the Installation

After installation, verify the module is available:

```powershell
# Check if module is loaded
Get-Module vmbak

# If not loaded, import it
Import-Module vmbak

# Verify the cmdlets are available
Get-Command vmbak
Get-Command vm-bak

# Display help
vmbak
```

## Common Usage Patterns

```powershell
# Backup all VMs to default location
vmbak -NamePattern "*"

# Backup VMs matching a pattern
vm-bak -NamePattern "web-*"

# Backup to specific destination
vmbak -NamePattern "db-*" -Destination "E:\backups"

# Backup without forcing VMs off on checkpoint failure
vm-bak -NamePattern "*" -ForceTurnOff:$false
```

## Uninstallation

To remove the module:

**Using Add/Remove Programs:**
1. Open Settings ? Apps
2. Find "PSVMTools"
3. Click Uninstall

**Using Start Menu:**
1. Open Start Menu
2. Find PSVMTools folder
3. Click "Uninstall PSVMTools"

**Using Command Line:**
```cmd
msiexec /x PSVMTools-Setup-1.0.0.msi
```

## Auto-load Module on Startup (Optional)

The module is automatically available after installation. If you want to ensure it's loaded:

```powershell
# Edit your PowerShell profile
notepad $PROFILE

# Add this line:
Import-Module vmbak

# Save and close the file
```

## Troubleshooting

### "vmbak" or "vm-bak" command not found

```powershell
# Verify installation
Get-Module vmbak -ListAvailable

# If found, import manually
Import-Module vmbak

# Verify both commands are available
Get-Command vmbak, vm-bak
```

### Module not loading automatically

```powershell
# Check your module path
$env:PSModulePath -split ';'

# Verify module files exist in:
# C:\Program Files\WindowsPowerShell\Modules\vmbak
```

### Need to refresh module after changes

```powershell
# Remove and re-import
Remove-Module vmbak -ErrorAction SilentlyContinue
Import-Module vmbak -Force
```

### Check module version and aliases

```powershell
# Get module information
Get-Module vmbak | Select-Object Name, Version, ExportedAliases

# List all exported aliases
(Get-Module vmbak).ExportedAliases
```

## Pro Tips

1. **Use tab completion:** Type `vmbak -` and press Tab to cycle through parameters
2. **Both commands work:** Choose whichever you prefer - `vmbak` or `vm-bak`
3. **Check help anytime:** Run `vmbak` without parameters to see full help
4. **Wildcards work:** Use patterns like `"web-*"`, `"*-prod"`, etc.
5. **Ctrl+C to cancel:** Gracefully stops backups and cleans up

## Need More Help?

- **Full Documentation:** See README_VMBAK_MODULE.md in installation folder
- **GitHub Issues:** https://github.com/vitalie-vrabie/psvmtools/issues
- **Repository:** https://github.com/vitalie-vrabie/psvmtools
