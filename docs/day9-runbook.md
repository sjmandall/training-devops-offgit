###Day 9 Runbook

##Task
Dockerization of the training website using a multi-stage Docker build.

###Objective
Containerize the existing app using Docker with a separate build context, proper .dockerignore, a non-root container user where feasible, environment variables for DB configuration, a healthcheck instruction, and container access on port 8080.

Expected Deliverables
1. Dockerfile and .dockerignore
2. docker run proof that the app is reachable
3. docker inspect output showing healthcheck configuration

Repository Layout Used
- app/site/              application pages
- app/config/            example environment config
- app/db/                SQL files
- docker/Dockerfile      container build definition
- .dockerignore          build context exclusions
- docs/                  evidence files

Step 1: Prepare application structure in the repo
The repository should contain the app source that Docker will build from.

Commands:
cd ~/project
mkdir -p app/site app/config app/db docker

cp /var/www/website/. app/site/ 2>/dev/null || true


cp sql/schema.sql app/db/ 2>/dev/null || true
cp sql/seed.sql app/db/ 2>/dev/null || true

Step 2: Create example environment configuration
Command:
cat > ~/project/app/config/app.env.example <<'CFGEOF'
DB_HOST=localhost
DB_PORT=3306
DB_NAME=trainingdb
DB_USER=trainingapp
DB_PASSWORD=StrongPassword123!
EOF

Step 3: Create .dockerignore at project root
The build context is the repository root, so .dockerignore must be created there.

Command:
cat > ~/project/.dockerignore <<'IGNOREEOF'
.git
.gitignore
docs
logs
backups
infra
k8s
ci
*.tar.gz
*.sql
.env
.env.*
node_modules
IGNOREEOF

Step 4: Create multi-stage Dockerfile
Command:
cat > ~/project/docker/Dockerfile <<'DOCKEREOF'
FROM alpine:3.20 AS prepare
WORKDIR /src
COPY app/site/ /src/site/
COPY app/config/app.env.example /src/config/app.env.example

FROM php:8.2-apache

ENV APP_HOME=/var/www/website \
    DB_HOST=localhost \
    DB_PORT=3306 \
    DB_NAME=trainingdb \
    DB_USER=trainingapp \
    DB_PASSWORD=StrongPassword123!

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && a2enmod rewrite

RUN mkdir -p ${APP_HOME} /var/www/config

COPY docker/apache/website.conf /etc/apache2/sites-available/website.conf

RUN a2dissite 000-default.conf \
    && a2ensite website.conf

COPY --from=prepare /src/site/ ${APP_HOME}/
COPY --from=prepare /src/config/app.env.example /var/www/config/app.env.example

RUN chown -R www-data:www-data ${APP_HOME} /var/www/config

WORKDIR ${APP_HOME}

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://127.0.0.1/info.php || curl -fsS http://127.0.0.1/index.php || exit 1

USER www-data

EXPOSE 80


##create the vhost  file

- Create this file in your project as:


docker/apache/website.conf

with this content:

```
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/website

    <Directory /var/www/website>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```
Step 5: Build the Docker image
The Dockerfile is stored in docker/ but the build context is the repository root.

Command:
cd ~/project
docker build -t mysite -f ~/project/docker/Dockerfile ~/project

Step 6: Run the container on port 8080
Map host port 8080 to container port 80.

Command:
docker run -d --name mysite-container -p 8080:80 mysite

Step 7: Verify the app is reachable
Commands:
curl http://localhost:8080/
curl -I http://localhost:8080/

Step 8: Save runtime proof
Commands:
mkdir -p ~/project/docs
docker ps > ~/project/docs/day9-docker-ps.txt
curl -I http://localhost:8080/ > ~/project/docs/day9-info-status.txt

Optional:
curl http://localhost:8080/info.php > ~/project/docs/day9-info-php.txt

Step 9: Save healthcheck evidence
Use docker inspect to show that the healthcheck is configured and active.

Commands:
docker inspect mysite --format '{{json .Config.Healthcheck}}' > ~/project/docs/day9-healthcheck-inspect.txt
docker inspect mysite-container --format '{{json .State.Health}}' >> ~/project/docs/day9-healthcheck-inspect.txt

Step 10: Verification commands
Check image:
docker images | grep mysite

Check running container:
docker ps

Check health:
docker inspect mysite --format '{{json .State.Health}}'

Check container logs:
docker logs mysite

Step 11: Files produced
- .dockerignore
- docker/Dockerfile
- app/config/app.env.example
- docs/day9-docker-ps.txt
- docs/day9-reachable.txt
- docs/day9-healthcheck-inspect.txt
- docs/day9-info-php.txt (optional)



Important Notes
- Do not change host Apache VirtualHost files just for Day 9.
- Host Apache and container Apache are separate.
- The host may still serve /var/www/website, while Docker builds from ~/project/app/site.
- Keep .dockerignore at the root of the build context.
- Use copy into app/site instead of moving files from /var/www/website so the host site remains available during migration.

Expected Result
- App source exists inside the repository under app/
- Docker image builds successfully using docker/Dockerfile
- Container runs and is reachable at http://localhost:8080
- docker inspect output proves the healthcheck is configured
- Day 9 deliverables are committed into the repo

Conclusion
Day 9 completed by preparing the app source inside the repository, building a multi-stage Docker image, using a proper .dockerignore, running the container with environment variables, exposing it on port 8080, and recording healthcheck evidence with docker inspect.
EOF
