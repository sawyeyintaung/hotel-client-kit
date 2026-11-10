#!/bin/bash
# MyApp installer for Mac. The Mac version of install.bat.
# This script is in mac/; MyApp's folder is one level up.
SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"
APPDIR="$(cd "$SCRIPTDIR/.." && pwd)"
cd "$APPDIR" || exit 1
export PATH="/usr/local/bin:/opt/homebrew/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH"

echo "================================================"
echo "  MyApp installer"
echo "================================================"
echo

# ---- Step 1: Docker Desktop ----
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker Desktop is not installed yet."
  if command -v brew >/dev/null 2>&1; then
    echo "Installing it now with Homebrew. Type your Mac password if asked."
    brew install --cask docker-desktop || open "https://www.docker.com/products/docker-desktop/"
  else
    echo "Your browser will open the Docker download page."
    echo "Download \"Docker Desktop for Mac\" (Apple chip or Intel chip, to match"
    echo "this Mac: Apple menu > About This Mac) and drag it into Applications."
    open "https://www.docker.com/products/docker-desktop/"
  fi
  echo
  echo "================================================"
  echo "  NEXT STEPS:"
  echo "  1. Open \"Docker\" from Applications."
  echo "  2. Click \"Accept\" on the terms. You can skip sign-in."
  echo "  3. Turn on: Settings > General > \"Start Docker Desktop when you sign in\"."
  echo "  4. Double-click install.command in the mac folder again."
  echo "================================================"
  read -r -p "Press Return to close."
  exit 0
fi

# ---- Step 2: start Docker and load settings ----
. "$SCRIPTDIR/_common.sh"

# ---- Step 3: download and start the app ----
echo "Downloading the app. First time can take several minutes..."
docker compose pull || fail "Could not download the app."
docker compose up -d || fail "Could not start the app."

# ---- Step 4: desktop shortcut + daily backup ----
echo 'Creating desktop shortcut "MyApp"...'
ln -sf "$SCRIPTDIR/start.command" "$HOME/Desktop/MyApp"

echo "Scheduling a daily database backup at 12:00..."
PLIST="$HOME/Library/LaunchAgents/com.myapp.backup.plist"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.myapp.backup</string>
  <key>ProgramArguments</key>
  <array><string>/bin/bash</string><string>$SCRIPTDIR/backup.command</string></array>
  <key>StartCalendarInterval</key>
  <dict><key>Hour</key><integer>12</integer><key>Minute</key><integer>0</integer></dict>
  <key>StandardOutPath</key><string>$APPDIR/backups/backup.log</string>
  <key>StandardErrorPath</key><string>$APPDIR/backups/backup.log</string>
</dict>
</plist>
EOF
mkdir -p "$APPDIR/backups"
launchctl unload "$PLIST" 2>/dev/null
launchctl load "$PLIST"

echo
echo "================================================"
echo "  Installed! Opening MyApp in your browser..."
echo "  Next time, just double-click \"MyApp\" on your desktop."
echo "================================================"
sleep 10
open "$APP_URL"
read -r -p "Press Return to close."
