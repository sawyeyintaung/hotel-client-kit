@echo off
title MyApp - Update
call "%~dp0_common.bat"
if errorlevel 1 goto fail

echo Backing up your data before updating...
call "%~dp0backup.bat"
if errorlevel 1 goto fail

echo Downloading the latest version...
echo %GHCR_TOKEN%| docker login ghcr.io -u %GHCR_USER% --password-stdin >nul
if errorlevel 1 goto fail
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
