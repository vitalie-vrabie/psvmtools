#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Uninstalls PSHVTools PowerShell module.

.DESCRIPTION
    Removes the hvbak module from the system-wide PowerShell modules directory.
    Requires administrator privileges.

.EXAMPLE
    .\Uninstall-PSHVTools.ps1
    
.NOTES
    Run as Administrator to uninstall system-wide module.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PSHVTools Uninstaller" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Define installation path
$InstallPath = "$env:ProgramFiles\WindowsPowerShell\Modules\pshvtools"

# Check if module is installed
if (-not (Test-Path $InstallPath)) {
    Write-Host "Module is not installed at: $InstallPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Nothing to uninstall." -ForegroundColor Green
    exit 0
}

Write-Host "Found module at: $InstallPath" -ForegroundColor Cyan
Write-Host ""

# Remove module if it's loaded
Write-Host "Checking for loaded module..." -ForegroundColor Yellow
if (Get-Module pshvtools) {
    Write-Host "  Removing loaded module..." -ForegroundColor Yellow
    Remove-Module pshvtools -Force
    Write-Host "  [OK] Module unloaded" -ForegroundColor Green
}

# Delete the module directory
Write-Host ""
Write-Host "Removing module files..." -ForegroundColor Yellow
try {
    Remove-Item -Path $InstallPath -Recurse -Force
    Write-Host "  [OK] Module directory removed" -ForegroundColor Green
} catch {
    Write-Error "Failed to remove module: $_"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Uninstall Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "The pshvtools module has been removed from your system." -ForegroundColor Cyan
Write-Host ""
