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

[Code]
var
  PowerShellVersionPage: TOutputMsgMemoWizardPage;
  DevBuildConsentPage: TWizardPage;
  DevBuildConsentCheck: TNewCheckBox;
  RequirementsOK: Boolean;
  NeedsDevBuildConsent: Boolean;

function NormalizeVersionForCompare(const S: String): String;
var
  T: String;
begin
  T := Trim(S);
  if (Length(T) > 0) and ((T[1] = 'v') or (T[1] = 'V')) then
    Delete(T, 1, 1);
  Result := T;
end;

procedure RequireDevBuildConsent(const CurrentVersion, ReferenceVersion, ReferenceLabel: String);
begin
  NeedsDevBuildConsent := True;
  if DevBuildConsentPage <> nil then
  begin
    DevBuildConsentPage.Caption := 'Development build warning';
    DevBuildConsentPage.Description :=
      'This installer appears to be a development build.' + #13#10 +
      'Installer version: ' + CurrentVersion + #13#10 +
      ReferenceLabel + ': ' + ReferenceVersion + #13#10 + #13#10 +
      'This build may be unstable. You must acknowledge before continuing.';
    DevBuildConsentCheck.Checked := False;
  end;
end;

function CompareSemVer(const A, B: String): Integer;
begin
  // Simple comparison - just handle the major version numbers
  if A = B then Result := 0
  else if A > B then Result := 1
  else Result := -1;
end;

procedure WarnIfOutdatedInstaller();
begin
  if CompareSemVer('{#MyAppVersion}', '{#MyAppLatestStableVersion}') > 0 then
    RequireDevBuildConsent(NormalizeVersionForCompare('{#MyAppVersion}'), NormalizeVersionForCompare('{#MyAppLatestStableVersion}'), 'Latest stable release');
end;

function CheckPowerShellVersion(): Boolean;
var
  ResultCode: Integer;
begin
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
  Result := Exec('cmd.exe',
    '/c where 7z.exe >nul 2>&1',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  if Result and (ResultCode = 0) then
  begin
    Result := True;
    exit;
  end;
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

function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
  AppPath: String;
  ModulePath: String;
begin
  Exec('taskkill.exe', '/F /IM powershell.exe /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(1000);
  AppPath := ExpandConstant('{autopf}\PSHVTools');
  if DirExists(AppPath) then
  begin
    RemoveDir(AppPath);
    Sleep(500);
  end;
  ModulePath := ExpandConstant('{commonpf64}\WindowsPowerShell\Modules\pshvtools');
  if DirExists(ModulePath) then
  begin
    RemoveDir(ModulePath);
    Sleep(500);
  end;
  Result := True;
end;

procedure InitializeWizard();
begin
  RequirementsOK := True;
  NeedsDevBuildConsent := False;

  // Create consent page FIRST, before calling WarnIfOutdatedInstaller
  DevBuildConsentPage := CreateCustomPage(wpWelcome, 'Development build warning', '');
  DevBuildConsentCheck := TNewCheckBox.Create(DevBuildConsentPage);
  DevBuildConsentCheck.Parent := DevBuildConsentPage.Surface;
  DevBuildConsentCheck.Left := ScaleX(0);
  DevBuildConsentCheck.Top := ScaleY(8);
  DevBuildConsentCheck.Width := DevBuildConsentPage.SurfaceWidth;
  DevBuildConsentCheck.Caption := 'I understand and want to continue.';

  // NOW check for dev build warning (page exists)
  WarnIfOutdatedInstaller();
  
  // Create requirements check page
  PowerShellVersionPage := CreateOutputMsgMemoPage(DevBuildConsentPage.ID,
    'Checking System Requirements',
    'Please wait while Setup checks if your system meets the requirements.',
    'Setup is checking for PowerShell 5.1+ and Hyper-V...',
    '');
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
  if (DevBuildConsentPage <> nil) and (PageID = DevBuildConsentPage.ID) then
    Result := not NeedsDevBuildConsent;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  HasHyperV: Boolean;
  Has7Zip: Boolean;
  Message: String;
begin
  Result := True;

  // Handle dev build consent page
  if (DevBuildConsentPage <> nil) and (CurPageID = DevBuildConsentPage.ID) then
  begin
    if not DevBuildConsentCheck.Checked then
    begin
      MsgBox('You must check "I understand and want to continue." to proceed.', mbError, MB_OK);
      Result := False;
      exit;
    end;
  end;

  // Handle requirements check page - populate it and run checks
  if (PowerShellVersionPage <> nil) and (CurPageID = PowerShellVersionPage.ID) then
  begin
    PowerShellVersionPage.RichEditViewer.Clear;
    PowerShellVersionPage.RichEditViewer.Lines.Add('Checking PowerShell version...');
    
    if CheckPowerShellVersion() then
      PowerShellVersionPage.RichEditViewer.Lines.Add('  [OK] PowerShell 5.1+ detected')
    else
    begin
      PowerShellVersionPage.RichEditViewer.Lines.Add('  [ERROR] PowerShell 5.1 or later is required!');
      RequirementsOK := False;
    end;

    PowerShellVersionPage.RichEditViewer.Lines.Add('');
    PowerShellVersionPage.RichEditViewer.Lines.Add('Checking Hyper-V...');
    HasHyperV := CheckHyperV();
    
    if HasHyperV then
      PowerShellVersionPage.RichEditViewer.Lines.Add('  [OK] Hyper-V PowerShell module is available')
    else
    begin
      PowerShellVersionPage.RichEditViewer.Lines.Add('  [WARNING] Hyper-V PowerShell module not detected');
      PowerShellVersionPage.RichEditViewer.Lines.Add('  The module will install, but requires Hyper-V to function.');
    end;

    PowerShellVersionPage.RichEditViewer.Lines.Add('');
    PowerShellVersionPage.RichEditViewer.Lines.Add('Checking 7-Zip (7z.exe)...');
    Has7Zip := Check7Zip();
    
    if Has7Zip then
      PowerShellVersionPage.RichEditViewer.Lines.Add('  [OK] 7-Zip detected (7z.exe)')
    else
    begin
      PowerShellVersionPage.RichEditViewer.Lines.Add('  [ERROR] 7-Zip not detected (7z.exe)');
      PowerShellVersionPage.RichEditViewer.Lines.Add('  Please install 7-Zip and ensure 7z.exe is in PATH,');
      PowerShellVersionPage.RichEditViewer.Lines.Add('  or installed in "C:\Program Files\7-Zip\7z.exe".');
      RequirementsOK := False;
    end;

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
        Result := False;
    end;
  end;
end;
