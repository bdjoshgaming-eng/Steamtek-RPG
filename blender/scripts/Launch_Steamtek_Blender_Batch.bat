@echo off
setlocal
set "BLENDER=C:\Program Files\Blender Foundation\Blender 4.5\blender.exe"
if not exist "%BLENDER%" (
  echo Blender 4.5 LTS was not found at:
  echo %BLENDER%
  pause
  exit /b 2
)
if "%~1"=="" (
  echo Drag a reviewed Blender builder manifest JSON onto this file.
  pause
  exit /b 2
)
"%BLENDER%" --background --python "%~dp0Steamtek_Batch_Build.py" -- --manifest "%~1"
set EXIT_CODE=%ERRORLEVEL%
echo.
pause
exit /b %EXIT_CODE%
