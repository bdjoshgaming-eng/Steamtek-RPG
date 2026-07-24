@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Run_Steamtek_Environment_Intake.ps1" %*
if errorlevel 1 (
  echo.
  echo The intake pipeline stopped. Review the message above.
  pause
  exit /b 1
)
echo.
echo Steamtek intake action completed.
pause
