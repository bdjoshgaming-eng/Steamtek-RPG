@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%tools\Invoke-SteamtekCharacterIntake.ps1" -ProjectRoot "C:\My Game\Steamtek-RPG" -BlenderRoot "C:\Program Files\Blender Foundation\Blender 4.5"
exit /b %errorlevel%
