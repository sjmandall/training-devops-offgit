#!/usr/bin/env bash
set -euo pipefail

SITE_RESTORE_BASE="/var/www/website"
SITE_NAME="day3"

DB_NAME="trainingdb"
DB_USER="trainingapp"
DB_PASS="StrongPassword123!"


SITE_BACKUP_DIR="$HOME/project/backups/site"
DB_BACKUP_DIR="$HOME/project/backups/db"
SQL_DIR="$HOME/project/sql"

LATEST_SITE_BACKUP="$(ls -t "$SITE_BACKUP_DIR"/site_backup_*.tar.gz 2>/dev/null | head -n 1)"
LATEST_DB_BACKUP="$(ls -t "$DB_BACKUP_DIR"/db_backup_"$DB_NAME"_*.tar.gz 2>/dev/null | head -n 1)"

if [[ -z "${LATEST_SITE_BACKUP:-}" ]]; then
  echo "No site backup found in $SITE_BACKUP_DIR"
  exit 1
fi


echo "Restoring site from: $LATEST_SITE_BACKUP"
sudo rm -rf "$SITE_RESTORE_BASE/$SITE_NAME"
sudo tar -xzf "$LATEST_SITE_BACKUP" -C "$SITE_RESTORE_BASE"
sudo chown -R webadmin:webadmin "$SITE_RESTORE_BASE/$SITE_NAME"

echo "Dropping and recreating clean database: $DB_NAME"
sudo mysql -e "DROP DATABASE IF EXISTS $DB_NAME;"
sudo mysql -e "CREATE DATABASE $DB_NAME;"
sudo mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
sudo mysql -e "ALTER USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

if [[ -n "${LATEST_DB_BACKUP:-}" ]]; then
  echo "Restoring database from latest dump: $LATEST_DB_BACKUP"
  tar -xOzf "$LATEST_DB_BACKUP" | mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME"
else
  echo "No DB dump found. Restoring from schema.sql and seed.sql"
  mysql -u root -p"$DB_PASS"  "$DB_NAME" < "$SQL_DIR/schema.sql"
  mysql -u root -p"$DB_PASS"  "$DB_NAME" < "$SQL_DIR/seed.sql"
fi

echo "Restore completed successfully."
