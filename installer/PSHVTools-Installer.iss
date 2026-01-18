; PSHVTools Inno Setup Script
; Creates a professional Windows installer with GUI wizard
; Version 1.0.11

#define MyAppName "PSHVTools"
#ifndef MyAppVersion
#define MyAppVersion "1.0.11"
#endif
#ifndef MyAppLatestStableVersion
#define MyAppLatestStableVersion "1.0.9"
#endif

#define MyAppPublisher "Vitalie Vrabie"
#define MyAppURL "https://github.com/vitalie-vrabie/pshvtools"
#define MyAppDescription "PowerShell Hyper-V Tools - VM Backup Utilities"

[Setup]
; Basic application information
AppId={{8C5E8F1D-9D4B-4A2C-B6E7-8F3D9C1A5B2E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
AppComments={#MyAppDescription}
AppCopyright=Copyright (C) 2026 {#MyAppPublisher}

; Installation directories
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

; **CRITICAL:** Force overwrite old installation
UsePreviousAppDir=no
; Run uninstall for old version BEFORE installing new one
DisableFinishedPage=no

; Output settings
OutputDir=..\dist
OutputBaseFilename=PSHVTools-Setup
; SetupIconFile=icon.ico (commented out - optional custom icon)
Compression=lzma2/max
SolidCompression=yes

; Installer UI settings
WizardStyle=modern
WizardSizePercent=100,100
DisableWelcomePage=no
LicenseFile=..\LICENSE.txt
InfoBeforeFile=..\QUICKSTART.md

; Privileges and compatibility
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
MinVersion=6.1sp1
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; Uninstall settings
; UninstallDisplayIcon={app}\icon.ico (commented out - optional custom icon)
UninstallDisplayName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
WelcomeLabel1=Welcome to [name] Setup
WelcomeLabel2=This will install [name/ver] on your computer.%n%nPSHVTools provides PowerShell cmdlets for backing up Hyper-V virtual machines with checkpoint support and 7-Zip compression.%n%nIt is recommended that you close all other applications before continuing.
FinishedHeadingLabel=Completing [name] Setup
FinishedLabelNoIcons=[name] has been successfully installed.%n%nThe pshvtools PowerShell module is now available system-wide.
FinishedLabel=[name] has been successfully installed.%n%nThe pshvtools PowerShell module is now available system-wide.%n%nYou can now use the following commands:%n  Import-Module hvbak%n  Get-Help Invoke-VMBackup -Full

[CustomMessages]
english.PowerShellCheck=Checking PowerShell version...
english.HyperVCheck=Checking Hyper-V availability...
english.ModuleInstall=Installing PowerShell module...

[Files]
; Module files - install to PowerShell modules directory
Source: "..\scripts\hvbak.ps1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\pshvtools"; Flags: ignoreversion
Source: "..\scripts\hvcompact.ps1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\pshvtools"; Flags: ignoreversion
Source: "..\scripts\hvfixacl.ps1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\pshvtools"; Flags: ignoreversion
Source: "..\scripts\pshvtools.psm1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\pshvtools"; Flags: ignoreversion
Source: "..\scripts\pshvtools.psd1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\pshvtools"; Flags: ignoreversion
Source: "..\scripts\fix-vhd-acl.ps1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\pshvtools"; Flags: ignoreversion
Source: "..\scripts\restore-vmbackup.ps1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\pshvtools"; Flags: ignoreversion
Source: "..\scripts\restore-orphaned-vms.ps1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\pshvtools"; Flags: ignoreversion
Source: "..\scripts\remove-gpu-partitions.ps1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\pshvtools"; Flags: ignoreversion

; Documentation files - install to application directory
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion isreadme
Source: "..\RELEASE_NOTES.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\QUICKSTART.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\CHANGELOG.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\BUILD_GUIDE.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\PROJECT_SUMMARY.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Start Menu shortcuts
Name: "{group}\{#MyAppName} Documentation"; Filename: "{app}\README.md"
Name: "{group}\Changelog"; Filename: "{app}\CHANGELOG.md"
Name: "{group}\Quick Start Guide"; Filename: "{app}\QUICKSTART.md"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"

[Registry]
; Register installation path
Root: HKLM; Subkey: "Software\{#MyAppPublisher}\{#MyAppName}"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\{#MyAppPublisher}\{#MyAppName}"; ValueType: string; ValueName: "Version"; ValueData: "{#MyAppVersion}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\{#MyAppPublisher}\{#MyAppName}"; ValueType: string; ValueName: "ModulePath"; ValueData: "{commonpf64}\WindowsPowerShell\Modules\pshvtools"; Flags: uninsdeletekey

[Run]
; Clean up old module directory to ensure fresh install
Filename: "powershell.exe"; Parameters: "-NoProfile -Command ""Remove-Item -Path '{commonpf64}\WindowsPowerShell\Modules\pshvtools' -Recurse -Force -ErrorAction SilentlyContinue; exit 0"""; Flags: RunHidden; StatusMsg: "Cleaning up old module files..."
