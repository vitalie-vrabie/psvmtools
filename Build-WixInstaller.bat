@echo off
REM Build-WixInstaller.bat
REM Builds the MSI installer using WiX Toolset

setlocal enabledelayedexpansion

REM Set output path (default to .\dist)
set "OUTPUT_PATH=.\dist"
if not "%~1"=="" set "OUTPUT_PATH=%~1"

echo.
echo ========================================
echo   PSHVTools MSI Installer Builder
echo ========================================
echo.

REM Get script directory
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM Check for WiX Toolset
echo Checking for WiX Toolset...

set "WIX_PATH="

REM Check common installation paths
if exist "%ProgramFiles%\WiX Toolset v3.11\bin\candle.exe" (
    set "WIX_PATH=%ProgramFiles%\WiX Toolset v3.11\bin"
    goto :wix_found
)
if exist "%ProgramFiles(x86)%\WiX Toolset v3.11\bin\candle.exe" (
    set "WIX_PATH=%ProgramFiles(x86)%\WiX Toolset v3.11\bin"
    goto :wix_found
)
if exist "%ProgramFiles%\WiX Toolset v3.14\bin\candle.exe" (
    set "WIX_PATH=%ProgramFiles%\WiX Toolset v3.14\bin"
    goto :wix_found
)
if exist "%ProgramFiles(x86)%\WiX Toolset v3.14\bin\candle.exe" (
    set "WIX_PATH=%ProgramFiles(x86)%\WiX Toolset v3.14\bin"
    goto :wix_found
)
if not "%WIX%"=="" (
    if exist "%WIX%bin\candle.exe" (
        set "WIX_PATH=%WIX%bin"
        goto :wix_found
    )
)

REM Try to find in PATH
where candle.exe >nul 2>&1
if !errorlevel! equ 0 (
    for /f "delims=" %%i in ('where candle.exe') do (
        set "WIX_PATH=%%~dpi"
        if "!WIX_PATH:~-1!"=="\" set "WIX_PATH=!WIX_PATH:~0,-1!"
        goto :wix_found
    )
)

REM WiX not found
echo.
echo [ERROR] WiX Toolset not found!
echo.
echo Please install WiX Toolset v3.11 or later from:
echo https://wixtoolset.org/releases/
echo.
echo Or use WinGet: winget install WiXToolset.WiXToolset
echo Or use Chocolatey: choco install wixtoolset
exit /b 1

:wix_found
echo   [OK] Found WiX Toolset at: %WIX_PATH%

REM Create output directory
if not exist "%OUTPUT_PATH%" (
    mkdir "%OUTPUT_PATH%"
    echo Created output directory: %OUTPUT_PATH%
)

REM Validate required files
echo.
echo Validating files...

set "MISSING_FILES="

if not exist "%SCRIPT_DIR%\hvbak.ps1" (
    echo   [MISSING] hvbak.ps1
    set "MISSING_FILES=1"
) else (
    echo   [OK] hvbak.ps1
)

if not exist "%SCRIPT_DIR%\hvbak.psm1" (
    echo   [MISSING] hvbak.psm1
    set "MISSING_FILES=1"
) else (
    echo   [OK] hvbak.psm1
)

if not exist "%SCRIPT_DIR%\hvbak.psd1" (
    echo   [MISSING] hvbak.psd1
    set "MISSING_FILES=1"
) else (
    echo   [OK] hvbak.psd1
)

if not exist "%SCRIPT_DIR%\QUICKSTART.md" (
    echo   [MISSING] QUICKSTART.md
    set "MISSING_FILES=1"
) else (
    echo   [OK] QUICKSTART.md
)

if not exist "%SCRIPT_DIR%\PSHVTools-Installer.wxs" (
    echo   [MISSING] PSHVTools-Installer.wxs
    set "MISSING_FILES=1"
) else (
    echo   [OK] PSHVTools-Installer.wxs
)

REM Check for license file
if not exist "%SCRIPT_DIR%\License.rtf" (
    echo.
    echo [ERROR] License.rtf not found!
    echo Please ensure License.rtf exists in the project root.
    set "MISSING_FILES=1"
) else (
    echo   [OK] License.rtf
)

if defined MISSING_FILES (
    echo.
    echo [ERROR] Required files are missing!
    exit /b 1
)

REM Check for icon file
if not exist "%SCRIPT_DIR%\icon.ico" (
    echo.
    echo [NOTE] icon.ico not found, using default Windows icon
)

REM Build with WiX
echo.
echo Building MSI installer...

set "WXS_FILE=%SCRIPT_DIR%\PSHVTools-Installer.wxs"
set "WIXOBJ_FILE=%OUTPUT_PATH%\PSHVTools-Installer.wixobj"
set "MSI_FILE=%OUTPUT_PATH%\PSHVTools-Setup-1.0.0.msi"

REM Step 1: Compile with candle.exe
echo   Step 1/2: Compiling WXS to WIXOBJ...

"%WIX_PATH%\candle.exe" -nologo -out "%WIXOBJ_FILE%" "%WXS_FILE%"
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Candle.exe failed with exit code: !errorlevel!
    exit /b !errorlevel!
)

echo     [OK] Compilation successful

REM Step 2: Link with light.exe
echo   Step 2/2: Linking to MSI...

"%WIX_PATH%\light.exe" -nologo -ext WixUIExtension -cultures:en-us -out "%MSI_FILE%" "%WIXOBJ_FILE%"
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Light.exe failed with exit code: !errorlevel!
    exit /b !errorlevel!
)

echo     [OK] Linking successful

REM Cleanup intermediate files
if exist "%WIXOBJ_FILE%" del /q "%WIXOBJ_FILE%"

REM Success!
echo.
echo ========================================
echo   MSI Build Successful!
echo ========================================

if exist "%MSI_FILE%" (
    for %%A in ("%MSI_FILE%") do set "FILE_SIZE=%%~zA"
    set /a "FILE_SIZE_KB=!FILE_SIZE! / 1024"
    echo.
    echo Output:
    echo   File: %MSI_FILE%
    echo   Size: !FILE_SIZE_KB! KB
)

echo.
echo Installation:
echo   Interactive: Double-click the MSI file
echo   Silent:      msiexec /i PSHVTools-Setup-1.0.0.msi /quiet
echo   Uninstall:   msiexec /x PSHVTools-Setup-1.0.0.msi /quiet
echo.

exit /b 0
