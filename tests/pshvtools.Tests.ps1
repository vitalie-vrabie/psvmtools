BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot '..\scripts\pshvtools.psd1'
    
    # Check if Hyper-V module is available (may not be on GitHub Actions)
    $hvModuleAvailable = Get-Module -ListAvailable -Name Hyper-V
    
    if (-not $hvModuleAvailable) {
        Write-Warning "Hyper-V module not available - some tests will be skipped"
    }
    
    # Import module without Hyper-V requirement check for CI
    if (Test-Path $ModulePath) {
        $manifest = Import-PowerShellDataFile $ModulePath
        # Module will be imported in tests that need it
    }
}

Describe 'PSHVTools Module' {
    Context 'Module Manifest' {
        It 'Should have a valid module manifest' {
            $ModulePath = Join-Path $PSScriptRoot '..\scripts\pshvtools.psd1'
            { Test-ModuleManifest -Path $ModulePath -ErrorAction Stop } | Should -Not -Throw
        }
        
        It 'Should have the correct version' {
            $versionFile = Join-Path $PSScriptRoot '..\version.json'
            $ModulePath = Join-Path $PSScriptRoot '..\scripts\pshvtools.psd1'
            
            $expectedVersion = (Get-Content $versionFile | ConvertFrom-Json).version
            $manifest = Test-ModuleManifest -Path $ModulePath
            
            $manifest.Version.ToString() | Should -Be $expectedVersion
        }
        
        It 'Should export expected functions' {
            $ModulePath = Join-Path $PSScriptRoot '..\scripts\pshvtools.psd1'
            $manifest = Test-ModuleManifest -Path $ModulePath
            
            $expectedFunctions = @(
                'Invoke-VMBackup',
                'Repair-VhdAcl',
                'Restore-VMBackup',
                'Restore-OrphanedVMs',
                'Remove-GpuPartitions',
                'Clone-VM',
                'Test-PSHVToolsEnvironment',
                'Get-PSHVToolsConfig',
                'Set-PSHVToolsConfig',
                'Reset-PSHVToolsConfig',
                'Show-PSHVToolsConfig'
            )
            
            foreach ($func in $expectedFunctions) {
                $manifest.ExportedFunctions.Keys | Should -Contain $func
            }
        }
        
        It 'Should export expected aliases' {
            $ModulePath = Join-Path $PSScriptRoot '..\scripts\pshvtools.psd1'
            $manifest = Test-ModuleManifest -Path $ModulePath
            
            $expectedAliases = @(
                'hvbak',
                'hv-bak',
                'fix-vhd-acl',
                'hvrestore',
                'hvrecover',
                'nogpup',
                'hvclone',
                'hv-clone',
                'hvhealth',
                'hv-health'
            )
            
            foreach ($alias in $expectedAliases) {
                $manifest.ExportedAliases.Keys | Should -Contain $alias
            }
        }
    }
    
    Context 'Module Files' {
        It 'Should have main module file' {
            $moduleFile = Join-Path $PSScriptRoot '..\scripts\pshvtools.psm1'
            Test-Path $moduleFile | Should -Be $true
        }
        
        It 'Should have config module file' {
            $configFile = Join-Path $PSScriptRoot '..\scripts\PSHVTools.Config.psm1'
            Test-Path $configFile | Should -Be $true
        }
        
        It 'Should have health check script' {
            $healthFile = Join-Path $PSScriptRoot '..\scripts\Test-PSHVToolsEnvironment.ps1'
            Test-Path $healthFile | Should -Be $true
        }
    }
    
    Context 'Version Consistency' {
        It 'Should have consistent versions across all files' {
            $versionCheckScript = Join-Path $PSScriptRoot 'Test-VersionConsistency.ps1'
            { & $versionCheckScript } | Should -Not -Throw
        }
    }
    
    Context 'Documentation' -Skip:(-not (Get-Module -ListAvailable -Name Hyper-V)) {
        BeforeAll {
            $ModulePath = Join-Path $PSScriptRoot '..\scripts\pshvtools.psd1'
            Import-Module $ModulePath -Force -ErrorAction SilentlyContinue
        }
        
        It 'Invoke-VMBackup should have help documentation' {
            $help = Get-Help Invoke-VMBackup -ErrorAction SilentlyContinue
            if ($help) {
                $help.Synopsis | Should -Not -BeNullOrEmpty
                $help.Description | Should -Not -BeNullOrEmpty
            }
        }
        
        AfterAll {
            Remove-Module pshvtools -Force -ErrorAction SilentlyContinue
        }
    }
}

AfterAll {
    Remove-Module pshvtools -Force -ErrorAction SilentlyContinue
}
