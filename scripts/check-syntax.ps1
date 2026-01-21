param(
    [string[]]$Files
)

if (-not $Files -or $Files.Count -eq 0) {
    Write-Error "Usage: .\check-syntax.ps1 <file1> [file2 ...]"
    exit 2
}

$hadError = $false
foreach ($f in $Files) {
    $path = (Resolve-Path $f -ErrorAction SilentlyContinue)
    if (-not $path) {
        Write-Output "MISSING: $f"
        $hadError = $true
        continue
    }
    $errs = $null
    try {
        [System.Management.Automation.Language.Parser]::ParseFile($path.Path, [ref]$errs, [ref]$null) | Out-Null
        if ($errs) {
            foreach ($e in $errs) {
                Write-Output "$f SYNTAX ERROR: $($e.Message) at $($e.Extent.StartLineNumber):$($e.Extent.StartColumnNumber)"
            }
            $hadError = $true
        } else {
            Write-Output ($f + ': OK')
        }
    } catch {
        Write-Output ($f + ' PARSE FAILED: ' + $_.ToString())
        $hadError = $true
    }
}

if ($hadError) { exit 1 } else { exit 0 }
