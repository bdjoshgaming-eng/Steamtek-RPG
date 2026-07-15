@echo off
setlocal
cd /d "%~dp0"
where py >nul 2>nul
if %errorlevel%==0 (
  py -c "import PIL" >nul 2>nul || py -m pip install Pillow
  py steamtek_studio.py
) else (
  python -c "import PIL" >nul 2>nul || python -m pip install Pillow
  python steamtek_studio.py
)
if errorlevel 1 pause
