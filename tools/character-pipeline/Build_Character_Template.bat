@echo off
setlocal
set "PROJECT_ROOT=%~dp0..\.."
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0find_blender.ps1"`) do set "BLENDER_EXE=%%I"
if not defined BLENDER_EXE exit /b 1
echo Using %BLENDER_EXE%
"%BLENDER_EXE%" --background --factory-startup --python "%PROJECT_ROOT%\blender\character_pipeline\scripts\build_character_template.py"
if errorlevel 1 exit /b %errorlevel%
echo Character template built successfully.
pause
