@echo off
title MyApp - Start
call "%~dp0_common.bat"
if errorlevel 1 goto fail

docker compose up -d
if errorlevel 1 goto fail

start "" "%APP_URL%"
exit /b 0

:fail
echo.
echo [ERROR] MyApp could not start. Please send a screenshot to your developer.
pause
exit /b 1
