<#
.SYNOPSIS
    Build the installer, mark release as stable and publish a GitHub release with build artifacts.

.DESCRIPTION
    - Reads version from `scripts\pshvtools.psd1` (ModuleVersion)
    - Invokes `build.ps1` to produce `dist\PSHVTools-Setup.exe` and checksum
    - Creates a Git tag `v<version>` if missing
    - Uses `gh` CLI when available to create a GitHub release (stable by default)
    - Falls back to GitHub REST API using `GITHUB_TOKEN` when `gh` is not available

.PARAMETER WhatIf
    Show planned actions without making changes.
#>

[CmdletBinding()]
param(
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

function Write-Short {
    param([string]$m)
    Write-Host $m -ForegroundColor Cyan
}

Write-Short "Publish GitHub Release Helper"

# Read version from module manifest
$manifest = Join-Path $PSScriptRoot '..\scripts\pshvtools.psd1'
if (-not (Test-Path $manifest)) { throw "Module manifest not found: $manifest" }
$content = Get-Content $manifest -Raw
if ($content -match "ModuleVersion\s*=\s*'([^']+)'") { $version = $Matches[1] } else { throw 'Could not parse ModuleVersion from psd1' }
$tag = "v$version"
Write-Short "Detected version: $version (tag: $tag)"

# Build unless WhatIf
$buildScript = Join-Path $PSScriptRoot '..\build.ps1'
if (-not (Test-Path $buildScript)) { throw "Build script not found: $buildScript" }

if ($WhatIf) {
    Write-Short "WhatIf: Would run build (creating dist/PSHVTools-Setup.exe)"
} else {
    Write-Short "Running build.ps1"
    & $buildScript -WhatIf:$false
}

$installer = Join-Path $PSScriptRoot '..\dist\PSHVTools-Setup.exe' | Resolve-Path -ErrorAction SilentlyContinue
$checksum = "$($installer.Path).sha256" -as [string]
if (-not $installer) { throw 'Installer not found after build: dist\PSHVTools-Setup.exe' }

# Determine GitHub repo (owner/repo) from git remote
$remoteUrl = git remote get-url origin 2>$null
if (-not $remoteUrl) { throw 'Failed to get git remote origin URL' }

# Normalize URL to owner/repo
if ($remoteUrl -match 'github.com[:/](.+?)(?:\.git)?$') { $ownerRepo = $Matches[1] } else { throw "Unable to parse origin URL: $remoteUrl" }
Write-Short "Repository: $ownerRepo"

# Create tag if not exists
$tagExists = (& git tag -l $tag) -ne ''
if ($tagExists) { Write-Short "Tag $tag already exists" } else {
    if ($WhatIf) { Write-Short "WhatIf: Would create git tag $tag and push" } else {
        Write-Short "Creating git tag $tag and pushing to origin"
        git tag -a $tag -m "Release $tag"
        git push origin $tag
    }
}

# Prepare release notes: prefer docs/RELEASE_NOTES.md header for this version
$releaseNotesPath = Join-Path $PSScriptRoot '..\docs\RELEASE_NOTES.md'
$notes = ""
if (Test-Path $releaseNotesPath) {
    try { $notes = Get-Content $releaseNotesPath -Raw } catch {}
}
if (-not $notes) { $notes = "Release $tag" }

# Use gh CLI if available
$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($gh) {
    Write-Short "Using gh CLI to create or update release (stable)"
    if ($WhatIf) {
        Write-Short "WhatIf: gh release create $tag --title 'PSHVTools $tag' --notes-file $releaseNotesPath <assets...>"
    } else {
        # Check if release already exists
        $releaseExists = $false
        try {
            & gh release view $tag --repo $ownerRepo > $null 2>&1
            if ($LASTEXITCODE -eq 0) { $releaseExists = $true }
        } catch {}

        if ($releaseExists) {
            Write-Short "Release $tag already exists; uploading assets and updating release notes"

            # Upload assets (use --clobber to replace existing assets with same name)
            $uploadArgs = @('release','upload',$tag,'--repo',$ownerRepo,'--clobber')
            if ($installer -and $installer.Path) { $uploadArgs += $installer.Path }
            if (Test-Path $checksum) { $uploadArgs += $checksum }

            if ($uploadArgs.Count -gt 4) {
                & gh @uploadArgs
                if ($LASTEXITCODE -ne 0) { throw "gh release upload failed with exit code $LASTEXITCODE" }
            } else {
                Write-Short "No assets found to upload for release $tag"
            }

            # Update release notes/title
            if (Test-Path $releaseNotesPath) {
                & gh release edit $tag --repo $ownerRepo --title "PSHVTools $tag" --notes-file $releaseNotesPath
            } else {
                & gh release edit $tag --repo $ownerRepo --title "PSHVTools $tag" --notes "$notes"
            }
            if ($LASTEXITCODE -ne 0) { throw "gh release edit failed with exit code $LASTEXITCODE" }

            Write-Short "Release update via gh complete"
            return
        }

        # Create new release
        $args = @('release','create',$tag)
        if ($installer -and $installer.Path) { $args += $installer.Path }
        if (Test-Path $checksum) { $args += $checksum }
        if (Test-Path $releaseNotesPath) {
            $args += @('--title', "PSHVTools $tag", '--notes-file', $releaseNotesPath, '--repo', $ownerRepo)
        } else {
            $args += @('--title', "PSHVTools $tag", '--notes', $notes, '--repo', $ownerRepo)
        }

        & gh @args
        if ($LASTEXITCODE -ne 0) { throw "gh release create failed with exit code $LASTEXITCODE" }
    }
    Write-Short "Release creation via gh complete"
    return
}

# Fallback to REST API
Write-Short "gh CLI not found; falling back to GitHub REST API. Ensure GITHUB_TOKEN is set in environment."
$token = $env:GITHUB_TOKEN
if (-not $token) { throw 'GITHUB_TOKEN environment variable is required when gh is not available' }

if ($WhatIf) {
    Write-Short "WhatIf: Would create GitHub release $tag and upload $installer"
    return
}

$apiBase = "https://api.github.com/repos/$ownerRepo"
$releaseBody = @{ tag_name = $tag; name = "PSHVTools $tag"; body = $notes; draft = $false; prerelease = $false } | ConvertTo-Json

$headers = @{ Authorization = "token $token"; Accept = 'application/vnd.github+json' }
Write-Short "Creating GitHub release via API"
$release = Invoke-RestMethod -Method Post -Uri "$apiBase/releases" -Headers $headers -Body $releaseBody -ContentType 'application/json'

if (-not $release.upload_url) { throw 'Release created but upload_url missing' }

# Upload asset helper
function Upload-Asset($uploadUrl, $filePath) {
    $fileName = Split-Path $filePath -Leaf
    $u = $uploadUrl -replace '{\?name,label}$','' + "?name=$fileName"
    Write-Short "Uploading $fileName"
    $fh = [System.IO.File]::ReadAllBytes($filePath)
    $contentType = 'application/octet-stream'
    Invoke-RestMethod -Method Post -Uri $u -Headers $headers -Body $fh -ContentType $contentType
}

Upload-Asset $release.upload_url $installer.Path
if (Test-Path $checksum) { Upload-Asset $release.upload_url $checksum }

Write-Short "GitHub release published: $($release.html_url)"
