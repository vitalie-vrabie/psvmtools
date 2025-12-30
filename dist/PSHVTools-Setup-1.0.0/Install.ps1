# PSHVTools Installer v1.0.0
# Installs the hvbak PowerShell module system-wide

param(
    [switch]$Silent,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

$ModuleName = 'hvbak'
$ModuleVersion = '1.0.0'
$ProductName = 'PSHVTools'
$InstallPath = "$env:ProgramFiles\WindowsPowerShell\Modules\$ModuleName"

function Write-Log {
    param([string]$Message, [string]$Level = 'Info')
    
    if (-not $Silent) {
        $color = switch($Level) {
            'Error' { 'Red' }
            'Warning' { 'Yellow' }
            'Success' { 'Green' }
            default { 'White' }
        }
        Write-Host $Message -ForegroundColor $color
    }
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-PSHVTools {
    Write-Log "
========================================" -Level 'Info'
    Write-Log "  $ProductName Installer v$ModuleVersion" -Level 'Info'
    Write-Log "========================================
" -Level 'Info'
    
    if (-not (Test-Administrator)) {
        Write-Log "ERROR: Administrator privileges required!" -Level 'Error'
        Write-Log "Please run this installer as Administrator.
" -Level 'Error'
        exit 1
    }
    
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Log "ERROR: PowerShell 5.1 or later is required!" -Level 'Error'
        Write-Log "Current version: $($PSVersionTable.PSVersion)
" -Level 'Error'
        exit 1
    }
    
    Write-Log "Installing $ProductName..." -Level 'Info'
    Write-Log "Installation path: $InstallPath
" -Level 'Info'
    
    try {
        if (Test-Path $InstallPath) {
            Write-Log "Removing existing installation..." -Level 'Warning'
            Remove-Item -Path $InstallPath -Recurse -Force
        }
        
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        
        $sourceDir = Join-Path $PSScriptRoot 'Module'
        Copy-Item -Path "$sourceDir\*" -Destination $InstallPath -Recurse -Force
        
        Write-Log "Module files installed successfully." -Level 'Success'
        
        Import-Module $ModuleName -Force
        $installedModule = Get-Module $ModuleName
        
        if ($installedModule) {
            Write-Log "
========================================" -Level 'Success'
            Write-Log "  Installation Successful!" -Level 'Success'
            Write-Log "========================================
" -Level 'Success'
            Write-Log "Module: $ModuleName" -Level 'Info'
            Write-Log "Version: $($installedModule.Version)" -Level 'Info'
            Write-Log "Location: $InstallPath
" -Level 'Info'
            Write-Log "Quick Start:" -Level 'Info'
            Write-Log "  Get-Help Backup-HyperVVM -Full" -Level 'Info'
            Write-Log "  Get-Help Restore-HyperVVM -Full
" -Level 'Info'
        }
        
        exit 0
    }
    catch {
        Write-Log "
ERROR: Installation failed!" -Level 'Error'
        Write-Log $_.Exception.Message -Level 'Error'
        exit 1
    }
}

function Uninstall-PSHVTools {
    Write-Log "
========================================" -Level 'Info'
    Write-Log "  $ProductName Uninstaller" -Level 'Info'
    Write-Log "========================================
" -Level 'Info'
    
    if (-not (Test-Administrator)) {
        Write-Log "ERROR: Administrator privileges required!" -Level 'Error'
        Write-Log "Please run this uninstaller as Administrator.
" -Level 'Error'
        exit 1
    }
    
    try {
        if (Test-Path $InstallPath) {
            Write-Log "Removing $ProductName from: $InstallPath" -Level 'Info'
            Remove-Item -Path $InstallPath -Recurse -Force
            Write-Log "
$ProductName has been successfully uninstalled.
" -Level 'Success'
        }
        else {
            Write-Log "$ProductName is not installed.
" -Level 'Warning'
        }
        
        exit 0
    }
    catch {
        Write-Log "
ERROR: Uninstallation failed!" -Level 'Error'
        Write-Log $_.Exception.Message -Level 'Error'
        exit 1
    }
}

if ($Uninstall) {
    Uninstall-PSHVTools
}
else {
    Install-PSHVTools
}
