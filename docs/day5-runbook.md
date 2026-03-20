# Day 5 Runbook

## Objective
Automate backups and health checks using cron, implement a retention policy to keep only the latest 7 backups, configure logrotate for custom health logs, and verify log rotation with before/after evidence.

## Task Summary
Day 5 focuses on:
- Scheduling backup and health-check scripts with cron
- Applying backup retention so only the newest 7 backups are kept
- Configuring logrotate for `~/project/logs/health.jsonl`
- Forcing a log rotation test and collecting proof

## Project Paths
- Project root: `~/project`
- Scripts: `~/project/scripts`
- Site backups: `~/project/backups/site`
- DB backups: `~/project/backups/db`
- Logs: `~/project/logs`
- Health log: `~/project/logs/health.jsonl`
- Logrotate config: `/etc/logrotate.d/day4-healthcheck`

## Scripts Used
- `~/project/scripts/backup_site.sh`
- `~/project/scripts/backup_db.sh`
- `~/project/scripts/healthcheck.sh`


## Cron Scheduling

### Purpose
Cron is used to run scripts automatically at scheduled times without manual execution.

### Configured Jobs
Open crontab:
```bash
crontab -e
```

##Add:

```
*/5 * * * * /home/webadmin/project/scripts/healthcheck.sh
0 1 * * * /home/webadmin/project/scripts/backup_site.sh
10 1 * * * /home/webadmin/project/scripts/backup_db.sh
```
#Verification
Display configured cron jobs:

```
crontab -l
```

###Retention Policy
- Purpose
  A retention policy prevents unlimited growth of backup files by keeping only the latest 7 backups.

- Site backup retention
  Added to backup_site.sh:

	```
	ls -1t "$BACKUP_DIR"/site_backup_*.tar.gz | tail -n +8 | xargs -r rm -f
	```
- DB backup retention
  Added to backup_db.sh:

      	```
	ls -1t "$BACKUP_DIR"/db_backup_"$DB_NAME"_*.tar.gz | tail -n +8 | xargs -r rm -f
	```
- Result:

 newest 7 backups are kept

 older backups are removed automatically


###Logrotate Configuration
- Purpose
  Logrotate manages log growth by rotating, compressing, and limiting retained log files.

##Config file
  Created:

   	```
	sudo nano /etc/logrotate.d/day4-healthcheck

	```
- Content:

```
/home/webadmin/project/logs/health.jsonl {
    su webadmin webadmin
    daily
    rotate 7
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
    create 0644 webadmin webadmin
}
```

###Forced Rotation Test

- Generate health log entries
```
for i in {1..10}; do ~/project/scripts/healthcheck.sh; sleep 1; done
```

- Before rotation
```
ls -lh ~/project/logs
```
- Force logrotate
```
sudo logrotate -f /etc/logrotate.d/day4-healthcheck
```
- After rotation
```
ls -lh ~/project/logs
```
- result:
```
4 -rw-rw-r-- 1 webadmin webadmin  440 Mar 19 14:25 health.jsonl
8 -rw-rw-r-- 1 webadmin webadmin 5651 Mar 19 14:05 health.jsonl.1
```

###Verification Commands

##Show cron jobs
```
crontab -l
```

##Show logrotate config
```
cat /etc/logrotate.d/day4-healthcheck
```
##Show site backups
```
ls -lh ~/project/backups/site/
```
##Show DB backups
```
ls -lh ~/project/backups/db/
```

##Show last 10 health log entries
```
tail -n 10 ~/project/logs/health.jsonl
```
