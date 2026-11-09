#!/bin/bash
# Open MyApp (the desktop shortcut runs this). The Mac version of start.bat.
. "$(cd "$(dirname "$0")" && pwd)/_common.sh"

docker compose up -d || fail "MyApp could not start."
open "$APP_URL"
