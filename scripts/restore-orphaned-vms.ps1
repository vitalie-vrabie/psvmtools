<#
.SYNOPSIS
  Scan Hyper-V VM configuration folders for orphaned VMs (present on disk but not registered) and register them.

.DESCRIPTION
  Hyper-V stores per-VM configuration under a "Virtual Machines" folder. Newer Hyper-V versions use .vmcx
  (and .vmrs) per-VM files; older versions can use .xml.

  This script:
   - Enumerates all *.vmcx (and optionally *.xml) beneath the supplied root folder(s)
   - Compares discovered VM IDs (GUIDs) against currently registered VMs (Get-VM)
   - For missing IDs, attempts to register them in-place using Import-VM -Register

  It can also "move" the VM to a new store using Import-VM -Copy -GenerateNewId, but the default is in-place
  registration.

.PARAMETER VmConfigRoot
  One or more roots to scan.

  Typical defaults:
   - $env:ProgramData\Microsoft\Windows\Hyper-V
   - <custom VM storage root>

  The script will scan recursively for *.vmcx.

.PARAMETER IncludeXml
  Also scan for legacy *.xml config files. Use only if you expect pre-2016 exports/configs.

.PARAMETER Mode
  Import strategy for discovered orphaned configs:
   - Register (default): register in-place (no file copy)
   - Copy: copy to VmStorageRoot and generate a new VM ID

.PARAMETER VmStorageRoot
  Destination root used only when Mode=Copy.

.PARAMETER Force
  Passed through to Import-VM.

.EXAMPLE
  # Preview what would be registered
  .\restore-orphaned-vms.ps1 -VmConfigRoot "$env:ProgramData\Microsoft\Windows\Hyper-V" -WhatIf

.EXAMPLE
  # Scan a custom VM storage folder too
  .\restore-orphaned-vms.ps1 -VmConfigRoot "D:\Hyper-V","E:\Hyper-V"

.NOTES
  - Run elevated (Administrator)
  - Requires the Hyper-V PowerShell module
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$VmConfigRoot = @("$env:ProgramData\Microsoft\Windows\Hyper-V"),

    [Parameter(Mandatory = $false)]
    [switch]$IncludeXml,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Register', 'Copy')]
    [string]$Mode = 'Register',

    [Parameter(Mandatory = $false)]
    [string]$VmStorageRoot = "$env:ProgramData\Microsoft\Windows\Hyper-V",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
    param([Parameter(Mandatory = $true)][string]$Message)
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Write-Host "$ts  $Message"
}

function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Administrator privileges are required.'
    }
}

function Try-ParseGuidFromPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $name = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    $g = [guid]::Empty
    if ([guid]::TryParse($name, [ref]$g)) { return $g }

    $folder = Split-Path -Path $Path -Parent
    $leaf = Split-Path -Path $folder -Leaf
    if ([guid]::TryParse($leaf, [ref]$g)) { return $g }

    return $null
}

function Get-OrphanCandidates {
    param(
        [Parameter(Mandatory = $true)][string[]]$Roots,
        [Parameter(Mandatory = $true)][switch]$IncludeXml
    )

    $files = New-Object System.Collections.Generic.List[System.IO.FileInfo]

    foreach ($r in $Roots) {
        if ([string]::IsNullOrWhiteSpace($r)) { continue }
        if (-not (Test-Path -LiteralPath $r)) {
            Write-Log "WARNING: Root not found: $r"
            continue
        }

        Write-Log "Scanning: $r"

        $vmcx = Get-ChildItem -LiteralPath $r -Recurse -File -Filter '*.vmcx' -ErrorAction SilentlyContinue
        foreach ($f in $vmcx) { $files.Add($f) }

        if ($IncludeXml) {
            $xml = Get-ChildItem -LiteralPath $r -Recurse -File -Filter '*.xml' -ErrorAction SilentlyContinue
            foreach ($f in $xml) {
                # Practical filter: keep only GUID.xml (older configs) and ignore generic docs.
                $g = [guid]::Empty
                if ([guid]::TryParse([System.IO.Path]::GetFileNameWithoutExtension($f.Name), [ref]$g)) {
                    $files.Add($f)
                }
            }
        }
    }

    # De-dupe by FullName
    $files | Sort-Object FullName -Unique
}

Assert-Admin
Import-Module Hyper-V -ErrorAction Stop

$registered = @(Get-VM -ErrorAction SilentlyContinue)
$registeredIds = @{}
foreach ($vm in $registered) {
    try { $registeredIds[$vm.Id.Guid.ToString().ToLowerInvariant()] = $true } catch {}
}

$candidates = Get-OrphanCandidates -Roots $VmConfigRoot -IncludeXml:$IncludeXml

if (-not $candidates -or $candidates.Count -eq 0) {
    Write-Log 'No candidate VM config files found.'
    return
}

$orphans = @()
foreach ($f in $candidates) {
    $gid = Try-ParseGuidFromPath -Path $f.FullName
    if (-not $gid) { continue }

    if (-not $registeredIds.ContainsKey($gid.Guid.ToString().ToLowerInvariant())) {
        $orphans += [PSCustomObject]@{
            Id   = $gid
            Path = $f.FullName
        }
    }
}

if ($orphans.Count -eq 0) {
    Write-Log 'No orphaned VMs detected.'
    return
}

Write-Log ("Found {0} orphaned VM config(s)." -f $orphans.Count)

$results = New-Object System.Collections.Generic.List[object]

foreach ($o in $orphans) {
    $path = $o.Path

    # For vmcx: Import-VM typically wants the export root or the vmcx path; it varies.
    # We'll try a small set of candidates like restore-vmbackup does.
    $tryPaths = New-Object System.Collections.Generic.List[string]
    $tryPaths.Add($path)

    $dir = Split-Path -Path $path -Parent
    if ($dir) { $tryPaths.Add($dir) }

    # If path contains "Virtual Machines", try its parent (common store/export root)
    if ($dir -and ($dir -match '(?i)\\Virtual Machines(\\|$)')) {
        $parent = Split-Path -Path $dir -Parent
        if ($parent) { $tryPaths.Add($parent) }
    }

    $tryPaths = $tryPaths | Sort-Object -Unique

    $importParams = @{ ErrorAction = 'Stop' }
    if ($Force) { $importParams.Force = $true }

    if ($Mode -eq 'Register') {
        $importParams.Register = $true
    } else {
        $importParams.Copy = $true
        $importParams.GenerateNewId = $true
        $importParams.VirtualMachinePath = $VmStorageRoot
        $importParams.VhdDestinationPath = $VmStorageRoot
        $importParams.SnapshotFilePath = $VmStorageRoot
    }

    $imported = $null
    $lastErr = $null

    foreach ($p in $tryPaths) {
        try {
            if (-not $PSCmdlet.ShouldProcess($p, "Import-VM ($Mode) for orphaned config $($o.Id)")) {
                $imported = 'WhatIf'
                break
            }

            Write-Log "Attempting Import-VM from: $p"
            $imported = Import-VM -Path $p @importParams
            break
        } catch {
            $lastErr = $_
            Write-Log "Import-VM failed for '$p': $($_.Exception.Message)"
        }
    }

    if ($imported -and $imported -ne 'WhatIf') {
        Write-Log "Registered VM: $($imported.Name) (Id: $($imported.Id))"
        $results.Add([PSCustomObject]@{ Id = $o.Id; Path = $o.Path; Success = $true; VmName = $imported.Name; Message = 'Imported' })
    } elseif ($imported -eq 'WhatIf') {
        $results.Add([PSCustomObject]@{ Id = $o.Id; Path = $o.Path; Success = $true; VmName = $null; Message = 'WhatIf' })
    } else {
        $msg = if ($lastErr) { $lastErr.Exception.Message } else { 'Import failed' }
        $results.Add([PSCustomObject]@{ Id = $o.Id; Path = $o.Path; Success = $false; VmName = $null; Message = $msg })
    }
}

$results | Sort-Object Success, VmName, Path | Format-Table -AutoSize
