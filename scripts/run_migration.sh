#!/bin/bash
set -e

echo "=== Starting DB Migration v2.0.0 ==="

DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-trainingdb}
DB_USER=${DB_USER:-trainingapp}
DB_PASSWORD=${DB_PASSWORD:-StrongPassword123!}
MIGRATION_FILE=${MIGRATION_FILE:-/migrations/v2_migration.sql}

echo "Connecting to: ${DB_HOST}:${DB_PORT}/${DB_NAME}"

# Wait for database to be ready
echo "Waiting for database..."
for i in $(seq 1 30); do
  if mysqladmin ping -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" --silent 2>/dev/null; then
    echo "Database is ready"
    break
  fi
  echo "Attempt ${i}/30 - waiting..."
  sleep 2
done

# Run migration
echo "Running migration: ${MIGRATION_FILE}"
mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" < "${MIGRATION_FILE}"

echo "=== Migration completed successfully ==="
