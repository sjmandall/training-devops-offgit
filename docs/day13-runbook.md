###Day 13 Runbook

Topic
Jenkinsfile (real pipeline) with stages: Checkout, Lint, Build Docker image, Test, Publish artifacts; plus post actions archive and cleanup.

Objective
- Extend Makefile with lint and build targets.
- Create a declarative Jenkinsfile that:
  - Checks out code from Git.
  - Runs lint and tests via make.
  - Builds Docker image using docker/Dockerfile.
  - Publishes artifacts from logs and build output.
  - Cleans workspace after each build.
- Verify Jenkins job runs successfully and evidence files are stored.

Environment
- Host: Windows with WSL2 Ubuntu.
- Repo root: ~/project
- Git remote: training-devops-offgit (GitHub).
- Jenkins: running on Ubuntu WSL, reachable at http://localhost:8080.
- Jenkins job: tranning-pipeline (Pipeline script from SCM).
- Docker: installed and usable from Jenkins agent.

Prerequisites
- Jenkins installed and configured (admin user, plugins, GitHub credentials).
- Repo structure:
  - Makefile at repo root.
  - docker/Dockerfile and docker/apache/website.conf.
  - scripts/healthcheck.sh and logs/health.jsonl from earlier days.
- Docker daemon running and accessible from Jenkins agent.

Step 1: Update Makefile with lint and build targets
Goal: Provide standard CI commands that Jenkins can call.

From WSL:

cd ~/project

Edit Makefile so it contains:

SHELL := /bin/bash

lint:
\t@echo "Running PHP lint..."
\tphp -l app/site/index.php || true

build:
\t@echo "Building app Docker image (local)..."
\tdocker build -f docker/Dockerfile -t training-site:local .

test:
\t@echo "Running healthcheck..."
\tbash scripts/healthcheck.sh
\ttail -n 1 logs/health.jsonl

run:
\t@echo "Checking local app..."
\tcurl -k https://localhost/day3/

backup:
\t@echo "Running backups..."
\t/home/webadmin/project/scripts/backup_site.sh
\t/home/webadmin/project/scripts/backup_db.sh

restore:
\t@echo "Running restore..."
\t/home/webadmin/project/scripts/restore_all.sh

Quick local check:

make lint
make build
make test

Expected:
- lint prints PHP syntax check output.
- build runs docker build -f docker/Dockerfile -t training-site:local .
- test runs healthcheck.sh and prints last line of logs/health.jsonl.

Step 2: Create declarative Jenkinsfile with required stages
Goal: Jenkinsfile implementing stages: Checkout, Lint, Build Docker image, Test, Publish artifacts, and post cleanup.

Use ci/Jenkinsfile to keep CI config under ci/.

cd ~/project
mkdir -p ci

cat > ci/Jenkinsfile <<'JEOF'
pipeline {
  agent any

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }

  environment {
    APP_NAME  = 'training-site'
    IMAGE_TAG = "training-site:${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Lint') {
      steps {
        sh '''
          echo "=== Lint stage ==="
          make lint
        '''
      }
    }

    stage('Build Docker image') {
      steps {
        sh '''
          echo "=== Build Docker Image stage ==="
          docker build -f docker/Dockerfile -t ${IMAGE_TAG} .
        '''
      }
    }

    stage('Test') {
      steps {
        sh '''
          echo "=== Test stage ==="
          make test
        '''
      }
    }

    stage('Publish artifacts') {
      steps {
        sh '''
          echo "=== Publish artifacts stage ==="
          mkdir -p logs build
          echo "Day 13 build number: ${BUILD_NUMBER}" > logs/day13-build-info.txt
        '''
        archiveArtifacts artifacts: 'logs/**,build/**', allowEmptyArchive: true
      }
    }
  }

  post {
    always {
      echo "Cleaning workspace..."
      cleanWs()
    }
  }
}
JEOF

Notes:
- Lint stage uses make lint for basic syntax check.
- Build Docker image stage tags image with build number using docker/Dockerfile.
- Test stage uses make test, which runs scripts/healthcheck.sh.
- Publish artifacts stage archives logs/** and build/** for each build. [web:1727][web:1728]
- post { always { cleanWs() } } ensures workspace is cleaned after every build. [web:1729][web:1731]

Step 3: Commit Day 13 changes
Record Makefile and Jenkinsfile updates.

cd ~/project
git status

git add Makefile ci/Jenkinsfile
git commit -m "feat: day13 real Jenkins pipeline with lint, docker build, test, artifacts, cleanup"
git push origin main

Step 4: Configure Jenkins job to use ci/Jenkinsfile
Ensure tranning-pipeline points to the new Jenkinsfile.

In Jenkins UI:
- Open job: tranning-pipeline.
- Click "Configure".
- Under "Pipeline":
  - Definition: Pipeline script from SCM.
  - SCM: Git.
    - Repository URL: https://github.com/sjmandall/training-devops-offgit.git
    - Credentials: GitHub PAT credential.
    - Branches to build: main.
  - Script Path: ci/Jenkinsfile
- Click "Save".

Step 5: Run the Day 13 pipeline
Trigger and observe the pipeline.

- Open tranning-pipeline.
- Click "Build Now".
- Click the latest build number, then "Console Output".

Check stages in order:
- Checkout: Jenkins clones repo from GitHub.
- Lint: "=== Lint stage ===" and "Running PHP lint..." appear, php -l runs.
- Build Docker image: "=== Build Docker Image stage ===" appears, docker build runs with tag training-site:<build-number>.
- Test: "=== Test stage ===" and "Running healthcheck..." appear; healthcheck.sh and tail of logs/health.jsonl run.
- Publish artifacts: "=== Publish artifacts stage ===" appears; logs/day13-build-info.txt is created; archiveArtifacts archives logs/** and build/**.
- Post: "Cleaning workspace..." printed; cleanWs() executes.

Build should end with:
Finished: SUCCESS

Step 6: Verify artifacts were archived
From the successful build page:

- Under "Artifacts", confirm presence of:
  - logs/day13-build-info.txt
  - other files under logs/** (health logs, etc.).
  - any build/** files you create later.

Download day13-build-info.txt and verify it contains the build number line.


Step 7: Verify workspace was cleaned
From the same build page:

- Click "Workspace".
- Confirm workspace is empty or minimal because cleanWs() ran in the post section. If files remain, re-check Jenkinsfile post block placement.

Step 8: Capture Day 13 evidence files in repo
Store console output and notes under docs/ for future review.

In WSL:

cd ~/project
mkdir -p docs

# Save Jenkins console log
cat > docs/day13-jenkins-build-log.txt
(paste full console output from successful Day 13 build)
Ctrl+D to finish.

# Create Day 13 notes
cat > docs/day13-jenkins-notes.txt <<'NOTEOF'
Day 13 Jenkins Pipeline Notes

- Jenkinsfile path: ci/Jenkinsfile
- Pipeline type: Declarative
- Stages:
  - Checkout: checkout scm
  - Lint: make lint
  - Build Docker image: docker build -f docker/Dockerfile -t training-site:${BUILD_NUMBER} .
  - Test: make test
  - Publish artifacts: write logs/day13-build-info.txt, archive logs/** and build/**
- Post actions:
  - always: cleanWs() (workspace cleanup after each build)
- Job name: tranning-pipeline
- Jenkins URL: http://localhost:8080/
- Acceptance criteria:
  - Jenkinsfile committed.
  - Artifacts archived (logs/**, build/**).
  - Workspace cleaned after build via cleanWs().
NOTEOF

Commit and push:

git add docs/day13-jenkins-build-log.txt docs/day13-jenkins-notes.txt
git commit -m "chore: add day13 Jenkins real pipeline evidence files"
git push origin main

Expected Day 13 Outcomes
- Makefile contains lint, build, test targets used by CI.
- Declarative Jenkinsfile (ci/Jenkinsfile) implements stages: Checkout, Lint, Build Docker image, Test, Publish artifacts.
- Jenkins artifacts include logs/day13-build-info.txt and other logs/build files.
- Workspace is cleaned after each build because cleanWs() runs in post { always }.
- Evidence files docs/day13-jenkins-build-log.txt and docs/day13-jenkins-notes.txt exist in the repo.

