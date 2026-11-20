@echo off
setlocal

cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"

if errorlevel 1 (
    echo.
    echo [ERROR] Setup failed with code %errorlevel%
    pause
    exit /b %errorlevel%
)

echo.
echo [OK] Setup finished.
pause