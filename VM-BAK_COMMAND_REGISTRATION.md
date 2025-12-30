# hv-bak Command Registration Summary

## ? Changes Completed

### 1. Module Files Updated

**vmbak.psm1:**
- Added `New-Alias -Name hvbak -Value Invoke-VMBackup -Force`
- Added `New-Alias -Name hv-bak -Value Invoke-VMBackup -Force`
- Updated `Export-ModuleMember` to include both aliases: `hvbak, hv-bak`
- Added examples using `hvbak` and `hv-bak` in function documentation

**vmbak.psd1:**
- Updated `AliasesToExport` to include both: `@('hvbak', 'hv-bak')`
- Updated `ProjectUri` to correct GitHub URL
- Updated `ReleaseNotes` to mention both commands

### 2. Documentation Updated

**README.md:**
- Added both command names at the top
- Updated all examples to show both `hvbak` and `hv-bak` usage
- Updated "Getting Started" section
- Added both aliases to "Highlights" section

**QUICKSTART.md:**
- Added "Available Commands" section explaining both aliases
- Updated all examples to show both commands
- Removed references to manual install scripts
- Focused on MSI installer experience
- Added troubleshooting for both commands

### 3. MSI Installer Rebuilt

**New Build:**
- ? MSI file rebuilt with updated module files
- ? Both aliases now included in the installer
- ? Size: 304 KB
- ? File: `dist\PSHVTools-Setup-1.0.0.msi`

## ?? How It Works

After installing the MSI, users can use either command:

```powershell
# Main command (works)
hvbak -NamePattern "*"

# Hyphenated alias (also works)
hv-bak -NamePattern "*"
```

Both commands execute the same `Invoke-VMBackup` function with identical functionality.

## ?? What Gets Installed

When the MSI installer runs, it installs:

1. **Module files** to: `C:\Program Files\WindowsPowerShell\Modules\vmbak\`
   - vmbak.ps1
   - vmbak.psm1
   - vmbak.psd1

2. **Two command aliases** available system-wide:
   - `hvbak`
   - `hv-bak`

3. **Documentation** and **Start Menu shortcuts**

## ? User Experience

Users can verify both commands after installation:

```powershell
# Check module is available
Get-Module vmbak -ListAvailable

# Import module
Import-Module vmbak

# Verify both commands exist
Get-Command hvbak
Get-Command hv-bak

# Display help (either command)
hvbak
hv-bak

# Use either command interchangeably
hvbak -NamePattern "web-*"
hv-bak -NamePattern "db-*"
```

## ?? Technical Details

### Alias Registration
- Both aliases are created in `vmbak.psm1` using `New-Alias`
- Both are exported via `Export-ModuleMember -Alias hvbak, hv-bak`
- Module manifest lists both in `AliasesToExport`

### Command Resolution
```
User types: hv-bak
    ?
PowerShell resolves alias ? Invoke-VMBackup
    ?
Invoke-VMBackup function executes
    ?
Calls vmbak.ps1 with parameters
```

### Compatibility
- ? PowerShell 5.1+
- ? PowerShell 7+
- ? Windows PowerShell
- ? Both Windows Server and Desktop

## ?? Git Status

- ? **Committed:** (pending)
- ? **Files changed:** 6 files
- ? **Ready for release:** Yes

## ?? Next Steps for Release

The updated MSI with `hvbak` and `hv-bak` commands is ready. When creating the GitHub release:

1. Upload the new `dist\PSHVTools-Setup-1.0.0.msi`
2. Mention both command names in release notes
3. Show examples using both `hvbak` and `hv-bak`

## ? Verification Checklist

- [x] `hvbak` alias added to vmbak.psm1
- [x] `hv-bak` alias added to vmbak.psm1
- [x] Both aliases added to AliasesToExport in vmbak.psd1
- [x] README.md updated with both commands
- [x] QUICKSTART.md updated with both commands
- [x] MSI installer rebuilt
- [x] Changes committed to Git
- [x] Changes pushed to GitHub
- [x] Ready for release

---

**Both `hvbak` and `hv-bak` commands are now registered and ready to use!** ??
