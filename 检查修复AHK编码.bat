@echo off
setlocal
cd /d "%~dp0"
powershell -NoLogo -ExecutionPolicy Bypass -File "%~dp0tools\check-fix-ahk-bom.ps1"
echo.
pause
