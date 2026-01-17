# PSHVTools Troubleshooting Guide

Common issues and their solutions.

---

## ?? Installation Issues

### Issue: "Execution policy does not allow script execution"

**Solution:**
```powershell
# Temporarily bypass execution policy
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Or run with bypass flag
powershell -ExecutionPolicy Bypass -File Install.ps1
```

### Issue: "Hyper-V module not found"

**Error:** `Module 'Hyper-V' not found`

**Solution:**
```powershell
# Enable Hyper-V feature (requires reboot)
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Verify installation
Get-WindowsOptionalFeature -Online -FeatureName *Hyper-V*
```

### Issue: Installer fails silently

**Solution:**
```cmd
# Run installer with log
PSHVTools-Setup.exe /LOG="install.log"

# Check log file
notepad install.log
```

---

## ?? Backup Issues

### Issue: "No VMs match the pattern"

**Error:** `No VMs found matching pattern: '*'`

**Solution:**
```powershell
# Verify VMs are visible
Get-VM

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-Host "Running as Admin: $isAdmin"

# If not admin, restart PowerShell as Administrator
```

### Issue: Backup fails with checkpoint error

**Error:** `Failed to create checkpoint for VM 'MyVM'`

**Solutions:**

1. **Check VM state:**
   ```powershell
   Get-VM -Name "MyVM" | Select-Object Name, State, Status
   ```

2. **Verify Integration Services:**
   ```powershell
   Get-VM -Name "MyVM" | Get-VMIntegrationService
   ```

3. **Try manual checkpoint:**
   ```powershell
   Checkpoint-VM -Name "MyVM" -SnapshotName "Test"
   Remove-VMSnapshot -Name "Test"
   ```

4. **Check disk space:**
   ```powershell
   Get-PSDrive C | Select-Object Used, Free
   ```

### Issue: 7-Zip compression fails

**Error:** `7z.exe not found` or `Compression failed`

**Solutions:**

1. **Install 7-Zip:**
   ```powershell
   # Using Chocolatey
   choco install 7zip -y
   
   # Or download from
   # https://www.7-zip.org/download.html
   ```

2. **Verify installation:**
   ```powershell
   $7zPath = "${env:ProgramFiles}\7-Zip\7z.exe"
   Test-Path $7zPath
   ```

3. **Check disk space for temp files:**
   ```powershell
   Get-PSDrive | Where-Object { $_.Used -ne $null }
   ```

### Issue: Backup runs out of disk space

**Error:** `Not enough space on disk`

**Solutions:**

1. **Check available space:**
   ```powershell
   Get-PSDrive | Select-Object Name, @{N='Free(GB)';E={[math]::Round($_.Free/1GB,2)}}
   ```

2. **Use different temp location:**
   ```powershell
   hvbak -NamePattern "*" -TempFolder "E:\Temp"
   ```

3. **Reduce KeepCount:**
   ```powershell
   hvbak -NamePattern "*" -KeepCount 1
   ```

4. **Clean up old backups:**
   ```powershell
   # List backup folders
   Get-ChildItem "$HOME\hvbak-archives" -Directory
   
   # Remove old backups
   Get-ChildItem "$HOME\hvbak-archives" | 
       Sort-Object LastWriteTime | 
       Select-Object -First 5 | 
       Remove-Item -Recurse -Force
   ```

### Issue: Backup hangs or freezes

**Solutions:**

1. **Cancel gracefully with Ctrl+C**
   - Script will clean up checkpoints and temp files

2. **Check background jobs:**
   ```powershell
   Get-Job | Format-Table -AutoSize
   
   # Stop all jobs
   Get-Job | Stop-Job
   Get-Job | Remove-Job
   ```

3. **Kill 7z processes:**
   ```powershell
   Get-Process 7z -ErrorAction SilentlyContinue | Stop-Process -Force
   ```

4. **Clean up temp folder:**
   ```powershell
   Remove-Item "$env:TEMP\hvbak" -Recurse -Force -ErrorAction SilentlyContinue
   ```

---

## ?? Restore Issues

### Issue: "Backup archive not found"

**Error:** `No backup archives found for VM 'MyVM'`

**Solutions:**

1. **Verify backup location:**
   ```powershell
   Get-ChildItem "$HOME\hvbak-archives" -Recurse -Filter "*.7z"
   ```

2. **Specify custom backup path:**
   ```powershell
   hvrestore -VmName "MyVM" -Latest -BackupPath "D:\Backups"
   ```

3. **List available backups:**
   ```powershell
   Get-ChildItem "$HOME\hvbak-archives" -Recurse -Filter "MyVM*.7z"
   ```

### Issue: Restore fails with "Invalid archive"

**Error:** `Failed to extract archive` or `Archive is corrupted`

**Solutions:**

1. **Verify archive integrity:**
   ```powershell
   & "${env:ProgramFiles}\7-Zip\7z.exe" t "path\to\backup.7z"
   ```

2. **Check file hash (if available):**
   ```powershell
   Get-FileHash "backup.7z" -Algorithm SHA256
   ```

3. **Try extracting manually:**
   ```powershell
   & "${env:ProgramFiles}\7-Zip\7z.exe" x "backup.7z" -o"C:\Temp\extract"
   ```

### Issue: Network switch not found during restore

**Error:** `Virtual switch 'External' not found`

**Solutions:**

1. **List available switches:**
   ```powershell
   Get-VMSwitch | Select-Object Name, SwitchType
   ```

2. **Restore without network:**
   ```powershell
   hvrestore -VmName "MyVM" -Latest -NoNetwork
   ```

3. **Map to different switch:**
   ```powershell
   # This feature may need manual reconfiguration after import
   Get-VM "MyVM" | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName "NewSwitch"
   ```

---

## ?? Permission Issues

### Issue: "Access denied" errors on VHD files

**Error:** `Access to VHD denied` or `Permission denied`

**Solution:**
```powershell
# Run VHD ACL repair utility
fix-vhd-acl

# Or specify VM pattern
fix-vhd-acl -NamePattern "MyVM*"

# Manual repair
$vhd = "C:\VMs\MyVM\disk.vhdx"
icacls $vhd /grant "NT VIRTUAL MACHINE\Virtual Machines:(F)"
```

### Issue: "Access denied" during export

**Solutions:**

1. **Run as Administrator**
2. **Check Hyper-V service account permissions:**
   ```powershell
   # Grant Virtual Machines group access to destination
   $dest = "D:\Backups"
   icacls $dest /grant "NT VIRTUAL MACHINE\Virtual Machines:(OI)(CI)F" /T
   ```

---

## ?? Diagnostic Commands

### Environment Health Check

```powershell
# Run full environment check
Test-PSHVToolsEnvironment -Detailed

# Quick check
hvhealth
```

### Check Module Status

```powershell
# Verify module is loaded
Get-Module pshvtools

# Check module version
(Get-Module pshvtools).Version

# List all commands
Get-Command -Module pshvtools

# Check command help
Get-Help hvbak -Detailed
```

### Check Hyper-V Status

```powershell
# Check Hyper-V service
Get-Service vmms

# Check VM Management Service
Get-Service vmcompute

# List VMs and their state
Get-VM | Format-Table Name, State, Status, Uptime -AutoSize

# Check checkpoints
Get-VM | Get-VMSnapshot | Format-Table VMName, Name, CreationTime
```

### Check Disk Space

```powershell
# All drives
Get-PSDrive | Where-Object { $_.Used -ne $null } | 
    Select-Object Name, 
                  @{N='Used(GB)';E={[math]::Round($_.Used/1GB,2)}},
                  @{N='Free(GB)';E={[math]::Round($_.Free/1GB,2)}}

# Backup location
$backupPath = "$HOME\hvbak-archives"
$size = (Get-ChildItem $backupPath -Recurse | Measure-Object -Property Length -Sum).Sum
Write-Host "Backups using: $([math]::Round($size/1GB,2)) GB"
```

### Clean Up Resources

```powershell
# Remove orphaned checkpoints
Get-VM | Get-VMSnapshot | Where-Object { $_.Name -like "*hvbak-checkpoint*" } | Remove-VMSnapshot

# Clean temp folders
Remove-Item "$env:TEMP\hvbak" -Recurse -Force -ErrorAction SilentlyContinue

# Stop hung jobs
Get-Job | Where-Object { $_.State -eq 'Running' } | Stop-Job -PassThru | Remove-Job

# Kill orphaned 7z processes
Get-Process 7z -ErrorAction SilentlyContinue | Stop-Process -Force
```

---

## ?? Reporting Issues

If you encounter an issue not covered here:

1. **Run diagnostics:**
   ```powershell
   Test-PSHVToolsEnvironment -Detailed > diagnostics.txt
   Get-VM | Out-File -Append diagnostics.txt
   ```

2. **Collect logs:**
   - Backup logs in temp folder: `$env:TEMP\hvbak\*.log`
   - Windows Event Logs: `Get-EventLog -LogName "Hyper-V-*"`

3. **Report on GitHub:**
   - https://github.com/vitalie-vrabie/pshvtools/issues
   - Include diagnostics output
   - Describe steps to reproduce
   - Include error messages

---

## ?? Additional Resources

- **README:** [README.md](README.md)
- **Quick Start:** [QUICKSTART.md](QUICKSTART.md)
- **Build Guide:** [BUILD_GUIDE.md](BUILD_GUIDE.md)
- **Contributing:** [CONTRIBUTING.md](CONTRIBUTING.md)
- **GitHub Issues:** https://github.com/vitalie-vrabie/pshvtools/issues
