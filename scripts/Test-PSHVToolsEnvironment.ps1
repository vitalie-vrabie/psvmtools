#Requires -Version 5.1
#Requires -Modules Hyper-V

function Test-PSHVToolsEnvironment {
    <#
    .SYNOPSIS
        Validates the PSHVTools environment and prerequisites.
        
    .DESCRIPTION
        Checks all prerequisites required for PSHVTools to function properly:
        - PowerShell version
        - Hyper-V module availability
        - Administrative privileges
        - 7-Zip installation
        - Hyper-V service status
        - Required permissions
        
    .PARAMETER Detailed
        Show detailed information about each check.
        
    .EXAMPLE
        Test-PSHVToolsEnvironment
        
    .EXAMPLE
        Test-PSHVToolsEnvironment -Detailed
    #>
    [CmdletBinding()]
    [Alias('hvhealth', 'hv-health')]
    param(
        [switch]$Detailed
    )
    
    Write-Host "`n?? PSHVTools Environment Health Check`n" -ForegroundColor Cyan
    
    $allPassed = $true
    $checks = @()
    
    # Check 1: PowerShell Version
    Write-Host "Checking PowerShell version..." -NoNewline
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -ge 5 -and $psVersion.Minor -ge 1) {
        Write-Host " ?" -ForegroundColor Green
        $checks += [PSCustomObject]@{
            Check = "PowerShell Version"
            Status = "Pass"
            Value = $psVersion.ToString()
            Required = "5.1 or higher"
        }
    } else {
        Write-Host " ?" -ForegroundColor Red
        $allPassed = $false
        $checks += [PSCustomObject]@{
            Check = "PowerShell Version"
            Status = "Fail"
            Value = $psVersion.ToString()
            Required = "5.1 or higher"
        }
    }
    
    # Check 2: Hyper-V Module
    Write-Host "Checking Hyper-V module..." -NoNewline
    $hvModule = Get-Module -Name Hyper-V -ListAvailable
    if ($hvModule) {
        Write-Host " ?" -ForegroundColor Green
        $checks += [PSCustomObject]@{
            Check = "Hyper-V Module"
            Status = "Pass"
            Value = $hvModule.Version.ToString()
            Required = "Installed"
        }
    } else {
        Write-Host " ?" -ForegroundColor Red
        $allPassed = $false
        $checks += [PSCustomObject]@{
            Check = "Hyper-V Module"
            Status = "Fail"
            Value = "Not found"
            Required = "Installed"
        }
    }
    
    # Check 3: Administrative Privileges
    Write-Host "Checking administrative privileges..." -NoNewline
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        Write-Host " ?" -ForegroundColor Green
        $checks += [PSCustomObject]@{
            Check = "Administrator Rights"
            Status = "Pass"
            Value = "Yes"
            Required = "Required for Hyper-V operations"
        }
    } else {
        Write-Host " ??" -ForegroundColor Yellow
        $checks += [PSCustomObject]@{
            Check = "Administrator Rights"
            Status = "Warning"
            Value = "No"
            Required = "Required for most operations"
        }
    }
    
    # Check 4: 7-Zip Installation
    Write-Host "Checking 7-Zip installation..." -NoNewline
    $7zPaths = @(
        "${env:ProgramFiles}\7-Zip\7z.exe",
        "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
    )
    $7zExe = $7zPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    
    if ($7zExe) {
        Write-Host " ?" -ForegroundColor Green
        $checks += [PSCustomObject]@{
            Check = "7-Zip"
            Status = "Pass"
            Value = $7zExe
            Required = "Required for compression"
        }
    } else {
        Write-Host " ?" -ForegroundColor Red
        $allPassed = $false
        $checks += [PSCustomObject]@{
            Check = "7-Zip"
            Status = "Fail"
            Value = "Not found"
            Required = "Required for compression"
        }
    }
    
    # Check 5: Hyper-V Service
    if ($isAdmin) {
        Write-Host "Checking Hyper-V service..." -NoNewline
        try {
            $hvService = Get-Service -Name vmms -ErrorAction Stop
            if ($hvService.Status -eq 'Running') {
                Write-Host " ?" -ForegroundColor Green
                $checks += [PSCustomObject]@{
                    Check = "Hyper-V Service (vmms)"
                    Status = "Pass"
                    Value = $hvService.Status
                    Required = "Running"
                }
            } else {
                Write-Host " ??" -ForegroundColor Yellow
                $checks += [PSCustomObject]@{
                    Check = "Hyper-V Service (vmms)"
                    Status = "Warning"
                    Value = $hvService.Status
                    Required = "Running"
                }
            }
        } catch {
            Write-Host " ?" -ForegroundColor Red
            $allPassed = $false
            $checks += [PSCustomObject]@{
                Check = "Hyper-V Service (vmms)"
                Status = "Fail"
                Value = "Not found"
                Required = "Hyper-V must be installed"
            }
        }
    }
    
    # Check 6: VM Connectivity (if admin)
    if ($isAdmin) {
        Write-Host "Checking VM connectivity..." -NoNewline
        try {
            $vms = @(Get-VM -ErrorAction Stop)
            Write-Host " ?" -ForegroundColor Green
            $checks += [PSCustomObject]@{
                Check = "VM Connectivity"
                Status = "Pass"
                Value = "$($vms.Count) VMs found"
                Required = "Hyper-V access"
            }
        } catch {
            Write-Host " ?" -ForegroundColor Red
            $allPassed = $false
            $checks += [PSCustomObject]@{
                Check = "VM Connectivity"
                Status = "Fail"
                Value = $_.Exception.Message
                Required = "Hyper-V access"
            }
        }
    }
    
    # Check 7: Module Version
    Write-Host "Checking PSHVTools version..." -NoNewline
    $module = Get-Module -Name pshvtools
    if ($module) {
        Write-Host " ?" -ForegroundColor Green
        $checks += [PSCustomObject]@{
            Check = "PSHVTools Version"
            Status = "Pass"
            Value = $module.Version.ToString()
            Required = "Module loaded"
        }
    } else {
        Write-Host " ??" -ForegroundColor Yellow
        $checks += [PSCustomObject]@{
            Check = "PSHVTools Version"
            Status = "Warning"
            Value = "Not loaded"
            Required = "Import-Module pshvtools"
        }
    }
    
    # Summary
    Write-Host ""
    if ($allPassed) {
        Write-Host "? All critical checks passed!" -ForegroundColor Green
    } else {
        Write-Host "? Some checks failed. See details below." -ForegroundColor Red
    }
    
    if ($Detailed) {
        Write-Host "`nDetailed Results:" -ForegroundColor Cyan
        $checks | Format-Table -AutoSize
    }
    
    # Recommendations
    $failedChecks = $checks | Where-Object { $_.Status -eq 'Fail' }
    if ($failedChecks) {
        Write-Host "`n?? Recommendations:" -ForegroundColor Yellow
        
        if ($failedChecks | Where-Object { $_.Check -eq 'Hyper-V Module' }) {
            Write-Host "   • Install Hyper-V: Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All" -ForegroundColor Gray
        }
        
        if ($failedChecks | Where-Object { $_.Check -eq '7-Zip' }) {
            Write-Host "   • Install 7-Zip: https://www.7-zip.org/download.html" -ForegroundColor Gray
            Write-Host "   • Or use Chocolatey: choco install 7zip" -ForegroundColor Gray
        }
        
        if ($failedChecks | Where-Object { $_.Check -eq 'Administrator Rights' }) {
            Write-Host "   • Run PowerShell as Administrator for Hyper-V operations" -ForegroundColor Gray
        }
        
        Write-Host ""
    }
    
    return $allPassed
}

Export-ModuleMember -Function Test-PSHVToolsEnvironment -Alias @('hvhealth', 'hv-health')
