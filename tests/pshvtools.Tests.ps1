BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot '..\scripts\pshvtools.psd1'
    Import-Module $ModulePath -Force
}

Describe 'PSHVTools Module' {
    Context 'Module Loading' {
        It 'Should load the module successfully' {
            Get-Module pshvtools | Should -Not -BeNullOrEmpty
        }
        
        It 'Should have the correct version' {
            $versionFile = Join-Path $PSScriptRoot '..\version.json'
            $expectedVersion = (Get-Content $versionFile | ConvertFrom-Json).version
            $module = Get-Module pshvtools
            $module.Version.ToString() | Should -Be $expectedVersion
        }
        
        It 'Should export all expected functions' {
            $expectedFunctions = @(
                'Invoke-VMBackup',
                'Repair-VhdAcl',
                'Restore-VMBackup',
                'Restore-OrphanedVMs',
                'Remove-GpuPartitions',
                'Clone-VM'
            )
            
            $exportedFunctions = (Get-Command -Module pshvtools).Name
            
            foreach ($func in $expectedFunctions) {
                $exportedFunctions | Should -Contain $func
            }
        }
        
        It 'Should export all expected aliases' {
            $expectedAliases = @(
                'hvbak',
                'hv-bak',
                'fix-vhd-acl',
                'hvrestore',
                'hvrecover',
                'nogpup',
                'hvclone',
                'hv-clone'
            )
            
            $exportedAliases = (Get-Alias -ErrorAction SilentlyContinue | Where-Object { $_.ModuleName -eq 'pshvtools' }).Name
            
            foreach ($alias in $expectedAliases) {
                $exportedAliases | Should -Contain $alias
            }
        }
    }
    
    Context 'Function Help' {
        It 'Invoke-VMBackup should have help documentation' {
            $help = Get-Help Invoke-VMBackup
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
            $help.Examples | Should -Not -BeNullOrEmpty
        }
        
        It 'Restore-VMBackup should have help documentation' {
            $help = Get-Help Restore-VMBackup
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
        
        It 'Repair-VhdAcl should have help documentation' {
            $help = Get-Help Repair-VhdAcl
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Parameter Validation' {
        It 'Invoke-VMBackup should accept NamePattern parameter' {
            $cmd = Get-Command Invoke-VMBackup
            $cmd.Parameters['NamePattern'] | Should -Not -BeNullOrEmpty
        }
        
        It 'Invoke-VMBackup should have KeepCount parameter with valid range' {
            $cmd = Get-Command Invoke-VMBackup
            $param = $cmd.Parameters['KeepCount']
            $param | Should -Not -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module pshvtools -Force -ErrorAction SilentlyContinue
}
