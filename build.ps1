[CmdletBinding()]
param(
    [string]$IsccPath = $env:INNO_SETUP_PATH,
    [string]$IssFile = $env:INNO_SETUP_ISS,
    [switch]$WhatIf,
    [switch]$Clean,
    [switch]$SkipVersionCheck
)

$ErrorActionPreference = 'Stop'

# Helper function for formatted output
function Write-BuildMessage {
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

Write-BuildMessage "PSHVTools Build Script" -Type Info
Write-Host ""

# Clean build artifacts if requested
if ($Clean) {
    Write-BuildMessage "Cleaning build artifacts..." -Type Info
    $distPath = Join-Path $PSScriptRoot 'dist'
    if (Test-Path $distPath) {
        Remove-Item $distPath -Recurse -Force
        Write-BuildMessage "Removed: $distPath" -Type Success
    }
}

# Validate version consistency
if (-not $SkipVersionCheck) {
    Write-BuildMessage "Validating version consistency..." -Type Info
    $versionCheckScript = Join-Path $PSScriptRoot 'tests\Test-VersionConsistency.ps1'
    if (Test-Path $versionCheckScript) {
        try {
            & $versionCheckScript
        } catch {
            Write-BuildMessage "Version consistency check failed: $_" -Type Error
            throw
        }
    } else {
        Write-BuildMessage "Version check script not found, skipping..." -Type Warning
    }
}

# Resolve ISCC path
if ([string]::IsNullOrWhiteSpace($IsccPath)) {
    $IsccPath = "C:\Program Files (x86)\Inno Setup 6"
}

$isccExe = Join-Path $IsccPath 'ISCC.exe'

if (-not (Test-Path -LiteralPath $isccExe)) {
    Write-BuildMessage "ISCC.exe not found at '$isccExe'" -Type Error
    Write-Host ""
    Write-Host "?? Tip: Install Inno Setup 6 or provide -IsccPath parameter" -ForegroundColor Yellow
    Write-Host "   Download: https://jrsoftware.org/isdl.php" -ForegroundColor Gray
    Write-Host ""
    throw "ISCC.exe not found. Provide -IsccPath or set INNO_SETUP_PATH."
}

Write-BuildMessage "Found Inno Setup at: $IsccPath" -Type Success

# Resolve ISS file path
if ([string]::IsNullOrWhiteSpace($IssFile)) {
    $candidate = Join-Path $PSScriptRoot 'installer\PSHVTools-Installer.iss'
    if (Test-Path -LiteralPath $candidate) {
        $IssFile = $candidate
    } else {
        $IssFile = Join-Path $PSScriptRoot 'PSHVTools-Installer.iss'
    }
}

if (-not (Test-Path -LiteralPath $IssFile)) {
    Write-BuildMessage "Installer script not found at '$IssFile'" -Type Error
    Write-Host ""
    Write-Host "?? Expected location: installer\PSHVTools-Installer.iss" -ForegroundColor Yellow
    Write-Host "   Current directory: $PSScriptRoot" -ForegroundColor Gray
    Write-Host ""
    Write-Host "?? See BUILD_GUIDE.md for more information" -ForegroundColor Gray
    Write-Host ""
    throw "ISS file not found. Provide -IssFile or set INNO_SETUP_ISS."
}

Write-BuildMessage "Using installer script: $IssFile" -Type Success

# WhatIf support
if ($WhatIf) {
    Write-Host ""
    Write-BuildMessage "WhatIf: Would execute build with:" -Type Warning
    Write-Host "   ISCC: $isccExe" -ForegroundColor Gray
    Write-Host "   Script: $IssFile" -ForegroundColor Gray
    Write-Host ""
    exit 0
}

# Execute build
Write-Host ""
Write-BuildMessage "Building installer..." -Type Info
Write-Host ""

try {
    & $isccExe $IssFile
    
    if ($LASTEXITCODE -ne 0) {
        throw "Inno Setup compiler returned exit code: $LASTEXITCODE"
    }
    
} catch {
    Write-Host ""
    Write-BuildMessage "Build failed: $_" -Type Error
    throw
}

# Verify build output
$outputPath = Join-Path $PSScriptRoot 'dist\PSHVTools-Setup.exe'
if (-not (Test-Path $outputPath)) {
    Write-Host ""
    Write-BuildMessage "Build verification failed: PSHVTools-Setup.exe not found" -Type Error
    throw "Build output not found at: $outputPath"
}

$fileInfo = Get-Item $outputPath
Write-Host ""
Write-BuildMessage "Build completed successfully!" -Type Success
Write-Host "   Output: $outputPath" -ForegroundColor Gray
Write-Host "   Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray

# Generate checksum
Write-Host ""
Write-BuildMessage "Generating SHA256 checksum..." -Type Info

$hash = Get-FileHash $outputPath -Algorithm SHA256
$checksumFile = "$outputPath.sha256"
"$($hash.Hash)  PSHVTools-Setup.exe" | Out-File $checksumFile -Encoding ASCII

Write-BuildMessage "Checksum saved to: $checksumFile" -Type Success
Write-Host "   SHA256: $($hash.Hash)" -ForegroundColor Gray

Write-Host ""
Write-BuildMessage "?? Build process complete!" -Type Success
Write-Host ""
