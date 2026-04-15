# Day 24 Security - DevSecOps Controls

## Objective
Move secrets to secure storage, add scanning stages to pipeline,
prove scanning catches real secrets and vulnerabilities.

## Secrets management

### Jenkins credentials
- GitHub PAT stored in Jenkins Credentials Store
- Credential ID: github-training
- No secrets in Git repo

### Kubernetes Secrets
- DB credentials stored as Kubernetes Secret
- Secret name: training-site-secrets
- Namespace: dev
- Created via: kubectl apply -f k8s/base/secret.yaml

## Security scan stages in pipeline

### Stage 1: Secret scanning (Gitleaks)
Tool: gitleaks v8.18.2
Command: gitleaks detect --source . --no-git --exit-code 1
What it does: Scans all files for accidentally committed secrets
Fails pipeline if: any secrets detected (exit code 1)
Report: gitleaks-report.json archived as artifact

### Stage 2: Image scanning (Trivy)
Tool: trivy v0.50.1
Command: trivy image training-site:VERSION --severity HIGH,CRITICAL
What it does: Scans Docker image for known CVEs
Fails pipeline if: more than 10 CRITICAL vulnerabilities found
Report: trivy-image-report.json archived as artifact

### Stage 3: Dependency scanning (Trivy)
Tool: trivy v0.50.1
Command: trivy fs . --severity HIGH,CRITICAL
What it does: Scans filesystem and dependencies for CVEs
Report: trivy-fs-report.json archived as artifact

## Proof pipeline fails on fake secret

1. Run Jenkins pipeline with parameter SEED_FAKE_SECRET=true
2. Pipeline seeds fake-secret-demo.txt containing fake AWS keys
3. Secret scanning stage runs gitleaks
4. Gitleaks detects fake AWS key pattern
5. Pipeline exits with code 1
6. Build marked as FAILED
7. Evidence: Jenkins console log showing failure at secret scan stage

Fake secrets used for demo:
  FAKE_AWS_KEY=AKIAIOSFODNN7EXAMPLE
  FAKE_AWS_SECRET=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
  FAKE_GITHUB_TOKEN=ghp_FakeTokenForTestingPurposesOnly12345

## Security controls summary

| Control | Tool | Where | Action on finding |
|---|---|---|---|
| Secret detection | Gitleaks | Pipeline stage | Fail build |
| Image CVE scan | Trivy | Pipeline stage | Fail if >10 critical |
| Dependency scan | Trivy | Pipeline stage | Report only |
| Secret storage | Jenkins Credentials | Jenkins | No plaintext secrets |
| Secret storage | Kubernetes Secret | k8s/base/secret.yaml | Encrypted at rest |
