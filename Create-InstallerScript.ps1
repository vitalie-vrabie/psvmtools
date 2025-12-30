# Create-InstallerScript.ps1
# Generates the Install.ps1 and README.txt for the distributable installer package

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputDir,
    
    [Parameter(Mandatory=$true)]
    [string]$Version
)

$ErrorActionPreference = 'Stop'

# Create Install.ps1 script
$installScript = @"
# PSHVTools Installer v$Version
# Installs the hvbak PowerShell module system-wide

param(
    [switch]`$Silent,
    [switch]`$Uninstall
)

`$ErrorActionPreference = 'Stop'

`$ModuleName = 'hvbak'
`$ModuleVersion = '$Version'
`$ProductName = 'PSHVTools'
`$InstallPath = "`$env:ProgramFiles\WindowsPowerShell\Modules\`$ModuleName"

function Write-Log {
    param([string]`$Message, [string]`$Level = 'Info')
    
    if (-not `$Silent) {
        `$color = switch(`$Level) {
            'Error' { 'Red' }
            'Warning' { 'Yellow' }
            'Success' { 'Green' }
            default { 'White' }
        }
        Write-Host `$Message -ForegroundColor `$color
    }
}

function Test-Administrator {
    `$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    `$principal = New-Object Security.Principal.WindowsPrincipal(`$currentUser)
    return `$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-PSHVTools {
    Write-Log "`n========================================" -Level 'Info'
    Write-Log "  `$ProductName Installer v`$ModuleVersion" -Level 'Info'
    Write-Log "========================================`n" -Level 'Info'
    
    if (-not (Test-Administrator)) {
        Write-Log "ERROR: Administrator privileges required!" -Level 'Error'
        Write-Log "Please run this installer as Administrator.`n" -Level 'Error'
        exit 1
    }
    
    if (`$PSVersionTable.PSVersion.Major -lt 5) {
        Write-Log "ERROR: PowerShell 5.1 or later is required!" -Level 'Error'
        Write-Log "Current version: `$(`$PSVersionTable.PSVersion)`n" -Level 'Error'
        exit 1
    }
    
    Write-Log "Installing `$ProductName..." -Level 'Info'
    Write-Log "Installation path: `$InstallPath`n" -Level 'Info'
    
    try {
        if (Test-Path `$InstallPath) {
            Write-Log "Removing existing installation..." -Level 'Warning'
            Remove-Item -Path `$InstallPath -Recurse -Force
        }
        
        New-Item -ItemType Directory -Path `$InstallPath -Force | Out-Null
        
        `$sourceDir = Join-Path `$PSScriptRoot 'Module'
        Copy-Item -Path "`$sourceDir\*" -Destination `$InstallPath -Recurse -Force
        
        Write-Log "Module files installed successfully." -Level 'Success'
        
        Import-Module `$ModuleName -Force
        `$installedModule = Get-Module `$ModuleName
        
        if (`$installedModule) {
            Write-Log "`n========================================" -Level 'Success'
            Write-Log "  Installation Successful!" -Level 'Success'
            Write-Log "========================================`n" -Level 'Success'
            Write-Log "Module: `$ModuleName" -Level 'Info'
            Write-Log "Version: `$(`$installedModule.Version)" -Level 'Info'
            Write-Log "Location: `$InstallPath`n" -Level 'Info'
            Write-Log "Quick Start:" -Level 'Info'
            Write-Log "  Get-Help Backup-HyperVVM -Full" -Level 'Info'
            Write-Log "  Get-Help Restore-HyperVVM -Full`n" -Level 'Info'
        }
        
        exit 0
    }
    catch {
        Write-Log "`nERROR: Installation failed!" -Level 'Error'
        Write-Log `$_.Exception.Message -Level 'Error'
        exit 1
    }
}

function Uninstall-PSHVTools {
    Write-Log "`n========================================" -Level 'Info'
    Write-Log "  `$ProductName Uninstaller" -Level 'Info'
    Write-Log "========================================`n" -Level 'Info'
    
    if (-not (Test-Administrator)) {
        Write-Log "ERROR: Administrator privileges required!" -Level 'Error'
        Write-Log "Please run this uninstaller as Administrator.`n" -Level 'Error'
        exit 1
    }
    
    try {
        if (Test-Path `$InstallPath) {
            Write-Log "Removing `$ProductName from: `$InstallPath" -Level 'Info'
            Remove-Item -Path `$InstallPath -Recurse -Force
            Write-Log "`n`$ProductName has been successfully uninstalled.`n" -Level 'Success'
        }
        else {
            Write-Log "`$ProductName is not installed.`n" -Level 'Warning'
        }
        
        exit 0
    }
    catch {
        Write-Log "`nERROR: Uninstallation failed!" -Level 'Error'
        Write-Log `$_.Exception.Message -Level 'Error'
        exit 1
    }
}

if (`$Uninstall) {
    Uninstall-PSHVTools
}
else {
    Install-PSHVTools
}
"@

$installScriptPath = Join-Path $OutputDir "Install.ps1"
$installScript | Out-File -FilePath $installScriptPath -Encoding UTF8

# Create README.txt
$readmeContent = @"
# PSHVTools Setup v$Version

## Installation

### Option 1: Interactive Installation
Right-click 'Install.ps1' and select "Run with PowerShell" (as Administrator)

### Option 2: Command Line Installation
``````powershell
# Run as Administrator
powershell -ExecutionPolicy Bypass -File Install.ps1
``````

### Option 3: Silent Installation
``````powershell
# Run as Administrator
powershell -ExecutionPolicy Bypass -File Install.ps1 -Silent
``````

## Uninstallation

``````powershell
# Run as Administrator
powershell -ExecutionPolicy Bypass -File Install.ps1 -Uninstall
``````

## Requirements

- Windows with Hyper-V
- PowerShell 5.1 or later
- Administrator privileges for installation

## What Gets Installed

The installer will:
- Copy the hvbak PowerShell module to: C:\Program Files\WindowsPowerShell\Modules\hvbak
- Make the module available system-wide
- No registry changes or system modifications required

## More Information

- Quick Start Guide: See QUICKSTART.md
- Full Documentation: See README.md
- License: See LICENSE.txt
- Project: https://github.com/vitalie-vrabie/pshvtools

## Replacing the WiX MSI Installer

This PowerShell-based installer replaces the previous WiX MSI installer with a simpler,
dependency-free solution that works on any Windows system with PowerShell 5.1+.

Benefits:
- No WiX Toolset required to build
- No special tools required to install
- Simple PowerShell script installation
- Easy to customize and maintain
- Works on all Windows versions with PowerShell 5.1+
"@

$readmePath = Join-Path $OutputDir "README.txt"
$readmeContent | Out-File -FilePath $readmePath -Encoding UTF8

Write-Host "Installer scripts created successfully in: $OutputDir" -ForegroundColor Green
Write-Host "  - Install.ps1" -ForegroundColor Cyan
Write-Host "  - README.txt" -ForegroundColor Cyan
