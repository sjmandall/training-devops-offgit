Day 23 Runbook

Topic
Central logging using Loki and Grafana on Kubernetes.

Objective
- Deploy Loki logging stack in Kubernetes using Helm.
- Deploy Promtail as log shipping agent.
- Connect Loki to existing Grafana from Day 22.
- Query logs using LogQL.
- Show one request trace in Grafana Explore.
- Export query example and screenshot as evidence.

Evidence Required
1. Logging stack manifests committed (k8s/monitoring/loki-values.yaml).
2. Query example saved in docs/day23-logging.md.
3. Screenshot of log query result.

Environment
- Host: Windows with WSL2 Ubuntu 24.04
- User: webadmin
- Minikube: running locally on WSL
- Kubernetes namespace: monitoring
- Loki Helm release: loki
- Loki URL internal: http://loki:3100
- Grafana URL: http://localhost:3000 via port-forward
- Grafana login: admin / admin123
- Repo: https://github.com/sjmandall/training-devops-offgit.git

Prerequisites
- Minikube running: minikube status
- Grafana already running from Day 22
- Prometheus stack already installed from Day 22
- kubectl configured: kubectl get nodes
- Helm installed: helm version

Project Structure

k8s/
  monitoring/
    prometheus-values.yaml  from Day 22
    loki-values.yaml        new for Day 23

docs/
  day23-runbook.txt
  day23-logging.md
  day23-pods-running.txt

Architecture

Kubernetes pods write logs to stdout and stderr
        down
Promtail DaemonSet one pod per node
  reads /var/log/pods/
  ships logs to Loki
        down
Loki SingleBinary
  stores on filesystem
  indexes by labels
  retains 24 hours
  answers LogQL queries
        down
Grafana
  connects to http://loki:3100
  runs LogQL queries
  displays log lines in browser

Step 1: Verify prerequisites

  minikube status
  kubectl get nodes
  kubectl get pods -n monitoring
  helm version

If Minikube not running:
  minikube start --memory=2200mb --cpus=2

If Grafana port-forward not running:
  kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80 &

Step 2: Add Grafana Helm repo

  helm repo add grafana https://grafana.github.io/helm-charts
  helm repo update

Step 3: Create loki-values.yaml

File: ~/project/k8s/monitoring/loki-values.yaml

  mkdir -p ~/project/k8s/monitoring

Full file content:

deploymentMode: SingleBinary

loki:
  auth_enabled: false
  commonConfig:
    replication_factor: 1
  storage:
    type: filesystem
  schemaConfig:
    configs:
      - from: "2024-01-01"
        store: tsdb
        object_store: filesystem
        schema: v13
        index:
          prefix: loki_index_
          period: 24h
  limits_config:
    retention_period: 24h
  resources:
    requests:
      memory: 128Mi
      cpu: 100m
    limits:
      memory: 256Mi
      cpu: 200m

singleBinary:
  replicas: 1
  resources:
    requests:
      memory: 128Mi
      cpu: 100m
    limits:
      memory: 256Mi
      cpu: 200m
  persistence:
    enabled: true
    size: 1Gi

backend:
  replicas: 0
read:
  replicas: 0
write:
  replicas: 0

chunksCache:
  enabled: false

resultsCache:
  enabled: false

promtail:
  enabled: true
  config:
    clients:
      - url: http://loki:3100/loki/api/v1/push
    scrapeConfigs:
      - job_name: kubernetes-pods
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_node_name]
            target_label: __host__
          - action: labelmap
            regex: __meta_kubernetes_pod_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            target_label: namespace
          - source_labels: [__meta_kubernetes_pod_name]
            target_label: pod
          - source_labels: [__meta_kubernetes_pod_container_name]
            target_label: container
          - source_labels: [__meta_kubernetes_pod_node_name]
            target_label: node
          - replacement: /var/log/pods/*$1/*.log
            separator: /
            source_labels:
              - __meta_kubernetes_pod_uid
              - __meta_kubernetes_pod_container_name
            target_label: __path__
  resources:
    requests:
      memory: 64Mi
      cpu: 50m
    limits:
      memory: 128Mi
      cpu: 100m

gateway:
  enabled: false

test:
  enabled: false

Values explained:

deploymentMode: SingleBinary
  All Loki components run in one pod.
  Required for filesystem storage.
  Default Scalable mode requires AWS S3 or GCS.

auth_enabled: false
  No authentication for local dev.
  Production always uses true.

replication_factor: 1
  One copy of logs stored.
  Production uses 3 for redundancy.
  Single-node Minikube only supports 1.

storage.type: filesystem
  Store logs on local disk.
  No cloud account needed.

schema: v13
  Latest stable Loki schema version.
  tsdb = modern index format.
  period: 24h = new index file every day.

retention_period: 24h
  Auto-delete logs older than 24 hours.
  Saves disk space on WSL.

backend read write replicas: 0
  Disable scalable components.
  Scalable mode needs object storage.
  SingleBinary handles everything in one pod.

chunksCache and resultsCache: disabled
  Cache pods need 200-500MB RAM each.
  WSL does not have enough memory.
  Loki reads from disk directly instead.

promtail.enabled: true
  Install Promtail as DaemonSet.
  Reads /var/log/pods/ on each node.
  Ships logs to Loki at http://loki:3100.

gateway.enabled: false
  Not needed in SingleBinary mode.
  Gateway routes between separate components.
  One pod means no routing needed.

Step 4: Install Loki via Helm

  helm upgrade --install loki \
    grafana/loki \
    -f ~/project/k8s/monitoring/loki-values.yaml \
    -n monitoring \
    --timeout 300s

Step 5: Wait for pods

  kubectl get pods -n monitoring -w

Expected:
  loki-0              Running
  loki-canary-xxx     Running
  loki-promtail-xxx   Running

Step 6: Verify services

  kubectl get svc -n monitoring | grep loki

Expected:
  loki              ClusterIP   3100/TCP
  loki-canary       ClusterIP   3500/TCP
  loki-headless     ClusterIP   3100/TCP
  loki-memberlist   ClusterIP   7946/TCP

Step 7: Add Loki data source in Grafana

Open http://localhost:3000
Left sidebar > Connections > Data sources
Click Add data source
Select Loki

URL: http://loki:3100


Click Save and Test.
Expected: Data source connected and labels found.

Step 8: Explore logs in Grafana

Left sidebar > Explore
Select loki-1 as data source
Click Label browser to see labels:
  pod
  service_name
  stream: stdout or stderr

Click Code tab for manual query entry.

Step 9: LogQL queries for evidence

Query 1: All stdout logs
  {stream="stdout"}

Query 2: Logs from specific pod
  {pod="loki-canary-sr2ql"}

Query 3: HTTP GET request trace (one request trace)
  {stream="stdout"} |= "GET"

Query 4: Filter for log level
  {stream="stdout"} |= "level"

Query 5: Show only errors
  {stream="stderr"}

Query 6: Exclude debug logs
  {stream="stdout"} != "debug"


Step 10: Screenshot for evidence 3

Run query: {stream="stdout"}
Save as day23-log-query-screenshot.png

Step 11: Add Logs panel to dashboard

Open Node Metrics dashboard
Click Add > Visualization
Change data source to loki-1
Enter query: {stream="stdout"}
Right sidebar change type to Logs
Title: Kubernetes Pod Logs
Click Save dashboard

Step 12: Create docs/day23-logging.md

  cat > ~/project/docs/day23-logging.md <<'LOGEOF'
  Day 23 Logging - Loki and Grafana

  Stack deployed:
    Loki: SingleBinary mode filesystem storage
    Promtail: log shipping agent DaemonSet
    Grafana: log visualization from Day 22

  Loki data source URL: http://loki:3100

  Available labels:
    pod
    service_name
    stream stdout or stderr

  LogQL queries:

  All stdout logs:
    {stream="stdout"}

  Specific pod:
    {pod="loki-canary-sr2ql"}

  HTTP GET request trace:
    {stream="stdout"} |= "GET"

  Log level filter:
    {stream="stdout"} |= "level"

  Errors only:
    {stream="stderr"}

  How LogQL works:
    {stream="stdout"}  = label selector required always
    |= "GET"           = include lines containing GET
    != "debug"         = exclude lines containing debug
    | json             = parse JSON log lines
    | logfmt           = parse key=value log lines

  Architecture flow:
    Pod logs to stdout
    Promtail reads /var/log/pods/
    Promtail ships to http://loki:3100/loki/api/v1/push
    Loki stores with 24h retention
    Grafana queries http://loki:3100
    You see logs in browser
  LOGEOF

Step 13: Capture pods evidence

  kubectl get pods -n monitoring \
    > ~/project/docs/day23-pods-running.txt

  kubectl get svc -n monitoring \
    >> ~/project/docs/day23-pods-running.txt


