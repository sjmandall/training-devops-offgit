# Day 14 – CI Controls

## Pipeline Parameters
- ENVIRONMENT: choose dev / staging / production
- VERSION: semantic version string e.g. 1.0.0
- SIMULATE_FAILURE: boolean to trigger intentional failure for demo

## Auto-trigger
- Poll SCM configured: H/5 * * * *
- Webhook configured: GitHub webhook pointing to Jenkins

## Failure Simulation
- Tick SIMULATE_FAILURE checkbox in Build with Parameters
- Pipeline fails at "Simulate failure" stage
- Subsequent stages are blocked/skipped in Jenkins UI
- Failure email notification sent automatically

## Notification
- mail() step configured in post { failure } and post { success }
- Email sent to sjmandal2415@gmail.com on every build result
- In production: can also add Slack plugin for team channel alerts

## Evidence
- Build auto-triggered by git push via webhook
- One failing build: SIMULATE_FAILURE = true
- One passing build: SIMULATE_FAILURE = false

