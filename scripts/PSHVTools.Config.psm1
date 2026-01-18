#Requires -Version 5.1

<#
.SYNOPSIS
    Configuration management for PSHVTools.
    
.DESCRIPTION
    Provides functions to read and write user configuration for PSHVTools.
    Configuration is stored in $HOME\.pshvtools\config.json
#>

function Get-PSHVToolsConfigPath {
    $configDir = Join-Path $HOME '.pshvtools'
    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }
    Join-Path $configDir 'config.json'
}

function Get-PSHVToolsConfig {
    <#
    .SYNOPSIS
        Gets the current PSHVTools user configuration.
    #>
    [CmdletBinding()]
    param()
    
    $configPath = Get-PSHVToolsConfigPath
    
    if (Test-Path $configPath) {
        try {
            Get-Content $configPath | ConvertFrom-Json
        } catch {
            Write-Warning "Failed to read config from ${configPath}: $_"
            Get-PSHVToolsDefaultConfig
        }
    } else {
        Get-PSHVToolsDefaultConfig
    }
}

function Get-PSHVToolsDefaultConfig {
    <#
    .SYNOPSIS
        Returns default configuration values.
    #>
    [PSCustomObject]@{
        DefaultBackupPath = Join-Path $HOME 'hvbak-archives'
        DefaultTempPath = Join-Path $env:TEMP 'hvbak'
        DefaultKeepCount = 2
        CompressionThreads = 0  # 0 = auto
        EnableNotifications = $false
        LogPath = $null  # null = no file logging
        Verbose = $false
    }
}

function Set-PSHVToolsConfig {
    <#
    .SYNOPSIS
        Sets PSHVTools user configuration values.
        
    .PARAMETER DefaultBackupPath
        Default backup destination path.
        
    .PARAMETER DefaultTempPath
        Default temporary folder for exports.
        
    .PARAMETER DefaultKeepCount
        Default number of backups to keep per VM.
        
    .PARAMETER CompressionThreads
        Number of threads for 7-Zip compression (0 = auto).
        
    .PARAMETER EnableNotifications
        Enable desktop notifications.
        
    .PARAMETER LogPath
        Path to log file. Use $null to disable file logging.
        
    .EXAMPLE
        Set-PSHVToolsConfig -DefaultBackupPath "D:\Backups" -DefaultKeepCount 5
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$DefaultBackupPath,
        [string]$DefaultTempPath,
        [ValidateRange(1, 100)]
        [int]$DefaultKeepCount,
        [ValidateRange(0, 1024)]
        [int]$CompressionThreads,
        [bool]$EnableNotifications,
        [string]$LogPath,
        [switch]$Verbose
    )
    
    $config = Get-PSHVToolsConfig
    
    if ($PSBoundParameters.ContainsKey('DefaultBackupPath')) {
        $config.DefaultBackupPath = $DefaultBackupPath
    }
    
    if ($PSBoundParameters.ContainsKey('DefaultTempPath')) {
        $config.DefaultTempPath = $DefaultTempPath
    }
    
    if ($PSBoundParameters.ContainsKey('DefaultKeepCount')) {
        $config.DefaultKeepCount = $DefaultKeepCount
    }
    
    if ($PSBoundParameters.ContainsKey('CompressionThreads')) {
        $config.CompressionThreads = $CompressionThreads
    }
    
    if ($PSBoundParameters.ContainsKey('EnableNotifications')) {
        $config.EnableNotifications = $EnableNotifications
    }
    
    if ($PSBoundParameters.ContainsKey('LogPath')) {
        $config.LogPath = $LogPath
    }
    
    if ($PSBoundParameters.ContainsKey('Verbose')) {
        $config.Verbose = $Verbose.IsPresent
    }
    
    $configPath = Get-PSHVToolsConfigPath
    
    if ($PSCmdlet.ShouldProcess($configPath, "Save configuration")) {
        $config | ConvertTo-Json | Out-File $configPath -Encoding UTF8
        Write-Verbose "Configuration saved to: $configPath"
    }
}

function Reset-PSHVToolsConfig {
    <#
    .SYNOPSIS
        Resets PSHVTools configuration to defaults.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    $configPath = Get-PSHVToolsConfigPath
    
    if ($PSCmdlet.ShouldProcess($configPath, "Reset to default configuration")) {
        $defaultConfig = Get-PSHVToolsDefaultConfig
        $defaultConfig | ConvertTo-Json | Out-File $configPath -Encoding UTF8
        Write-Host "? Configuration reset to defaults" -ForegroundColor Green
        $defaultConfig
    }
}

function Show-PSHVToolsConfig {
    <#
    .SYNOPSIS
        Displays the current PSHVTools configuration.
    #>
    [CmdletBinding()]
    param()
    
    $config = Get-PSHVToolsConfig
    $configPath = Get-PSHVToolsConfigPath
    
    Write-Host "`nPSHVTools Configuration" -ForegroundColor Cyan
    Write-Host "Location: $configPath`n" -ForegroundColor Gray
    
    $config | Format-List
}

Export-ModuleMember -Function @(
    'Get-PSHVToolsConfig',
    'Set-PSHVToolsConfig',
    'Reset-PSHVToolsConfig',
    'Show-PSHVToolsConfig'
)
