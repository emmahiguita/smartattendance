@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0qa\katalon\Iniciar-Pruebas-Android.ps1" %*
set "testResult=%ERRORLEVEL%"
echo.
echo Codigo de salida: %testResult%
pause
exit /b %testResult%
