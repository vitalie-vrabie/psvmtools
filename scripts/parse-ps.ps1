param([string]$Path)
$errs=$null
[System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path).Path,[ref]$errs,[ref]$null) | Out-Null
if ($errs) { foreach($e in $errs){ Write-Host "$($e.Message) at $($e.Extent.StartLineNumber):$($e.Extent.StartColumnNumber)" } ; exit 1 } else { Write-Host "OK"; exit 0 }