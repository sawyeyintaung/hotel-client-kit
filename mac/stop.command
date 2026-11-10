#!/bin/bash
# Stop MyApp. Your data is kept. The Mac version of stop.bat.
. "$(cd "$(dirname "$0")" && pwd)/_common.sh"

docker compose down || fail "Could not stop MyApp."

echo "MyApp has been stopped. Your data is safe."
echo 'Double-click the "MyApp" desktop shortcut to start it again.'
read -r -p "Press Return to close."
