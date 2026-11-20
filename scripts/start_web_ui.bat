@echo off
setlocal
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_web_ui.ps1"

if errorlevel 1 (
    echo.
    echo [ERROR] start_web_ui failed with code %errorlevel%
    pause
    exit /b %errorlevel%
)

pause