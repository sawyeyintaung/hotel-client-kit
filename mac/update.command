#!/bin/bash
# Install the newest version: MyApp's own files from GitHub (git pull), then
# the newest images. The Mac version of update.bat.
#
# git pull can replace this file, and bash reads a script as it runs. So
# everything is inside main(): bash reads the whole function before running
# it, and the file can then change safely. A changed update.command takes
# effect from the next update.
main() {
  # This script is in mac/; MyApp's folder (with .git) is one level up.
  SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"
  APPDIR="$(cd "$SCRIPTDIR/.." && pwd)"
  cd "$APPDIR" || exit 1

  # ---- MyApp's files: scripts and docker-compose.yml ----
  if ! git --version >/dev/null 2>&1; then
    echo "[WARNING] git is not installed, so MyApp's files were not updated."
  elif [ ! -d .git ]; then
    echo "[WARNING] This folder was not set up with git, so MyApp's files were not updated."
  else
    echo "Updating MyApp's files..."
    git pull --ff-only \
      || echo "[WARNING] Could not update MyApp's files. Updating the app anyway."
  fi

  # Loaded after the pull, so a new _common.sh or .env change applies now
  . "$SCRIPTDIR/_common.sh"

  echo "Backing up your data before updating..."
  /bin/bash "$SCRIPTDIR/backup.command" || fail "The backup failed, so nothing was updated. Your data is safe."

  echo "Downloading the latest version..."
  docker compose pull || fail "Update failed. Your data is safe."

  echo "Restarting MyApp with the new version..."
  docker compose up -d || fail "Update failed. Your data is safe."

  # Remove old versions to free disk space
  docker image prune -f >/dev/null

  echo
  echo "MyApp is up to date!"
  sleep 5
  open "$APP_URL"
  read -r -p "Press Return to close."
}

main "$@"
exit
