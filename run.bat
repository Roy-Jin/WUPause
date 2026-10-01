@echo off

set "SCRIPTNAME=main.ps1"
cd /d "%~dp0"

if not exist "%SCRIPTNAME%" (
    echo [ERR] File not found: "%SCRIPTNAME%"
    echo        Please put it in the same folder as this bat.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPTNAME%"

if errorlevel 1 (
    echo.
    echo [ERR] Script exited with an error.
    pause
)