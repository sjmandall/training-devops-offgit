# Release Notes v2.0.0

## Release date: 2026-04-16

## Changes
- Added `created_at` column to users table
- Added email index for faster database lookups
- Added `schema_version` tracking table
- Added `/version.php` API endpoint
- DB migration automated via Kubernetes Job
- Migration runs before app deployment via init container

## Migration details
Migration script: app/db/migrations/v2_migration.sql
Kubernetes Job: k8s/base/migration-job.yaml
ConfigMap: k8s/base/migration-configmap.yaml

## How migration works
1. Kubernetes Job is applied before deployment
2. Init container waits for DB to be ready
3. Main container runs v2_migration.sql
4. Job completes and is cleaned up after 300 seconds
5. New app deployment starts after migration

## Rollback procedure
If migration causes issues:
  kubectl rollout undo deployment/training-site -n dev
  Note: Column and index additions are safe to roll back
  The schema_version record can be manually removed if needed
