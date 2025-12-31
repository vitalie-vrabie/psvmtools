@echo off
REM Build-InnoSetupInstaller.bat
REM Builds the EXE installer using Inno Setup

setlocal enabledelayedexpansion

echo.
echo ========================================
echo   PSHVTools Inno Setup Installer Builder
echo   Creates Professional GUI Wizard EXE
echo ========================================
echo.

REM Get script directory
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM Check for Inno Setup
echo Checking for Inno Setup...

set "ISCC_PATH="

REM Try common Inno Setup locations
if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" (
    set "ISCC_PATH=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
    goto :inno_found
)
if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" (
    set "ISCC_PATH=%ProgramFiles%\Inno Setup 6\ISCC.exe"
    goto :inno_found
)
if exist "%ProgramFiles(x86)%\Inno Setup 5\ISCC.exe" (
    set "ISCC_PATH=%ProgramFiles(x86)%\Inno Setup 5\ISCC.exe"
    goto :inno_found
)

REM Try to find in PATH
where ISCC.exe >nul 2>&1
if !errorlevel! equ 0 (
    for /f "delims=" %%i in ('where ISCC.exe') do (
        set "ISCC_PATH=%%i"
        goto :inno_found
    )
)

REM Inno Setup not found
echo.
echo [ERROR] Inno Setup not found!
echo.
echo Please install Inno Setup 6 from:
echo https://jrsoftware.org/isdl.php
echo.
echo Or use WinGet: winget install JRSoftware.InnoSetup
echo Or use Chocolatey: choco install innosetup
exit /b 1

:inno_found
echo   [OK] Found Inno Setup: !ISCC_PATH!
echo.

REM Validate required files
echo Validating files...

set "MISSING_FILES="

if not exist "%SCRIPT_DIR%\hvbak.ps1" (
    echo   [MISSING] hvbak.ps1
    set "MISSING_FILES=1"
) else (
    echo   [OK] hvbak.ps1
)

if not exist "%SCRIPT_DIR%\pshvtools.psm1" (
    echo   [MISSING] pshvtools.psm1
    set "MISSING_FILES=1"
) else (
    echo   [OK] pshvtools.psm1
)

if not exist "%SCRIPT_DIR%\pshvtools.psd1" (
    echo   [MISSING] pshvtools.psd1
    set "MISSING_FILES=1"
) else (
    echo   [OK] pshvtools.psd1
)

if not exist "%SCRIPT_DIR%\fix-vhd-acl.ps1" (
    echo   [MISSING] fix-vhd-acl.ps1
    set "MISSING_FILES=1"
) else (
    echo   [OK] fix-vhd-acl.ps1
)

if not exist "%SCRIPT_DIR%\QUICKSTART.md" (
    echo   [MISSING] QUICKSTART.md
    set "MISSING_FILES=1"
) else (
    echo   [OK] QUICKSTART.md
)

if not exist "%SCRIPT_DIR%\PSHVTools-Installer.iss" (
    echo   [MISSING] PSHVTools-Installer.iss
    set "MISSING_FILES=1"
) else (
    echo   [OK] PSHVTools-Installer.iss
)

if not exist "%SCRIPT_DIR%\LICENSE.txt" (
    echo   [MISSING] LICENSE.txt
    set "MISSING_FILES=1"
) else (
    echo   [OK] LICENSE.txt
)

if defined MISSING_FILES (
    echo.
    echo [ERROR] Required files are missing!
    exit /b 1
)

REM Create dist directory if it doesn't exist
if not exist "%SCRIPT_DIR%\dist" (
    mkdir "%SCRIPT_DIR%\dist"
    echo Created dist directory
)

REM Check for icon file (optional)
if not exist "%SCRIPT_DIR%\icon.ico" (
    echo.
    echo [NOTE] icon.ico not found, will use default Inno Setup icon
    echo [NOTE] You can add a custom icon.ico file to customize the installer
    echo.
)

REM Build with Inno Setup
echo Building EXE installer...
echo.

"!ISCC_PATH!" "%SCRIPT_DIR%\PSHVTools-Installer.iss"

if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Inno Setup compilation failed with exit code: !errorlevel!
    exit /b !errorlevel!
)

REM Success!
echo.
echo ========================================
echo   EXE Installer Build Successful!
echo ========================================

REM Keep this in sync with #define MyAppVersion in PSHVTools-Installer.iss
set "APP_VERSION=1.0.1"

set "EXE_FILE=%SCRIPT_DIR%\dist\PSHVTools-Setup-%APP_VERSION%.exe"

if exist "%EXE_FILE%" (
    for %%A in ("%EXE_FILE%") do set "FILE_SIZE=%%~zA"
    set /a "FILE_SIZE_KB=!FILE_SIZE! / 1024"
    set /a "FILE_SIZE_MB=!FILE_SIZE! / 1048576"

    echo.
    echo Output:
    echo   File: dist\PSHVTools-Setup-%APP_VERSION%.exe
    echo   Size: !FILE_SIZE_MB! MB (!FILE_SIZE_KB! KB)
    echo.
    echo Features:
    echo   - Professional GUI wizard
    echo   - System requirements check
    echo   - PowerShell version validation
    echo   - Hyper-V availability check
    echo   - Modern Windows installer UI
    echo   - Start Menu shortcuts
    echo   - Uninstaller included
    echo   - Add/Remove Programs integration
)

echo.
echo ========================================
echo   Installation Instructions
echo ========================================
echo.
echo For end users:
echo   1. Double-click PSHVTools-Setup-%APP_VERSION%.exe
echo   2. Follow the installation wizard
echo   3. Done!
echo.
echo Silent installation:
echo   PSHVTools-Setup-%APP_VERSION%.exe /VERYSILENT /NORESTART

echo.
echo Silent with log:
echo   PSHVTools-Setup-%APP_VERSION%.exe /VERYSILENT /NORESTART /LOG="install.log"
echo.
echo Uninstall:
echo   - Use Add/Remove Programs
echo   - Or use Start Menu uninstaller
echo   - Or run: unins000.exe from installation folder
echo.

exit /b 0
