# Shared helper for the Mac scripts (*.command): loads .env and makes sure
# Docker is running. Sourced by the other scripts. Do not run it directly.
# The Mac version of _common.bat.

# Docker Desktop's command-line tools, also when launchd runs backup.command
# with a minimal PATH
export PATH="/usr/local/bin:/opt/homebrew/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH"

# The scripts live in mac/; .env, docker-compose.yml, backups and setup are
# in MyApp's folder, one level up.
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPDIR="$(cd "$SCRIPTDIR/.." && pwd)"
cd "$APPDIR" || exit 1

fail() {
  echo
  echo "[ERROR] $1"
  echo "Please take a screenshot of this window and send it to your developer."
  # Keep the Terminal window open when the script was double-clicked
  [ -t 0 ] && read -r -p "Press Return to close."
  exit 1
}

if [ ! -f .env ]; then
  fail "The .env file is missing from this folder."
fi
# Strip Windows line endings, in case .env was edited on a PC
set -a
eval "$(tr -d '\r' < .env)"
set +a

if ! command -v docker >/dev/null 2>&1; then
  fail "Docker is not installed. Please run mac/install.command first."
fi

if ! docker info >/dev/null 2>&1; then
  echo "Starting Docker, please wait. This can take 1-2 minutes..."
  open -a Docker 2>/dev/null
  tries=0
  until docker info >/dev/null 2>&1; do
    tries=$((tries + 1))
    if [ "$tries" -ge 48 ]; then
      fail 'Docker did not start. Open "Docker" from Applications, wait until it says "Engine running", then try again.'
    fi
    sleep 5
  done
  echo "Docker is ready."
fi
