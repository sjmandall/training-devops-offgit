# Day 4 Runbook

## Objective
Perform website and database backup, restore the application using a single restore script, run health checks, and verify that the site, database, and logs are working correctly.

## Project Paths
- Project root: `~/project`
- Site path: `/var/www/website/day3`
- Site backups: `~/project/backups/site`
- DB backups: `~/project/backups/db`
- Scripts: `~/project/scripts`
- Logs: `~/project/logs`
- SQL files: `~/project/sql`

## Files Created
- `~/project/scripts/backup_site.sh`
- `~/project/scripts/backup_db.sh`
- `~/project/scripts/restore_all.sh`
- `~/project/scripts/healthcheck.sh`
- `~/project/logs/health.jsonl`

## Backup Process

### 1. Site backup
The site backup script creates a compressed archive of the website folder and stores it in:
`~/project/backups/site/`
 
## Expected output:

```
Site backup created: /home/webadmin/project/backups/site/site_backup_<timestamp>.tar.gz
```
###2. Database backup
The database backup script creates a MySQL dump, compresses it as a tar archive, and stores it in:
`~/project/backups/db/`
##Expected output:

```
Database backup created: /home/webadmin/project/backups/db/db_backup_trainingdb_<timestamp>.tar.gz
```

### Restore Script
The restore script restores both:

website files from the latest site backup

database from the latest DB backup

Example command:

```
~/project/scripts/restore_all.sh
```
# What restore_all.sh does
Finds the latest site backup from ~/project/backups/site

Finds the latest DB backup from ~/project/backups/db

Deletes the current site folder and restores it

Drops and recreates the trainingdb database

Creates or updates the MySQL user trainingapp

Grants privileges on trainingdb

Restores the database from the latest .tar.gz DB dump

Falls back to schema.sql and seed.sql if no DB backup is found

###Health Check

## Health check script
The health check script verifies:

HTTPS availability of https://localhost/day3/

Database connectivity using MySQL

It writes JSON log entries to:
`~/project/logs/health.jsonl`

###Generate at least 10 log entries
```
for i in {1..10}; do ~/project/scripts/healthcheck.sh; sleep 1; done 
```

##View latest log entries
```
tail -n 10 ~/project/logs/health.jsonl
```

##Verification Steps
1. Verify site backup exists
```
ls -lh ~/project/backups/site/
```
2. Verify DB backup exists
```
ls -lh ~/project/backups/db/
```
3. Verify site restore
```
curl -k https://localhost/day3/
```
4. Verify DB connection manually
```
mysql -u trainingapp -p trainingdb
```
Then inside MySQL:

sql
SHOW TABLES;
SELECT * FROM users;
SELECT * FROM tickets;

5. Verify latest health log
```
tail -n 1 ~/project/logs/health.jsonl
```
###Demonstrate restore
##To satisfy the “demonstrate restore on same machine” requirement, do this:

Run backup scripts.

Deliberately change the site.

Run restore script.

Show the original site comes back.
​

#Example:

```
~/project/scripts/backup_site.sh
~/project/scripts/backup_db.sh
echo "<?php echo 'BROKEN PAGE'; ?>" | sudo tee /var/www/website/day3/index.php
curl http://localhost/day3/
~/project/scripts/restore_all.sh
curl http://localhost/day3/
```
