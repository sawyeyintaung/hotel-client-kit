@echo off
rem Shared helper: loads .env and makes sure Docker is running.
rem Called by the other scripts. Do not run this file directly.

cd /d "%~dp0"

if not exist ".env" (
  echo [ERROR] The .env file is missing from this folder.
  exit /b 1
)
for /f "usebackq eol=# tokens=1,* delims==" %%A in (".env") do set "%%A=%%B"

where docker >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Docker is not installed. Please run install.bat first.
  exit /b 1
)

docker info >nul 2>&1
if not errorlevel 1 exit /b 0

echo Starting Docker, please wait. This can take 1-2 minutes...
if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"

set /a _tries=0
:waitdocker
ping -n 6 127.0.0.1 >nul
docker info >nul 2>&1
if not errorlevel 1 (
  echo Docker is ready.
  exit /b 0
)
set /a _tries+=1
if %_tries% lss 48 goto waitdocker

echo [ERROR] Docker did not start. Open "Docker Desktop" from the Start menu,
echo wait until it says "Engine running", then try again.
exit /b 1
