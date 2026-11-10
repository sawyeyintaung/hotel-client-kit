@echo off
title MyApp - Install
rem This script is in windows\; MyApp's folder is one level up.
set "SCRIPTS=%~dp0"
for %%I in ("%~dp0..") do set "APPDIR=%%~fI\"
cd /d "%APPDIR%"

echo ================================================
echo   MyApp installer
echo ================================================
echo.

rem ---- Step 1: Docker Desktop ----
where docker >nul 2>&1
if errorlevel 1 goto installdocker

rem ---- Step 2: start Docker and load settings ----
call "%SCRIPTS%_common.bat"
if errorlevel 1 goto fail

rem ---- Step 3: download and start the app ----
echo Downloading the app. First time can take several minutes...
docker compose pull
if errorlevel 1 goto fail
docker compose up -d
if errorlevel 1 goto fail

rem ---- Step 4: desktop shortcut + daily backup ----
echo Creating desktop shortcut "MyApp"...
powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop')+'\MyApp.lnk'); $s.TargetPath='%SCRIPTS%start.bat'; $s.WorkingDirectory='%APPDIR%'; $s.Save()"

echo Scheduling a daily database backup at 12:00...
schtasks /create /tn "MyApp Daily Backup" /tr "\"%SCRIPTS%backup.bat\"" /sc daily /st 12:00 /f >nul

echo.
echo ================================================
echo   Installed! Opening MyApp in your browser...
echo   Next time, just double-click "MyApp" on your desktop.
echo ================================================
timeout /t 10 /nobreak >nul
start "" "%APP_URL%"
pause
exit /b 0

:installdocker
echo Docker Desktop is not installed yet. Installing it now.
echo This can take 10-20 minutes. Click "Yes" if Windows asks for permission.
echo.
where winget >nul 2>&1
if errorlevel 1 goto manualdocker
winget install -e --id Docker.DockerDesktop --accept-package-agreements --accept-source-agreements
if errorlevel 1 goto manualdocker
goto afterdocker

:manualdocker
echo Automatic install is not available on this PC.
echo Your browser will open the Docker download page.
echo Download "Docker Desktop for Windows" and install it with the default options.
start "" "https://www.docker.com/products/docker-desktop/"

:afterdocker
echo.
echo ================================================
echo   NEXT STEPS:
echo   1. Restart your computer.
echo   2. Open "Docker Desktop" from the Start menu.
echo   3. Click "Accept" on the terms. You can skip sign-in.
echo   4. Turn on: Settings - General - "Start Docker Desktop when you sign in".
echo   5. Double-click install.bat in the windows folder again.
echo ================================================
pause
exit /b 0

:fail
echo.
echo [ERROR] Something went wrong. Please take a screenshot of this window
echo and send it to your developer.
pause
exit /b 1
