# Kubernetes Complete Documentation Guide

## Table of Contents
1. [Kubernetes Basics](#kubernetes-basics)
2. [Core Objects](#core-objects)
3. [Networking](#networking)
4. [Storage](#storage)
5. [Security](#security)
6. [Scaling & Availability](#scaling--availability)
7. [Observability](#observability)
8. [CI/CD & DevOps](#cicd--devops)
9. [Advanced Kubernetes](#advanced-kubernetes)
10. [Production Best Practices](#production-best-practices)

---

# Kubernetes Basics

## What is Kubernetes

### Overview
Kubernetes (K8s) is an open-source container orchestration platform that automates the deployment, scaling, and management of containerized applications. Originally developed by Google and now maintained by the Cloud Native Computing Foundation (CNCF), it has become the industry standard for container orchestration.

### Problems Kubernetes Solves
- **Manual container management**: Eliminates need for manual container lifecycle management across multiple hosts
- **Service discovery**: Automatically discovers and load balances containers
- **Scaling challenges**: Handles horizontal and vertical scaling automatically
- **Self-healing**: Automatically restarts failed containers and replaces nodes
- **Configuration management**: Centralizes application configuration and secrets
- **Resource optimization**: Efficiently utilizes infrastructure resources

### Core Capabilities
- Automated rollouts and rollbacks
- Service discovery and load balancing
- Storage orchestration
- Self-healing mechanisms
- Secret and configuration management
- Batch execution and job scheduling
- Horizontal scaling
- IPv4/IPv6 dual-stack support

### Kubernetes vs Alternatives

| Feature | Kubernetes | Docker Swarm | Nomad | ECS |
|---------|-----------|--------------|-------|-----|
| Complexity | High | Low | Medium | Low |
| Ecosystem | Extensive | Limited | Growing | AWS-centric |
| Scalability | Excellent | Good | Excellent | Good |
| Learning Curve | Steep | Gentle | Moderate | Moderate |
| Multi-cloud | Yes | Yes | Yes | AWS-only |

### When to Use Kubernetes
- Microservices architectures
- Multi-cloud or hybrid deployments
- Applications requiring high availability
- Complex scaling requirements
- Teams with container orchestration expertise

### When NOT to Use Kubernetes
- Simple applications with minimal scaling needs
- Small teams without DevOps expertise
- Monolithic applications with no containerization
- Budget-constrained projects (operational overhead)

---

## Kubernetes Architecture

### High-Level Overview
Kubernetes follows a master-worker architecture with a declarative model. Users declare desired state, and Kubernetes continuously works to maintain that state.

### Architecture Diagram
```
┌─────────────────────────────────────────────────────────────┐
│                     Control Plane                            │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐   │
│  │  API Server │  │  Scheduler   │  │ Controller Mgr  │   │
│  └─────────────┘  └──────────────┘  └─────────────────┘   │
│  ┌─────────────┐  ┌──────────────┐                         │
│  │    etcd     │  │ Cloud Ctrl   │                         │
│  └─────────────┘  └──────────────┘                         │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────▼────────┐  ┌───────▼────────┐  ┌──────▼─────────┐
│  Worker Node 1 │  │  Worker Node 2 │  │  Worker Node N │
│  ┌──────────┐  │  │  ┌──────────┐  │  │  ┌──────────┐  │
│  │  Kubelet │  │  │  │  Kubelet │  │  │  │  Kubelet │  │
│  └──────────┘  │  │  └──────────┘  │  │  └──────────┘  │
│  ┌──────────┐  │  │  ┌──────────┐  │  │  ┌──────────┐  │
│  │ Kube-Proxy│ │  │  │Kube-Proxy│  │  │  │Kube-Proxy│  │
│  └──────────┘  │  │  └──────────┘  │  │  └──────────┘  │
│  ┌──────────┐  │  │  ┌──────────┐  │  │  ┌──────────┐  │
│  │Container │  │  │  │Container │  │  │  │Container │  │
│  │ Runtime  │  │  │  │ Runtime  │  │  │  │ Runtime  │  │
│  └──────────┘  │  │  └──────────┘  │  │  └──────────┘  │
└────────────────┘  └────────────────┘  └────────────────┘
```

### Control Plane Components

#### API Server (kube-apiserver)
- **Purpose**: Front-end for Kubernetes control plane, exposes REST API
- **Responsibilities**:
  - Validates and processes REST requests
  - Updates etcd with cluster state
  - Serves as communication hub for all components
- **Key Features**:
  - Authentication and authorization
  - Admission control
  - RESTful interface (JSON/YAML)

#### etcd
- **Purpose**: Distributed key-value store for cluster state
- **Responsibilities**:
  - Stores all cluster data (configuration, state, metadata)
  - Provides consistency and high availability
  - Maintains cluster configuration and service discovery
- **Key Characteristics**:
  - Raft consensus algorithm
  - Watch mechanism for state changes
  - Backup and restore capabilities

#### Scheduler (kube-scheduler)
- **Purpose**: Assigns pods to nodes
- **Responsibilities**:
  - Watches for newly created pods with no assigned node
  - Selects optimal node based on resource requirements
  - Considers constraints and policies
- **Scheduling Factors**:
  - Resource requests (CPU, memory)
  - Node affinity/anti-affinity
  - Taints and tolerations
  - Pod topology spread

#### Controller Manager (kube-controller-manager)
- **Purpose**: Runs controller processes
- **Key Controllers**:
  - **Node Controller**: Monitors node health
  - **Replication Controller**: Maintains correct number of pods
  - **Endpoints Controller**: Populates Endpoints objects
  - **Service Account Controller**: Creates default service accounts
  - **Deployment Controller**: Manages Deployment rollouts

#### Cloud Controller Manager
- **Purpose**: Integrates with cloud provider APIs
- **Responsibilities**:
  - Node lifecycle management
  - Route management
  - Load balancer provisioning
  - Volume management

### Worker Node Components

#### Kubelet
- **Purpose**: Primary node agent
- **Responsibilities**:
  - Ensures containers are running in pods
  - Reports node and pod status to API server
  - Executes pod lifecycle hooks
  - Manages volume mounts
- **Key Functions**:
  - Pod spec execution
  - Health checking (probes)
  - Resource monitoring

#### Kube-proxy
- **Purpose**: Network proxy on each node
- **Responsibilities**:
  - Maintains network rules for pod communication
  - Implements Service abstraction
  - Load balances traffic to pods
- **Modes**:
  - **iptables**: Default, rule-based routing
  - **IPVS**: High-performance load balancing
  - **userspace**: Legacy mode

#### Container Runtime
- **Purpose**: Runs containers
- **Supported Runtimes**:
  - containerd (most common)
  - CRI-O
  - Docker Engine (via containerd)
- **Interface**: Container Runtime Interface (CRI)

---

## Control Plane & Worker Nodes

### Control Plane Deep Dive

#### High Availability Configuration
```yaml
# Multi-master setup for production
Control Plane Setup:
- 3+ master nodes (odd number for quorum)
- etcd cluster (3-5 nodes)
- Load balancer for API server
- Separate etcd cluster or stacked

Stacked etcd:
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Master 1   │  │  Master 2   │  │  Master 3   │
│  API+etcd   │  │  API+etcd   │  │  API+etcd   │
└─────────────┘  └─────────────┘  └─────────────┘

External etcd:
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Master 1   │  │  Master 2   │  │  Master 3   │
│  API Server │  │  API Server │  │  API Server │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                │
       └────────────────┼────────────────┘
                        │
       ┌────────────────┼────────────────┐
       │                │                │
┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐
│   etcd 1    │  │   etcd 2    │  │   etcd 3    │
└─────────────┘  └─────────────┘  └─────────────┘
```

#### Communication Flow
1. **User → API Server**: kubectl sends request
2. **API Server → etcd**: Validates and stores desired state
3. **Controller Manager → API Server**: Watches for changes
4. **Scheduler → API Server**: Assigns pods to nodes
5. **Kubelet → API Server**: Reports node status
6. **API Server → Kubelet**: Sends pod specifications

### Worker Node Deep Dive

#### Node Registration
```yaml
apiVersion: v1
kind: Node
metadata:
  name: worker-node-1
  labels:
    node-role.kubernetes.io/worker: ""
    topology.kubernetes.io/zone: us-west-2a
spec:
  podCIDR: 10.244.1.0/24
  providerID: aws:///us-west-2a/i-0123456789abcdef
status:
  capacity:
    cpu: "4"
    memory: 16Gi
    pods: "110"
  allocatable:
    cpu: "3900m"
    memory: 14.5Gi
    pods: "110"
  conditions:
  - type: Ready
    status: "True"
  - type: MemoryPressure
    status: "False"
  - type: DiskPressure
    status: "False"
```

#### Node Lifecycle
- **Pending**: Node registered but not ready
- **Ready**: Node healthy and accepting pods
- **NotReady**: Node unhealthy (network issue, kubelet down)
- **Unknown**: Node status unknown (lost connection)

#### Resource Management
```yaml
# Node resource allocation
Total Resources:
  CPU: 4 cores
  Memory: 16 GB

Reserved (system):
  CPU: 100m (kubelet, OS)
  Memory: 1.5 GB

Allocatable (pods):
  CPU: 3900m
  Memory: 14.5 GB

Pod Resources:
  Requests: Guaranteed minimum
  Limits: Maximum allowed
```

---

## Cluster Components

### Add-on Components

#### DNS (CoreDNS)
```yaml
# CoreDNS deployment
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
```

**Service Discovery Example**:
```bash
# Pod can reach service via DNS
my-service.my-namespace.svc.cluster.local
# Short form within same namespace
my-service
```

#### Dashboard
- Web-based UI for cluster management
- View resources, logs, and metrics
- Not recommended for production (security)

#### Metrics Server
```yaml
# Metrics Server deployment
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-server
  namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-server
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      serviceAccountName: metrics-server
      containers:
      - name: metrics-server
        image: registry.k8s.io/metrics-server/metrics-server:v0.6.4
        args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP
```

#### Ingress Controller
Common implementations:
- NGINX Ingress Controller
- Traefik
- HAProxy
- AWS ALB Controller
- GCE Ingress Controller

### Cluster Networking

#### Pod Network
```yaml
# Pod CIDR allocation
Cluster CIDR: 10.244.0.0/16
Node 1 CIDR: 10.244.1.0/24
Node 2 CIDR: 10.244.2.0/24
Node 3 CIDR: 10.244.3.0/24

# Each pod gets IP from node's CIDR
Pod 1 on Node 1: 10.244.1.2
Pod 2 on Node 1: 10.244.1.3
Pod 1 on Node 2: 10.244.2.2
```

#### Service Network
```yaml
# Service CIDR (virtual IPs)
Service CIDR: 10.96.0.0/12

# Services get cluster IPs
kubernetes service: 10.96.0.1
kube-dns service: 10.96.0.10
my-app service: 10.96.45.23
```

---

## kubectl Basics

### Installation
```bash
# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# macOS
brew install kubectl

# Windows
choco install kubernetes-cli
```

### Configuration

#### Kubeconfig Structure
```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: LS0tLS...
    server: https://kubernetes.example.com:6443
  name: production-cluster
contexts:
- context:
    cluster: production-cluster
    namespace: default
    user: admin-user
  name: prod-context
current-context: prod-context
users:
- name: admin-user
  user:
    client-certificate-data: LS0tLS...
    client-key-data: LS0tLS...
```

#### Context Management
```bash
# List contexts
kubectl config get-contexts

# Switch context
kubectl config use-context dev-context

# Set namespace for current context
kubectl config set-context --current --namespace=my-namespace

# View current context
kubectl config current-context

# View merged kubeconfig
kubectl config view
```

### Essential Commands

#### Resource Management
```bash
# Get resources
kubectl get pods
kubectl get pods -o wide
kubectl get pods -A  # All namespaces
kubectl get pods --show-labels
kubectl get pods -l app=nginx  # Label selector

# Describe resource
kubectl describe pod my-pod
kubectl describe node worker-1

# Create resources
kubectl create -f manifest.yaml
kubectl apply -f manifest.yaml
kubectl apply -f ./manifests/  # Directory

# Edit resource
kubectl edit deployment my-app

# Delete resources
kubectl delete pod my-pod
kubectl delete -f manifest.yaml
kubectl delete deployment --all
```

#### Pod Operations
```bash
# Get pod logs
kubectl logs my-pod
kubectl logs my-pod -c container-name  # Multi-container
kubectl logs -f my-pod  # Follow logs
kubectl logs --tail=100 my-pod  # Last 100 lines
kubectl logs --since=1h my-pod  # Last hour

# Execute commands in pod
kubectl exec my-pod -- ls /app
kubectl exec -it my-pod -- /bin/bash  # Interactive shell
kubectl exec my-pod -c container-name -- env

# Port forwarding
kubectl port-forward pod/my-pod 8080:80
kubectl port-forward svc/my-service 8080:80

# Copy files
kubectl cp my-pod:/path/to/file ./local-file
kubectl cp ./local-file my-pod:/path/to/file
```

#### Debugging
```bash
# Get events
kubectl get events --sort-by='.lastTimestamp'

# Cluster info
kubectl cluster-info
kubectl get componentstatuses

# Node information
kubectl top nodes
kubectl top pods
kubectl describe node worker-1

# Resource usage
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'

# Debug pod
kubectl run debug-pod --image=busybox --rm -it -- sh
```

### Command Cheatsheet

#### Common Options
```bash
-n, --namespace=""     # Namespace scope
-A, --all-namespaces   # All namespaces
-o, --output=""        # Output format (yaml, json, wide, name)
-l, --selector=""      # Label selector
-f, --filename=""      # File or directory
--dry-run=client       # Dry run mode
--force               # Force operation
-w, --watch           # Watch for changes
```

#### Output Formats
```bash
kubectl get pods -o yaml
kubectl get pods -o json
kubectl get pods -o wide
kubectl get pods -o name
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase
kubectl get pods -o jsonpath='{.items[0].metadata.name}'
```

#### Quick Generators
```bash
# Generate YAML without creating
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml

# Run temporary pod
kubectl run test-pod --image=nginx --rm -it --restart=Never -- /bin/sh

# Expose deployment
kubectl expose deployment nginx --port=80 --target-port=8080 --type=LoadBalancer
```

---

# Core Objects

## Pod

### Overview
A Pod is the smallest deployable unit in Kubernetes, representing one or more containers that share network and storage resources.

### Pod Lifecycle

```
┌──────────┐
│ Pending  │  Pod accepted, waiting for scheduling
└────┬─────┘
     │
┌────▼─────────┐
│  Running     │  Pod scheduled, containers starting/running
└────┬─────────┘
     │
┌────▼────────────┐
│ Succeeded/Failed│  All containers terminated
└─────────────────┘
```

### Basic Pod Manifest
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
    tier: frontend
  annotations:
    description: "Simple nginx pod"
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - containerPort: 80
      name: http
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
    env:
    - name: ENVIRONMENT
      value: "production"
    volumeMounts:
    - name: data
      mountPath: /usr/share/nginx/html
  volumes:
  - name: data
    emptyDir: {}
  restartPolicy: Always
```

### Multi-Container Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-sidecar
spec:
  containers:
  # Main application
  - name: app
    image: myapp:1.0
    ports:
    - containerPort: 8080
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/app
  
  # Sidecar: Log shipper
  - name: log-shipper
    image: fluent/fluent-bit:latest
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/app
      readOnly: true
  
  # Init container: Setup
  initContainers:
  - name: init-setup
    image: busybox:latest
    command: ['sh', '-c', 'echo "Initializing..." && sleep 5']
  
  volumes:
  - name: shared-logs
    emptyDir: {}
```

### Pod Patterns

#### Sidecar Pattern
```yaml
# Example: Service mesh proxy
spec:
  containers:
  - name: app
    image: myapp:1.0
  - name: envoy-proxy
    image: envoyproxy/envoy:v1.28
    # Intercepts all traffic
```

#### Ambassador Pattern
```yaml
# Example: Redis proxy
spec:
  containers:
  - name: app
    image: myapp:1.0
  - name: redis-ambassador
    image: redis-proxy:latest
    # App connects to localhost, proxy handles sharding
```

#### Adapter Pattern
```yaml
# Example: Metrics adapter
spec:
  containers:
  - name: app
    image: myapp:1.0
  - name: metrics-adapter
    image: prometheus-adapter:latest
    # Converts app metrics to Prometheus format
```

### Pod Configuration

#### Resource Management
```yaml
spec:
  containers:
  - name: app
    resources:
      requests:  # Minimum guaranteed
        memory: "256Mi"
        cpu: "500m"
      limits:    # Maximum allowed
        memory: "512Mi"
        cpu: "1000m"
```

**QoS Classes**:
- **Guaranteed**: requests == limits for all resources
- **Burstable**: requests < limits
- **BestEffort**: No requests or limits set

#### Environment Variables
```yaml
spec:
  containers:
  - name: app
    env:
    # Direct value
    - name: DB_HOST
      value: "postgres.example.com"
    
    # From ConfigMap
    - name: APP_CONFIG
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: config.json
    
    # From Secret
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
    
    # From Pod fields
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    
    # From resource limits
    - name: MEMORY_LIMIT
      valueFrom:
        resourceFieldRef:
          resource: limits.memory
    
    # Import all from ConfigMap
    envFrom:
    - configMapRef:
        name: app-config
    - secretRef:
        name: app-secret
```

### Pod Networking

#### Network Policies
```yaml
# Pod receives IP from pod network
Pod IP: 10.244.2.5
Hostname: pod-name
DNS: pod-name.namespace.pod.cluster.local

# Container ports
containers:
- ports:
  - containerPort: 8080
    protocol: TCP
    name: http
  - containerPort: 9090
    protocol: TCP
    name: metrics
```

### Pod Security

#### Security Context
```yaml
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE
```

### Troubleshooting Pods

#### Common Issues
```bash
# Pod stuck in Pending
kubectl describe pod my-pod  # Check events
# Causes: Insufficient resources, node selector mismatch, PV unavailable

# Pod stuck in ImagePullBackOff
# Causes: Wrong image name, private registry without credentials, network issue

# CrashLoopBackOff
kubectl logs my-pod --previous  # Check previous container logs
# Causes: Application error, missing dependencies, misconfiguration

# Pod terminating
kubectl get pod my-pod -o yaml | grep deletionTimestamp
# Check for finalizers, stuck volumes
```

#### Debug Commands
```bash
# Inspect pod
kubectl get pod my-pod -o yaml
kubectl describe pod my-pod

# Check logs
kubectl logs my-pod
kubectl logs my-pod --all-containers
kubectl logs my-pod -c container-name --previous

# Execute commands
kubectl exec -it my-pod -- sh
kubectl exec my-pod -- ps aux
kubectl exec my-pod -- cat /etc/resolv.conf

# Debug with ephemeral container
kubectl debug my-pod -it --image=busybox --target=app
```

---

## ReplicaSet

### Overview
ReplicaSet ensures a specified number of pod replicas are running at any given time. It's primarily used by Deployments rather than directly.

### Basic ReplicaSet
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-replicaset
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
      tier: frontend
  template:
    metadata:
      labels:
        app: nginx
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
```

### Selector Matching
```yaml
spec:
  selector:
    # Simple equality
    matchLabels:
      app: nginx
      env: production
    
    # Advanced expressions
    matchExpressions:
    - key: tier
      operator: In
      values:
      - frontend
      - backend
    - key: environment
      operator: NotIn
      values:
      - development
    - key: release
      operator: Exists
```

### ReplicaSet Operations

#### Scaling
```bash
# Imperative scaling
kubectl scale replicaset nginx-replicaset --replicas=5

# Declarative scaling
kubectl apply -f replicaset.yaml  # Update replicas in file

# Autoscaling
kubectl autoscale replicaset nginx-replicaset --min=2 --max=10 --cpu-percent=80
```

#### Rolling Updates (Limitation)
```yaml
# ReplicaSet does NOT support rolling updates
# Must delete and recreate pods manually
# This is why Deployments are preferred

# Manual update process:
1. Update image in ReplicaSet spec
2. kubectl delete pod <pod-name>  # Delete pods one by one
3. ReplicaSet creates new pods with updated spec
```

### Use Cases
- Deployments use ReplicaSets internally
- Direct use rare - only for specific scenarios:
  - When Deployment features aren't needed
  - Custom orchestration logic
  - Educational purposes

---

## Deployment

### Overview
Deployment provides declarative updates for Pods and ReplicaSets, enabling rolling updates, rollbacks, and controlled releases.

### Basic Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

### Update Strategies

#### Rolling Update (Default)
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max pods above desired count
      maxUnavailable: 0  # Max pods below desired count
  
  # Example with 3 replicas:
  # maxSurge=1, maxUnavailable=0
  # Updates: 3 → 4 → 3 → 4 → 3 (one at a time)
  # Always maintains at least 3 running
```

#### Recreate Strategy
```yaml
spec:
  strategy:
    type: Recreate
  
  # Process:
  # 1. Delete all existing pods
  # 2. Create new pods with updated spec
  # 3. Results in downtime
  # Use case: Database migrations requiring schema changes
```

### Deployment Lifecycle

#### Updating Deployment
```bash
# Update image
kubectl set image deployment/nginx-deployment nginx=nginx:1.26

# Edit deployment
kubectl edit deployment nginx-deployment

# Apply updated manifest
kubectl apply -f deployment.yaml

# Check rollout status
kubectl rollout status deployment/nginx-deployment

# View rollout history
kubectl rollout history deployment/nginx-deployment
```

#### Rollback
```bash
# Rollback to previous version
kubectl rollout undo deployment/nginx-deployment

# Rollback to specific revision
kubectl rollout history deployment/nginx-deployment
kubectl rollout undo deployment/nginx-deployment --to-revision=2

# Pause rollout (for canary testing)
kubectl rollout pause deployment/nginx-deployment

# Resume rollout
kubectl rollout resume deployment/nginx-deployment
```

### Advanced Deployment Patterns

#### Blue-Green Deployment
```yaml
# Blue deployment (current)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
      - name: app
        image: myapp:v1
---
# Green deployment (new)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
      - name: app
        image: myapp:v2
---
# Service (switch traffic by changing selector)
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
    version: blue  # Change to 'green' to switch traffic
  ports:
  - port: 80
```

#### Canary Deployment
```yaml
# Stable deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-stable
spec:
  replicas: 9
  selector:
    matchLabels:
      app: myapp
      track: stable
  template:
    metadata:
      labels:
        app: myapp
        track: stable
    spec:
      containers:
      - name: app
        image: myapp:v1
---
# Canary deployment (10% of traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      track: canary
  template:
    metadata:
      labels:
        app: myapp
        track: canary
    spec:
      containers:
      - name: app
        image: myapp:v2
---
# Service routes to both (90/10 split)
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp  # Matches both stable and canary
  ports:
  - port: 80
```

### Deployment Best Practices

#### Resource Limits
```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
```

#### Health Checks
```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          successThreshold: 1
        
        startupProbe:
          httpGet:
            path: /startup
            port: 8080
          failureThreshold: 30
          periodSeconds: 10
```

#### Pod Disruption Budget
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2  # Or maxUnavailable: 1
  selector:
    matchLabels:
      app: myapp
```

---

## StatefulSet

### Overview
StatefulSet manages stateful applications requiring stable network identity, persistent storage, and ordered deployment/scaling.

### Key Features
- Stable, unique network identifiers
- Stable, persistent storage
- Ordered, graceful deployment and scaling
- Ordered, automated rolling updates

### Basic StatefulSet
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-service
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15
        ports:
        - containerPort: 5432
          name: postgres
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: fast-ssd
      resources:
        requests:
          storage: 10Gi
---
# Headless service for StatefulSet
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  clusterIP: None  # Headless
  selector:
    app: postgres
  ports:
  - port: 5432
```

### Pod Identity
```yaml
# Pod names are deterministic
postgres-0  # Always the first pod
postgres-1  # Always the second pod
postgres-2  # Always the third pod

# DNS names are stable
postgres-0.postgres-service.default.svc.cluster.local
postgres-1.postgres-service.default.svc.cluster.local
postgres-2.postgres-service.default.svc.cluster.local

# PVC names are also stable
data-postgres-0
data-postgres-1
data-postgres-2
```

### Deployment and Scaling

#### Ordered Deployment
```bash
# Pods created sequentially
1. postgres-0 created and Running
2. postgres-1 created (after postgres-0 is Running)
3. postgres-2 created (after postgres-1 is Running)

# Scaling up
kubectl scale statefulset postgres --replicas=5
# Creates postgres-3, then postgres-4

# Scaling down
kubectl scale statefulset postgres --replicas=2
# Deletes postgres-4, then postgres-3 (reverse order)
```

#### Update Strategies
```yaml
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0  # Update pods with ordinal >= partition
  
  # OnDelete strategy
  updateStrategy:
    type: OnDelete  # Manual pod deletion triggers update
```

### StatefulSet Patterns

#### Database Cluster (PostgreSQL)
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-cluster
spec:
  serviceName: postgres
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      initContainers:
      - name: init-replica
        image: postgres:15
        command:
        - bash
        - "-c"
        - |
          if [[ $(hostname) != *"-0" ]]; then
            # Not the primary, set up replication
            until pg_basebackup -h postgres-0.postgres -D /var/lib/postgresql/data -U replicator -vP; do
              sleep 1
            done
          fi
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
      containers:
      - name: postgres
        image: postgres:15
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 50Gi
```

#### Kafka Cluster
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kafka
spec:
  serviceName: kafka-headless
  replicas: 3
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
      - name: kafka
        image: confluentinc/cp-kafka:7.5.0
        ports:
        - containerPort: 9092
          name: kafka
        env:
        - name: KAFKA_BROKER_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: KAFKA_ZOOKEEPER_CONNECT
          value: "zookeeper-0.zookeeper:2181,zookeeper-1.zookeeper:2181,zookeeper-2.zookeeper:2181"
        - name: KAFKA_ADVERTISED_LISTENERS
          value: "PLAINTEXT://$(POD_NAME).kafka-headless:9092"
        volumeMounts:
        - name: data
          mountPath: /var/lib/kafka/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 100Gi
```

### StatefulSet Operations

```bash
# Get StatefulSet status
kubectl get statefulset
kubectl describe statefulset postgres

# Check pod creation order
kubectl get pods -l app=postgres --watch

# Delete a pod (it will be recreated)
kubectl delete pod postgres-1

# Force delete stuck pod
kubectl delete pod postgres-1 --grace-period=0 --force

# Get PVCs
kubectl get pvc
kubectl describe pvc data-postgres-0

# Update StatefulSet
kubectl apply -f statefulset.yaml
kubectl rollout status statefulset/postgres

# Partition update (canary)
kubectl patch statefulset postgres -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":2}}}}'
# Only postgres-2 will update, postgres-0 and postgres-1 remain on old version
```

---

## DaemonSet

### Overview
DaemonSet ensures a copy of a pod runs on all (or selected) nodes. Useful for node-level operations like monitoring, logging, or networking.

### Basic DaemonSet
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: kube-system
  labels:
    k8s-app: fluentd-logging
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd:v1.16
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: containers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: containers
        hostPath:
          path: /var/lib/docker/containers
```

### Node Selection

#### Node Selector
```yaml
spec:
  template:
    spec:
      nodeSelector:
        disktype: ssd
        # Runs only on nodes with label disktype=ssd
```

#### Node Affinity
```yaml
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/arch
                operator: In
                values:
                - amd64
                - arm64
```

#### Tolerations
```yaml
spec:
  template:
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      - key: node.kubernetes.io/disk-pressure
        operator: Exists
        effect: NoSchedule
```

### Common Use Cases

#### Node Monitoring (Prometheus Node Exporter)
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      hostNetwork: true
      hostPID: true
      containers:
      - name: node-exporter
        image: prom/node-exporter:v1.7.0
        args:
        - --path.sysfs=/host/sys
        - --path.rootfs=/host/root
        - --collector.filesystem.mount-points-exclude=^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/.+)($|/)
        ports:
        - containerPort: 9100
          name: metrics
        volumeMounts:
        - name: sys
          mountPath: /host/sys
          readOnly: true
        - name: root
          mountPath: /host/root
          readOnly: true
      volumes:
      - name: sys
        hostPath:
          path: /sys
      - name: root
        hostPath:
          path: /
```

#### CNI Network Plugin
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: calico-node
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: calico-node
  template:
    metadata:
      labels:
        k8s-app: calico-node
    spec:
      hostNetwork: true
      serviceAccountName: calico-node
      containers:
      - name: calico-node
        image: calico/node:v3.27.0
        env:
        - name: DATASTORE_TYPE
          value: "kubernetes"
        - name: CALICO_NETWORKING_BACKEND
          value: "bird"
        securityContext:
          privileged: true
        volumeMounts:
        - name: lib-modules
          mountPath: /lib/modules
          readOnly: true
        - name: var-run-calico
          mountPath: /var/run/calico
      volumes:
      - name: lib-modules
        hostPath:
          path: /lib/modules
      - name: var-run-calico
        hostPath:
          path: /var/run/calico
```

### Update Strategy
```yaml
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1  # Update one node at a time
  
  # Or OnDelete for manual updates
  updateStrategy:
    type: OnDelete
```

---

## Job & CronJob

### Job

#### Overview
Job creates one or more pods and ensures a specified number successfully complete. Used for batch processing, data migrations, or one-time tasks.

#### Basic Job
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-migration
spec:
  completions: 1      # Number of successful completions needed
  parallelism: 1      # Number of pods running in parallel
  backoffLimit: 3     # Number of retries before marking as failed
  template:
    spec:
      containers:
      - name: migration
        image: myapp/migration:v1
        command: ["python", "migrate.py"]
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: url
      restartPolicy: Never  # or OnFailure
```

#### Parallel Jobs
```yaml
# Process multiple items in parallel
apiVersion: batch/v1
kind: Job
metadata:
  name: parallel-processing
spec:
  completions: 10     # Need 10 successful completions
  parallelism: 3      # Run 3 pods at a time
  template:
    spec:
      containers:
      - name: processor
        image: myapp/processor:v1
        command: ["./process.sh"]
      restartPolicy: Never
```

#### Job with Work Queue
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: queue-processor
spec:
  parallelism: 5
  # No completions - job completes when queue is empty
  template:
    spec:
      containers:
      - name: worker
        image: myapp/worker:v1
        env:
        - name: QUEUE_URL
          value: "redis://redis-service:6379"
      restartPolicy: Never
```

#### Job Patterns

**Fixed Completion Count**:
```yaml
spec:
  completions: 5
  parallelism: 2
# Creates 5 pods total, 2 at a time
```

**Work Queue**:
```yaml
spec:
  parallelism: 3
  # completions omitted
# Pods pull work from queue until empty
```

**Single Pod**:
```yaml
spec:
  completions: 1
  parallelism: 1
# One pod, one completion
```

### CronJob

#### Overview
CronJob creates Jobs on a repeating schedule, similar to Unix cron.

#### Basic CronJob
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: database-backup
spec:
  schedule: "0 2 * * *"  # Every day at 2 AM
  timeZone: "America/New_York"
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  concurrencyPolicy: Forbid  # or Allow, Replace
  startingDeadlineSeconds: 300
  suspend: false
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:15
            command:
            - /bin/sh
            - -c
            - |
              pg_dump -h $DB_HOST -U $DB_USER $DB_NAME | \
              gzip > /backup/db-$(date +%Y%m%d-%H%M%S).sql.gz
            env:
            - name: DB_HOST
              value: "postgres-service"
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: username
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: password
            - name: DB_NAME
              value: "production"
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
```

#### Cron Schedule Examples
```yaml
# Every minute
schedule: "*/1 * * * *"

# Every hour at minute 30
schedule: "30 * * * *"

# Every day at midnight
schedule: "0 0 * * *"

# Every Monday at 9 AM
schedule: "0 9 * * 1"

# First day of every month at midnight
schedule: "0 0 1 * *"

# Every 6 hours
schedule: "0 */6 * * *"

# Business hours (9-5, Mon-Fri)
schedule: "0 9-17 * * 1-5"
```

#### Concurrency Policies
```yaml
spec:
  # Allow: Multiple jobs can run concurrently
  concurrencyPolicy: Allow
  
  # Forbid: Skip new job if previous is still running
  concurrencyPolicy: Forbid
  
  # Replace: Cancel current job and start new one
  concurrencyPolicy: Replace
```

#### Real-World CronJob Examples

**Log Cleanup**:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: log-cleanup
spec:
  schedule: "0 3 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: cleanup
            image: busybox
            command:
            - /bin/sh
            - -c
            - find /logs -type f -mtime +7 -delete
            volumeMounts:
            - name: logs
              mountPath: /logs
          volumes:
          - name: logs
            hostPath:
              path: /var/log/apps
          restartPolicy: OnFailure
```

**Report Generation**:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: daily-report
spec:
  schedule: "0 6 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: report
            image: myapp/report-generator:v1
            command: ["python", "generate_report.py"]
            env:
            - name: REPORT_DATE
              value: "$(date -d yesterday +%Y-%m-%d)"
            - name: EMAIL_TO
              value: "team@example.com"
          restartPolicy: OnFailure
```

### Job Management

```bash
# Create job
kubectl create job test-job --image=busybox -- echo "Hello"

# Create job from CronJob
kubectl create job --from=cronjob/backup-job manual-backup-1

# List jobs
kubectl get jobs
kubectl get cronjobs

# View job details
kubectl describe job data-migration
kubectl logs job/data-migration

# Delete completed jobs
kubectl delete job data-migration

# Suspend CronJob
kubectl patch cronjob backup-job -p '{"spec":{"suspend":true}}'

# Clean up finished jobs
kubectl delete jobs --field-selector status.successful=1
```

---

## Namespace

### Overview
Namespaces provide logical isolation within a cluster, enabling multi-tenancy, resource quotas, and access control.

### Default Namespaces
```bash
# System namespaces
default          # Default namespace for objects without a namespace
kube-system      # Kubernetes system components
kube-public      # Publicly readable by all users
kube-node-lease  # Node heartbeat objects
```

### Creating Namespaces

#### Via kubectl
```bash
kubectl create namespace development
kubectl create namespace production
kubectl create namespace staging
```

#### Via YAML
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: development
  labels:
    environment: dev
    team: platform
```

### Resource Organization

#### Multi-Environment Setup
```yaml
# Development namespace
apiVersion: v1
kind: Namespace
metadata:
  name: development
  labels:
    environment: dev
---
# Staging namespace
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    environment: staging
---
# Production namespace
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: prod
```

### Resource Quotas

#### Basic Resource Quota
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: development
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    persistentvolumeclaims: "10"
    pods: "50"
    services: "20"
    configmaps: "10"
    secrets: "10"
```

#### Object Count Quota
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: object-quota
  namespace: development
spec:
  hard:
    count/deployments.apps: "10"
    count/services: "20"
    count/configmaps: "30"
    count/secrets: "30"
    count/persistentvolumeclaims: "10"
```

### Limit Ranges

#### Pod and Container Limits
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: development
spec:
  limits:
  # Pod limits
  - max:
      cpu: "2"
      memory: 4Gi
    min:
      cpu: "100m"
      memory: 128Mi
    type: Pod
  
  # Container limits
  - default:
      cpu: "500m"
      memory: 512Mi
    defaultRequest:
      cpu: "100m"
      memory: 128Mi
    max:
      cpu: "1"
      memory: 2Gi
    min:
      cpu: "50m"
      memory: 64Mi
    type: Container
  
  # PVC limits
  - max:
      storage: 100Gi
    min:
      storage: 1Gi
    type: PersistentVolumeClaim
```

### Network Policies per Namespace

```yaml
# Deny all ingress by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
# Allow only from same namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
```

### Namespace Operations

```bash
# List namespaces
kubectl get namespaces
kubectl get ns

# Describe namespace
kubectl describe namespace development

# Set default namespace for context
kubectl config set-context --current --namespace=development

# Get resources in namespace
kubectl get pods -n development
kubectl get all -n development

# Get resources in all namespaces
kubectl get pods --all-namespaces
kubectl get pods -A

# Delete namespace (deletes all resources)
kubectl delete namespace development

# Check resource usage
kubectl top pods -n development
kubectl describe resourcequota -n development
```

### Namespace Best Practices

#### Organization Strategies

**By Environment**:
```
development
staging
production
```

**By Team**:
```
team-platform
team-data
team-ml
```

**By Application**:
```
app-frontend
app-backend
app-database
```

**Hybrid**:
```
prod-frontend
prod-backend
staging-frontend
staging-backend
dev-shared
```

---

## Labels & Annotations

### Labels

#### Overview
Labels are key-value pairs attached to objects for identification and selection. Used by selectors to group and filter resources.

#### Label Syntax
```yaml
metadata:
  labels:
    # Standard labels
    app: nginx
    version: v1.2.3
    environment: production
    tier: frontend
    
    # Reverse DNS notation (recommended)
    app.kubernetes.io/name: nginx
    app.kubernetes.io/version: "1.25"
    app.kubernetes.io/component: web-server
    app.kubernetes.io/part-of: my-application
    app.kubernetes.io/managed-by: helm
    
    # Custom organizational labels
    team: platform
    cost-center: engineering
    compliance: pci-dss
```

#### Recommended Labels
```yaml
# Kubernetes recommended label set
metadata:
  labels:
    app.kubernetes.io/name: wordpress
    app.kubernetes.io/instance: wordpress-prod
    app.kubernetes.io/version: "6.4"
    app.kubernetes.io/component: web
    app.kubernetes.io/part-of: cms-platform
    app.kubernetes.io/managed-by: kubectl
```

#### Label Selectors

**Equality-based**:
```bash
kubectl get pods -l environment=production
kubectl get pods -l 'environment=production,tier=frontend'
kubectl get pods -l 'environment!=development'
```

**Set-based**:
```bash
kubectl get pods -l 'environment in (production, staging)'
kubectl get pods -l 'tier notin (cache, queue)'
kubectl get pods -l 'version'  # Has 'version' label
kubectl get pods -l '!version'  # Doesn't have 'version' label
```

#### Label Selectors in YAML
```yaml
selector:
  matchLabels:
    app: nginx
    tier: frontend
  matchExpressions:
  - key: environment
    operator: In
    values:
    - production
    - staging
  - key: version
    operator: Exists
  - key: deprecated
    operator: DoesNotExist
```

#### Label Use Cases

**Service Selection**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
    environment: production
  ports:
  - port: 80
```

**Deployment Selection**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
        version: "1.25"
```

**Node Selection**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  nodeSelector:
    disktype: ssd
    zone: us-west-1a
  containers:
  - name: nginx
    image: nginx
```

### Annotations

#### Overview
Annotations store arbitrary non-identifying metadata. Not used for selection but for tools, libraries, and client operations.

#### Annotation Examples
```yaml
metadata:
  annotations:
    # Build information
    build.version: "1.2.3-abc123"
    build.timestamp: "2024-01-15T10:30:00Z"
    git.commit: "abc123def456"
    git.branch: "main"
    
    # Contact information
    contact.email: "team@example.com"
    contact.slack: "#platform-team"
    contact.oncall: "https://oncall.example.com/platform"
    
    # Documentation
    documentation: "https://docs.example.com/services/nginx"
    runbook: "https://runbooks.example.com/nginx"
    
    # Tool-specific
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
    
    # Kubernetes-specific
    kubernetes.io/change-cause: "Update to version 1.25"
    deployment.kubernetes.io/revision: "5"
    
    # Custom metadata
    cost-center: "engineering-001"
    compliance.requirements: "pci-dss,soc2"
    backup.policy: "daily"
```

#### Common Annotations

**Ingress**:
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    kubernetes.io/ingress.class: "nginx"
```

**Service**:
```yaml
metadata:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "http"
    cloud.google.com/neg: '{"ingress": true}'
```

**Deployment**:
```yaml
metadata:
  annotations:
    kubernetes.io/change-cause: "Updated image to v2.0"
    deployment.kubernetes.io/revision: "3"
```

### Label and Annotation Management

```bash
# Add label
kubectl label pod nginx-pod environment=production

# Update label
kubectl label pod nginx-pod environment=staging --overwrite

# Remove label
kubectl label pod nginx-pod environment-

# Add annotation
kubectl annotate pod nginx-pod description="Main web server"

# Update annotation
kubectl annotate pod nginx-pod description="Updated web server" --overwrite

# Remove annotation
kubectl annotate pod nginx-pod description-

# Show labels
kubectl get pods --show-labels

# Filter by label
kubectl get pods -l app=nginx

# Get specific label values
kubectl get pods -L app,version,environment
```

### Best Practices

#### Label Guidelines
- Use consistent naming conventions
- Keep labels short and meaningful
- Use reverse DNS notation for organizational labels
- Don't use labels for large or structured data
- Maximum 63 characters per label value
- Use lowercase letters, numbers, hyphens, and underscores

#### Annotation Guidelines
- Use for non-identifying metadata
- Store tool configuration and metadata
- Include contact and documentation info
- Use for debugging and troubleshooting info
- No size limit (within reason)
- Can contain any characters

---

# Networking

## Service Types

### Overview
Services provide stable network endpoints for accessing pods. Kubernetes offers multiple service types for different use cases.

### ClusterIP

#### Overview
Default service type. Exposes service on cluster-internal IP. Only accessible from within cluster.

#### Basic ClusterIP Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  sessionAffinity: None  # or ClientIP

# Access from within cluster:
# http://backend-service.default.svc.cluster.local
# http://backend-service (same namespace)
```

#### Multi-Port Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: multi-port-service
spec:
  selector:
    app: myapp
  ports:
  - name: http
    port: 80
    targetPort: 8080
  - name: https
    port: 443
    targetPort: 8443
  - name: metrics
    port: 9090
    targetPort: 9090
```

### NodePort

#### Overview
Exposes service on each Node's IP at a static port. Accessible from outside the cluster via `<NodeIP>:<NodePort>`.

#### NodePort Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-nodeport
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080  # Optional, auto-assigned if omitted (30000-32767)
    protocol: TCP

# Access from outside:
# http://<node-1-ip>:30080
# http://<node-2-ip>:30080
# http://<node-n-ip>:30080
```

### LoadBalancer

#### Overview
Exposes service externally using cloud provider's load balancer. Creates NodePort and ClusterIP services automatically.

#### LoadBalancer Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-loadbalancer
  annotations:
    # AWS-specific
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    # GCP-specific
    cloud.google.com/load-balancer-type: "Internal"
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
  loadBalancerSourceRanges:
  - 10.0.0.0/8  # Restrict source IPs
  externalTrafficPolicy: Local  # or Cluster

# Cloud provider provisions external LB
# Access via: http://<external-lb-ip>
```

#### External Traffic Policy
```yaml
spec:
  externalTrafficPolicy: Local
  # Local: Preserves client IP, no extra hop, only nodes with pods receive traffic
  # Cluster: May lose client IP, even distribution, all nodes receive traffic
```

### ExternalName

#### Overview
Maps service to external DNS name. Returns CNAME record instead of proxying.

#### ExternalName Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-database
spec:
  type: ExternalName
  externalName: db.example.com
  ports:
  - port: 5432

# Pods can access via:
# external-database.default.svc.cluster.local
# Resolves to: db.example.com
```

### Headless Service

#### Overview
Service without cluster IP (`clusterIP: None`). Returns pod IPs directly for client-side load balancing.

#### Headless Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
spec:
  clusterIP: None  # Headless
  selector:
    app: postgres
  ports:
  - port: 5432

# DNS returns all pod IPs:
# postgres-headless.default.svc.cluster.local
# → 10.244.1.5, 10.244.2.7, 10.244.3.9

# With StatefulSet:
# postgres-0.postgres-headless.default.svc.cluster.local → 10.244.1.5
# postgres-1.postgres-headless.default.svc.cluster.local → 10.244.2.7
```

### Service Discovery

#### DNS-Based Discovery
```bash
# Full FQDN
<service-name>.<namespace>.svc.cluster.local

# Short form (same namespace)
<service-name>

# Examples:
backend-service.default.svc.cluster.local
backend-service

# SRV records for named ports
_http._tcp.backend-service.default.svc.cluster.local
```

#### Environment Variables
```bash
# Kubernetes injects env vars for services
# Format: <SERVICE_NAME>_SERVICE_HOST and <SERVICE_NAME>_SERVICE_PORT

BACKEND_SERVICE_HOST=10.96.45.23
BACKEND_SERVICE_PORT=80
BACKEND_SERVICE_PORT_HTTP=80
```

### Service Endpoints

```yaml
# Endpoints auto-created by service
apiVersion: v1
kind: Endpoints
metadata:
  name: backend-service
subsets:
- addresses:
  - ip: 10.244.1.5
    nodeName: worker-1
    targetRef:
      kind: Pod
      name: backend-7d8f9c-abc12
  - ip: 10.244.2.8
    nodeName: worker-2
  ports:
  - port: 8080
    protocol: TCP
```

---

## Ingress & Ingress Controller

### Ingress Overview
Ingress manages external HTTP/HTTPS access to services, providing load balancing, SSL termination, and name-based virtual hosting.

### Ingress Controller
Must install an Ingress Controller (not included by default):
- NGINX Ingress Controller (most popular)
- Traefik
- HAProxy
- Kong
- AWS ALB Controller
- GCE Ingress Controller

#### Installing NGINX Ingress Controller
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml
```

### Basic Ingress

#### Simple Host-Based Routing
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

#### Path-Based Routing
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-based-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /v1
        pathType: Prefix
        backend:
          service:
            name: api-v1-service
            port:
              number: 80
      - path: /v2
        pathType: Prefix
        backend:
          service:
            name: api-v2-service
            port:
              number: 80
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 80
```

#### Multiple Hosts
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host-ingress
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
  - host: admin.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 80
```

### TLS/SSL Configuration

#### TLS Ingress
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-cert>
  tls.key: <base64-encoded-key>
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  tls:
  - hosts:
    - secure.example.com
    secretName: tls-secret
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: secure-service
            port:
              number: 443
```

#### cert-manager Integration
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cert-manager-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls  # cert-manager creates this
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

### Ingress Annotations

#### NGINX Ingress Annotations
```yaml
metadata:
  annotations:
    # Rewrite
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    
    # SSL
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    
    # Authentication
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
    
    # Rate limiting
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-connections: "5"
    
    # CORS
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    
    # Timeouts
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "30"
    
    # Custom headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Custom-Header: value";
    
    # Whitelist
    nginx.ingress.kubernetes.io/whitelist-source-range: "10.0.0.0/8,192.168.0.0/16"
```

### PathType Options

```yaml
# Prefix: Matches based on URL path prefix
pathType: Prefix
path: /app
# Matches: /app, /app/, /app/page, /app/page/123

# Exact: Matches exact path only
pathType: Exact
path: /app
# Matches: /app only (not /app/ or /app/page)

# ImplementationSpecific: Depends on Ingress Controller
pathType: ImplementationSpecific
```

### Advanced Ingress Patterns

#### Canary Deployment
```yaml
# Production ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: production-ingress
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-v1
            port:
              number: 80
---
# Canary ingress (10% traffic)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: canary-ingress
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-v2
            port:
              number: 80
```

#### Header-Based Routing
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: header-based-canary
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-by-header: "X-Canary"
    nginx.ingress.kubernetes.io/canary-by-header-value: "true"
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-canary
            port:
              number: 80
```

---

## DNS in Kubernetes

### CoreDNS Architecture
```
Pod → CoreDNS Service (kube-dns) → CoreDNS Pod(s) → 
  → Kubernetes API (for service/pod records)
  → Upstream DNS (for external queries)
```

### DNS Records

#### Service DNS Records
```bash
# Format: <service>.<namespace>.svc.cluster.local

# Examples:
backend.default.svc.cluster.local
postgres.database.svc.cluster.local
redis.cache.svc.cluster.local

# A record returns ClusterIP
nslookup backend.default.svc.cluster.local
# → 10.96.45.23

# SRV records for named ports
_http._tcp.backend.default.svc.cluster.local
```

#### Pod DNS Records
```bash
# Format: <pod-ip-with-dashes>.<namespace>.pod.cluster.local

# Example:
10-244-1-5.default.pod.cluster.local

# With hostname and subdomain:
<hostname>.<subdomain>.<namespace>.svc.cluster.local
```

### DNS Configuration

#### Pod DNS Policy
```yaml
spec:
  # Default: Inherits from node
  dnsPolicy: Default
  
  # ClusterFirst: Use cluster DNS (default for most pods)
  dnsPolicy: ClusterFirst
  
  # ClusterFirstWithHostNet: For pods with hostNetwork: true
  dnsPolicy: ClusterFirstWithHostNet
  
  # None: Custom DNS config
  dnsPolicy: None
  dnsConfig:
    nameservers:
    - 8.8.8.8
    - 8.8.4.4
    searches:
    - ns1.svc.cluster.local
    - my.dns.search.suffix
    options:
    - name: ndots
      value: "5"
```

#### Custom DNS Configuration
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: custom-dns-pod
spec:
  dnsPolicy: None
  dnsConfig:
    nameservers:
    - 1.1.1.1
    - 8.8.8.8
    searches:
    - default.svc.cluster.local
    - svc.cluster.local
    - cluster.local
    options:
    - name: ndots
      value: "2"
    - name: edns0
```

### CoreDNS Configuration

#### CoreDNS ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
    
    # Custom domain
    example.com:53 {
        errors
        cache 30
        forward . 10.0.0.53
    }
```

### DNS Troubleshooting

```bash
# Test DNS from pod
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# DNS debugging pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: dnsutils
spec:
  containers:
  - name: dnsutils
    image: registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3
    command:
      - sleep
      - "infinity"
EOF

# Test DNS from pod
kubectl exec -it dnsutils -- nslookup kubernetes.default
kubectl exec -it dnsutils -- dig backend.default.svc.cluster.local
kubectl exec -it dnsutils -- cat /etc/resolv.conf
```

---

## Network Policies

### Overview
Network Policies control traffic flow between pods, implementing network segmentation and security.

### Basic Network Policy

#### Deny All Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: production
spec:
  podSelector: {}  # Applies to all pods
  policyTypes:
  - Ingress
  # No ingress rules = deny all
```

#### Allow Specific Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

### Network Policy Rules

#### Allow from Namespace
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-namespace
spec:
  podSelector:
    matchLabels:
      app: api
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          environment: production
    ports:
    - protocol: TCP
      port: 80
```

#### Allow from IP Range
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-external
spec:
  podSelector:
    matchLabels:
      app: web
  ingress:
  - from:
    - ipBlock:
        cidr: 172.17.0.0/16
        except:
        - 172.17.1.0/24
    ports:
    - protocol: TCP
      port: 80
```

#### Egress Rules
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: egress-policy
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  # Allow DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # Allow to backend
  - to:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 8080
  # Allow to external API
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 443
```

### Advanced Network Policies

#### Multi-Tier Application
```yaml
# Database: Only backend can access
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
---
# Backend: Only frontend can access
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
---
# Frontend: Allow from ingress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 8080
```

### Zero Trust Network
```yaml
# Default deny all
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
# Allow DNS only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    podSelector:
      matchLabels:
        k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
```

---

## CNI Plugins

### Overview
Container Network Interface (CNI) plugins provide networking capabilities to pods. Must choose one CNI plugin per cluster.

### Popular CNI Plugins

#### Calico
**Features**:
- Network policy enforcement
- BGP routing
- Both overlay and non-overlay modes
- High performance

**Installation**:
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
```

**Configuration**:
```yaml
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    bgp: Enabled
    ipPools:
    - blockSize: 26
      cidr: 10.244.0.0/16
      encapsulation: VXLAN
      natOutgoing: Enabled
      nodeSelector: all()
```

#### Flannel
**Features**:
- Simple overlay network
- Easy setup
- Low overhead
- Good for basic use cases

**Installation**:
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

#### Cilium
**Features**:
- eBPF-based networking
- Advanced network policies (L7)
- Service mesh capabilities
- Hubble observability

**Installation**:
```bash
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.15.0 \
  --namespace kube-system
```

#### Weave Net
**Features**:
- Simple setup
- Automatic mesh network
- Network encryption
- Multicast support

**Installation**:
```bash
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
```

### CNI Comparison

| Feature | Calico | Flannel | Cilium | Weave |
|---------|--------|---------|---------|-------|
| Performance | High | Good | Excellent | Good |
| Network Policy | Full | No | Advanced (L7) | Basic |
| Complexity | Medium | Low | High | Low |
| Overlay Options | VXLAN, IPIP | VXLAN | VXLAN, Geneve | VXLAN |
| Service Mesh | No | No | Yes | No |
| Observability | Basic | Basic | Excellent | Basic |

### CNI Configuration

#### Pod CIDR Configuration
```yaml
# kubeadm init config
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
networking:
  podSubnet: "10.244.0.0/16"
  serviceSubnet: "10.96.0.0/12"
```

#### CNI Config File
```json
{
  "cniVersion": "0.4.0",
  "name": "k8s-pod-network",
  "plugins": [
    {
      "type": "calico",
      "log_level": "info",
      "datastore_type": "kubernetes",
      "nodename": "__KUBERNETES_NODE_NAME__",
      "ipam": {
        "type": "calico-ipam"
      },
      "policy": {
        "type": "k8s"
      },
      "kubernetes": {
        "kubeconfig": "__KUBECONFIG_FILEPATH__"
      }
    },
    {
      "type": "portmap",
      "snat": true,
      "capabilities": {"portMappings": true}
    }
  ]
}
```

---

# Storage

## Volumes

### Overview
Volumes provide persistent or temporary storage to pods, surviving container restarts and enabling data sharing between containers.

### Volume Types

#### emptyDir
Temporary directory that exists as long as pod runs.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: cache
      mountPath: /cache
  - name: sidecar
    image: busybox
    command: ['sh', '-c', 'tail -f /cache/app.log']
    volumeMounts:
    - name: cache
      mountPath: /cache
  volumes:
  - name: cache
    emptyDir: {}
    # emptyDir:
    #   medium: Memory  # Use tmpfs (RAM)
    #   sizeLimit: 1Gi
```

#### hostPath
Mounts file or directory from host node.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: host-data
      mountPath: /data
  volumes:
  - name: host-data
    hostPath:
      path: /mnt/data
      type: DirectoryOrCreate  # Directory, File, Socket, etc.
```

⚠️ **Warning**: hostPath ties pod to specific node and has security implications.

#### configMap
Inject configuration data as files.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.conf: |
    server_name=myapp
    port=8080
  database.conf: |
    host=postgres
    port=5432
---
apiVersion: v1
kind: Pod
metadata:
  name: configmap-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: config
      mountPath: /etc/config
  volumes:
  - name: config
    configMap:
      name: app-config
      items:
      - key: app.conf
        path: app.conf
```

#### secret
Inject sensitive data as files.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
stringData:
  username: admin
  password: secretpass123
---
apiVersion: v1
kind: Pod
metadata:
  name: secret-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: secrets
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secrets
    secret:
      secretName: db-secret
      defaultMode: 0400
```

#### persistentVolumeClaim
Reference to PersistentVolumeClaim (covered in next section).

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pvc-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-pvc
```

#### Cloud Provider Volumes

**AWS EBS**:
```yaml
volumes:
- name: aws-ebs
  awsElasticBlockStore:
    volumeID: vol-0123456789abcdef
    fsType: ext4
```

**GCE Persistent Disk**:
```yaml
volumes:
- name: gce-pd
  gcePersistentDisk:
    pdName: my-disk
    fsType: ext4
```

**Azure Disk**:
```yaml
volumes:
- name: azure-disk
  azureDisk:
    diskName: my-disk
    diskURI: /subscriptions/.../my-disk
```

#### NFS
```yaml
volumes:
- name: nfs-volume
  nfs:
    server: nfs-server.example.com
    path: /exports/data
    readOnly: false
```

---

## PersistentVolume (PV)

### Overview
PersistentVolume is cluster-wide storage resource provisioned by administrator or dynamically via StorageClass.

### Basic PersistentVolume
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-manual
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem  # or Block
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain  # or Delete, Recycle
  storageClassName: manual
  hostPath:
    path: /mnt/data
```

### Access Modes
- **ReadWriteOnce (RWO)**: Single node read-write
- **ReadOnlyMany (ROX)**: Multiple nodes read-only
- **ReadWriteMany (RWX)**: Multiple nodes read-write
- **ReadWriteOncePod (RWOP)**: Single pod read-write (K8s 1.27+)

### Reclaim Policies