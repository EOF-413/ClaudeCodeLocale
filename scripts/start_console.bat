@echo off
setlocal

cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_console.ps1"

if errorlevel 1 (
    echo.
    echo [ERROR] Script exited with code %errorlevel%
    pause
    exit /b %errorlevel%
)

pause