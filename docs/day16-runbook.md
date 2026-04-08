# Day 16 – Kubernetes Deploy + Ingress Routing

## Overview
This runbook documents deploying the training-site app using Kubernetes
Deployment and Service, configuring Ingress for mysite.sj routing,
and verifying access via curl and browser on WSL Ubuntu.

---

## 1. Environment

- OS          : Ubuntu 24.04 (WSL)
- Kubernetes  : minikube v1.38.1
- Driver      : Docker
- App image   : training-site:local
- Hostname    : mysite.sj
- Project dir : ~/project
- YAML dir    : ~/project/k8s/

---

## 2. Prerequisites

### Ensure minikube is running
```bash
minikube start
minikube status
```

### Ensure ingress addon is enabled
```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx
```

### Ensure image is available in minikube
```bash
eval $(minikube docker-env)
docker build -f docker/Dockerfile -t training-site:1.0.0 .
minikube image ls | grep training-site
```

---

## 3. Kubernetes Objects Created

Three objects are needed to deploy and expose the app:

| Object | File | Purpose |
|---|---|---|
| Deployment | k8s/deployment.yaml | Runs app container as pods |
| Service | k8s/service.yaml | Exposes pods inside cluster |
| Ingress | k8s/ingress.yaml | Routes external traffic to service |

### Traffic flow:
Browser (http://mysite.sj or http://localhost:7070)
↓
---

## 4. Deployment YAML (k8s/deployment.yaml)

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
  template:
    metadata:
      labels:
        app: training-site
    spec:
      containers:
        - name: training-site
          image: training-site:local
          imagePullPolicy: Never
          ports:
            - containerPort: 80
```

### Key fields explained:
- `replicas: 1` – run 1 pod
- `selector: matchLabels` – deployment manages pods with label app=training-site
- `imagePullPolicy: Never` – use local image, never pull from Docker Hub
- `containerPort: 80` – container listens on port 80

---

## 5. Service YAML (k8s/service.yaml)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: training-site
  labels:
    app: training-site
spec:
  selector:
    app: training-site
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
```

### Key fields explained:
- `selector: app: training-site` – routes traffic to pods with this label
- `port: 80` – service listens on port 80
- `targetPort: 80` – forwards to port 80 on pod
- `type: LoadBalancer` – gets external IP (used with minikube tunnel)

### Service types comparison:
| Type | Internal | External | Use case |
|---|---|---|---|
| ClusterIP | Yes | No | Internal pod communication |
| NodePort | Yes | Yes (node IP) | Dev/test access |
| LoadBalancer | Yes | Yes (external IP) | Production cloud |
| ExternalName | DNS only | No | External DB/API access |

---

## 6. Ingress YAML (k8s/ingress.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: training-site
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: mysite.sj
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: training-site
                port:
                  number: 80
```

### Key fields explained:
- `ingressClassName: nginx` – use nginx ingress controller
- `host: mysite.sj` – only handle requests for this hostname
- `path: /` – match all paths
- `pathType: Prefix` – match / and everything after
- `backend: service: name: training-site` – send to training-site service
- `port: number: 80` – use service port 80

---

## 7. Apply YAMLs to Cluster

```bash
cd ~/project

# Apply all at once
kubectl apply -f k8s/

# Or apply individually
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
```

---

## 8. Verify All Objects Running

```bash
# Check deployment
kubectl get deployments

# Check pods
kubectl get pods

# Check service
kubectl get services

# Check ingress
kubectl get ingress

# Check ingress controller
kubectl get pods -n ingress-nginx
```

### Expected output:

#### kubectl get deployments
kubectl port-forward (WSL workaround)
↓
Ingress-nginx controller
↓
Service (ClusterIP/LoadBalancer)
↓
Pod (training-site container)
↓
App responds with HTML


---

## 4. Deployment YAML (k8s/deployment.yaml)

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
```

### Key fields explained:
- `replicas: 1` – run 1 pod
- `selector: matchLabels` – deployment manages pods with label app=training-site
- `imagePullPolicy: Never` – use local image, never pull from Docker Hub
- `containerPort: 80` – container listens on port 80

---

## 5. Service YAML (k8s/service.yaml)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: training-site
  labels:
    app: training-site
spec:
  selector:
    app: training-site
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
```

### Key fields explained:
- `selector: app: training-site` – routes traffic to pods with this label
- `port: 80` – service listens on port 80
- `targetPort: 80` – forwards to port 80 on pod
- `type: LoadBalancer` – gets external IP (used with minikube tunnel)

### Service types comparison:
| Type | Internal | External | Use case |
|---|---|---|---|
| ClusterIP | Yes | No | Internal pod communication |
| NodePort | Yes | Yes (node IP) | Dev/test access |
| LoadBalancer | Yes | Yes (external IP) | Production cloud |
| ExternalName | DNS only | No | External DB/API access |

---

## 6. Ingress YAML (k8s/ingress.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: training-site
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: mysite.sj
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: training-site
                port:
                  number: 80
```

### Key fields explained:
- `ingressClassName: nginx` – use nginx ingress controller
- `host: mysite.sj` – only handle requests for this hostname
- `path: /` – match all paths
- `pathType: Prefix` – match / and everything after
- `backend: service: name: training-site` – send to training-site service
- `port: number: 80` – use service port 80

---

## 7. Apply YAMLs to Cluster

```bash
cd ~/project

# Apply all at once
kubectl apply -f k8s/

# Or apply individually
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
```

---

## 8. Verify All Objects Running

```bash
# Check deployment
kubectl get deployments

# Check pods
kubectl get pods

# Check service
kubectl get services

# Check ingress
kubectl get ingress

# Check ingress controller
kubectl get pods -n ingress-nginx
```


---

## 9. Add mysite.sj to /etc/hosts

```bash
# Get minikube IP
minikube ip
# Output: 192.168.49.2

# Add to WSL /etc/hosts
echo "$(minikube ip) mysite.sj" | sudo tee -a /etc/hosts

# Verify
cat /etc/hosts | grep mysite.sj
# Output: 192.168.49.2 mysite.sj
```




---

## 10. Verify with curl (WSL)

```bash
# Using hostname
curl -H "Host: mysite.sj" http://mysite.sj

# Using minikube IP directly
curl -H "Host: mysite.sj" http://192.168.49.2
```

Expected output:
```html
<!DOCTYPE html>
<html>
<head><title>Home</title></head>
<body>
  <h1>Home</h1>
  <p>This is the home page.</p>
</body>
</html>
```

---


