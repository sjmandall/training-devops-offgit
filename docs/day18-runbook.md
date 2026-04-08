# Day 18 – Helm Chart + Values per Environment

## Overview
This runbook documents creating a Helm chart for the devops-training-site
PHP application, supporting separate values files for dev and production
environments, adding chart NOTES, and deploying both releases to minikube.

---

## 1. Environment

- OS          : Ubuntu 24.04 (WSL)
- Kubernetes  : minikube v1.38.1
- Helm        : v3.x.x
- Driver      : Docker
- App image   : training-site:1.0.0
- Project dir : ~/project
- Chart dir   : ~/project/k8s/helm/devops-training-site/

---

## 2. What is Helm

Helm is the package manager for Kubernetes.

Without Helm:
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/configmap.yaml
= 4 separate commands, hard to manage

With Helm:
helm upgrade --install dev ./devops-training-site
= 1 command installs everything



## 3. Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
helm version
```

---

## 4. Chart Structure
k8s/helm/devops-training-site/
├── Chart.yaml ← chart metadata
├── values.yaml ← default values
├── values-dev.yaml ← dev environment overrides
├── values-prod.yaml ← prod environment overrides
└── templates/
├── deployment.yaml ← deployment template
├── service.yaml ← service template
├── ingress.yaml ← ingress template
├── configmap.yaml ← configmap template
└── NOTES.txt ← message shown after helm install

---

## 5. Create Chart Structure

```bash
# Method 1: Let Helm create structure automatically
cd ~/project/k8s/helm
helm create devops-training-site

# Remove auto-generated templates
rm ~/project/k8s/helm/devops-training-site/templates/*.yaml
rm ~/project/k8s/helm/devops-training-site/templates/*.txt
rm ~/project/k8s/helm/devops-training-site/templates/_helpers.tpl

# Method 2: Create manually
mkdir -p ~/project/k8s/helm/devops-training-site/templates
```

---

## 6. Chart.yaml

```yaml
apiVersion: v2
name: devops-training-site
description: A Helm chart for the training-site PHP application
type: application
version: 0.1.0
appVersion: "1.0.0"
```

### Fields explained:
- `apiVersion: v2` – Helm 3 chart API version
- `name:` – chart name, must match folder name
- `description:` – what this chart does
- `type: application` – application chart (not library)
- `version:` – version of the chart itself
- `appVersion:` – version of the application

---

## 7. values.yaml (default values)

```yaml
replicaCount: 1

image:
  repository: training-site
  tag: "1.0.0"
  pullPolicy: Never

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  host: mysite.sj
  path: /

configmap:
  APP_ENV: "development"
  APP_VERSION: "1.0.0"
  APP_NAME: "training-site"
  LOG_LEVEL: "debug"
  MAX_CONNECTIONS: "10"

probes:
  readiness:
    path: /
    port: 80
    initialDelaySeconds: 5
    periodSeconds: 10
    failureThreshold: 3
  liveness:
    path: /
    port: 80
    initialDelaySeconds: 15
    periodSeconds: 20
    failureThreshold: 3
```

---

## 8. values-dev.yaml

```yaml
replicaCount: 1

image:
  repository: training-site
  tag: "1.0.0"
  pullPolicy: Never

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  host: mysite.sj
  path: /

configmap:
  APP_ENV: "development"
  APP_VERSION: "1.0.0"
  APP_NAME: "training-site"
  LOG_LEVEL: "debug"
  MAX_CONNECTIONS: "10"

probes:
  readiness:
    path: /
    port: 80
    initialDelaySeconds: 5
    periodSeconds: 10
    failureThreshold: 3
  liveness:
    path: /
    port: 80
    initialDelaySeconds: 15
    periodSeconds: 20
    failureThreshold: 3
```

---

## 9. values-prod.yaml

```yaml
replicaCount: 2

image:
  repository: training-site
  tag: "1.0.0"
  pullPolicy: Never

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  host: prod.mysite.sj
  path: /

configmap:
  APP_ENV: "production"
  APP_VERSION: "1.0.0"
  APP_NAME: "training-site"
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"

probes:
  readiness:
    path: /
    port: 80
    initialDelaySeconds: 5
    periodSeconds: 10
    failureThreshold: 3
  liveness:
    path: /
    port: 80
    initialDelaySeconds: 15
    periodSeconds: 20
    failureThreshold: 3
```



## 10. Template Files

### templates/deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-training-site
  labels:
    app: {{ .Release.Name }}-training-site
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}-training-site
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}-training-site
    spec:
      containers:
        - name: training-site
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.service.port }}
          envFrom:
            - configMapRef:
                name: {{ .Release.Name }}-config
            - secretRef:
                name: training-site-secret
          readinessProbe:
            httpGet:
              path: {{ .Values.probes.readiness.path }}
              port: {{ .Values.probes.readiness.port }}
            initialDelaySeconds: {{ .Values.probes.readiness.initialDelaySeconds }}
            periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
            failureThreshold: {{ .Values.probes.readiness.failureThreshold }}
          livenessProbe:
            httpGet:
              path: {{ .Values.probes.liveness.path }}
              port: {{ .Values.probes.liveness.port }}
            initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
            periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
            failureThreshold: {{ .Values.probes.liveness.failureThreshold }}
```

### templates/configmap.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-config
data:
  APP_ENV: {{ .Values.configmap.APP_ENV | quote }}
  APP_VERSION: {{ .Values.configmap.APP_VERSION | quote }}
  APP_NAME: {{ .Values.configmap.APP_NAME | quote }}
  LOG_LEVEL: {{ .Values.configmap.LOG_LEVEL | quote }}
  MAX_CONNECTIONS: {{ .Values.configmap.MAX_CONNECTIONS | quote }}
```

### templates/service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-training-site
  labels:
    app: {{ .Release.Name }}-training-site
spec:
  selector:
    app: {{ .Release.Name }}-training-site
  ports:
    - protocol: TCP
      port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.port }}
  type: {{ .Values.service.type }}
```

### templates/ingress.yaml
```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-training-site
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: {{ .Values.ingress.className }}
  rules:
    - host: {{ .Values.ingress.host }}
      http:
        paths:
          - path: {{ .Values.ingress.path }}
            pathType: Prefix
            backend:
              service:
                name: {{ .Release.Name }}-training-site
                port:
                  number: {{ .Values.service.port }}
{{- end }}
```

### templates/NOTES.txt

========================================
Training Site Helm Chart
========================================

Release name : {{ .Release.Name }}
Namespace : {{ .Release.Namespace }}
Environment : {{ .Values.configmap.APP_ENV }}
App version : {{ .Values.configmap.APP_VERSION }}
Replicas : {{ .Values.replicaCount }}
Image : {{ .Values.image.repository }}:{{ .Values.image.tag }}

Access your application:

Port forward to access in browser:
kubectl port-forward service/{{ .Release.Name }}-training-site 7070:80 -n {{ .Release.Namespace }}

Open in browser:
http://localhost:7070

Curl test:
curl -H "Host: {{ .Values.ingress.host }}" http://{{ .Values.ingress.host }}

Useful commands:

Check pods:
kubectl get pods -l app={{ .Release.Name }}-training-site -n {{ .Release.Namespace }}

Uninstall:
helm uninstall {{ .Release.Name }} -n {{ .Release.Namespace }}

========================================



---

## 11. Helm Template Syntax Explained

### Dot notation:
- `.` = root context
- `.Release` = built-in release info object
- `.Values` = your values.yaml content
- `.Chart` = your Chart.yaml content

### Built-in objects:
| Object | Example | Value |
|---|---|---|
| `.Release.Name` | release name | dev or prod |
| `.Release.Namespace` | namespace | dev or prod |
| `.Release.Revision` | upgrade count | 1, 2, 3 |
| `.Values.replicaCount` | from values file | 1 or 2 |
| `.Values.image.tag` | nested value | 1.0.0 |

### Helm functions:
- `| quote` – wraps value in double quotes
- `{{- if .Values.ingress.enabled }}` – conditional block
- `{{- end }}` – closes conditional block
- `-` in `{{-` removes extra whitespace

---

## 12. Validate Chart

```bash
# Lint chart for errors
helm lint ~/project/k8s/helm/devops-training-site

# Dry run with dev values
helm upgrade --install dev \
  ~/project/k8s/helm/devops-training-site \
  -f ~/project/k8s/helm/devops-training-site/values-dev.yaml \
  -n dev \
  --create-namespace \
  --dry-run

# Dry run with prod values
helm upgrade --install prod \
  ~/project/k8s/helm/devops-training-site \
  -f ~/project/k8s/helm/devops-training-site/values-prod.yaml \
  -n prod \
  --create-namespace \
  --dry-run
```

---

## 13. Create Secrets in Each Namespace

Secrets are namespace scoped. Must be created in each namespace separately.

```bash
# Dev namespace secret
kubectl create secret generic training-site-secret \
  --from-literal=DB_PASSWORD='TrainingPass123' \
  --from-literal=DB_USER='dbadmin' \
  --from-literal=API_KEY='demo-api-key-day18' \
  -n dev

# Prod namespace secret
kubectl create secret generic training-site-secret \
  --from-literal=DB_PASSWORD='TrainingPass123' \
  --from-literal=DB_USER='dbadmin' \
  --from-literal=API_KEY='demo-api-key-day18' \
  -n prod
```

---

## 14. Install Both Releases

```bash
# Install dev release
helm upgrade --install dev \
  ~/project/k8s/helm/devops-training-site \
  -f ~/project/k8s/helm/devops-training-site/values-dev.yaml \
  -n dev \
  --create-namespace

# Install prod release
helm upgrade --install prod \
  ~/project/k8s/helm/devops-training-site \
  -f ~/project/k8s/helm/devops-training-site/values-prod.yaml \
  -n prod \
  --create-namespace
```

### helm upgrade --install explained word by word:
- `helm` – Helm CLI
- `upgrade` – upgrade existing release
- `--install` – install if release does not exist yet
- `dev` or `prod` – release name
- path to chart – folder containing Chart.yaml
- `-f` – use this values file
- `-n dev` – install in dev namespace
- `--create-namespace` – create namespace if not exists

---

## 15. Verify Both Releases

```bash
# List all releases across all namespaces
helm list -A

# Check pods in dev
kubectl get pods -n dev

# Check pods in prod
kubectl get pods -n prod

# Check services in dev
kubectl get svc -n dev

# Check services in prod
kubectl get svc -n prod
```

### Expected helm list -A output:
NAME NAMESPACE REVISION STATUS CHART APP VERSION
dev dev 1 deployed devops-training-site-0.1.0 1.0.0
prod prod 1 deployed devops-training-site-0.1.0 1.0.0

text

---


