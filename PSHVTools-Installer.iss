; PSHVTools Inno Setup Script
; Creates a professional Windows installer with GUI wizard
; Version 1.0.0

#define MyAppName "PSHVTools"
#define MyAppVersion "1.0.0"
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
AppCopyright=Copyright (C) 2025 {#MyAppPublisher}

; Installation directories
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

; Output settings
OutputDir=dist
OutputBaseFilename=PSHVTools-Setup-{#MyAppVersion}
; SetupIconFile=icon.ico (commented out - optional custom icon)
Compression=lzma2/max
SolidCompression=yes

; Installer UI settings
WizardStyle=modern
WizardSizePercent=100,100
DisableWelcomePage=no
LicenseFile=LICENSE.txt
InfoBeforeFile=QUICKSTART.md

; Privileges and compatibility
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
MinVersion=6.1sp1
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

; Uninstall settings
; UninstallDisplayIcon={app}\icon.ico (commented out - optional custom icon)
UninstallDisplayName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
WelcomeLabel1=Welcome to [name] Setup
WelcomeLabel2=This will install [name/ver] on your computer.%n%nPSHVTools provides PowerShell cmdlets for backing up Hyper-V virtual machines with checkpoint support and 7-Zip compression.%n%nIt is recommended that you close all other applications before continuing.
FinishedHeadingLabel=Completing [name] Setup
FinishedLabelNoIcons=[name] has been successfully installed.%n%nThe hvbak PowerShell module is now available system-wide.
FinishedLabel=[name] has been successfully installed.%n%nThe hvbak PowerShell module is now available system-wide.%n%nYou can now use the following commands:%n  Import-Module hvbak%n  Get-Help Backup-HyperVVM -Full

[CustomMessages]
english.PowerShellCheck=Checking PowerShell version...
english.HyperVCheck=Checking Hyper-V availability...
english.ModuleInstall=Installing PowerShell module...

[Files]
; Module files - install to PowerShell modules directory
Source: "hvbak.ps1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\hvbak"; Flags: ignoreversion
Source: "hvbak.psm1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\hvbak"; Flags: ignoreversion
Source: "hvbak.psd1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\hvbak"; Flags: ignoreversion
Source: "fix-vhd-acl.ps1"; DestDir: "{commonpf64}\WindowsPowerShell\Modules\hvbak"; Flags: ignoreversion

; Documentation files - install to application directory
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion isreadme
Source: "QUICKSTART.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "BUILD_GUIDE.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "PROJECT_SUMMARY.md"; DestDir: "{app}"; Flags: ignoreversion

; Installation scripts (for reference)
Source: "Install-PSHVTools.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Uninstall-PSHVTools.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Start Menu shortcuts
Name: "{group}\{#MyAppName} Documentation"; Filename: "{app}\README.md"
Name: "{group}\Quick Start Guide"; Filename: "{app}\QUICKSTART.md"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"

[Registry]
; Register installation path
Root: HKLM; Subkey: "Software\{#MyAppPublisher}\{#MyAppName}"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\{#MyAppPublisher}\{#MyAppName}"; ValueType: string; ValueName: "Version"; ValueData: "{#MyAppVersion}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\{#MyAppPublisher}\{#MyAppName}"; ValueType: string; ValueName: "ModulePath"; ValueData: "{commonpf64}\WindowsPowerShell\Modules\hvbak"; Flags: uninsdeletekey

[Code]
var
  PowerShellVersionPage: TOutputMsgMemoWizardPage;
  RequirementsOK: Boolean;

function GetPowerShellVersion(): String;
var
  ResultCode: Integer;
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
      Message := Message + '  - Hyper-V (recommended)' + #13#10 + #13#10;
      Message := Message + 'Do you want to abort the installation?';
      
      if MsgBox(Message, mbError, MB_YESNO) = IDYES then
      begin
        Result := False;
      end;
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    // Verify module installation
    Exec('powershell.exe',
      '-NoProfile -NonInteractive -Command "Import-Module hvbak -ErrorAction SilentlyContinue"',
      '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
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
      '-NoProfile -NonInteractive -Command "Remove-Module hvbak -ErrorAction SilentlyContinue"',
      '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;
