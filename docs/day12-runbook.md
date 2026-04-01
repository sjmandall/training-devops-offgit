###Day 12 Runbook

##Topic
Jenkins install + secured setup, and a pipeline job that checks out the training repo and runs "make test".

Objective
- Jenkins reachable locally on WSL Ubuntu.
- Configured with an admin user and recommended plugins.
- Credentials stored in Jenkins (no secrets in Git repo).
- Pipeline job using "Pipeline script from SCM" that checks out the repo and runs "make test".
- Successful pipeline build log captured.

Environment
- Host OS: Windows with WSL2
- Linux: Ubuntu (WSL)
- User: webadmin
- Git repo: https://github.com/sjmandall/training-devops-offgit.git
- Jenkins URL: http://localhost:8080
- Java: openjdk 21

Prerequisites
- Docker installed and working on WSL (for future use if needed).
- Git and make installed in WSL.
- Repo already cloned in ~/project.
- WSL systemd enabled.

Step 1: Verify Java and Git on WSL
Commands:
java -version
git --version

Expected:
- Java version 17 or 21
- Git version 2.x

Step 2: Ensure Jenkins service is running
Command:
sudo systemctl status jenkins

If not running:
sudo systemctl start jenkins
sudo systemctl status jenkins

If Jenkins fails due to port 8080 in use, find and free the port:
sudo ss -tulpn | grep 8080
sudo kill <PID>

Then start Jenkins again:
sudo systemctl restart jenkins
sudo systemctl status jenkins

Step 3: Access Jenkins Web UI
On Windows, open browser:
http://localhost:8080

Step 4: Unlock Jenkins
In WSL:
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

Copy the password and paste it into the Jenkins unlock screen.

Step 5: Install suggested plugins
From Jenkins UI:
- Choose "Install suggested plugins".
- Wait for plugins to install.

Step 6: Create first admin user
In Jenkins UI:
- Username: testuser (example)
- Password: strong password
- Full name and email as required.
Continue to Jenkins dashboard.

Step 7: Confirm Jenkins URL
In Jenkins UI:
- Manage Jenkins -> System
- Set Jenkins URL to: http://localhost:8080/
- Save.

Step 8: Create Git credentials in Jenkins
Goal: Use credentials without storing tokens in the repo.

In Jenkins UI:
- Manage Jenkins -> Credentials -> (global) -> Add Credentials
  - Kind: Username with password (or Secret text, if using PAT)
  - Scope: Global
  - Username: <your GitHub username>
  - Password: <your GitHub personal access token>
  - ID: github-training (example)
  - Description: GitHub PAT for training-devops-offgit
Save.

Important:
- No tokens or passwords are committed in the Git repo.
- All secrets live in Jenkins Credentials Store.

Step 9: Jenkinsfile in the repo
In WSL, create Jenkinsfile at project root:

cd ~/project

cat > ci/Jenkinsfile <<'JEOF'
pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Debug perms') {
      steps {
        sh '''
          echo "Workspace:"
          pwd
          echo "Listing scripts directory:"
          ls -l scripts || true
        '''
      }
    }

    stage('Build and Test') {
      steps {
        sh '''
          echo "Running make test..."
          make test
        '''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'logs/**', allowEmptyArchive: true
    }
  }
}
JEOF

Commit and push:

cd ~/project
git add Jenkinsfile
git commit -m "feat: add Jenkins pipeline for make test"
git push origin main

Step 10: Fix healthcheck.sh path and permissions (if needed)
Ensure test target uses relative path:

Open Makefile and set:

test:
\t echo "Running healthcheck..."
\t bash scripts/healthcheck.sh

Ensure executable bit is set, and commit it:

cd ~/project
chmod +x scripts/healthcheck.sh
git add scripts/healthcheck.sh Makefile
git commit -m "fix: healthcheck script path and permissions"
git push origin main

Step 11: Create Jenkins pipeline job
In Jenkins UI:
- Click "New Item".
- Name: tranning-pipeline
- Type: Pipeline
- Click OK.

Under "Pipeline" section:
- Definition: Pipeline script from SCM
- SCM: Git
  - Repository URL: https://github.com/sjmandall/training-devops-offgit.git
  - Credentials: github-training (or the ID created in Step 8)
  - Branches to build: main
- Script Path: Jenkinsfile

Click Save.

Step 12: Run the pipeline
In Jenkins UI:
- Open job tranning-pipeline.
- Click "Build Now".

Watch Console Output.

Expected console highlights:
- Jenkins clones the repo from GitHub.
- Checkout stage succeeds.
- Debug perms stage lists scripts/healthcheck.sh with executable bits.
- "Build and Test" stage runs "make test" successfully (exit code 0).
- Pipeline ends with "Finished: SUCCESS".

Step 13: Archive build log for evidence
In Jenkins UI:
- Open the successful build of tranning-pipeline.
- Click "Console Output".
- Copy entire output and save into wsl:

cd ~/project
mkdir -p docs
cat > docs/day12-jenkins-build-log.txt

Paste the console output in the terminal (right-click or Shift+Insert), then press Ctrl+D to finish.




Expected Outcome
- Jenkins is installed and reachable locally on WSL via http://localhost:8080.
- An admin user and suggested plugins are configured.
- GitHub credentials are stored in Jenkins Credentials Store, with no secrets in the repo.
- A Pipeline job "tranning-pipeline" is configured to pull the repo from GitHub and run "make test".
- A successful pipeline build is run and the console log is stored as docs/day12-jenkins-build-log.txt in the repo.

