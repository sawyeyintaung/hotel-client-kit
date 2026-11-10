#!/bin/bash
# Saves the database to the "backups" folder. Runs daily at 12:00 (launchd,
# set up by install.command) and before every update. Backups older than 30
# days are deleted. The Mac version of backup.bat.
. "$(cd "$(dirname "$0")" && pwd)/_common.sh"

mkdir -p backups
FILE="backups/backup-$(date +%Y-%m-%d_%H%M).sql"

if ! docker compose exec -T db pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists > "$FILE"; then
  rm -f "$FILE"
  echo "[ERROR] Backup failed. Is MyApp running?"
  exit 1
fi

find backups -name 'backup-*.sql' -mtime +30 -delete
echo "Backup saved: $FILE"
