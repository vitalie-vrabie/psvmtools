# PSHVTools - Build Guide
## Building Release Packages

---

## Quick Start

### Build GUI EXE Installer

Prerequisite: **Inno Setup 6**

```cmd
installer\Build-InnoSetupInstaller.bat
```

**Output:** `dist\\PSHVTools-Setup-1.0.3.exe`

---

## Prerequisites

- Inno Setup 6
- Windows PowerShell 5.1+

---

## Silent Installation (end users)

```cmd
PSHVTools-Setup-1.0.3.exe /VERYSILENT /NORESTART
```

---

## Smoke Test After Install

```powershell
Import-Module pshvtools
Get-Command -Module pshvtools

# Backup
hvbak -NamePattern "*"

# Restore (from hvbak archives)
hvrecover -WhatIf

# Recover orphaned VMs (re-register configs)
hvrecover -WhatIf
```

---

## Notes

The repository no longer uses MSBuild packaging scripts. The distributable artifact is the GUI installer EXE built via Inno Setup.
