<#
.SYNOPSIS
  Fix VHD/VHDX ACLs for Hyper-V after copy/restore from backup without creating ACL backup files.

.DESCRIPTION
  Modes:
    - Default (no VhdFolder or VhdListCsv): enumerate Get-VM and fix attached VHDs.
    - -VhdFolder <path>: recursively process *.vhd, *.vhdx under the folder.
    - -VhdListCsv <path>: CSV with columns Path and optional VMId (GUID without braces).
  Use -WhatIf to preview actions.

.EXAMPLE
  .\Fix-VhdAcl-NoBak.ps1 -WhatIf
  .\Fix-VhdAcl-NoBak.ps1 -VhdFolder "D:\Restores"
  .\Fix-VhdAcl-NoBak.ps1 -VhdListCsv "C:\temp\vhd-list.csv"
#>

param(
  [switch]$WhatIf,
  [string]$VhdFolder,
  [string]$VhdListCsv,
  [string]$LogFile = "C:\Temp\FixVhdAcl-NoBak.log"
)

# Ensure log folder exists
$logDir = Split-Path -Path $LogFile -Parent
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
New-Item -Path $LogFile -ItemType File -Force | Out-Null

function Log {
  param([string]$Text)
  $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Text
  $line | Out-File -FilePath $LogFile -Append -Encoding UTF8
  Write-Output $line
}

function Resolve-AccountSid {
  param([string]$AccountName)
  try {
    $nt = New-Object System.Security.Principal.NTAccount($AccountName)
    $sid = $nt.Translate([System.Security.Principal.SecurityIdentifier])
    return $sid.Value
  } catch {
    return $null
  }
}

function Take-Ownership {
  param([string]$Path)
  try {
    # takeown for single file, assign to Administrators
    takeown /f "$Path" /a | Out-Null
    Log "TAKEOWN succeeded for $Path"
  } catch {
    try {
      icacls "$Path" /setowner "Administrators" | Out-Null
      Log "ICACLS setowner succeeded for $Path"
    } catch {
      Log "ERROR take ownership failed for $Path : $_"
      throw
    }
  }
}

function Grant-Permissions {
  param(
    [string]$Path,
    [string[]]$GrantStrings
  )
  foreach ($g in $GrantStrings) {
    try {
      icacls "$Path" /grant $g /inheritance:e | Out-Null
      Log "GRANT $g to $Path"
    } catch {
      Log "ERROR granting $g to $Path : $_"
    }
  }
}

function Process-Vhd {
  param(
    [string]$Path,
    [string]$VmId  # optional GUID without braces
  )

  if (-not (Test-Path $Path)) {
    Log "SKIP not found $Path"
    return
  }

  if ($WhatIf) {
    if ($VmId) {
      $vmAccount = "NT VIRTUAL MACHINE\$VmId"
      Log "WHATIF Would take ownership of $Path"
      Log "WHATIF Would grant ${vmAccount}:(F) and SYSTEM:(F) and Administrators:(F) to $Path"
    } else {
      Log "WHATIF Would take ownership of $Path"
      Log "WHATIF Would grant SYSTEM:(F) and Administrators:(F) to $Path"
    }
    return
  }

  try {
    Take-Ownership -Path $Path
  } catch {
    Log "ERROR ownership step failed for $Path, continuing to attempt grants"
  }

  $grants = @()
  if ($VmId) {
    $vmAccount = "NT VIRTUAL MACHINE\$VmId"
    $sid = Resolve-AccountSid -AccountName $vmAccount
    if ($sid) {
      $grants += "${vmAccount}:(F)"
      Log "INFO VM account ${vmAccount} resolves to $sid"
    } else {
      Log "WARN VM account ${vmAccount} could not be resolved on this host"
    }
  }

  # Always grant SYSTEM and Administrators
  $grants += "SYSTEM:(F)"
  $grants += "Administrators:(F)"

  Grant-Permissions -Path $Path -GrantStrings $grants
  Log "DONE processed $Path"
}

# Main logic
try {
  if ($VhdListCsv) {
    if (-not (Test-Path $VhdListCsv)) { throw "VhdListCsv not found: $VhdListCsv" }
    Log "MODE CSV list $VhdListCsv"
    $rows = Import-Csv -Path $VhdListCsv
    foreach ($r in $rows) {
      $p = $r.Path
      $id = $null
      if ($r.PSObject.Properties.Name -contains 'VMId') { $id = $r.VMId }
      Process-Vhd -Path $p -VmId $id
    }
  } elseif ($VhdFolder) {
    if (-not (Test-Path $VhdFolder)) { throw "VhdFolder not found: $VhdFolder" }
    Log "MODE Folder $VhdFolder"
    $files = Get-ChildItem -Path $VhdFolder -Recurse -File -Include *.vhd,*.vhdx -ErrorAction SilentlyContinue
    foreach ($f in $files) {
      Process-Vhd -Path $f.FullName -VmId $null
    }
  } else {
    Log "MODE Enumerate VMs on host"
    $vms = Get-VM -ErrorAction Stop
    foreach ($vm in $vms) {
      $vmId = $vm.Id.Guid.ToString()
      $vmName = $vm.Name
      Log "Processing VM $vmName $vmId"
      $disks = Get-VMHardDiskDrive -VMName $vmName -ErrorAction SilentlyContinue
      foreach ($d in $disks) {
        $path = $d.Path
        if (-not $path) {
          Log "SKIP VM $vmName disk has no path"
          continue
        }
        Process-Vhd -Path $path -VmId $vmId
      }
    }
  }
} catch {
  Log "FATAL ERROR: $_"
}

Log "Script finished"