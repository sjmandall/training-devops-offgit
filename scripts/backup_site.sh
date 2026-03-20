#!/usr/bin/env bash
set -euo pipefail

SITE_SOURCE="/var/www/website/day3"
BACKUP_DIR="$HOME/project/backups/site"
TIMESTAMP="$(date +%F_%H-%M-%S)"
ARCHIVE_NAME="site_backup_${TIMESTAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

tar -czf "$BACKUP_DIR/$ARCHIVE_NAME" -C /var/www/website day3

ls -1t "$BACKUP_DIR"/site_backup_*.tar.gz | tail -n +8 | xargs -r rm -f

echo "Site backup created: $BACKUP_DIR/$ARCHIVE_NAME"

