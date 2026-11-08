@echo off
title MyApp - Create the first admin
rem Creates the first admin account on a new install. Refuses once an admin
rem exists; admins make every other account on the Staff page.
setlocal
call "%~dp0_common.bat"
if errorlevel 1 goto fail

set /p "NAME=Username for the admin (for example owner): "
if "%NAME%"=="" goto fail

echo Type a password (8-128 characters). It won't show as you type.
docker compose exec backend npm run -s staff:create-admin -- %NAME%
if errorlevel 1 goto fail

echo.
echo Done. Log in to MyApp as "%NAME%".
pause
exit /b 0

:fail
echo.
echo [ERROR] Could not create the admin. Is MyApp running?
echo Please send a screenshot to your developer.
pause
exit /b 1
