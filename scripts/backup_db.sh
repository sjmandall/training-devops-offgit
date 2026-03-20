#!/usr/bin/env bash
set -euo pipefail

DB_NAME="trainingdb"
DB_USER="trainingapp"
DB_PASS="StrongPassword123!"
BACKUP_DIR="$HOME/project/backups/db"
TIMESTAMP="$(date +%F_%H-%M-%S)"
SQL_FILE="db_backup_${DB_NAME}_${TIMESTAMP}.sql"
TAR_FILE="db_backup_${DB_NAME}_${TIMESTAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

mysqldump --single-transaction --skip-lock-tables --no-tablespaces -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/$SQL_FILE"

tar -czf "$BACKUP_DIR/$TAR_FILE" -C "$BACKUP_DIR" "$SQL_FILE"

rm -f "$BACKUP_DIR/$SQL_FILE"

ls -1t "$BACKUP_DIR"/db_backup_"$DB_NAME"_*.tar.gz  | tail -n +8 | xargs -r rm -f

echo "Database dump created: $BACKUP_DIR/$TAR_FILE"

