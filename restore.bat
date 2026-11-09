@echo off
title MyApp - Restore backup
rem Usage: drag a .sql file from the "backups" folder onto this file.
setlocal
call "%~dp0_common.bat"
if errorlevel 1 goto fail

if "%~1"=="" (
  echo To restore, drag a backup file from the "backups" folder
  echo and drop it onto restore.bat.
  pause
  exit /b 1
)

echo WARNING: This replaces ALL current data with the backup:
echo   %~nx1
set /p "OK=Type YES to continue: "
if /i not "%OK%"=="YES" (
  echo Cancelled. Nothing was changed.
  pause
  exit /b 0
)

docker compose exec -T db psql -U %POSTGRES_USER% -d %POSTGRES_DB% -q < "%~1"
if errorlevel 1 goto fail

docker compose restart backend >nul
echo Restore complete.
pause
exit /b 0

:fail
echo [ERROR] Restore failed. Please send a screenshot to your developer.
pause
exit /b 1
