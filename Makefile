SHELL := /bin/bash


lint:
	@echo "Running PHP lint..."
	php -l app/site/index.php || true

build:
	@echo "Building app Dcoker image (local)..."
	sudo docker build -f docker/Dockerfile -t mysite:local .

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
