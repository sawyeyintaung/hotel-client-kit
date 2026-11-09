@echo off
rem Install the newest version: MyApp's own files from GitHub (git pull),
rem then the newest images.
rem
rem git pull can replace this file, and cmd reads a .bat file line by line
rem while it runs. So the first run copies this file to TEMP and runs the
rem copy; the original can then change safely. A changed update.bat takes
rem effect from the next update.
if /i not "%~1"=="--from-copy" (
  copy /y "%~f0" "%TEMP%\myapp-update.bat" >nul
  call "%TEMP%\myapp-update.bat" --from-copy "%~dp0"
  exit /b
)

title MyApp - Update
set "APPDIR=%~2"
cd /d "%APPDIR%"

rem ---- MyApp's files: scripts and docker-compose.yml ----
where git >nul 2>&1
if errorlevel 1 (
  echo [WARNING] git is not installed, so MyApp's files were not updated.
  goto images
)
if not exist ".git" (
  echo [WARNING] This folder was not set up with git, so MyApp's files were not updated.
  goto images
)
echo Updating MyApp's files...
git pull --ff-only
if errorlevel 1 (
  echo [WARNING] Could not update MyApp's files. Updating the app anyway.
)

:images
call "%APPDIR%_common.bat"
if errorlevel 1 goto fail

echo Backing up your data before updating...
call "%APPDIR%backup.bat"
if errorlevel 1 goto fail

echo Downloading the latest version...
docker compose pull
if errorlevel 1 goto fail

echo Restarting MyApp with the new version...
docker compose up -d
if errorlevel 1 goto fail

rem Remove old versions to free disk space
docker image prune -f >nul

echo.
echo MyApp is up to date!
timeout /t 5 /nobreak >nul
start "" "%APP_URL%"
pause
exit /b 0

:fail
echo.
echo [ERROR] Update failed. Your data is safe. Please send a screenshot to your developer.
pause
exit /b 1
