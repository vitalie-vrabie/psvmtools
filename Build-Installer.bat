@echo off
REM Build-Installer.bat
REM Builds PSHVTools installer package (replaces Build-WixInstaller.bat)
REM This script uses MSBuild instead of WiX Toolset

setlocal enabledelayedexpansion

echo.
echo ========================================
echo   PSHVTools Installer Builder
echo   MSBuild-based (No WiX required!)
echo ========================================
echo.

REM Get script directory
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM Check for MSBuild
echo Checking for MSBuild...

set "MSBUILD_PATH="

REM Try to find MSBuild via vswhere (Visual Studio 2017+)
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" (
    for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe`) do (
        set "MSBUILD_PATH=%%i"
        goto :msbuild_found
    )
)

REM Try common MSBuild locations
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" (
    set "MSBUILD_PATH=%ProgramFiles%\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
    goto :msbuild_found
)
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe" (
    set "MSBUILD_PATH=%ProgramFiles%\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"
    goto :msbuild_found
)
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe" (
    set "MSBUILD_PATH=%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
    goto :msbuild_found
)

REM Try .NET SDK MSBuild
where dotnet >nul 2>&1
if !errorlevel! equ 0 (
    set "MSBUILD_PATH=dotnet msbuild"
    goto :msbuild_found
)

REM MSBuild not found
echo.
echo [ERROR] MSBuild not found!
echo.
echo Please install one of the following:
echo - Visual Studio 2022 (any edition)
echo - .NET SDK 6.0 or later
echo.
exit /b 1

:msbuild_found
echo   [OK] Found MSBuild: !MSBUILD_PATH!
echo.

REM Build installer package with MSBuild
echo Building installer package...
echo.

"!MSBUILD_PATH!" "%SCRIPT_DIR%\PSHVTools.csproj" /t:Package /p:Configuration=Release /v:minimal

if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Build failed with exit code: !errorlevel!
    exit /b !errorlevel!
)

echo.
echo ========================================
echo   Build Successful!
echo ========================================
echo.

REM Display output
if exist "%SCRIPT_DIR%\dist\PSHVTools-Setup-1.0.0.zip" (
    echo Installer Package Created:
    for %%A in ("%SCRIPT_DIR%\dist\PSHVTools-Setup-1.0.0.zip") do set "FILE_SIZE=%%~zA"
    set /a "FILE_SIZE_KB=!FILE_SIZE! / 1024"
    echo   File: dist\PSHVTools-Setup-1.0.0.zip
    echo   Size: !FILE_SIZE_KB! KB
    echo.
    echo Also available:
    echo   Folder: dist\PSHVTools-Setup-1.0.0\
    echo   Source ZIP: release\PSHVTools-v1.0.0.zip
    echo.
)

echo ========================================
echo   Installation Instructions
echo ========================================
echo.
echo For users:
echo   1. Extract PSHVTools-Setup-1.0.0.zip
echo   2. Right-click Install.ps1
echo   3. Select "Run with PowerShell" as Administrator
echo.
echo Or command line:
echo   powershell -ExecutionPolicy Bypass -File Install.ps1
echo.
echo Silent install:
echo   powershell -ExecutionPolicy Bypass -File Install.ps1 -Silent
echo.
echo Uninstall:
echo   powershell -ExecutionPolicy Bypass -File Install.ps1 -Uninstall
echo.

exit /b 0
