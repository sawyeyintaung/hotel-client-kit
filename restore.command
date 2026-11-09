#!/bin/bash
# Restore a backup from the "backups" folder. Shows the backups and asks
# which one, since Finder can't drop a file onto a .command. The Mac version
# of restore.bat.
. "$(cd "$(dirname "$0")" && pwd)/_common.sh"

backups=()
while IFS= read -r f; do backups+=("$f"); done < <(ls -1t backups/backup-*.sql 2>/dev/null)
if [ ${#backups[@]} -eq 0 ]; then
  fail 'There are no backups in the "backups" folder.'
fi

echo "Backups, newest first:"
PS3="Type the number of the backup to restore (or Ctrl+C to cancel): "
select FILE in "${backups[@]}"; do
  [ -n "$FILE" ] && break
done

echo
echo "WARNING: This replaces ALL current data with the backup:"
echo "  $(basename "$FILE")"
read -r -p "Type YES to continue: " OK
if [ "$OK" != "YES" ]; then
  echo "Cancelled. Nothing was changed."
  read -r -p "Press Return to close."
  exit 0
fi

docker compose exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -q < "$FILE" \
  || fail "Restore failed."
docker compose restart backend >/dev/null

echo "Restore complete."
read -r -p "Press Return to close."
