###Day 10 Runbook

##Task
Docker Compose full stack deployment.

##Objective
Deploy the app using Docker Compose with web, MySQL database, and optional Adminer UI. Use named volumes for persistence, configure depends_on and healthchecks, initialize schema automatically, and prove data persists after docker compose down and up.

Expected Deliverables
1. docker-compose.yml
2. Fresh start instructions in docs
3. Proof of persistence with record count before and after restart

Environment
- Project root: ~/project
- Web service: PHP Apache app
- Database service: MySQL 8
- Optional admin UI: Adminer
- App port: 8080
- Adminer port: 8081
- Database name: trainingdb
- Database user: trainingapp
- Database password: StrongPassword123!

Service Design
1. db
   - MySQL 8 database container
   - Uses named volume for persistent storage
   - Loads SQL initialization files from app/db/
   - Includes healthcheck using mysqladmin ping

2. web
   - Builds from docker/Dockerfile
   - Depends on healthy db service
   - Exposes port 8080
   - Uses DB environment variables

3. adminer
   - Optional browser-based DB management UI
   - Depends on healthy db service
   - Exposes port 8081

Step 1: Ensure required app files exist
Required paths:
- app/site/
- app/db/schema.sql
- app/db/seed.sql
- docker/Dockerfile
- .dockerignore

Step 2: Create docker-compose.yml
Command:
cat > ~/project/docker-compose.yml <<'YAMLEOF'
services:
  db:
    image: mysql:8.0
    container_name: training-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: trainingdb
      MYSQL_USER: trainingapp
      MYSQL_PASSWORD: StrongPassword123!
    volumes:
      - db_data:/var/lib/mysql
      - ../app/db:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD-SHELL", "mysqladmin ping -h 127.0.0.1 -uroot -prootpass || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 20s

  web:
    build:
      context: ..
      dockerfile: docker/Dockerfile
    container_name: training-web
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      DB_HOST: db
      DB_PORT: 3306
      DB_NAME: trainingdb
      DB_USER: trainingapp
      DB_PASSWORD: StrongPassword123!
    ports:
      - "8080:80"
    healthcheck:
      test: ["CMD-SHELL", "curl -fsS http://127.0.0.1/info.php || curl -fsS http://127.0.0.1/index.html || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 5
      start_period: 15s

  adminer:
    image: adminer:latest
    container_name: training-adminer
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "8081:8080"

volumes:
  db_data:
YAMLEOF

Step 3: Create fresh start instructions
Command:
cat > ~/project/docs/day10-fresh-start.txt <<'DOCSEOF'
Day 10 Fresh Start Instructions

1. Go to project root:
   cd ~/project

2. Remove existing containers and volumes:
   docker compose down -v

3. Start the stack with rebuild:
   docker compose up -d --build

4. Check service status:
   docker compose ps

5. Check logs:
   docker compose logs db --tail=50
   docker compose logs web --tail=50

6. Open the web app:
   http://localhost:8080

7. Optional Adminer UI:
   http://localhost:8081

Adminer login values:
- System: MySQL
- Server: db
- Username: trainingapp
- Password: StrongPassword123!
- Database: trainingdb

Important:
- SQL files in app/db/ run automatically only on a fresh volume.
- docker compose down -v removes the named volume and resets database data.
- For persistence proof, restart without -v.
DOCSEOF

Step 4: Start from a clean state
Use this only for first initialization so schema.sql and seed.sql run again.

Commands:
cd ~/project
docker compose down -v
docker compose up -d --build

Step 5: Verify services
Commands:
docker compose ps
docker compose logs db --tail=50
docker compose logs web --tail=50
curl http://localhost:8080/

Step 6: Verify database tables
Command:
sudo docker exec -it training-db mysql -utrainingapp -p'StrongPassword123!' trainingdb -e "SHOW TABLES;"

Expected tables:
- tickets
- users

Step 7: Check initial row count
The selected proof table is tickets.

Command:
sudo docker exec training-db mysql -utrainingapp -p'StrongPassword123!' trainingdb -e "SELECT COUNT(*) AS total FROM tickets;" > ~/project/docs/day10-count-before.txt

Observed Result
- tickets row count before restart = 3

Step 8: Restart stack without removing volume
This step proves named volume persistence.

Commands:
sudo docker compose down
sudo docker compose up -d

Step 9: Check row count after restart
Command:
sudo docker exec training-db mysql -utrainingapp -p'StrongPassword123!' trainingdb -e "SELECT COUNT(*) AS total FROM tickets;" > ~/project/docs/day10-count-after.txt

Observed Result
- tickets row count after restart = 3

Persistence Conclusion
Because the row count remained 3 before and after docker compose down and docker compose up -d, the MySQL data persisted successfully through the named Docker volume.

Step 10: Save health and runtime evidence
Commands:
docker compose ps > ~/project/docs/day10-compose-ps.txt
docker inspect training-db --format '{{json .State.Health}}' > ~/project/docs/day10-db-health.txt
docker inspect training-web --format '{{json .State.Health}}' > ~/project/docs/day10-web-health.txt

Step 11: Save optional web and Adminer access evidence
Commands:
curl -I http://localhost:8080/ > ~/project/docs/day10-web-check.txt
echo "Adminer URL: http://localhost:8081" > ~/project/docs/day10-adminer.txt

Step 12: Files generated
- docker-compose.yml
- docs/day10-fresh-start.txt
- docs/day10-count-before.txt
- docs/day10-count-after.txt
- docs/day10-compose-ps.txt
- docs/day10-db-health.txt
- docs/day10-web-health.txt
- docs/day10-web-check.txt
- docs/day10-adminer.txt



Important Notes
- Use docker compose down -v only for a fresh initialization test.
- Do not use -v when proving persistence, because it removes the named volume and deletes DB data.
- The warning about using a password on the MySQL CLI is normal and not the cause of table errors.
- The correct table name used for persistence proof is tickets, not ticket.
- Adminer is optional and is included only for browser-based database management.

Expected Outcome
- Full stack starts with docker compose
- MySQL becomes healthy before web starts
- SQL files initialize the database on fresh startup
- Web app is reachable on port 8080
- Adminer is reachable on port 8081
- tickets table count remains 3 before and after restart
- Persistence is verified successfully

Conclusion
Day 10 completed by deploying a full Docker Compose stack with web, MySQL, and optional Adminer, using healthchecks and depends_on, initializing schema automatically, and proving named-volume persistence with a stable tickets row count across restart.

