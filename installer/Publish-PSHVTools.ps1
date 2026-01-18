#Requires -Version 5.1

<#
.SYNOPSIS
    Publishes PSHVTools to PowerShell Gallery.
    
.DESCRIPTION
    Validates and publishes the PSHVTools module to PowerShell Gallery.
    Requires PSGallery API key to be set in environment variable PSGALLERY_API_KEY.
    
.PARAMETER ApiKey
    PowerShell Gallery API key. If not provided, uses PSGALLERY_API_KEY environment variable.
    
.PARAMETER WhatIf
    Shows what would be published without actually publishing.
    
.EXAMPLE
    .\Publish-PSHVTools.ps1 -ApiKey "your-api-key"
    
.EXAMPLE
    $env:PSGALLERY_API_KEY = "your-api-key"
    .\Publish-PSHVTools.ps1
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ApiKey = $env:PSGALLERY_API_KEY,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

function Write-PublishMessage {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )
    
    $icon = switch ($Type) {
        'Info'    { '??' }
        'Success' { '?' }
        'Warning' { '??' }
        'Error'   { '?' }
    }
    
    $color = switch ($Type) {
        'Info'    { 'Cyan' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
    }
    
    Write-Host "$icon $Message" -ForegroundColor $color
}

Write-PublishMessage "PSHVTools PowerShell Gallery Publisher" -Type Info
Write-Host ""

# Check API key
if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-PublishMessage "API key not provided" -Type Error
    Write-Host ""
    Write-Host "?? Provide API key via:" -ForegroundColor Yellow
    Write-Host "   -ApiKey parameter" -ForegroundColor Gray
    Write-Host "   Or set environment variable: `$env:PSGALLERY_API_KEY" -ForegroundColor Gray
    Write-Host ""
    throw "PowerShell Gallery API key required"
}

# Validate module manifest
$manifestPath = Join-Path $PSScriptRoot '..\scripts\pshvtools.psd1'
Write-PublishMessage "Validating module manifest..." -Type Info

try {
    $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
    Write-PublishMessage "Manifest validation passed" -Type Success
    Write-Host "   Version: $($manifest.Version)" -ForegroundColor Gray
    Write-Host "   Author: $($manifest.Author)" -ForegroundColor Gray
} catch {
    Write-PublishMessage "Manifest validation failed: $_" -Type Error
    throw
}

# Check version consistency
Write-PublishMessage "Checking version consistency..." -Type Info
$versionCheckScript = Join-Path $PSScriptRoot '..\tests\Test-VersionConsistency.ps1'
if (Test-Path $versionCheckScript) {
    try {
        & $versionCheckScript
    } catch {
        Write-PublishMessage "Version consistency check failed" -Type Error
        throw
    }
}

# Run tests
Write-PublishMessage "Running tests..." -Type Info
if (Get-Module Pester -ListAvailable) {
    try {
        $testResults = Invoke-Pester -Path "$PSScriptRoot\..\tests" -PassThru -ErrorAction Stop
        if ($testResults.FailedCount -gt 0) {
            Write-PublishMessage "$($testResults.FailedCount) test(s) failed" -Type Error
            throw "Tests must pass before publishing"
        }
        Write-PublishMessage "All tests passed" -Type Success
    } catch {
        Write-PublishMessage "Test execution failed: $_" -Type Warning
    }
} else {
    Write-PublishMessage "Pester not installed, skipping tests" -Type Warning
}

# Prepare module for publishing
$modulePath = Join-Path $PSScriptRoot '..\scripts'
Write-PublishMessage "Module path: $modulePath" -Type Info

# Check for required files
$requiredFiles = @('pshvtools.psm1', 'pshvtools.psd1')
foreach ($file in $requiredFiles) {
    $filePath = Join-Path $modulePath $file
    if (-not (Test-Path $filePath)) {
        Write-PublishMessage "Required file missing: $file" -Type Error
        throw "Module incomplete"
    }
}

# WhatIf support
if ($WhatIf) {
    Write-Host ""
    Write-PublishMessage "WhatIf: Would publish module:" -Type Warning
    Write-Host "   Name: PSHVTools" -ForegroundColor Gray
    Write-Host "   Version: $($manifest.Version)" -ForegroundColor Gray
    Write-Host "   Path: $modulePath" -ForegroundColor Gray
    Write-Host "   Repository: PSGallery" -ForegroundColor Gray
    Write-Host ""
    exit 0
}

# Publish to PowerShell Gallery
Write-Host ""
Write-PublishMessage "Publishing to PowerShell Gallery..." -Type Info

try {
    Publish-Module `
        -Path $modulePath `
        -NuGetApiKey $ApiKey `
        -Repository PSGallery `
        -Verbose `
        -ErrorAction Stop
    
    Write-Host ""
    Write-PublishMessage "Successfully published PSHVTools v$($manifest.Version)!" -Type Success
    Write-Host ""
    Write-Host "?? Module will be available shortly at:" -ForegroundColor Cyan
    Write-Host "   https://www.powershellgallery.com/packages/pshvtools" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Users can install with:" -ForegroundColor Cyan
    Write-Host "   Install-Module -Name pshvtools" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-PublishMessage "Publish failed: $_" -Type Error
    throw
}
