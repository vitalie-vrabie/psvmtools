# Quick Start Guide - PSHVTools

## Available Commands

After installation, you can use either of these commands:
- `hvbak` - Main command name
- `hv-bak` - Hyphenated alias

Both commands work identically!

## Usage

### Display Help and Syntax
Simply run the cmdlet without parameters:

```powershell
hvbak
# or
hv-bak
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
Get-Help hvbak -Examples

# Backup all VMs (using either command)
hvbak -NamePattern "*"
hv-bak -NamePattern "*"

# Backup specific VMs
hvbak -NamePattern "MyVM"
hv-bak -NamePattern "srv-*"

# Specify custom destination
hvbak -NamePattern "*" -Destination "D:\backups"

# Disable force turn off
hv-bak -NamePattern "*" -ForceTurnOff:$false
```

## Testing the Installation

After installation, verify the module is available:

```powershell
# Check if module is loaded
Get-Module hvbak

# If not loaded, import it
Import-Module hvbak

# Verify the cmdlets are available
Get-Command hvbak
Get-Command hv-bak

# Display help
hvbak
```

## Common Usage Patterns

```powershell
# Backup all VMs to default location
hvbak -NamePattern "*"

# Backup VMs matching a pattern
hv-bak -NamePattern "web-*"

# Backup to specific destination
hvbak -NamePattern "db-*" -Destination "E:\backups"

# Backup without forcing VMs off on checkpoint failure
hv-bak -NamePattern "*" -ForceTurnOff:$false
```

## Uninstallation

To remove the module:

**Using Add/Remove Programs:**
1. Open Settings ? Apps
2. Find "PSHVTools"
3. Click Uninstall

**Using Start Menu:**
1. Open Start Menu
2. Find PSHVTools folder
3. Click "Uninstall PSHVTools"

**Using Command Line:**
```cmd
msiexec /x PSHVTools-Setup-1.0.0.msi
```

## Auto-load Module on Startup (Optional)

The module is automatically available after installation. If you want to ensure it's loaded:

```powershell
# Edit your PowerShell profile
notepad $PROFILE

# Add this line:
Import-Module hvbak

# Save and close the file
```

## Troubleshooting

### "hvbak" or "hv-bak" command not found

```powershell
# Verify installation
Get-Module hvbak -ListAvailable

# If found, import manually
Import-Module hvbak

# Verify both commands are available
Get-Command hvbak, hv-bak
```

### Module not loading automatically

```powershell
# Check your module path
$env:PSModulePath -split ';'

# Verify module files exist in:
# C:\Program Files\WindowsPowerShell\Modules\hvbak
```

### Need to refresh module after changes

```powershell
# Remove and re-import
Remove-Module hvbak -ErrorAction SilentlyContinue
Import-Module hvbak -Force
```

### Check module version and aliases

```powershell
# Get module information
Get-Module hvbak | Select-Object Name, Version, ExportedAliases

# List all exported aliases
(Get-Module hvbak).ExportedAliases
```

## Pro Tips

1. **Use tab completion:** Type `hvbak -` and press Tab to cycle through parameters
2. **Both commands work:** Choose whichever you prefer - `hvbak` or `hv-bak`
3. **Check help anytime:** Run `hvbak` without parameters to see full help
4. **Wildcards work:** Use patterns like `"web-*"`, `"*-prod"`, etc.
5. **Ctrl+C to cancel:** Gracefully stops backups and cleans up

## Need More Help?

- **Full Documentation:** See README_HVBAK_MODULE.md in installation folder
- **GitHub Issues:** https://github.com/vitalie-vrabie/pshvtools/issues
- **Repository:** https://github.com/vitalie-vrabie/pshvtools
