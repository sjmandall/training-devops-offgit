###Day 11 Runbook

##Task
Automated testing and image tagging.

##Objective
Add basic automated shell-based smoke tests and a DB connectivity test. Build Docker image tags from Git commit and date, and generate build-info.json as build metadata.

Expected Deliverables
1. scripts/test_smoke.sh
2. scripts/test_db.sh
3. Two builds that produce different image tags
4. build-info.json archived or committed as template

Prerequisites
- Project root is ~/project
- Docker is installed and working
- Git repository is initialized in ~/project
- Docker Compose stack from Day 10 is already working
- Web app is reachable on port 8080
- MySQL database is available with database name trainingdb
- DB user is trainingapp
- DB password is StrongPassword123!

Why smoke tests are used
Smoke tests are fast basic checks that confirm the most critical functionality of a build works after a change or deployment. They are used as an early gate so deeper testing is not run on a build that is already broken.

Examples of smoke test checks
- homepage returns HTTP 200
- info.php returns HTTP 200
- database accepts a connection
- required table exists

Step 1: Go to project root
Command:
cd ~/project

Step 2: Create smoke test script
This script checks whether the web app is responding correctly.

Command:
cat > ~/project/scripts/test_smoke.sh <<'SMOKEEOF'
#!/bin/bash
set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"

echo "Running smoke test against: $BASE_URL"

HOME_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/")
if [ "$HOME_CODE" != "200" ]; then
  echo "FAIL: Homepage returned HTTP $HOME_CODE"
  exit 1
fi

echo "PASS: Homepage returned 200"

INFO_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/info.php")
if [ "$INFO_CODE" != "200" ]; then
  echo "FAIL: info.php returned HTTP $INFO_CODE"
  exit 1
fi

echo "PASS: info.php returned 200"
echo "Smoke test passed"
SMOKEEOF

chmod +x ~/project/scripts/test_smoke.sh

Step 3: Create DB test script
This script checks MySQL connectivity and verifies that the tickets table exists.

Command:
cat > ~/project/scripts/test_db.sh <<'DBEOF'
#!/bin/bash
set -euo pipefail

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-trainingdb}"
DB_USER="${DB_USER:-trainingapp}"
DB_PASSWORD="${DB_PASSWORD:-StrongPassword123!}"

echo "Testing DB connection to $DB_HOST:$DB_PORT/$DB_NAME"

mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" \
  -e "USE $DB_NAME; SHOW TABLES LIKE 'tickets';" >/dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "PASS: DB connection successful and tickets table exists"
else
  echo "FAIL: DB connection failed or tickets table missing"
  exit 1
fi
DBEOF

chmod +x ~/project/scripts/test_db.sh

Step 4: Run the automated tests
Commands:
cd ~/project
./scripts/test_smoke.sh
DB_HOST=127.0.0.1 DB_PORT=3306 DB_NAME=trainingdb DB_USER=trainingapp DB_PASSWORD='StrongPassword123!' ./scripts/test_db.sh

Expected Result
- test_smoke.sh should pass if the web app is reachable and returns HTTP 200
- test_db.sh should pass if the DB connection works and the tickets table exists

Step 5: Generate build variables for image tagging
These variables use the current Git commit and the current time to create a unique Docker image tag.

Commands:
cd ~/project
COMMIT_SHA=$(git rev-parse --short HEAD)
BUILD_DATE=$(date +%Y%m%d-%H%M%S)
IMAGE_TAG="${BUILD_DATE}-${COMMIT_SHA}"

Optional check:
echo "$COMMIT_SHA"
echo "$BUILD_DATE"
echo "$IMAGE_TAG"

Meaning of variables
- COMMIT_SHA: short Git commit hash of the current source code
- BUILD_DATE: compact timestamp of when the image is built
- IMAGE_TAG: combined value used as the Docker image tag

Step 6: First image build
Command:
docker build -f docker/Dockerfile -t training-site:${IMAGE_TAG} .

Step 7: Create two different image tags from two builds
This is required to prove that separate builds produce different tags.

Commands:
cd ~/project
COMMIT_SHA=$(git rev-parse --short HEAD)

TAG1="$(date +%Y%m%d-%H%M%S)-${COMMIT_SHA}"
docker build -f docker/Dockerfile -t training-site:${TAG1} .

sleep 5

TAG2="$(date +%Y%m%d-%H%M%S)-${COMMIT_SHA}"
docker build -f docker/Dockerfile -t training-site:${TAG2} .

echo "First tag:  ${TAG1}"
echo "Second tag: ${TAG2}"

Step 8: Save proof of two different tags
Command:
cat > ~/project/docs/day11-image-tags.txt <<TAGEOF
First tag: ${TAG1}
Second tag: ${TAG2}
TAGEOF

Expected Result
- TAG1 and TAG2 should be different because the timestamp part changes
- The Git commit may remain the same if no new commit was made
- This proves two builds produced different image tags

Step 9: Create build-info.json
This file stores build metadata and can be committed as a template or archived as evidence.

Command:
cd ~/project
COMMIT_SHA=$(git rev-parse --short HEAD)
BUILD_DATE_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TAG="$(date +%Y%m%d-%H%M%S)-${COMMIT_SHA}"

cat > build-info.json <<JSONEOF
{
  "app_name": "training-site",
  "build_tag": "${TAG}",
  "git_commit": "${COMMIT_SHA}",
  "build_date_utc": "${BUILD_DATE_ISO}",
  "image_name": "training-site:${TAG}",
  "dockerfile": "docker/Dockerfile",
  "db_name": "trainingdb"
}
JSONEOF

Meaning of build-info.json fields
- app_name: logical project or application name
- build_tag: generated Docker tag
- git_commit: source commit used for the build
- build_date_utc: build time in UTC ISO-style format
- image_name: exact Docker image reference
- dockerfile: path of the Dockerfile used
- db_name: database name used by the app

Step 10: Save test output evidence
Commands:
cd ~/project
./scripts/test_smoke.sh > docs/day11-smoke-output.txt 2>&1
DB_HOST=127.0.0.1 DB_PORT=3306 DB_NAME=trainingdb DB_USER=trainingapp DB_PASSWORD='StrongPassword123!' ./scripts/test_db.sh > docs/day11-db-output.txt 2>&1

Step 11: List built Docker images
Command:
docker images | grep training-site > ~/project/docs/day11-docker-images.txt

Step 12: Files created
- scripts/test_smoke.sh
- scripts/test_db.sh
- build-info.json
- docs/day11-smoke-output.txt
- docs/day11-db-output.txt
- docs/day11-image-tags.txt
- docs/day11-docker-images.txt



Important Notes
- Run all COMMIT_SHA, BUILD_DATE, TAG, and docker build commands from ~/project
- COMMIT_SHA identifies which Git commit the build came from
- BUILD_DATE and TAG should be regenerated for fresh builds
- TAG1 and TAG2 differ mainly because of time, even if the commit is unchanged
- build-info.json should be created in ~/project root, not inside docs, because it is build metadata for the project
- The DB warning about password on CLI is normal and does not indicate failure by itself

Expected Outcome
- Smoke test script works
- DB connectivity test works
- Two builds create different image tags
- build-info.json records useful build metadata
- All required evidence files exist in the repository

Conclusion
Day 11 completed by creating automated shell-based smoke and database tests, generating traceable Docker image tags from Git commit and build time, and storing build metadata in build-info.json.

