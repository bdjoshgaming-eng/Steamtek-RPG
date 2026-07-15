@echo off
setlocal
set "PROJECT_ROOT=%~dp0..\.."
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0find_blender.ps1"`) do set "BLENDER_EXE=%%I"
if not defined BLENDER_EXE exit /b 1
set "BLEND=%PROJECT_ROOT%\blender\character_pipeline\master\Steamtek_CharacterTemplate.blend"
set "RENDERS=%PROJECT_ROOT%\assets\characters\_pipeline_test\renders"
set "SHEET=%PROJECT_ROOT%\assets\characters\_pipeline_test\production\CDEV_Proxy_walk_8dir.png"
set "META=%PROJECT_ROOT%\assets\characters\_pipeline_test\production\CDEV_Proxy_walk_8dir.json"
set "FRAMES=%PROJECT_ROOT%\assets\characters\_pipeline_test\production\CDEV_Proxy_walk_8dir.tres"
"%BLENDER_EXE%" --background "%BLEND%" --python "%PROJECT_ROOT%\blender\character_pipeline\scripts\render_character_8dir.py" -- --character-id CDEV_Proxy --animation walk --output "%RENDERS%"
if errorlevel 1 exit /b %errorlevel%
py "%PROJECT_ROOT%\tools\character-pipeline\pack_character_sheet.py" "%RENDERS%" "%SHEET%" --character-id CDEV_Proxy --animation walk
if errorlevel 1 exit /b %errorlevel%
py "%PROJECT_ROOT%\tools\character-pipeline\build_godot_spriteframes.py" "%META%" "%FRAMES%" --texture-res-path "res://assets/characters/_pipeline_test/production/CDEV_Proxy_walk_8dir.png" --fps 10
if errorlevel 1 exit /b %errorlevel%
py "%PROJECT_ROOT%\tools\character-pipeline\validate_character_output.py" "%RENDERS%" "%META%" --character-id CDEV_Proxy --animation walk
if errorlevel 1 exit /b %errorlevel%
echo Proxy sheet built at %SHEET%
pause
