# Day 15 – Kubernetes Local + Registry Setup

## Overview
This runbook documents the setup of a local Kubernetes cluster using minikube
on WSL Ubuntu, enabling the ingress addon, and setting up a local image
workflow so Kubernetes can pull freshly built Docker images.

---

## 1. Environment

- OS          : Ubuntu 24.04 (WSL)
- Kubernetes  : minikube v1.38.1
- Driver      : Docker
- kubectl     : latest stable
- App image   : training-site:local / training-site:1.0.0
- Docker Hub  : sjmandall/realcide-01
- Project dir : ~/project

---

## 2. Prerequisites

### Ensure Docker is running
```
sudo service docker start
docker ps
```

### Ensure webadmin user is in docker group
```
sudo usermod -aG docker $USER && newgrp docker
groups
# docker should appear in the list
```

---

## 3. Install kubectl

```
# Download kubectl binary
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make executable
chmod +x kubectl

# Move to system path
sudo mv kubectl /usr/local/bin/

# Verify
kubectl version --client
```

---

## 4. Install minikube

```
# Download minikube binary
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Install
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Verify
minikube version
```

---

## 5. Start minikube Cluster

```bash
# First time: specify docker driver
minikube start --driver=docker

# Every time after that
minikube start

# Check status
minikube status
```

#Expected output:

minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

### Check nodes
```bash
kubectl get nodes
```


## 6. Enable Ingress Addon

```bash
# Enable ingress
minikube addons enable ingress

# Verify ingress controller pod is running
kubectl get pods -n ingress-nginx
```

### Load existing image into minikube

If you already built the image in system Docker:

```bash
minikube image load training-site:1.0.0

# Verify (no output = success)
minikube image ls | grep training-site
```

## 9. Create Test Deployment

```bash
# Create deployment
kubectl create deployment training-site --image=training-site:local

# Check deployment
kubectl get deployments

# Check pods
kubectl get pods
