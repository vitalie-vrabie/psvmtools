#Requires -Version 5.1

<#
.SYNOPSIS
    Validates version consistency across all project files.
    
.DESCRIPTION
    Checks that version numbers in version.json, pshvtools.psd1, and PSHVTools-Installer.iss are consistent.
    Used in CI/CD pipeline to prevent version mismatches.
#>

$ErrorActionPreference = 'Stop'

Write-Host "`n?? Checking version consistency...`n" -ForegroundColor Cyan

# Read version.json (single source of truth)
$versionFile = Join-Path $PSScriptRoot '..\version.json'
if (-not (Test-Path $versionFile)) {
    throw "? version.json not found at: $versionFile"
}

$versionData = Get-Content $versionFile | ConvertFrom-Json
$expectedVersion = $versionData.version

Write-Host "?? Expected version: $expectedVersion" -ForegroundColor Yellow

# Check PowerShell module manifest
$manifestPath = Join-Path $PSScriptRoot '..\scripts\pshvtools.psd1'
$manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
$manifestVersion = $manifest.Version.ToString()

Write-Host "   PowerShell Manifest: $manifestVersion" -NoNewline
if ($manifestVersion -eq $expectedVersion) {
    Write-Host " ?" -ForegroundColor Green
} else {
    Write-Host " ? (Expected: $expectedVersion)" -ForegroundColor Red
    throw "Version mismatch in pshvtools.psd1"
}

# Check Inno Setup installer script
$issPath = Join-Path $PSScriptRoot '..\installer\PSHVTools-Installer.iss'
$issContent = Get-Content $issPath -Raw

if ($issContent -match '#define MyAppVersion "([^"]+)"') {
    $issVersion = $matches[1]
    Write-Host "   Inno Setup Script:   $issVersion" -NoNewline
    if ($issVersion -eq $expectedVersion) {
        Write-Host " ?" -ForegroundColor Green
    } else {
        Write-Host " ? (Expected: $expectedVersion)" -ForegroundColor Red
        throw "Version mismatch in PSHVTools-Installer.iss"
    }
} else {
    throw "? Could not find MyAppVersion in PSHVTools-Installer.iss"
}

Write-Host "`n? All versions are consistent!`n" -ForegroundColor Green
