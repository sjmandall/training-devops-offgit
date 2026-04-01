# DevOps Training Project

This repository contains a small Linux/DevOps training project built around a local PHP website, MySQL database, backup and restore automation, health checks, cron scheduling, and log rotation. It is structured like a real project with scripts, docs, infra configuration, logs, backups, and supporting SQL files. [web:1067][file:999]

## Project Overview

The project demonstrates:
- website backup automation,
- database backup automation,
- full restore workflow,
- health monitoring with JSON logs,
- backup scheduling with cron,
- log rotation with logrotate,
- repository standards with Makefile, `.editorconfig`, and `.gitignore`. 

The local application URL used in this project is:

```bash
https://localhost/day3/
```
## Repository Structure
```
project/
├── app/
├── backups/
│   ├── db/
│   └── site/
├── docs/
├── infra/
│   └── logrotate/
├── k8s/
├── logs/
├── scripts/
│   ├── backup_db.sh
│   ├── backup_site.sh
│   ├── healthcheck.sh
│   └── restore_all.sh
├── sql/
│   ├── schema.sql
│   └── seed.sql
├── .editorconfig
├── .gitignore
├── Makefile
└── README.md
```

##Features

- Site backup stored as .tar.gz.

- Database backup created using mysqldump, then archived as .tar.gz.

- Restore script for both site and database.

- Health check script that writes JSON lines to logs/health.jsonl.

- Cron scheduling for recurring jobs.

- Backup retention policy to keep the latest 7 backups.

- Logrotate configuration for custom logs.


##Prerequisites

- Install or ensure availability of the following tools and services:

- Ubuntu or WSL-based Linux environment.

- Bash shell.

- Apache HTTP Server.

- PHP.

- MySQL or MariaDB.

- curl

- tar

- mysqldump

- mysql

- logrotate

- cron

- make

- git


##Typical Ubuntu packages may include:

```
sudo apt update
sudo apt install -y apache2 php libapache2-mod-php mysql-server curl tar logrotate make git
```
##Local Configuration
This project uses the following application database settings in scripts:

- Database name: trainingdb

- Database user: trainingapp

##The health check targets:

```
https://localhost/day3/
```
- Backups are stored under:

backups/site/

backups/db/

- Logs are stored under:

logs/health.jsonl

##Quick Start
Run these commands from the project root directory:

```
cd ~/project
make test
make run
make backup
```

##Manual Commands
- Site backup:
```
~/project/scripts/backup_site.sh
```

- DB backup:
```
~/project/scripts/backup_db.sh
```

- Restore all:
```
~/project/scripts/restore_all.sh
```

- Generate 10 health log entries:
```
for i in {1..10}; do ~/project/scripts/healthcheck.sh; sleep 1; done
```

- Check latest health log:
```
tail -n 1 ~/project/logs/health.jsonl
```

##Notes
- Run make commands from the folder where the Makefile exists.
- Backups are stored in backups/site and backups/db.
- Health logs are stored in logs/health.jsonl.
- Retention policy keeps only the latest 7 backups.
- Logrotate manages health log rotation.


##Git Naming
Branch examples:
- feature/day6-repo-hygiene
- fix/backup-script
- docs/readme-update

##Commit examples:
- feat: add Makefile targets
- fix: correct backup retention logic
- docs: add project readme
#webhook test
