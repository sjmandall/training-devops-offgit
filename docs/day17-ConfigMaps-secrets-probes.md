# Day 17 – ConfigMaps, Secrets and Probes

## Overview
Externalize configuration via ConfigMap, store credentials in Secret,
add readiness and liveness probes, and validate rolling update.

---

## Files created/modified
- k8s/configmap.yaml   (new)
- k8s/deployment.yaml  (updated with envFrom and probes)

---

## ConfigMap
Stores non-sensitive config as environment variables.
Created via YAML and applied with kubectl apply.

## Secret
Stores sensitive credentials as base64 encoded values.
Created via CLI only (never stored in YAML in repo).

### Secret creation command:
kubectl create secret generic training-site-secret \
  --from-literal=DB_PASSWORD='MySecretPass123' \
  --from-literal=DB_USER='dbadmin' 

---

## Probes

### Readiness Probe
- Checks if app is ready to receive traffic
- HTTP GET / on port 80
- Starts after 5 seconds
- Checks every 10 seconds
- Fails 3 times before marking not ready

### Liveness Probe
- Checks if app is still alive
- HTTP GET / on port 80
- Starts after 15 seconds
- Checks every 20 seconds
- Fails 3 times before restarting container

---

## Rolling Update
- Strategy: RollingUpdate
- maxSurge: 1 (1 extra pod during update)
- maxUnavailable: 0 (zero downtime)
- Trigger: kubectl rollout restart deployment/training-site
- Verify: kubectl rollout status deployment/training-site

---

## Evidence
- kubectl describe pod shows probes and env from ConfigMap and Secret
- kubectl rollout status shows successful rolling update
- kubectl exec into pod shows env vars injected correctly

##kubectl describe pod training-site-64cb88b86-sg9nj
Name:             training-site-64cb88b86-sg9nj
Namespace:        default
Priority:         0
Service Account:  default
Node:             minikube/192.168.49.2
Start Time:       Mon, 06 Apr 2026 11:59:16 +0530
Labels:           app=training-site
                  pod-template-hash=64cb88b86
Annotations:      kubectl.kubernetes.io/restartedAt: 2026-04-06T11:59:16+05:30
Status:           Running
IP:               10.244.0.15
IPs:
  IP:           10.244.0.15
Controlled By:  ReplicaSet/training-site-64cb88b86
Containers:
  training-site:
    Container ID:   docker://f3d08dae29bd878caa95ea2a7f90400aa849a08aebc6be6fe321e70268ccb6c6
    Image:          training-site:1.0.0
    Image ID:       docker://sha256:6f6e51af924def3bacadfcf6aa0933cab269ccd5c3ad2a2a1b1141d766fc3926
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Mon, 06 Apr 2026 11:59:17 +0530
    Ready:          True
    Restart Count:  0
    Liveness:       http-get http://:80/ delay=15s timeout=1s period=20s #success=1 #failure=3
    Readiness:      http-get http://:80/ delay=5s timeout=1s period=10s #success=1 #failure=3
    Environment Variables from:
      training-site-config  ConfigMap  Optional: false
      training-site-secret  Secret     Optional: false
    Environment:            <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-p8tjs (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
Volumes:
  kube-api-access-p8tjs:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  22m   default-scheduler  Successfully assigned default/training-site-64cb88b86-sg9nj to minikube
  Normal  Pulled     22m   kubelet            spec.containers{training-site}: Container image "training-site:1.0.0" already present on machine and can be accessed by the pod
  Normal  Created    22m   kubelet            spec.containers{training-site}: Container created
  Normal  Started    22m   kubelet            spec.containers{training-site}: Container started
#webadmin@SJMANDAL:~/project$ kubectl rollout status deployment/training-site
#webadmin@SJMANDAL:~/project$ kubectl exec -it training-site-64cb88b86-sg9nj -- env | grep -E "APP_ENV|APP_VERSION|DB_USER|LOG_LEVEL"
DB_USER=trainingapp
APP_VERSION=2.0.0
LOG_LEVEL=info
APP_ENV=production
webadmin@SJMANDAL:~/project$
