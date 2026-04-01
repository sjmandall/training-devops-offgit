# Day 14 – CI Controls: Triggers, Parameters, Failure Simulation & Notifications

## Overview
This runbook documents the CI pipeline controls implemented on Day 14 of the DevOps training.
It covers webhook auto-triggering, pipeline parameters, failure simulation, and email notifications.

---

## 1. Environment

- OS        : Ubuntu (WSL)
- Jenkins   : 2.541.x (local)
- Repo      : https://github.com/sjmandall/training-devops-offgit.git
- Jenkinsfile path : ci/Jenkinsfile
- Docs path : docs/day14-ci-controls.md

---

## 2. Pipeline Parameters

Parameters are defined in the Jenkinsfile `parameters {}` block.
They appear in Jenkins UI as "Build with Parameters".

| Parameter       | Type        | Default | Description                          |
|----------------|-------------|---------|--------------------------------------|
| ENVIRONMENT     | choice      | dev     | Target environment: dev/staging/production |
| VERSION         | string      | 1.0.0   | Application version to deploy        |
| SIMULATE_FAILURE| booleanParam| false   | Tick to trigger intentional failure  |

### How to use parameters
1. Go to Jenkins job
2. Click "Build with Parameters"
3. Set ENVIRONMENT, VERSION, SIMULATE_FAILURE
4. Click Build

---

## 3. Auto-trigger Setup

### Method 1: Poll SCM
- Jenkins job → Configure → Build Triggers
- Tick "Poll SCM"
- Schedule: H/5 * * * *
- Jenkins checks GitHub every 5 minutes for new commits
- Triggers automatically if new commits found

### Method 2: GitHub Webhook
- Jenkins job → Configure → Build Triggers
- Tick "GitHub hook trigger for GITScm polling"
- GitHub repo → Settings → Webhooks → Add webhook
- Payload URL : http://<ngrok-url>/github-webhook/
- Content type: application/json
- Events      : Just the push event
- Click Add webhook

### How auto-trigger was tested
```bash
echo "# day14 trigger test" >> README.md
git add README.md
git commit -m "Day14: test webhook auto-trigger"
git push origin main
```
- Pipeline triggered automatically after push
- Ran with default parameters (SIMULATE_FAILURE = false)
- Build passed successfully

---

## 4. Failure Simulation

### Purpose
To demonstrate what a failed pipeline looks like in Jenkins UI
and to verify that failure notifications work correctly.

### How to simulate failure
1. Jenkins job → Build with Parameters
2. Set SIMULATE_FAILURE = true (tick the checkbox)
3. Click Build
4. Pipeline fails at "Simulate failure" stage
5. All subsequent stages are blocked/skipped
6. Failure email is sent automatically

### Jenkinsfile stage responsible
```groovy
stage('Simulate failure') {
  steps {
    script {
      if (params.SIMULATE_FAILURE) {
        error("Simulated failure triggered intentionally for Day 14 demo")
      } else {
        echo "SIMULATE_FAILURE is false. Skipping failure simulation."
      }
    }
  }
}
```

### How to fix/recover after simulated failure
1. Jenkins job → Build with Parameters
2. Set SIMULATE_FAILURE = false (untick the checkbox)
3. Click Build
4. Pipeline runs normally and passes

---

## 5. Email Notification Setup

### SMTP Configuration
- SMTP Server  : smtp.gmail.com
- SMTP Port    : 465
- Use SSL      : Yes
- Username     : sjmandal2415@gmail.com
- Password     : Gmail App Password (16 characters)

### Jenkins Configuration Steps
1. Manage Jenkins → System
2. Find "E-mail Notification"
3. Fill SMTP server: smtp.gmail.com
4. Fill Default suffix: @gmail.com
5. Click Advanced
6. Tick "Use SMTP Authentication"
7. Enter username and app password
8. Tick "Use SSL"
9. Port: 465
10. Set System Admin email: sjmandal2415@gmail.com
11. Save

### Email triggers in Jenkinsfile
```groovy
post {
  success {
    mail(
      to: 'sjmandal2415@gmail.com',
      subject: "SUCCESS: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
      body: """
Pipeline passed successfully.
Job        : ${env.JOB_NAME}
Build      : ${env.BUILD_NUMBER}
Version    : ${params.VERSION}
Environment: ${params.ENVIRONMENT}
Build URL  : ${env.BUILD_URL}
      """
    )
  }
  failure {
    mail(
      to: 'sjmandal2415@gmail.com',
      subject: "FAILED: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
      body: """
Pipeline has FAILED.
Job        : ${env.JOB_NAME}
Build      : ${env.BUILD_NUMBER}
Version    : ${params.VERSION}
Environment: ${params.ENVIRONMENT}
Build URL  : ${env.BUILD_URL}
Please check the logs immediately.
      """
    )
  }
  always {
    echo "Cleaning workspace..."
    cleanWs()
  }
}
```

---

## 6. Pipeline Stages Summary

| Stage            | What it does                                      |
|-----------------|---------------------------------------------------|
| Checkout         | Clones repo from GitHub into Jenkins workspace    |
| Lint             | Runs PHP syntax check via make lint               |
| Build Docker image| Builds Docker image tagged with VERSION          |
| Test             | Runs healthcheck via make test                    |
| Simulate failure | Fails pipeline if SIMULATE_FAILURE is ticked      |
| Publish artifacts| Archives logs and build info to Jenkins           |
| Notify           | Placeholder + real email via mail() step          |
| Post Actions     | Sends email on success/failure, cleans workspace  |

---

## 7. Evidence Checklist

| Evidence                        | Status |
|--------------------------------|--------|
| Webhook configured in GitHub    | Done   |
| Poll SCM configured in Jenkins  | Done   |
| Auto-trigger on git push        | Done   |
| Passing build screenshot        | Done   |
| Failing build screenshot        | Done   |
| Email received on failure       | Done   |
| Email received on success       | Done   |
| docs/day14-ci-controls.md       | Done   |
| Jenkinsfile at ci/Jenkinsfile   | Done   |

---

## 8. Commands Used

### Push Jenkinsfile
```bash
cd ~/project
git add ci/Jenkinsfile
git commit -m "Day14: add pipeline with parameters, failure simulation and notify stage"
git push origin main
```

### Create and push docs
```bash
mkdir -p ~/project/docs
cat > ~/project/docs/day14-ci-controls.md <<'EOF'
... content ...
EOF
git add docs/day14-ci-controls.md
git commit -m "Day14: add ci-controls documentation"
git push origin main
```

### Test auto-trigger
```bash
echo "# day14 trigger test" >> README.md
git add README.md
git commit -m "Day14: test webhook auto-trigger"
git push origin main
```

