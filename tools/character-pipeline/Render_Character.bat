@echo off
setlocal

if "%~3"=="" goto :usage

set "PROJECT_ROOT=%~dp0..\.."
set "BLEND=%~f1"
set "CHARACTER_ID=%~2"
set "ANIMATION=%~3"
set "FRAME_START=%~4"
set "FRAME_END=%~5"

if not exist "%BLEND%" (
  echo ERROR: Blender character file not found: %BLEND%
  exit /b 1
)

for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0find_blender.ps1"`) do set "BLENDER_EXE=%%I"
if not defined BLENDER_EXE exit /b 1

set "CHARACTER_ROOT=%PROJECT_ROOT%\assets\characters\%CHARACTER_ID%"
set "RENDERS=%CHARACTER_ROOT%\renders"
set "PRODUCTION=%CHARACTER_ROOT%\production"
set "SHEET=%PRODUCTION%\%CHARACTER_ID%_%ANIMATION%_8dir.png"
set "META=%PRODUCTION%\%CHARACTER_ID%_%ANIMATION%_8dir.json"
set "FRAMES=%PRODUCTION%\%CHARACTER_ID%_%ANIMATION%_8dir.tres"
set "RES_TEXTURE=res://assets/characters/%CHARACTER_ID%/production/%CHARACTER_ID%_%ANIMATION%_8dir.png"

set "FRAME_ARGS="
if not "%FRAME_START%"=="" set "FRAME_ARGS=--frame-start %FRAME_START%"
if not "%FRAME_END%"=="" set "FRAME_ARGS=%FRAME_ARGS% --frame-end %FRAME_END%"

echo.
echo STEAMTEK CHARACTER BUILD
echo Character: %CHARACTER_ID%
echo Animation: %ANIMATION%
echo Blender:   %BLENDER_EXE%
echo.

"%BLENDER_EXE%" --background "%BLEND%" --python "%PROJECT_ROOT%\blender\character_pipeline\scripts\render_character_8dir.py" -- --character-id "%CHARACTER_ID%" --animation "%ANIMATION%" --output "%RENDERS%" %FRAME_ARGS%
if errorlevel 1 exit /b %errorlevel%

py "%PROJECT_ROOT%\tools\character-pipeline\pack_character_sheet.py" "%RENDERS%" "%SHEET%" --character-id "%CHARACTER_ID%" --animation "%ANIMATION%" --target-world-height 100.5
if errorlevel 1 exit /b %errorlevel%

py "%PROJECT_ROOT%\tools\character-pipeline\build_godot_spriteframes.py" "%META%" "%FRAMES%" --texture-res-path "%RES_TEXTURE%" --fps 10
if errorlevel 1 exit /b %errorlevel%

py "%PROJECT_ROOT%\tools\character-pipeline\validate_character_output.py" "%RENDERS%" "%META%" --character-id "%CHARACTER_ID%" --animation "%ANIMATION%"
if errorlevel 1 exit /b %errorlevel%

echo.
echo SUCCESS: %SHEET%
echo GODOT:   %FRAMES%
exit /b 0

:usage
echo Usage:
echo   Render_Character.bat "C:\path\Character.blend" CHARACTER_ID ANIMATION [FRAME_START] [FRAME_END]
echo.
echo Example:
echo   Render_Character.bat "C:\Steamtek\C001.blend" C001_Player walk 1 8
exit /b 2
