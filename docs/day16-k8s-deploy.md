# Day 16 – Kubernetes Deploy + Ingress Routing

## Overview
Deploy the training-site app using Kubernetes Deployment and Service,
configure Ingress for mysite.sj routing, and verify in browser.

---

## Files created
- k8s/deployment.yaml
- k8s/service.yaml
- k8s/ingress.yaml

---

## Commands used

### Apply YAMLs
kubectl apply -f k8s/

### Check status
kubectl get deployments
kubectl get pods
kubectl get services
kubectl get ingress

### Add hosts entry
echo "$(minikube ip) mysite.sj" | sudo tee -a /etc/hosts

### Port forward to access from browser
kubectl port-forward service/training-site 7070:80

### Verify with curl
curl -H "Host: mysite.sj" http://mysite.sj

### Verify in browser
http://localhost:7070

---

## Evidence
- YAMLs in k8s/ directory
- curl -H "Host: mysite.sj" http://mysite.sj returns HTML
- Browser shows app at http://localhost:7070

---

## Notes
- minikube tunnel does not work on WSL due to WSL networking boundary
- kubectl port-forward binds to localhost which is shared between WSL and Windows
- Ingress-nginx correctly routes traffic inside cluster
- Port-forward is used as WSL workaround for browser access

