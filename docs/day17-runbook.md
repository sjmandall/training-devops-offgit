# Day 17 – ConfigMaps, Secrets and Probes

## Overview
This runbook documents externalizing configuration via ConfigMap,
storing credentials in Secret, adding readiness and liveness probes
to the Deployment, and validating rolling updates on WSL Ubuntu
with minikube.

---

## 1. Environment

- OS          : Ubuntu 24.04 (WSL)
- Kubernetes  : minikube v1.38.1
- Driver      : Docker
- App image   : training-site:1.0.0
- Project dir : ~/project
- YAML dir    : ~/project/k8s/

---

## 2. What was done

| Task | Method |
|---|---|
| Externalize config | ConfigMap YAML applied via kubectl |
| Store credentials | Secret created via CLI (safe method) |
| Health checks | Readiness and Liveness probes added to Deployment |
| Zero downtime update | RollingUpdate strategy configured |

---

## 3. ConfigMap

ConfigMap stores non-sensitive configuration data as key-value pairs
separately from the Docker image. This means config can change without
rebuilding the image.

### File: k8s/configmap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: training-site-config
data:
  APP_ENV: "production"
  APP_VERSION: "1.0.0"
  APP_NAME: "training-site"
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
```

### Apply ConfigMap
```bash
kubectl apply -f k8s/configmap.yaml
```

### Verify ConfigMap
```bash
kubectl get configmaps
kubectl describe configmap training-site-config
```

### Key fields explained:
- `kind: ConfigMap` – creates a ConfigMap object in Kubernetes
- `metadata: name` – name used to reference in Deployment
- `data:` – key-value pairs injected as env vars into pod
- `APP_ENV` – tells app which environment it runs in
- `APP_VERSION` – app version number for logging
- `LOG_LEVEL` – controls how much logging app does
- `MAX_CONNECTIONS` – limits connection pool size

---

## 4. Secret

Secret stores sensitive credentials. Values are base64 encoded
by Kubernetes automatically. Never store secrets in YAML files
committed to GitHub.

### Method used: CLI (safe method)
```bash
kubectl create secret generic training-site-secret \
  --from-literal=DB_PASSWORD='TrainingPass123' \
  --from-literal=DB_USER='dbadmin' 
```

### Verify Secret
```bash
kubectl get secrets
kubectl describe secret training-site-secret
```

## 5. Deployment YAML with ConfigMap, Secret and Probes

### File: k8s/deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: training-site
  labels:
    app: training-site
spec:
  replicas: 1
  selector:
    matchLabels:
      app: training-site
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: training-site
    spec:
      containers:
        - name: training-site
          image: training-site:1.0.0
          imagePullPolicy: Never
          ports:
            - containerPort: 80
          envFrom:
            - configMapRef:
                name: training-site-config
            - secretRef:
                name: training-site-secret
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
            failureThreshold: 3
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 15
            periodSeconds: 20
            failureThreshold: 3
```

---

## 6. Key fields in Deployment explained

### Rolling Update Strategy
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```
- `type: RollingUpdate` – update pods one at a time (zero downtime)
- `maxSurge: 1` – allow 1 extra pod during update
- `maxUnavailable: 0` – never have 0 running pods during update


### ConfigMap injection
```yaml
envFrom:
  - configMapRef:
      name: training-site-config
```
- `envFrom` – inject all ConfigMap keys as env vars
- `configMapRef` – reference ConfigMap by name
- All keys become environment variables in container

### Secret injection
```yaml
  - secretRef:
      name: training-site-secret
```
- `secretRef` – reference Secret by name
- Values automatically decoded from base64
- Available as env vars in container

### Readiness Probe
```yaml
readinessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 10
  failureThreshold: 3
```
- Checks if app is ready to receive traffic
- HTTP GET to / on port 80
- Wait 5s after container starts before first check
- Check every 10 seconds
- Fail 3 times before marking not ready
- On failure: remove pod from service (no traffic sent)

### Liveness Probe
```yaml
livenessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 15
  periodSeconds: 20
  failureThreshold: 3
```
- Checks if app is still alive
- HTTP GET to / on port 80
- Wait 15s after container starts before first check
- Check every 20 seconds
- Fail 3 times before restarting container
- On failure: restart the container automatically

## 7. Apply all YAMLs

```bash
cd ~/project

# Apply ConfigMap
kubectl apply -f k8s/configmap.yaml

# Apply updated Deployment
kubectl apply -f k8s/deployment.yaml

# Service and Ingress from Day 16 (no changes needed)
kubectl get services
kubectl get ingress
```

---

## 8. Validate YAML before applying

```bash
# Validate locally without applying
kubectl apply --dry-run=client -f k8s/deployment.yaml
```

## 9. Verify with kubectl describe pod

```bash
# Get pod name
kubectl get pods

# Describe pod
kubectl describe pod <pod-name>
```

Look for in output:
```
Environment Variables from:
training-site-config ConfigMap Optional: false
training-site-secret Secret Optional: false

Liveness: http-get http://:80/ delay=15s timeout=1s period=20s
Readiness: http-get http://:80/ delay=5s timeout=1s period=10s
```


---

## 10. Verify env vars injected inside pod

```bash
# Check specific env vars
kubectl exec -it <pod-name> -- env | grep -E "APP_ENV|APP_VERSION|DB_USER|LOG_LEVEL"
```

Expected output:
```
APP_ENV=production
APP_VERSION=1.0.0
APP_NAME=training-site
LOG_LEVEL=info
DB_USER=trainingapp
```

## 11. Validate Rolling Update

### Trigger rolling update by editing ConfigMap:
```bash
kubectl edit configmap training-site-config
# Change APP_VERSION from 1.0.0 to 2.0.0
```

### Restart deployment to pick up ConfigMap changes:
```bash
kubectl rollout restart deployment/training-site
```

### Watch rolling update happen:
```bash
kubectl rollout status deployment/training-site
```

Expected output:
```
Waiting for deployment "training-site" rollout to finish...
deployment "training-site" successfully rolled out
```



### Rollback commands (for reference):
```bash
# Rollback to previous version
kubectl rollout undo deployment/training-site

# Rollback to specific revision
kubectl rollout undo deployment/training-site --to-revision=1
```

### Verify change applied after rollout:
```bash
kubectl exec -it <pod-name> -- env | grep APP_VERSION
# Output: APP_VERSION=2.0.0
```

---

## 14. Commands Reference

```bash
# Apply ConfigMap
kubectl apply -f k8s/configmap.yaml

# Create Secret
kubectl create secret generic training-site-secret \
  --from-literal=DB_PASSWORD='StrongPassword123!' \
  --from-literal=DB_USER='trainingapp' \
  

# Apply Deployment
kubectl apply -f k8s/deployment.yaml

# Validate YAML
kubectl apply --dry-run=client -f k8s/deployment.yaml

# Describe pod
kubectl describe pod <pod-name>

# Check env vars
kubectl exec -it <pod-name> -- env | grep APP_VERSION

# Rollout restart
kubectl rollout restart deployment/training-site

# Rollout status
kubectl rollout status deployment/training-site

# Rollout history
kubectl rollout history deployment/training-site


