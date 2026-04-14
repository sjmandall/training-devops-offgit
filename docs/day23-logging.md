# Day 23 Logging - Loki + Grafana

## Stack deployed
- Loki: SingleBinary mode with filesystem storage
- Promtail: log shipping agent (DaemonSet)
- Grafana: log visualization (reused from Day 22)
- Namespace: monitoring

## Helm installation command
helm upgrade --install loki grafana/loki \
  -f k8s/monitoring/loki-values.yaml \
  -n monitoring

## Loki data source URL in Grafana
http://loki:3100

## Available labels in this setup
- pod
- service_name
- stream (stdout or stderr)

## LogQL query examples

### All stdout logs
{stream="stdout"}

### Logs from specific pod
{pod="loki-canary-sr2ql"}

### Filter for HTTP GET requests (one request trace)
{stream="stdout"} |= "GET"

### Filter for log level
{stream="stdout"} |= "level"

### Filter for errors only
{stream="stderr"}

### Exclude debug logs
{stream="stdout"} != "debug"

## How LogQL works
{stream="stdout"}     = select all stdout logs
|= "GET"              = include only lines containing GET
!= "debug"            = exclude lines containing debug
| json                = parse log lines as JSON format
| logfmt              = parse log lines as key=value format

## Architecture
Kubernetes pods write logs to stdout/stderr
        down
Promtail (DaemonSet) reads /var/log/pods/
        down
Loki (SingleBinary) stores and indexes logs
        down
Grafana queries Loki via http://loki:3100
        down
You see log lines in Grafana Explore

## Pods running
kubectl get pods -n monitoring | grep loki

## Services
kubectl get svc -n monitoring | grep loki
loki          ClusterIP   port 3100
loki-headless ClusterIP   port 3100

## Evidence files
- k8s/monitoring/loki-values.yaml
- docs/day23-logging.md
- docs/day23-pods-running.txt
- docs/day23-log-query-screenshot.png
