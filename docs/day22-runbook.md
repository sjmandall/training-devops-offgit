Day 22 Runbook

Topic
Observability - metrics using Prometheus and Grafana on Kubernetes.

Objective
- Deploy Prometheus and Grafana locally in Kubernetes using Helm.
- Deploy Node Exporter to collect system metrics.
- Create one dashboard with CPU and Memory panels.
- Export dashboard as JSON evidence.
- Capture screenshot of panel with live data.

Evidence Required
1. Evidence Prometheus and Grafana running.
2. One dashboard exported as JSON.
3. Screenshot of panel with data.

Environment
- Host: Windows with WSL2 Ubuntu 24.04
- User: webadmin
- Minikube: running locally on WSL
- Kubernetes namespace: monitoring
- Helm release name: prometheus-stack
- Grafana URL: http://localhost:3000 (via port-forward)
- Prometheus URL: http://localhost:9090 (via port-forward)
- Grafana login: admin / admin123
- Repo: https://github.com/sjmandall/training-devops-offgit.git

Prerequisites
- Minikube running: minikube status
- kubectl configured: kubectl get nodes
- Helm installed: helm version
- Sufficient RAM: minikube start --memory=2200mb --cpus=2

Project Structure

k8s/
  monitoring/
    prometheus-values.yaml

docs/
  day22-runbook.txt
  day22-pods-running.txt
  day22-grafana-dashboard.json

Step 1: Start Minikube with enough memory

  minikube status

If not running:

  minikube start --memory=2200mb --cpus=2

Why memory limit:
  Total WSL RAM is only 3593MB.
  Default Minikube allocation of 3072MB leaves no room for system overhead.
  2200MB gives Minikube enough for Prometheus and Grafana.
  Leaves around 1400MB for Windows WSL and Docker overhead.

Verify:
  kubectl get nodes

Expected:
  NAME       STATUS   ROLES           AGE   VERSION
  minikube   Ready    control-plane   ...   v1.x.x

Step 2: Add Helm repositories

  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo add grafana https://grafana.github.io/helm-charts
  helm repo update


Step 3: Create monitoring namespace

  kubectl create namespace monitoring


Step 4: Create prometheus-values.yaml

File location: ~/project/k8s/monitoring/prometheus-values.yaml

  mkdir -p ~/project/k8s/monitoring

Content:

prometheus:
  prometheusSpec:
    retention: 24h
    resources:
      requests:
        memory: 400Mi
        cpu: 200m
      limits:
        memory: 800Mi
        cpu: 500m

grafana:
  enabled: true
  adminPassword: "admin123"
  service:
    type: NodePort
    nodePort: 32000
  resources:
    requests:
      memory: 128Mi
      cpu: 100m
    limits:
      memory: 256Mi
      cpu: 200m

nodeExporter:
  enabled: true

alertmanager:
  enabled: false

Step 5: Install kube-prometheus-stack via Helm

  helm upgrade --install prometheus-stack \
    prometheus-community/kube-prometheus-stack \
    -f ~/project/k8s/monitoring/prometheus-values.yaml \
    -n monitoring \
    --timeout 300s


Step 6: Wait for pods to be ready

  kubectl get pods -n monitoring -w

Wait until all pods show Running. Press Ctrl+C to stop watching.

Expected pods:
  prometheus-stack-grafana                          Running
  prometheus-stack-kube-prom-operator               Running
  prometheus-stack-kube-state-metrics               Running
  prometheus-stack-prometheus-node-exporter         Running
  prometheus-prometheus-stack-kube-prom-prometheus  Running

This takes 2-5 minutes on WSL.

Step 7: Verify all services

  kubectl get svc -n monitoring

Services after install:
  prometheus-operated                         ClusterIP  9090/TCP
  prometheus-stack-grafana                    NodePort   80:32000/TCP
  prometheus-stack-kube-prom-operator         ClusterIP  443/TCP
  prometheus-stack-kube-prom-prometheus       ClusterIP  9090/TCP
  prometheus-stack-kube-state-metrics         ClusterIP  8080/TCP
  prometheus-stack-prometheus-node-exporter   ClusterIP  9100/TCP

Step 8: Access Prometheus UI

Port forward in WSL terminal 1:

  kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090

Open in Windows browser:
  http://localhost:9090

Go to Status > Target health to see all scrape targets.
All targets should show State UP.

Step 9: Access Grafana UI

Port forward in WSL terminal 2:

  kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80

Open in Windows browser:
  http://localhost:3000

Login:
  Username: admin
  Password: admin123

Step 10: Create dashboard with panels

PromQL queries explained:

CPU query:
  node_cpu_seconds_total{mode="idle"} = CPU time spent idle per second
  irate(...[5m])                      = instant rate over 5 minute window
  avg(...)                            = average across all CPU cores
  100 - (result * 100)                = convert idle to used percentage

Memory query:
  node_memory_MemAvailable_bytes = available memory from Node Exporter
  node_memory_MemTotal_bytes     = total system memory
  division * 100                 = percentage of memory available

Step 11: Export dashboard JSON (evidence 2)


Method 1 via Grafana UI:
  1. Open dashboard
  2. Click Settings (top right gear icon)
  3. Click JSON Model in left sidebar
  4. Copy all JSON content
  5. Paste into ~/project/docs/day22-grafana-dashboard.json

Step 12: Capture pods evidence (evidence 1)

  kubectl get pods -n monitoring \
    > ~/project/docs/day22-pods-running.txt

  kubectl get svc -n monitoring \
    >> ~/project/docs/day22-pods-running.txt

  cat ~/project/docs/day22-pods-running.txt

Step 13: Take screenshot (evidence 3)


Dashboard should show:
  Node Metrics dashboard
  CPU Usage % panel with live time series graph
  Memory Available % panel with live time series graph

Step 14: Commit all evidence files

  cd ~/project

  git add k8s/monitoring/prometheus-values.yaml
  git add docs/day22-runbook.txt
  git add docs/day22-pods-running.txt
  git add docs/day22-grafana-dashboard.json

  git status

  git commit -m "feat: day22 Prometheus Grafana observability on Kubernetes"
  git push origin main


Day 22 Outcomes Checklist

  Requirement                              How satisfied
  Prometheus running in Kubernetes         kube-prometheus-stack in monitoring namespace
  Grafana running in Kubernetes            Included in kube-prometheus-stack chart
  Node Exporter running                    nodeExporter.enabled: true in values file
  Dashboard created                        Node Metrics dashboard with 2 panels
  CPU panel with live data                 PromQL: 100 - avg(irate(node_cpu_seconds_total))
  Memory panel with live data              PromQL: node_memory_MemAvailable_bytes query
  Dashboard exported as JSON               docs/day22-grafana-dashboard.json
  Screenshot of panel with data            docs/day22-grafana-screenshot.png
  Evidence Prometheus and Grafana running  docs/day22-pods-running.txt

