@echo off
setlocal
cd /d "%~dp0"

:MENU
cls
echo ===================================================
echo        LOCAL CLAUDE CODE + OLLAMA
echo ===================================================
echo.
echo  [1] Setup (Download components ^& install .venv)
echo  [2] Start Web UI (Open in browser)
echo  [3] Start Console (In terminal)
echo  [4] Edit Config (Open config.jsonc)
echo  [5] Exit
echo.
echo ===================================================
set /p choice="Select action (1-5): "

if "%choice%"=="1" goto SETUP
if "%choice%"=="2" goto WEBUI
if "%choice%"=="3" goto CONSOLE
if "%choice%"=="4" goto EDITCONFIG
if "%choice%"=="5" exit
goto MENU

:SETUP
cls
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start_setup.ps1"
pause
goto MENU

:WEBUI
cls
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start_web_ui.ps1"
pause
goto MENU

:CONSOLE
cls
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start_console.ps1"
pause
goto MENU

:EDITCONFIG
cls
notepad "%~dp0config\config.jsonc"
goto MENU