Day 24 Runbook

Topic
DevSecOps - secrets management and security scanning in CI pipeline.

Objective
- Move secrets to Jenkins credentials and Kubernetes Secrets.
- Add secret scanning using Gitleaks.
- Add image and dependency scanning using Trivy.
- Fail pipeline on critical findings.
- Prove pipeline fails when fake secret is seeded.
- Document all security controls.

Evidence Required
1. Pipeline stages for scans shown in Jenkins console.
2. Proof build fails on seeded fake secret.
3. docs/day24-security.md describing controls.

Environment
- Host: Windows with WSL2 Ubuntu 24.04
- User: webadmin
- Jenkins: http://localhost:8080
- Minikube: running locally on WSL
- Repo: https://github.com/sjmandall/training-devops-offgit.git
- Jenkinsfile: ci/Jenkinsfile

Tools used
- Gitleaks v8: secret scanning
- Trivy v0.69: image and filesystem scanning

Project Structure

ci/
  Jenkinsfile          main pipeline with security stages
k8s/
  base/
    secrets.yaml       Kubernetes secret for DB credentials
docs/
  day24-runbook.txt
  day24-security.md
  day24-gitleaks-report.json
  day24-gitleaks-fake-secret-report.json
  day24-trivy-image-report.json
  day24-trivy-fs-report.json
.gitleaks.toml         gitleaks allowlist config
.gitleaksignore        gitleaks fingerprint ignore file

Step 1: Install Gitleaks

  cd ~
  curl -LO https://github.com/gitleaks/gitleaks/releases/download/v8.18.2/gitleaks_8.18.2_linux_x64.tar.gz
  tar -xzf gitleaks_8.18.2_linux_x64.tar.gz
  sudo mv gitleaks /usr/local/bin/
  gitleaks version

Step 2: Install Trivy via apt (NOT snap)

  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null

  echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
    | sudo tee /etc/apt/sources.list.d/trivy.list

  sudo apt-get update
  sudo apt-get install trivy -y
  trivy --version

Step 3: Create Kubernetes Secret

  kubectl create namespace dev

  kubectl create secret generic training-site-secrets \
    --from-literal=DB_HOST=localhost \
    --from-literal=DB_PORT=3306 \
    --from-literal=DB_NAME=trainingdb \
    --from-literal=DB_USER=trainingapp \
    --from-literal=DB_PASSWORD=StrongPassword! \
    -n dev

  kubectl get secrets -n dev
  kubectl describe secret training-site-secrets -n dev

Save as YAML for repo:
  kubectl get secret training-site-secrets -n dev -o yaml \
    > ~/project/k8s/base/secrets.yaml


Step 4: Create .gitleaks.toml config

File: ~/project/.gitleaks.toml

  title = "Training project gitleaks config"

  [extend]
  useDefault = true

  [allowlist]
  description = "Ignore known safe training files"
  paths = [
    '''docs/''',
    '''k8s/base/secrets.yaml''',
    '''k8s/monitoring/prometheus-values.yaml''',
    '''backups/''',
    '''\.gitleaksignore'''
  ]


Step 5: Create .gitleaksignore

File: ~/project/.gitleaksignore

Content:
  docs/day17-ConfigMaps-secrets-probes.md:generic-api-key:25
  docs/day22-runbook.md:hashicorp-tf-password:100
  k8s/base/secrets.yaml:generic-api-key:3
  k8s/monitoring/prometheus-values.yaml:hashicorp-tf-password:24

How to get fingerprints:
  Run gitleaks detect and check the JSON report
  Each finding has a Fingerprint field
  Format is: filename:rule-id:line-number
  Copy exact fingerprints into .gitleaksignore

Note:
  .gitleaksignore only works with git history scans not --no-git.
  For --no-git scans use .gitleaks.toml allowlist paths instead.
  Both files kept for completeness and git history scanning support.

Step 6: Run Gitleaks manually to verify

  cd ~/project

  gitleaks detect \
    --source . \
    --config .gitleaks.toml \
    --report-format json \
    --report-path ~/project/docs/day24-gitleaks-report.json \
    --no-git

  echo "Exit code: $?"

Expected: exit code 0 means no leaks found after allowlist applied.

Step 7: Run Trivy image scan manually

  eval $(minikube docker-env)

  trivy image training-site:local \
    --severity HIGH,CRITICAL \
    --format json \
    --output ~/project/docs/day24-trivy-image-report.json

  trivy image training-site:local \
    --severity HIGH,CRITICAL \
    --format table

Results:
  Total: 52 (HIGH: 52, CRITICAL: 0)
  Most findings in linux-libc-dev kernel headers (not runtime risk)
  libssl3 and openssl have fixed versions available
  No CRITICAL vulnerabilities found
  Pipeline passes because threshold is CRITICAL > 10

Step 8: Run Trivy filesystem scan manually

  trivy fs ~/project \
    --severity HIGH,CRITICAL \
    --format json \
    --output ~/project/docs/day24-trivy-fs-report.json

Step 9: Jenkins credentials stored securely

All credentials stored in Jenkins Credentials Store:
  twilio-account-sid    Twilio SID for SMS
  twilio-auth-token     Twilio token for SMS
  trello-api-key        Trello API key for card creation
  trello-token          Trello OAuth token
  trello-list-id        Trello list ID for failed builds
  github-training       GitHub PAT for repo checkout

Accessed in Jenkinsfile via:
  TWILIO_SID = credentials('twilio-account-sid')

Jenkins masks all credential values as **** in console output.
Values never appear in Jenkinsfile or logs.

Step 10: Pipeline security stages

Stage 1 - Seed fake secret (controlled by SEED_FAKE_SECRET parameter)
  Only runs when SEED_FAKE_SECRET checkbox is ticked.
  Creates fake-secret-demo.txt in workspace with:
    FAKE_AWS_KEY=AKIAIOSFODNN7EXAMPLE
    FAKE_GITHUB_TOKEN=ghp_FakeTokenForTestingPurposesOnly12345
  when { expression { params.SEED_FAKE_SECRET == true } }
  Skipped entirely in normal builds.

Stage 2 - Secret scanning
  Tool: gitleaks v8
  Command: gitleaks detect --source . --config .gitleaks.toml --no-git
  Scans all files in Jenkins workspace.
  Uses .gitleaks.toml allowlist to skip known safe files.
  Counts findings using Python json.load.
  Fails pipeline (exit 1) if FINDINGS > 0.
  Saves gitleaks-report.json as Jenkins artifact.

Stage 3 - Lint
  Runs make lint which checks PHP syntax.
  Prints ENVIRONMENT and VERSION for build record.

Stage 4 - Build Docker image
  Runs docker build with VERSION as image tag.
  Uses docker/Dockerfile with workspace as build context.

Stage 5 - Image scanning
  Tool: trivy v0.69
  Command: trivy image training-site:VERSION --severity HIGH,CRITICAL
  Scans Docker image for known CVEs in OS packages.
  Counts CRITICAL vulnerabilities using Python.
  Fails pipeline if CRITICAL_COUNT > 10.
  Saves trivy-image-report.json as Jenkins artifact.

Stage 6 - Dependency scanning
  Tool: trivy v0.69
  Command: trivy fs . --severity HIGH,CRITICAL
  Scans project files for vulnerable dependencies.
  Does not fail pipeline (informational only).
  Saves trivy-fs-report.json as Jenkins artifact.

Stage 7 - Test
  Runs make test which runs scripts/healthcheck.sh.
  Fails pipeline if healthcheck exits non-zero.

Stage 8 - Simulate failure (controlled by SIMULATE_FAILURE parameter)
  Only runs when SIMULATE_FAILURE is ticked.
  Uses error() to immediately fail pipeline.
  Useful for testing post failure notifications.

Stage 9 - Publish artifacts
  Archives logs/ and scan report JSON files.
  Creates logs/day14-build-info.txt with build details.

Stage 10 - Notify
  Placeholder echo statements.
  Real notifications happen in post blocks.

Step 11: Notifications in post blocks

Post success:
  1. Email via mail() to sjmandal2415@gmail.com
  2. Slack message to #jenkins-alerts channel (color: good)
  3. SMS via Twilio API curl command

Post failure:
  1. Email via mail() to sjmandal2415@gmail.com
  2. Slack message to #jenkins-alerts channel (color: danger)
  3. SMS via Twilio API curl command
  4. Trello card created via httpRequest POST to Trello API

Post always:
  cleanWs() removes all workspace files after every build.

Step 12: Prove pipeline fails on fake secret (evidence 2)

In Jenkins UI:
  Open pipeline job
  Click Build with Parameters
  Tick SEED_FAKE_SECRET checkbox
  Leave everything else as default
  Click Build

Expected console output showing failure:
  Seeding fake secret for scanning demo...
  Fake secret seeded.
  === Secret scanning with Gitleaks ===
  leaks found: 4
  Gitleaks findings: 4
  CRITICAL: Secrets detected in codebase!
  + exit 1
  script returned exit code 1
  Finished: FAILURE

What Gitleaks detected:
  ci/Jenkinsfile:aws-access-token:61       FAKE_AWS_KEY in workspace
  ci/Jenkinsfile:github-pat:63             FAKE_GITHUB_TOKEN in workspace
  test-secret.txt:aws-access-token:4       fake-secret-demo.txt AWS key
  test-secret.txt:github-pat:6             fake-secret-demo.txt GitHub token

This proves:
  Gitleaks correctly identifies AWS access key patterns.
  Gitleaks correctly identifies GitHub PAT patterns.
  Pipeline exits with code 1 on any secret detection.
  Build marked FAILED preventing deployment of compromised code.

Step 13: Prove pipeline passes on clean build (evidence 1)

In Jenkins UI:
  Click Build with Parameters
  Leave SEED_FAKE_SECRET UNTICKED
  Leave SIMULATE_FAILURE UNTICKED
  VERSION: 1.0.0
  ENVIRONMENT: dev
  Click Build

Expected stages all passing:
  Checkout              OK
  Seed fake secret      SKIPPED
  Secret scanning       OK - no secrets found
  Lint                  OK
  Build Docker image    OK
  Image scanning        OK - 0 CRITICAL found
  Dependency scanning   OK
  Test                  OK
  Simulate failure      OK - skipped
  Publish artifacts     OK
  Notify                OK

Expected result: Finished: SUCCESS

Step 14: Commit all Day 24 files

  cd ~/project

  git add ci/Jenkinsfile
  git add k8s/base/secrets.yaml
  git add .gitleaks.toml
  git add .gitleaksignore
  git add docs/day24-runbook.txt
  git add docs/day24-security.md
  git add docs/day24-gitleaks-report.json
  git add docs/day24-gitleaks-fake-secret-report.json
  git add docs/day24-trivy-image-report.json
  git add docs/day24-trivy-fs-report.json

  git status
  git commit -m "feat: day24 DevSecOps secret scanning image scanning pipeline security"
  git push origin main

