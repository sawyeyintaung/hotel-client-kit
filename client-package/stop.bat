@echo off
title MyApp - Stop
call "%~dp0_common.bat"
if errorlevel 1 goto fail

rem Stops the app. Your data is kept.
docker compose down
if errorlevel 1 goto fail

echo MyApp has been stopped. Your data is safe.
echo Double-click the "MyApp" desktop shortcut to start it again.
pause
exit /b 0

:fail
echo [ERROR] Could not stop MyApp. Please send a screenshot to your developer.
pause
exit /b 1
