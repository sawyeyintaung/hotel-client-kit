@echo off
rem Windows version of release.sh.  Usage:  release.bat 1.0.0
setlocal
if "%~1"=="" (echo Usage: release.bat 1.0.0 & exit /b 1)
set "VERSION=%~1"

rem ---- EDIT THESE ----
set "OWNER=sawyeyintaung"
set "FRONTEND_DIR=%USERPROFILE%\Documents\Github\Personal\hotel-frontend-next"
set "BACKEND_DIR=%USERPROFILE%\Documents\Github\Personal\hotel-backend"
rem --------------------

set "REG=ghcr.io/%OWNER%"

echo ==^> Building frontend %VERSION%
docker buildx build --platform linux/amd64 -t %REG%/hotel-frontend:%VERSION% -t %REG%/hotel-frontend:latest --push "%FRONTEND_DIR%" || exit /b 1

echo ==^> Building backend %VERSION%
docker buildx build --platform linux/amd64 -t %REG%/hotel-backend:%VERSION% -t %REG%/hotel-backend:latest --push "%BACKEND_DIR%" || exit /b 1

echo ==^> Done. Pushed %VERSION% and latest. Client can now run update.bat
