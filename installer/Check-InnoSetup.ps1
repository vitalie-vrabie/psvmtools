# Check-InnoSetup.ps1
# Robust check for Inno Setup compiler (ISCC.exe). Exits 0 if found, non-zero otherwise.
param()

Write-Host "Checking for Inno Setup (ISCC.exe)..."

# 1) Get-Command
try {
    $cmd = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Path) {
        Write-Host "Found via Get-Command: $($cmd.Path)"
        exit 0
    }
} catch {}

# 2) where.exe
try {
    $where = & where.exe ISCC.exe 2>$null
    if ($where) {
        foreach ($w in $where) { Write-Host "Found via where: $w" }
        exit 0
    }
} catch {}

# 3) Common install paths
$paths = @(
    "$env:ProgramFiles\\Inno Setup 6\\ISCC.exe",
    "$env:ProgramFiles(x86)\\Inno Setup 6\\ISCC.exe",
    "$env:ProgramFiles(x86)\\Inno Setup 5\\ISCC.exe",
    "$env:ProgramFiles\\Inno Setup 5\\ISCC.exe"
)
foreach ($p in $paths) {
    if (Test-Path $p) {
        Write-Host "Found in common path: $p"
        exit 0
    }
}

# 4) Registry uninstall entries
$regRoots = @(
    'HKLM:\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall',
    'HKLM:\SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall',
    'HKCU:\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall'
)
foreach ($rk in $regRoots) {
    try {
        Get-ChildItem -Path $rk -ErrorAction SilentlyContinue | ForEach-Object {
            $props = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
            if ($props) {
                if ($props.DisplayName -and $props.DisplayName -match 'Inno\s*Setup') {
                    if ($props.InstallLocation) {
                        $cand = Join-Path $props.InstallLocation 'ISCC.exe'
                        if (Test-Path $cand) { Write-Host "Found via registry InstallLocation: $cand"; exit 0 }
                    }
                    if ($props.DisplayIcon) {
                        $di = $props.DisplayIcon -replace '"',''
                        if (Test-Path $di) { Write-Host "Found via registry DisplayIcon: $di"; exit 0 }
                    }
                    if ($props.UninstallString) {
                        if ($props.UninstallString -match 'ISCC.exe') {
                            # extract possible path
                            if ($props.UninstallString -match '"(?<p>.*?ISCC.exe)"') {
                                $p = $Matches['p']
                                if (Test-Path $p) { Write-Host "Found via registry UninstallString: $p"; exit 0 }
                            }
                        }
                    }
                }
            }
        }
    } catch {}
}

Write-Error "Inno Setup (ISCC.exe) not found. Install Inno Setup 6 from https://jrsoftware.org/isdl.php"
exit 2
