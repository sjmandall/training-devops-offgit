# Day 15 – Kubernetes Local + Registry Setup

## Overview
This document covers the setup of a local Kubernetes cluster using minikube
on WSL Ubuntu, enabling the ingress addon, and setting up a local image
workflow so Kubernetes can pull freshly built Docker images.

---

## 1. Environment

- OS         : Ubuntu (WSL)
- Kubernetes : minikube
- Driver     : Docker
- kubectl    : latest stable

---

## 2. Installation Steps

### kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client
```

### minikube
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube version
```

---

## 3. Start Cluster
```bash
minikube start --driver=docker
minikube status
kubectl get nodes
```

---

## 4. Enable Ingress Addon
```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx
```

---

## 5. Local Image Workflow

### Point shell to minikube Docker daemon
```bash
eval $(minikube docker-env)
```

### Build image inside minikube
```bash
docker build -f docker/Dockerfile -t training-site:local .
```

### Verify image available to cluster
```bash
minikube image ls | grep training-site
```

###Load existing image into minikube
If you already built the image locally:

```
minikube image load training-site:local
```
---

## 6. Evidence

- Cluster running: minikube status shows Running
- App image available: minikube image ls shows training-site:local
- Ingress addon enabled: kubectl get pods -n ingress-nginx shows Running

---

## 7. Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| minikube start fails | Docker not running | sudo service docker start |
| Image not found in cluster | Built outside minikube Docker | eval $(minikube docker-env) then rebuild |
| kubectl not connecting | minikube not started | minikube start --driver=docker |
| Ingress pods not running | Addon not enabled | minikube addons enable ingress |

---


