; PSHVTools Inno Setup Script
; Creates a professional Windows installer with GUI wizard
; Version 1.0.3

#define MyAppName "PSHVTools"
#define MyAppVersion "1.0.3"
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

; Output settings
OutputDir=..\dist
OutputBaseFilename=PSHVTools-Setup-{#MyAppVersion}
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
Source: "..\scripts\pshvtools.psm1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\pshvtools"; Flags: ignoreversion
Source: "..\scripts\pshvtools.psd1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\pshvtools"; Flags: ignoreversion
Source: "..\scripts\fix-vhd-acl.ps1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\pshvtools"; Flags: ignoreversion
Source: "..\scripts\restore-vmbackup.ps1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\pshvtools"; Flags: ignoreversion
Source: "..\scripts\restore-orphaned-vms.ps1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\pshvtools"; Flags: ignoreversion

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

[Code]
var
  PowerShellVersionPage: TOutputMsgMemoWizardPage;
  RequirementsOK: Boolean;

function GetPowerShellVersion(): String;
begin
  Result := '5.1';  // Assume minimum version if check fails
  // We'll do a simple check in CheckPowerShellVersion instead
end;

function CheckPowerShellVersion(): Boolean;
var
  ResultCode: Integer;
begin
  // Check if PowerShell 5.1+ is available by trying to run a command
  Result := Exec('powershell.exe', 
    '-NoProfile -NonInteractive -Command "if ($PSVersionTable.PSVersion.Major -ge 5) { exit 0 } else { exit 1 }"',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := (ResultCode = 0);
end;

function CheckHyperV(): Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec('powershell.exe', 
    '-NoProfile -NonInteractive -Command "if (Get-Command Get-VM -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }"',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := (ResultCode = 0);
end;

function Check7Zip(): Boolean;
var
  ResultCode: Integer;
begin
  // Check if 7z.exe is available in PATH
  Result := Exec('cmd.exe',
    '/c where 7z.exe >nul 2>&1',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  if Result and (ResultCode = 0) then
  begin
    Result := True;
    exit;
  end;

  // Check common installation locations
  if FileExists(ExpandConstant('{pf}\7-Zip\7z.exe')) then
  begin
    Result := True;
    exit;
  end;

  if FileExists(ExpandConstant('{pf32}\7-Zip\7z.exe')) then
  begin
    Result := True;
    exit;
  end;

  Result := False;
end;

procedure InitializeWizard();
begin
  RequirementsOK := True;
  
  // Create a custom page to show requirements check
  PowerShellVersionPage := CreateOutputMsgMemoPage(wpWelcome,
    'Checking System Requirements',
    'Please wait while Setup checks if your system meets the requirements.',
    'Setup is checking for PowerShell 5.1+ and Hyper-V...',
    '');
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  HasHyperV: Boolean;
  Has7Zip: Boolean;
  Message: String;
begin
  Result := True;

  if CurPageID = wpWelcome then
  begin
    // Show requirements page
    PowerShellVersionPage.RichEditViewer.Clear;

    // Check PowerShell version
    PowerShellVersionPage.RichEditViewer.Lines.Add('Checking PowerShell version...');

    if CheckPowerShellVersion() then
    begin
      PowerShellVersionPage.RichEditViewer.Lines.Add('  [OK] PowerShell 5.1+ detected');
    end
    else
    begin
      PowerShellVersionPage.RichEditViewer.Lines.Add('  [ERROR] PowerShell 5.1 or later is required!');
      RequirementsOK := False;
    end;

    // Check Hyper-V
    PowerShellVersionPage.RichEditViewer.Lines.Add('');
    PowerShellVersionPage.RichEditViewer.Lines.Add('Checking Hyper-V...');
    HasHyperV := CheckHyperV();

    if HasHyperV then
    begin
      PowerShellVersionPage.RichEditViewer.Lines.Add('  [OK] Hyper-V PowerShell module is available');
    end
    else
    begin
      PowerShellVersionPage.RichEditViewer.Lines.Add('  [WARNING] Hyper-V PowerShell module not detected');
      PowerShellVersionPage.RichEditViewer.Lines.Add('  The module will install, but requires Hyper-V to function.');
    end;

    // Check 7-Zip
    PowerShellVersionPage.RichEditViewer.Lines.Add('');
    PowerShellVersionPage.RichEditViewer.Lines.Add('Checking 7-Zip (7z.exe)...');
    Has7Zip := Check7Zip();

    if Has7Zip then
    begin
      PowerShellVersionPage.RichEditViewer.Lines.Add('  [OK] 7-Zip detected (7z.exe)');
    end
    else
    begin
      PowerShellVersionPage.RichEditViewer.Lines.Add('  [ERROR] 7-Zip not detected (7z.exe)');
      PowerShellVersionPage.RichEditViewer.Lines.Add('  Please install 7-Zip and ensure 7z.exe is in PATH,');
      PowerShellVersionPage.RichEditViewer.Lines.Add('  or installed in "C:\\Program Files\\7-Zip\\7z.exe".');
      RequirementsOK := False;
    end;

    // Show summary
    PowerShellVersionPage.RichEditViewer.Lines.Add('');
    if RequirementsOK then
    begin
      PowerShellVersionPage.RichEditViewer.Lines.Add('System requirements check completed successfully!');
      PowerShellVersionPage.RichEditViewer.Lines.Add('Click Next to continue with installation.');
    end
    else
    begin
      PowerShellVersionPage.RichEditViewer.Lines.Add('System requirements check failed!');
      PowerShellVersionPage.RichEditViewer.Lines.Add('Please install the required components and try again.');
      Message := 'Your system does not meet the minimum requirements for PSHVTools.' + #13#10 + #13#10;
      Message := Message + 'Required:' + #13#10;
      Message := Message + '  - PowerShell 5.1 or later' + #13#10;
      Message := Message + '  - 7-Zip (7z.exe in PATH or standard install location)' + #13#10;
      Message := Message + '  - Hyper-V (recommended)' + #13#10 + #13#10;
      Message := Message + 'Do you want to abort the installation?';

      if MsgBox(Message, mbError, MB_YESNO) = IDYES then
      begin
        Result := False;
      end;
    end;
  end;
end;

function VerifyInstalledModule(): Boolean;
var
  ResultCode: Integer;
  PsArgs: String;
  InstallPath: String;
begin
  InstallPath := ExpandConstant('{commonpf64}\\WindowsPowerShell\\Modules\\pshvtools');

  // Minimal verification: ensure files exist and module manifest is readable.
  // Do NOT fail install on script parse/import; those can be impacted by AV/EDR or existing old module state.
  PsArgs :=
    '-NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ' +
    '"$ErrorActionPreference=''Stop''; ' +
    '$p=''' + InstallPath + '''; ' +
    '$files=@(''pshvtools.psd1'',''pshvtools.psm1'',''hvbak.ps1'',''fix-vhd-acl.ps1'',''restore-vmbackup.ps1'',''restore-orphaned-vms.ps1''); ' +
    'foreach($f in $files){ $fp=Join-Path $p $f; if(-not (Test-Path -LiteralPath $fp)){ throw (''Missing file: {0}'' -f $fp) } }; ' +
    'Test-ModuleManifest -Path (Join-Path $p ''pshvtools.psd1'') | Out-Null; exit 0"';

  Result := Exec('powershell.exe', PsArgs, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := Result and (ResultCode = 0);
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
  ModulePath: String;
begin
  if CurStep = ssPostInstall then
  begin
    // Harden: validate installation layout; warn but don't abort on deeper runtime checks.
    if not VerifyInstalledModule() then
    begin
      ModulePath := ExpandConstant('{commonpf64}\\WindowsPowerShell\\Modules\\pshvtools');

      MsgBox('PSHVTools installed, but post-install verification failed.' + #13#10 +
        'This usually indicates missing files or a permissions/AV issue.' + #13#10 + #13#10 +
        'Verify these files exist:' + #13#10 +
        '  ' + ModulePath + '\\pshvtools.psd1' + #13#10 +
        '  ' + ModulePath + '\\restore-vmbackup.ps1' + #13#10 +
        '  ' + ModulePath + '\\restore-orphaned-vms.ps1' + #13#10 + #13#10 +
        'Then run in an elevated PowerShell to diagnose parse errors:' + #13#10 +
        '  $p=""' + ModulePath + '""' + #13#10 +
        '  $tokens=$null; $errors=$null' + #13#10 +
        '  [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $p ""restore-vmbackup.ps1""), [ref]$tokens, [ref]$errors) | Out-Null' + #13#10 +
        '  $errors | Format-List *',
        mbInformation, MB_OK);
    end;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    // Remove module from memory if loaded
    Exec('powershell.exe',
      '-NoProfile -NonInteractive -Command "Remove-Module pshvtools -ErrorAction SilentlyContinue"',
      '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;
