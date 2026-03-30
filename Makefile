SHELL := /bin/bash

test:
	@echo "Running healthcheck..."
	bash scripts/healthcheck.sh
	tail -n 1 logs/health.jsonl

run:
	@echo "Checking local app..."
	curl -k https://localhost/day3/

backup:
	@echo "Running backups..."
	/home/webadmin/project/scripts/backup_site.sh
	/home/webadmin/project/scripts/backup_db.sh

restore:
	@echo "Running restore..."
	/home/webadmin/project/scripts/restore_all.sh
