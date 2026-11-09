@echo off
rem Saves the database to the "backups" folder. Runs daily automatically.
rem Backups older than 30 days are deleted.
setlocal
call "%~dp0_common.bat"
if errorlevel 1 exit /b 1

if not exist "backups" mkdir "backups"
for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HHmm"') do set "TS=%%T"
set "FILE=backups\backup-%TS%.sql"

docker compose exec -T db pg_dump -U %POSTGRES_USER% -d %POSTGRES_DB% --clean --if-exists > "%FILE%"
if errorlevel 1 (
  echo [ERROR] Backup failed. Is MyApp running?
  del "%FILE%" >nul 2>&1
  exit /b 1
)

forfiles /p "backups" /m *.sql /d -30 /c "cmd /c del @path" >nul 2>&1
echo Backup saved: %FILE%
exit /b 0
