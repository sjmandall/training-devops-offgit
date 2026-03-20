#!/usr/bin/env bash
set -euo pipefail

URL="https://localhost/day3/"
LOG_FILE="$HOME/project/logs/health.jsonl"
DB_NAME="trainingdb"
DB_USER="trainingapp"
DB_PASS="StrongPassword123!"
TIMESTAMP="$(date --iso-8601=seconds)"

mkdir -p "$(dirname "$LOG_FILE")"

HTTP_STATUS="down"
DB_STATUS="down"
DETAILS=""

HTTP_CODE="$(curl -k -s -o /dev/null -w "%{http_code}" "$URL" || true)"
if [[ "$HTTP_CODE" =~ ^(200|301|302)$ ]]; then
  HTTP_STATUS="up"
else
  DETAILS="https_failed:$HTTP_CODE"
fi

if mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SELECT 1;" >/dev/null 2>&1; then
  DB_STATUS="up"
else
  if [[ -n "$DETAILS" ]]; then
    DETAILS="$DETAILS,db_failed"
  else
    DETAILS="db_failed"
  fi
fi

echo "{\"timestamp\":\"$TIMESTAMP\",\"url\":\"$URL\",\"https\":\"$HTTP_STATUS\",\"db\":\"$DB_STATUS\",\"details\":\"$DETAILS\"}" >> "$LOG_FILE"

echo "Health check written to $LOG_FILE"
