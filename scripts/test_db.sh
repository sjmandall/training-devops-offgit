#!/bin/bash
set -euo pipefail

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-trainingdb}"
DB_USER="${DB_USER:-trainingapp}"
DB_PASSWORD="${DB_PASSWORD:-StrongPassword123!}"

echo "Testing DB connection to $DB_HOST:$DB_PORT/$DB_NAME"

mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" \
  -e "USE $DB_NAME; SHOW TABLES LIKE 'tickets';" >/dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "PASS: DB connection successful and tickets table exists"
else
  echo "FAIL: DB connection failed or tickets table missing"
  exit 1
fi

