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

function TryGetCachedLatestReleaseVersion(var CachedVersion: String): Boolean;
var
  V: String;
begin
  Result := False;
  CachedVersion := '';

  if RegQueryStringValue(HKLM, 'Software\{#MyAppPublisher}\{#MyAppName}', 'LatestReleaseVersion', V) then
  begin
    V := Trim(V);
    if V <> '' then
    begin
      CachedVersion := NormalizeVersionForCompare(V);
      Result := True;
      exit;
    end;
  end;
end;

procedure CacheLatestReleaseVersion(const LatestVersion: String);
begin
  // Best-effort: cache the latest GitHub release version so we can enforce dev-build warnings offline.
  try
    RegWriteStringValue(HKLM, 'Software\{#MyAppPublisher}\{#MyAppName}', 'LatestReleaseVersion', LatestVersion);
  except
    // ignore
  end;
end;

function TryGetInstalledVersion(var InstalledVersion: String): Boolean;
var
  V: String;
begin
  Result := False;
  InstalledVersion := '';

  // Version is written by this installer under HKLM
  if RegQueryStringValue(HKLM, 'Software\{#MyAppPublisher}\{#MyAppName}', 'Version', V) then
  begin
    V := Trim(V);
    if V <> '' then
    begin
      InstalledVersion := NormalizeVersionForCompare(V);
      Result := True;
      exit;
    end;
  end;
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

function ReadSemVerPart(const S: String; var Idx: Integer): Integer;
var
  n: String;
begin
  // Move to first digit
  while (Idx <= Length(S)) and ((S[Idx] < '0') or (S[Idx] > '9')) do
    Idx := Idx + 1;

  // Read digits
  n := '';
  while (Idx <= Length(S)) and (S[Idx] >= '0') and (S[Idx] <= '9') do
  begin
    n := n + S[Idx];
    Idx := Idx + 1;
  end;

  if n = '' then
    Result := 0
  else
    Result := StrToIntDef(n, 0);
end;

function CompareSemVer(const A, B: String): Integer;
var
  aWork: String;
  bWork: String;
  aPart: Integer;
  bPart: Integer;
  i: Integer;
  aIdx: Integer;
  bIdx: Integer;
begin
  // Returns: -1 if A < B, 0 if equal, 1 if A > B
  aWork := NormalizeVersionForCompare(A);
  bWork := NormalizeVersionForCompare(B);

  aIdx := 1;
  bIdx := 1;

  // Compare up to 4 parts (major.minor.patch.build)
  for i := 1 to 4 do
  begin
    aPart := ReadSemVerPart(aWork, aIdx);
    bPart := ReadSemVerPart(bWork, bIdx);
    if aPart < bPart then begin Result := -1; exit; end;
    if aPart > bPart then begin Result := 1; exit; end;
  end;

  Result := 0;
end;

function TryGetLatestReleaseTag(var Tag: String): Boolean;
var
  ResultCode: Integer;
  TmpFile: String;
  PsArgs: String;
  TagAnsi: AnsiString;
begin
  Result := False;
  Tag := '';
  TmpFile := ExpandConstant('{tmp}\\pshvtools_latest_release_tag.txt');
  DeleteFile(TmpFile);

  PsArgs :=
    '-NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ' +
    '"$ErrorActionPreference=''Stop''; ' +
    '$repo=''' + '{#MyAppURL}' + '''; ' +
    '$api=$repo.TrimEnd(''/'') + ''/releases/latest''; ' +
    'try { $r=Invoke-WebRequest -UseBasicParsing -Uri $api -MaximumRedirection 0 -ErrorAction Stop } catch { $r=$_.Exception.Response }; ' +
    'if(-not $r){ exit 2 }; ' +
    '$loc=$r.Headers[''Location'']; if(-not $loc){ exit 3 }; ' +
    '$tag=($loc -split ''/'')[-1]; if([string]::IsNullOrWhiteSpace($tag)){ exit 4 }; ' +
    'Set-Content -LiteralPath ''' + TmpFile + ''' -Value $tag -Encoding ASCII; exit 0"';

  if not Exec('powershell.exe', PsArgs, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    exit;
  if ResultCode <> 0 then
    exit;
  if not LoadStringFromFile(TmpFile, TagAnsi) then
    exit;

  Tag := Trim(String(TagAnsi));
  Result := (Tag <> '');
end;

procedure WarnIfOutdatedInstaller();
var
  LatestTag: String;
  LatestVersion: String;
  CurrentVersion: String;
  Cmp: Integer;
  InstalledVersion: String;
  Resp: Integer;
  CachedLatest: String;
begin
  CurrentVersion := NormalizeVersionForCompare('{#MyAppVersion}');

  // If we already have a cached "latest GitHub release" version, enforce dev-build consent deterministically.
  if TryGetCachedLatestReleaseVersion(CachedLatest) then
  begin
    Cmp := CompareSemVer(CurrentVersion, CachedLatest);
    if Cmp > 0 then
      RequireDevBuildConsent(CurrentVersion, CachedLatest, 'Cached latest GitHub release');
  end;

  // 1) Online check against latest GitHub release (preferred)
  if TryGetLatestReleaseTag(LatestTag) then
  begin
    LatestVersion := NormalizeVersionForCompare(LatestTag);
    if (LatestVersion <> '') then
    begin
      CacheLatestReleaseVersion(LatestVersion);
      Cmp := CompareSemVer(CurrentVersion, LatestVersion);
      if Cmp < 0 then
      begin
        MsgBox(
          'A newer PSHVTools release is available on GitHub.' + #13#10 + #13#10 +
          'Installed version: ' + CurrentVersion + #13#10 +
          'Latest version:    ' + LatestVersion + #13#10 + #13#10 +
          'You can download the latest installer from:' + #13#10 +
          '{#MyAppURL}' + #13#10 + #13#10 +
          'Setup will continue, but you may be installing an outdated version.',
          mbInformation, MB_OK);
      end;
      if Cmp > 0 then
      begin
        RequireDevBuildConsent(CurrentVersion, LatestVersion, 'Latest GitHub release');
      end;
    end;
    exit;
  end;

  // 2) Fallback when offline / GitHub blocked: compare to currently installed version
  if TryGetInstalledVersion(InstalledVersion) then
  begin
    Cmp := CompareSemVer(CurrentVersion, InstalledVersion);
    if Cmp > 0 then
    begin
      RequireDevBuildConsent(CurrentVersion, InstalledVersion, 'Currently installed version');
    end;
    exit;
  end;

  // 3) Last-resort: cannot verify latest release and no installed version known.
  // Require explicit acknowledgement so dev builds never install silently.
  Resp := MsgBox(
    'Version verification unavailable' + #13#10 + #13#10 +
    'Setup could not verify the latest PSHVTools release online (GitHub unreachable) and no prior installed version was found.' + #13#10 + #13#10 +
    'Installer version: ' + CurrentVersion + #13#10 + #13#10 +
    'Agreement required: [ ] I understand and want to continue anyway.' + #13#10 + #13#10 +
    'Click Yes to continue, or No to exit Setup.',
    mbConfirmation, MB_YESNO);
  if Resp <> IDYES then
    Abort;
end;

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
var
  UninstallString: String;
  ResultCode: Integer;
  ModulePath: String;
begin
  RequirementsOK := True;
  NeedsDevBuildConsent := False;

  // Dev-build consent page (shown only when needed)
  DevBuildConsentPage := CreateCustomPage(wpWelcome,
    'Development build warning',
    '');
  DevBuildConsentCheck := TNewCheckBox.Create(DevBuildConsentPage);
  DevBuildConsentCheck.Parent := DevBuildConsentPage.Surface;
  DevBuildConsentCheck.Left := ScaleX(0);
  DevBuildConsentCheck.Top := ScaleY(8);
  DevBuildConsentCheck.Width := DevBuildConsentPage.SurfaceWidth;
  DevBuildConsentCheck.Caption := 'I understand and want to continue.';

  // Deterministic dev-build guard (no network dependency).
  // If this installer version is higher than the last stable release, require explicit consent.
  if CompareSemVer('{#MyAppVersion}', '{#MyAppLatestStableVersion}') > 0 then
    RequireDevBuildConsent(NormalizeVersionForCompare('{#MyAppVersion}'), NormalizeVersionForCompare('{#MyAppLatestStableVersion}'), 'Latest stable release');
  
  // Create a custom page to show requirements check
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

function InitializeSetup(): Boolean;
var
  ModulePath: String;
  AppPath: String;
  ResultCode: Integer;
  i: Integer;
begin
  // **CRITICAL:** Force-clean old PSHVTools installation BEFORE wizard starts
  
  // Kill any PowerShell processes that might have the module loaded
  Exec('taskkill.exe', '/F /IM powershell.exe /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(1000);
  
  // Force-clean the module directory
  ModulePath := ExpandConstant('{commonpf64}\WindowsPowerShell\Modules\pshvtools');
  if DirExists(ModulePath) then
  begin
    // Try multiple times to delete
    for i := 1 to 3 do
    begin
      if RemoveDir(ModulePath) then
        break;
      Sleep(500);
    end;
  end;

  // Force-clean the app installation directory  
  AppPath := ExpandConstant('{autopf}\PSHVTools');
  if DirExists(AppPath) then
  begin
    // Try multiple times to delete
    for i := 1 to 3 do
    begin
      if RemoveDir(AppPath) then
        break;
      Sleep(500);
    end;
  end;
  
  // Clean up Start Menu shortcuts
  try
    RemoveDir(ExpandConstant('{commonprograms}\PSHVTools'));
  except
    // Ignore errors
  end;

  Result := True;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  HasHyperV: Boolean;
  Has7Zip: Boolean;
  Message: String;
begin
  Result := True;

  // Enforce dev-build checkbox agreement
  if (DevBuildConsentPage <> nil) and (CurPageID = DevBuildConsentPage.ID) then
  begin
    if not DevBuildConsentCheck.Checked then
    begin
      MsgBox('You must check "I understand and want to continue." to proceed.', mbError, MB_OK);
      Result := False;
      exit;
    end;
  end;

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
    '$files=@(''pshvtools.psd1'',''pshvtools.psm1'',''hvbak.ps1'',''hvcompact.ps1'',''hvfixacl.ps1'',''fix-vhd-acl.ps1'',''restore-vmbackup.ps1'',''restore-orphaned-vms.ps1'',''remove-gpu-partitions.ps1''); ' +
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
        '  ' + ModulePath + '\\restore-orphaned-vms.ps1' + #13#10 +
        '  ' + ModulePath + '\\remove-gpu-partitions.ps1' + #13#10 + #13#10 +
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
