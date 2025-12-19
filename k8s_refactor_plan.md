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

- **Retain**: PV remains after PVC deletion (manual cleanup required)
- **Delete**: PV and underlying storage deleted when PVC is deleted
- **Recycle**: Basic scrub (`rm -rf`) before making available again (deprecated)

### PersistentVolume Examples

#### NFS PersistentVolume
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
spec:
  capacity:
    storage: 100Gi
  accessModes:
  - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs
  nfs:
    server: 192.168.1.100
    path: /exports/data
```

#### AWS EBS PersistentVolume
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ebs-pv
spec:
  capacity:
    storage: 50Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: gp3
  awsElasticBlockStore:
    volumeID: vol-0123456789abcdef
    fsType: ext4
```

#### Local PersistentVolume
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 500Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/disks/ssd1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - worker-node-1
```

---

## PersistentVolumeClaim (PVC)

### Overview
PersistentVolumeClaim is a request for storage by a user. Kubernetes binds PVC to suitable PV.

### Basic PVC
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: fast-ssd
```

### PVC Binding Process
```
1. User creates PVC
2. K8s finds matching PV (capacity, access mode, storage class)
3. PVC bound to PV
4. Pod uses PVC
```

### PVC in Pod
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
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: my-pvc
```

### PVC with StatefulSet
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: nginx
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
        image: nginx
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: fast-ssd
      resources:
        requests:
          storage: 10Gi
```

---

## StorageClass

### Overview
StorageClass provides dynamic provisioning of PersistentVolumes. Eliminates manual PV creation.

### Basic StorageClass
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iops: "3000"
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Delete
```

### Common Provisioners

#### AWS EBS
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: aws-gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
  kmsKeyId: arn:aws:kms:us-east-1:123456789:key/xxx
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

#### GCE Persistent Disk
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gce-ssd
provisioner: pd.csi.storage.gke.io
parameters:
  type: pd-ssd
  replication-type: regional-pd
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

#### Azure Disk
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azure-premium
provisioner: disk.csi.azure.com
parameters:
  storageaccounttype: Premium_LRS
  kind: Managed
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

#### NFS (using nfs-subdir-external-provisioner)
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-client
provisioner: k8s-sigs.io/nfs-subdir-external-provisioner
parameters:
  archiveOnDelete: "false"
volumeBindingMode: Immediate
```

#### Local Storage
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

### Volume Binding Modes

**Immediate**:
- PV provisioned immediately when PVC created
- May lead to pods not scheduling if volume in wrong zone

**WaitForFirstConsumer**:
- PV provisioned when first pod using PVC is scheduled
- Ensures volume in correct zone/region

### Dynamic Provisioning Example
```yaml
# StorageClass
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
---
# PVC (no PV needed - dynamically created)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: fast
  resources:
    requests:
      storage: 20Gi
---
# Pod using PVC
apiVersion: v1
kind: Pod
metadata:
  name: app
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
      claimName: dynamic-pvc
```

### Volume Expansion
```yaml
# Enable in StorageClass
allowVolumeExpansion: true

# Expand PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  resources:
    requests:
      storage: 50Gi  # Increased from 20Gi
```

---

## CSI Drivers

### Overview
Container Storage Interface (CSI) is standard for exposing storage systems to containerized workloads.

### Popular CSI Drivers
- **AWS EBS CSI**: ebs.csi.aws.com
- **GCE PD CSI**: pd.csi.storage.gke.io
- **Azure Disk CSI**: disk.csi.azure.com
- **Ceph RBD CSI**: rbd.csi.ceph.com
- **NFS CSI**: nfs.csi.k8s.io
- **Local Path Provisioner**: rancher.io/local-path

### Installing CSI Driver (AWS EBS Example)
```bash
# Install EBS CSI driver
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.27"

# Verify installation
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
```

### Volume Snapshots
```yaml
# VolumeSnapshotClass
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: csi-aws-vsc
driver: ebs.csi.aws.com
deletionPolicy: Delete
---
# VolumeSnapshot
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: my-snapshot
spec:
  volumeSnapshotClassName: csi-aws-vsc
  source:
    persistentVolumeClaimName: my-pvc
---
# Restore from snapshot
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restored-pvc
spec:
  storageClassName: fast
  dataSource:
    name: my-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
```

---

# Security

## RBAC (Role-Based Access Control)

### Overview
RBAC regulates access to Kubernetes resources based on roles assigned to users/service accounts.

### RBAC Components
- **Role**: Permissions within a namespace
- **ClusterRole**: Cluster-wide permissions
- **RoleBinding**: Binds Role to subjects in namespace
- **ClusterRoleBinding**: Binds ClusterRole to subjects cluster-wide

### Basic Role
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: development
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
```

### RoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: development
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
- kind: ServiceAccount
  name: app-sa
  namespace: development
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### ClusterRole
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "namespaces", "persistentvolumes"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets", "daemonsets"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
```

### ClusterRoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-reader-binding
subjects:
- kind: User
  name: admin
  apiGroup: rbac.authorization.k8s.io
- kind: Group
  name: system:authenticated
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-reader
  apiGroup: rbac.authorization.k8s.io
```

### Common Role Examples

#### Developer Role
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: development
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["pods", "deployments", "services", "jobs", "cronjobs"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
```

#### Read-Only Role
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: read-only
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
```

#### Admin Role (Namespace)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: admin-binding
  namespace: production
subjects:
- kind: User
  name: admin-user
roleRef:
  kind: ClusterRole
  name: admin  # Built-in ClusterRole
  apiGroup: rbac.authorization.k8s.io
```

### ServiceAccount with Role
```yaml
# ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: production
---
# Role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
  namespace: production
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list"]
---
# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: production
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
---
# Pod using ServiceAccount
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  namespace: production
spec:
  serviceAccountName: app-sa
  containers:
  - name: app
    image: myapp:1.0
```

### RBAC Testing
```bash
# Check if user can perform action
kubectl auth can-i get pods --namespace=development --as=jane
kubectl auth can-i create deployments --namespace=production --as=john
kubectl auth can-i '*' '*' --all-namespaces --as=admin

# Test ServiceAccount permissions
kubectl auth can-i list secrets --as=system:serviceaccount:production:app-sa
```

---

## ServiceAccount

### Overview
ServiceAccount provides identity for processes running in pods to interact with API server.

### Default ServiceAccount
```yaml
# Every namespace has default ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
  namespace: default
```

### Custom ServiceAccount
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-sa
  namespace: production
automountServiceAccountToken: true
imagePullSecrets:
- name: registry-secret
```

### Using ServiceAccount in Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  serviceAccountName: my-app-sa
  containers:
  - name: app
    image: myapp:1.0
    # Token automatically mounted at /var/run/secrets/kubernetes.io/serviceaccount/token
```

### ServiceAccount Token
```bash
# View token from pod
kubectl exec -it app-pod -- cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Get ServiceAccount token
kubectl create token my-app-sa --duration=1h

# Use token to access API
TOKEN=$(kubectl create token my-app-sa)
curl -k -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc/api/v1/namespaces/default/pods
```

---

## Secrets

### Overview
Secrets store sensitive data like passwords, tokens, and keys.

### Secret Types
- **Opaque**: Arbitrary user-defined data (default)
- **kubernetes.io/service-account-token**: ServiceAccount token
- **kubernetes.io/dockerconfigjson**: Docker registry credentials
- **kubernetes.io/tls**: TLS certificate and key
- **kubernetes.io/basic-auth**: Basic authentication
- **kubernetes.io/ssh-auth**: SSH authentication

### Creating Secrets

#### From Literal
```bash
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=secretpass123
```

#### From File
```bash
echo -n 'admin' > username.txt
echo -n 'secretpass123' > password.txt
kubectl create secret generic db-secret \
  --from-file=username=username.txt \
  --from-file=password=password.txt
```

#### YAML Manifest
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  # Base64 encoded values
  username: YWRtaW4=
  password: c2VjcmV0cGFzczEyMw==
---
# Or use stringData (not base64 encoded)
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
stringData:
  username: admin
  password: secretpass123
```

### Using Secrets

#### Environment Variables
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-env-pod
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
    # Import all secret keys as env vars
    envFrom:
    - secretRef:
        name: db-secret
```

#### Volume Mount
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-volume-pod
spec:
  containers:
  - name: app
    image: myapp:1.0
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: db-secret
      defaultMode: 0400
      items:
      - key: username
        path: db-username
      - key: password
        path: db-password
```

### Docker Registry Secret
```yaml
# Create from command
kubectl create secret docker-registry registry-secret \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass \
  --docker-email=user@example.com

# Use in pod
apiVersion: v1
kind: Pod
metadata:
  name: private-image-pod
spec:
  imagePullSecrets:
  - name: registry-secret
  containers:
  - name: app
    image: registry.example.com/myapp:1.0
```

### TLS Secret
```yaml
# Create from cert files
kubectl create secret tls tls-secret \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key

# YAML
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi... (base64 encoded cert)
  tls.key: LS0tLS1CRUdJTi... (base64 encoded key)
```

### Secret Best Practices
- Enable encryption at rest
- Use RBAC to restrict access
- Rotate secrets regularly
- Use external secret managers (Vault, AWS Secrets Manager)
- Don't commit secrets to version control
- Use sealed-secrets or external-secrets operator

---

## ConfigMap

### Overview
ConfigMap stores non-sensitive configuration data as key-value pairs.

### Creating ConfigMaps

#### From Literal
```bash
kubectl create configmap app-config \
  --from-literal=app.name=myapp \
  --from-literal=app.port=8080 \
  --from-literal=log.level=info
```

#### From File
```bash
# config.properties
app.name=myapp
app.port=8080
log.level=info

kubectl create configmap app-config --from-file=config.properties
```

#### From Directory
```bash
kubectl create configmap app-config --from-file=./config-dir/
```

#### YAML Manifest
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.name: "myapp"
  app.port: "8080"
  log.level: "info"
  # Multi-line config file
  app.conf: |
    [server]
    host = 0.0.0.0
    port = 8080
    
    [database]
    host = postgres
    port = 5432
    name = mydb
```

### Using ConfigMaps

#### Environment Variables
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-env-pod
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    - name: APP_NAME
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: app.name
    - name: APP_PORT
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: app.port
    # Import all keys as env vars
    envFrom:
    - configMapRef:
        name: app-config
```

#### Volume Mount
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-volume-pod
spec:
  containers:
  - name: app
    image: myapp:1.0
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

#### Command Arguments
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-args-pod
spec:
  containers:
  - name: app
    image: myapp:1.0
    command: ["/app/start.sh"]
    args:
    - "--port=$(APP_PORT)"
    - "--log-level=$(LOG_LEVEL)"
    env:
    - name: APP_PORT
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: app.port
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: log.level
```

### ConfigMap vs Secret
| Feature | ConfigMap | Secret |
|---------|-----------|--------|
| Purpose | Non-sensitive config | Sensitive data |
| Storage | Plain text | Base64 encoded |
| Encryption | No | Optional (at rest) |
| Size Limit | 1MB | 1MB |
| Use Case | App config, env vars | Passwords, tokens, keys |

---

## Pod Security

### SecurityContext

#### Pod-level SecurityContext
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
    fsGroupChangePolicy: "OnRootMismatch"
    seccompProfile:
      type: RuntimeDefault
    supplementalGroups: [4000, 5000]
  containers:
  - name: app
    image: nginx
```

#### Container-level SecurityContext
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-container-pod
spec:
  containers:
  - name: app
    image: nginx
    securityContext:
      runAsUser: 1000
      runAsNonRoot: true
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE
      seLinuxOptions:
        level: "s0:c123,c456"
```

### Capabilities
```yaml
spec:
  containers:
  - name: app
    securityContext:
      capabilities:
        drop:
        - ALL  # Drop all capabilities
        add:
        - NET_BIND_SERVICE  # Bind to ports < 1024
        - SYS_TIME  # Set system time
        - CHOWN  # Change file ownership
```

### Pod Security Standards

#### Privileged
```yaml
# No restrictions - allows known privilege escalations
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
spec:
  containers:
  - name: app
    image: nginx
    securityContext:
      privileged: true
```

#### Baseline
```yaml
# Minimally restrictive - prevents known privilege escalations
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
```

#### Restricted
```yaml
# Heavily restricted - follows pod hardening best practices
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
```

---

## NetworkPolicy (Security Perspective)

### Default Deny All
```yaml
# Deny all ingress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
# Deny all egress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
spec:
  podSelector: {}
  policyTypes:
  - Egress
---
# Deny all ingress and egress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### Whitelist Approach
```yaml
# Allow only specific traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow-frontend
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    - namespaceSelector:
        matchLabels:
          name: production
    ports:
    - protocol: TCP
      port: 8080
```

---

# Scaling & Availability

## Horizontal Pod Autoscaler (HPA)

### Overview
HPA automatically scales number of pods based on CPU/memory utilization or custom metrics.

### Basic HPA
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### CPU-based HPA
```bash
# Create HPA via kubectl
kubectl autoscale deployment myapp --cpu-percent=50 --min=2 --max=10
```

### Multi-metric HPA
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: multi-metric-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 3
  maxReplicas: 20
  metrics:
  # CPU
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  # Memory
  - type: Resource
    resource:
      name: memory
      target:
        type: AverageValue
        averageValue: 500Mi
  # Custom metric (requests per second)
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
      - type: Pods
        value: 2
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
      - type: Pods
        value: 4
        periodSeconds: 30
```

### HPA Requirements
```yaml
# Deployment must have resource requests
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:1.0
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
```

### Monitoring HPA
```bash
# Get HPA status
kubectl get hpa
kubectl describe hpa app-hpa

# Watch HPA
kubectl get hpa --watch

# HPA events
kubectl get events --field-selector involvedObject.name=app-hpa
```

---

## Vertical Pod Autoscaler (VPA)

### Overview
VPA automatically adjusts CPU and memory requests/limits based on actual usage.

### Installing VPA
```bash
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler
./hack/vpa-up.sh
```





```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  updatePolicy:
    updateMode: "Auto"  # or "Recreate", "Initial", "Off"
  resourcePolicy:
    containerPolicies:
    - containerName: app
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 2
        memory: 2Gi
      controlledResources: ["cpu", "memory"]
```

### VPA Update Modes
- **Off**: Only provides recommendations
- **Initial**: Applies recommendations only at pod creation
- **Recreate**: Restarts pods with new recommendations
- **Auto**: Updates resources without restarting (requires in-place pod resize feature)

---

## Cluster Autoscaler

### Overview
Cluster Autoscaler automatically adjusts the number of nodes in the cluster based on pod resource requirements.

### How It Works
1. Monitors pending pods that can't be scheduled
2. Checks if adding nodes would help
3. Scales up node groups if needed
4. Scales down underutilized nodes (respecting PDBs)

### AWS Example
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
    spec:
      serviceAccountName: cluster-autoscaler
      containers:
      - image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.28.0
        name: cluster-autoscaler
        command:
        - ./cluster-autoscaler
        - --cloud-provider=aws
        - --namespace=kube-system
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/my-cluster
        - --balance-similar-node-groups
        - --skip-nodes-with-system-pods=false
        env:
        - name: AWS_REGION
          value: us-east-1
```

---

## Pod Disruption Budget (PDB)

### Overview
PDB limits the number of pods that can be disrupted simultaneously during voluntary disruptions.

### Basic PDB
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2  # At least 2 pods must remain available
  selector:
    matchLabels:
      app: myapp
```

### PDB with Percentage
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb-percent
spec:
  maxUnavailable: "25%"  # Max 25% of pods can be unavailable
  selector:
    matchLabels:
      app: myapp
```

### PDB Examples
```yaml
# Ensure high availability
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: critical-app-pdb
spec:
  minAvailable: 3
  selector:
    matchLabels:
      app: critical-app
      tier: production
---
# Allow some disruption
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: background-worker-pdb
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app: worker
```

---

## Resource Quotas & Limit Ranges

### Resource Quotas (Detailed)
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: comprehensive-quota
  namespace: development
spec:
  hard:
    # Compute resources
    requests.cpu: "20"
    requests.memory: 40Gi
    limits.cpu: "40"
    limits.memory: 80Gi
    
    # Storage
    requests.storage: 200Gi
    persistentvolumeclaims: "10"
    
    # Object counts
    count/pods: "100"
    count/services: "50"
    count/secrets: "50"
    count/configmaps: "50"
    count/replicationcontrollers: "20"
    count/deployments.apps: "20"
    count/statefulsets.apps: "10"
    count/jobs.batch: "50"
    count/cronjobs.batch: "20"
    
    # Network
    services.loadbalancers: "5"
    services.nodeports: "10"
```

### Limit Ranges (Detailed)
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: comprehensive-limits
  namespace: development
spec:
  limits:
  # Container limits
  - type: Container
    default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    max:
      cpu: "2"
      memory: "2Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
    maxLimitRequestRatio:
      cpu: "4"
      memory: "2"
  
  # Pod limits
  - type: Pod
    max:
      cpu: "4"
      memory: "4Gi"
    min:
      cpu: "100m"
      memory: "128Mi"
  
  # PVC limits
  - type: PersistentVolumeClaim
    max:
      storage: "100Gi"
    min:
      storage: "1Gi"
```

---

# Observability

## Probes (Health Checks)

### Liveness Probe
Determines if container is alive. Kubelet restarts container if probe fails.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-pod
spec:
  containers:
  - name: app
    image: myapp:1.0
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
        httpHeaders:
        - name: Custom-Header
          value: Awesome
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      successThreshold: 1
      failureThreshold: 3
```

### Readiness Probe
Determines if container is ready to serve traffic. Pod removed from service endpoints if probe fails.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: readiness-pod
spec:
  containers:
  - name: app
    image: myapp:1.0
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 3
      successThreshold: 1
      failureThreshold: 3
```

### Startup Probe
For slow-starting containers. Other probes disabled until startup probe succeeds.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: startup-pod
spec:
  containers:
  - name: app
    image: myapp:1.0
    startupProbe:
      httpGet:
        path: /startup
        port: 8080
      failureThreshold: 30
      periodSeconds: 10
      # Gives container up to 300 seconds (30 * 10) to start
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 10
```

### Probe Types

#### HTTP GET
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
    scheme: HTTPS
```

#### TCP Socket
```yaml
livenessProbe:
  tcpSocket:
    port: 3306
  initialDelaySeconds: 15
  periodSeconds: 20
```

#### Exec Command
```yaml
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
  initialDelaySeconds: 5
  periodSeconds: 5
```

#### gRPC
```yaml
livenessProbe:
  grpc:
    port: 9090
  initialDelaySeconds: 10
```

---

## Logging

### Container Logs
```bash
# View logs
kubectl logs pod-name
kubectl logs pod-name -c container-name

# Follow logs
kubectl logs -f pod-name

# Previous container logs
kubectl logs pod-name --previous

# Tail logs
kubectl logs pod-name --tail=100

# Logs since timestamp
kubectl logs pod-name --since=1h
kubectl logs pod-name --since-time=2024-01-15T10:00:00Z

# All containers in pod
kubectl logs pod-name --all-containers=true

# Multi-pod logs
kubectl logs -l app=nginx

# Logs from all namespaces
kubectl logs -l app=nginx --all-namespaces
```

### Logging Architecture

#### Node-level Logging
```yaml
# Application writes to stdout/stderr
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo $(date) Hello; sleep 1; done"]
```

#### Sidecar Container for Logs
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: counter
spec:
  containers:
  # Main container writes to file
  - name: count
    image: busybox
    command: ["/bin/sh"]
    args:
    - -c
    - >
      i=0;
      while true;
      do
        echo "$i: $(date)" >> /var/log/app.log;
        i=$((i+1));
        sleep 1;
      done
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  
  # Sidecar streams file to stdout
  - name: log-shipper
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "tail -f /var/log/app.log"]
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  
  volumes:
  - name: varlog
    emptyDir: {}
```

### EFK Stack (Elasticsearch, Fluentd, Kibana)

#### Fluentd DaemonSet
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      serviceAccountName: fluentd
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1-debian-elasticsearch
        env:
        - name: FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch.logging.svc.cluster.local"
        - name: FLUENT_ELASTICSEARCH_PORT
          value: "9200"
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

---

## Monitoring

### Metrics Server
```bash
# Install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# View node metrics
kubectl top nodes

# View pod metrics
kubectl top pods
kubectl top pods -n kube-system
kubectl top pods --all-namespaces

# Sort by CPU/memory
kubectl top pods --sort-by=cpu
kubectl top pods --sort-by=memory

# Container metrics
kubectl top pods --containers
```

### Prometheus & Grafana

#### Prometheus Operator
```bash
# Install using Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

#### ServiceMonitor
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: app-monitor
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

#### PodMonitor
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: app-pod-monitor
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: myapp
  podMetricsEndpoints:
  - port: metrics
    interval: 30s
```

### Custom Metrics

#### Prometheus Annotations
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
spec:
  containers:
  - name: app
    image: myapp:1.0
    ports:
    - containerPort: 9090
      name: metrics
```

---

## Tracing

### Distributed Tracing with Jaeger
```yaml
# Jaeger all-in-one
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
  namespace: observability
spec:
  selector:
    matchLabels:
      app: jaeger
  template:
    metadata:
      labels:
        app: jaeger
    spec:
      containers:
      - name: jaeger
        image: jaegertracing/all-in-one:latest
        ports:
        - containerPort: 5775
          protocol: UDP
        - containerPort: 6831
          protocol: UDP
        - containerPort: 6832
          protocol: UDP
        - containerPort: 5778
        - containerPort: 16686
        - containerPort: 14268
```

---

# CI/CD & DevOps

## GitOps with ArgoCD

### Installing ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### ArgoCD Application
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/myapp
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### App of Apps Pattern
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/apps
    targetRevision: HEAD
    path: apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## Helm

### Helm Basics
```bash
# Add repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Search charts
helm search repo nginx

# Install chart
helm install my-nginx bitnami/nginx

# Install with custom values
helm install my-nginx bitnami/nginx -f values.yaml
helm install my-nginx bitnami/nginx --set service.type=LoadBalancer

# List releases
helm list
helm list --all-namespaces

# Upgrade release
helm upgrade my-nginx bitnami/nginx
helm upgrade my-nginx bitnami/nginx -f new-values.yaml

# Rollback
helm rollback my-nginx 1

# Uninstall
helm uninstall my-nginx
```

### Creating Custom Chart
```bash
# Create chart
helm create mychart

# Chart structure
mychart/
  Chart.yaml          # Chart metadata
  values.yaml         # Default values
  charts/             # Chart dependencies
  templates/          # Template files
    deployment.yaml
    service.yaml
    ingress.yaml
    _helpers.tpl
```

### Chart.yaml
```yaml
apiVersion: v2
name: myapp
description: A Helm chart for my application
type: application
version: 1.0.0
appVersion: "2.0"
dependencies:
- name: postgresql
  version: 12.x.x
  repository: https://charts.bitnami.com/bitnami
```

### values.yaml
```yaml
replicaCount: 3

image:
  repository: myapp
  tag: "1.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  hosts:
  - host: myapp.example.com
    paths:
    - path: /
      pathType: Prefix

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

### Template Example
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "myapp.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "myapp.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: 8080
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
```

---

## Kustomize

### Overview
Kustomize customizes Kubernetes YAML configurations without templates.

### Basic Structure
```
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   └── service.yaml
└── overlays/
    ├── development/
    │   └── kustomization.yaml
    ├── staging/
    │   └── kustomization.yaml
    └── production/
        └── kustomization.yaml
```

### Base kustomization.yaml
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- deployment.yaml
- service.yaml

commonLabels:
  app: myapp
  
namespace: default
```

### Overlay kustomization.yaml (Production)
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
- ../../base

namespace: production

replicas:
- name: myapp
  count: 5

images:
- name: myapp
  newTag: v1.2.3

patchesStrategicMerge:
- resource-patch.yaml

configMapGenerator:
- name: app-config
  literals:
  - ENV=production
  - LOG_LEVEL=info

secretGenerator:
- name: app-secret
  literals:
  - DB_PASSWORD=prod-password
```

### Using Kustomize
```bash
# Build and view
kubectl kustomize overlays/production

# Apply directly
kubectl apply -k overlays/production

# Build to file
kubectl kustomize overlays/production > production.yaml
```

---

# Advanced Kubernetes

## Custom Resource Definitions (CRD)

### Creating CRD
```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: applications.stable.example.com
spec:
  group: stable.example.com
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              image:
                type: string
              replicas:
                type: integer
                minimum: 1
                maximum: 10
              port:
                type: integer
          status:
            type: object
            properties:
              availableReplicas:
                type: integer
  scope: Namespaced
  names:
    plural: applications
    singular: application
    kind: Application
    shortNames:
    - app
```

### Using Custom Resource
```yaml
apiVersion: stable.example.com/v1
kind: Application
metadata:
  name: my-application
spec:
  image: nginx:1.25
  replicas: 3
  port: 80
```

---

## Operators

### Operator Pattern
Operators extend Kubernetes to manage complex applications using custom resources.

### Example: PostgreSQL Operator
```yaml
apiVersion: acid.zalan.do/v1
kind: postgresql
metadata:
  name: acid-minimal-cluster
spec:
  teamId: "acid"
  volume:
    size: 1Gi
  numberOfInstances: 2
  users:
    zalando:
    - superuser
    - createdb
  databases:
    foo: zalando
  postgresql:
    version: "15"
```

---

## Admission Controllers

### ValidatingWebhook
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: pod-policy-webhook
webhooks:
- name: validate.example.com
  clientConfig:
    service:
      name: validation-service
      namespace: default
      path: "/validate"
    caBundle: LS0tLS...
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  admissionReviewVersions: ["v1"]
  sideEffects: None
```

### MutatingWebhook
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: pod-mutator-webhook
webhooks:
- name: mutate.example.com
  clientConfig:
    service:
      name: mutation-service
      namespace: default
      path: "/mutate"
    caBundle: LS0tLS...
  rules:
  - operations: ["CREATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  admissionReviewVersions: ["v1"]
  sideEffects: None
```

---

## Service Mesh (Istio)

### Installing Istio
```bash
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y

# Enable sidecar injection
kubectl label namespace default istio-injection=enabled
```

### Virtual Service
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp
  http:
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: myapp
        subset: v2
  - route:
    - destination:
        host: myapp
        subset: v1
      weight: 90
    - destination:
        host: myapp
        subset: v2
      weight: 10
```

### Destination Rule
```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: myapp
spec:
  host: myapp
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

---

# Production Best Practices

## High Availability

### Multi-Master Setup
```yaml
# 3 master nodes minimum
Master Nodes: 3 (or 5 for critical systems)
Worker Nodes: 3+ (distributed across availability zones)
etcd: 3 or 5 nodes (odd number)

# Load balancer for API server
API Server Load Balancer:
- Health checks on port 6443
- Distribute across all masters
```

### Pod Distribution
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 6
  template:
    spec:
      affinity:
        # Spread across nodes
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - myapp
              topologyKey: kubernetes.io/hostname
        # Spread across zones
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - myapp
              topologyKey: topology.kubernetes.io/zone
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: myapp
```

---

## Security Best Practices

### Security Checklist
```yaml
    RBAC enabled and configured
    Pod Security Standards enforced
    Network Policies implemented
    Secrets encrypted at rest
    Regular security updates
    Admission controllers active
    Audit logging enabled
    TLS everywhere
    Image scanning in CI/CD
    Runtime security monitoring
```

### Secure Pod Template
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10000
    fsGroup: 10000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: myapp:1.0
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      capabilities:
        drop:
        - ALL
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "512Mi"
        cpu: "500m"
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
```

---

## Resource Management

### Resource Requests and Limits
```yaml
# Conservative (guaranteed QoS)
resources:
  requests:
    memory: "256Mi"
    cpu: "200m"
  limits:
    memory: "256Mi"
    cpu: "200m"

# Burstable (balanced)
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"

# Best-effort (no guarantees)
# No requests or limits set
```

---

## Backup and Disaster Recovery

### Velero Backup
```bash
# Install Velero
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.8.0 \
  --bucket velero-backups \
  --backup-location-config region=us-east-1 \
  --snapshot-location-config region=us-east-1

# Create backup
velero backup create my-backup

# Schedule backups
velero schedule create daily-backup --schedule="0 2 * * *"

# Restore
velero restore create --from-backup my-backup
```

### Backup Strategy
```yaml
Full Cluster Backup:
- etcd snapshots (daily)
- Persistent volume snapshots
- Application configuration backups

Recovery Objectives:
- RPO: < 1 hour
- RTO: < 4 hours

Backup Locations:
- Primary: Cloud storage
- Secondary: Different region
- Tertiary: On-premises (compliance)
```

---

## Troubleshooting Guide

### Common Issues

#### Pod Stuck in Pending
```bash
kubectl describe pod <pod-name>
# Check:
# - Insufficient resources
# - Node selector mismatch
# - PV not available
# - Image pull issues
```

#### Pod CrashLoopBackOff
```bash
kubectl logs <pod-name> --previous
kubectl describe pod <pod-name>
# Check:
# - Application errors
# - Missing dependencies
# - Resource limits too low
# - Liveness probe failures
```

#### Service Not Accessible
```bash
# Check endpoints
kubectl get endpoints <service-name>

# Check service
kubectl describe service <service-name>

# Check network policies
kubectl get networkpolicies

# Test connectivity
kubectl run test-pod --rm -it --image=busybox -- wget -O- <service-name>
```

---

## Performance Optimization

### Node Performance
```yaml
# Node tuning
kubelet flags:
  --max-pods=110
  --kube-reserved=cpu=100m,memory=1Gi
  --system-reserved=cpu=100m,memory=1Gi
  --eviction-hard=memory.available<500Mi
```

### Application Optimization
```yaml
# Use readiness probes
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5

# Set appropriate resource limits
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"

# Use horizontal scaling
horizontalPodAutoscaler:
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

# Enable topology spread
topologySpreadConstraints:
- maxSkew: 1
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: DoNotSchedule
  labelSelector:
    matchLabels:
      app: myapp
```

### Network Performance
```yaml
# Use headless services for direct pod-to-pod
apiVersion: v1
kind: Service
metadata:
  name: fast-service
spec:
  clusterIP: None
  selector:
    app: myapp
  ports:
  - port: 8080

# Use service mesh for intelligent routing
# Enable connection pooling and circuit breaking
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: myapp-circuit-breaker
spec:
  host: myapp
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        http2MaxRequests: 100
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
```

### Storage Performance
```yaml
# Use appropriate storage class
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iops: "10000"
  throughput: "250"
volumeBindingMode: WaitForFirstConsumer

# Use local storage for high performance
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv-fast
spec:
  capacity:
    storage: 100Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-fast
  local:
    path: /mnt/nvme0n1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - high-perf-node-1
```

### DNS Optimization
```yaml
# Reduce DNS lookups with ndots
apiVersion: v1
kind: Pod
metadata:
  name: optimized-dns-pod
spec:
  dnsConfig:
    options:
    - name: ndots
      value: "2"
    - name: timeout
      value: "2"
    - name: attempts
      value: "2"
  containers:
  - name: app
    image: myapp:1.0
```

---

## Cluster Maintenance

### Node Maintenance

#### Drain Node
```bash
# Safely drain node (evict pods)
kubectl drain node-1 --ignore-daemonsets --delete-emptydir-data

# Uncordon node (make schedulable again)
kubectl uncordon node-1

# Cordon node (prevent new pods)
kubectl cordon node-1
```

#### Node Upgrade Process
```bash
# 1. Drain node
kubectl drain node-1 --ignore-daemonsets --delete-emptydir-data --force

# 2. Perform upgrade on node (SSH to node)
# - Update kubelet, kubectl, kubeadm
# - Restart services

# 3. Uncordon node
kubectl uncordon node-1

# 4. Verify
kubectl get nodes
```

### Cluster Upgrade

#### Control Plane Upgrade
```bash
# Upgrade kubeadm
apt-mark unhold kubeadm
apt-get update && apt-get install -y kubeadm=1.29.0-00
apt-mark hold kubeadm

# Check upgrade plan
kubeadm upgrade plan

# Apply upgrade
kubeadm upgrade apply v1.29.0

# Upgrade kubelet and kubectl
apt-mark unhold kubelet kubectl
apt-get update && apt-get install -y kubelet=1.29.0-00 kubectl=1.29.0-00
apt-mark hold kubelet kubectl

# Restart kubelet
systemctl daemon-reload
systemctl restart kubelet
```

#### Worker Node Upgrade
```bash
# On control plane - drain worker
kubectl drain worker-1 --ignore-daemonsets --delete-emptydir-data

# On worker node - upgrade kubeadm
apt-mark unhold kubeadm
apt-get update && apt-get install -y kubeadm=1.29.0-00
apt-mark hold kubeadm

# Upgrade node
kubeadm upgrade node

# Upgrade kubelet and kubectl
apt-mark unhold kubelet kubectl
apt-get update && apt-get install -y kubelet=1.29.0-00 kubectl=1.29.0-00
apt-mark hold kubelet kubectl
systemctl daemon-reload
systemctl restart kubelet

# On control plane - uncordon worker
kubectl uncordon worker-1
```

### etcd Backup and Restore

#### Backup etcd
```bash
# Snapshot etcd
ETCDCTL_API=3 etcdctl snapshot save snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify snapshot
ETCDCTL_API=3 etcdctl snapshot status snapshot.db --write-out=table
```

#### Restore etcd
```bash
# Stop kube-apiserver
systemctl stop kube-apiserver

# Restore from snapshot
ETCDCTL_API=3 etcdctl snapshot restore snapshot.db \
  --data-dir=/var/lib/etcd-restore \
  --initial-cluster=etcd-1=https://10.0.0.1:2380 \
  --initial-advertise-peer-urls=https://10.0.0.1:2380 \
  --name=etcd-1

# Update etcd configuration to use new data directory
# Restart etcd and kube-apiserver
systemctl restart etcd
systemctl start kube-apiserver
```

---

## Multi-Tenancy

### Namespace Isolation
```yaml
# Create tenant namespace
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-acme
  labels:
    tenant: acme
---
# Resource quota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-acme-quota
  namespace: tenant-acme
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    persistentvolumeclaims: "10"
    pods: "50"
---
# Network policy - deny all by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: tenant-acme
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
# Network policy - allow DNS
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: tenant-acme
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

### Tenant RBAC
```yaml
# Tenant admin role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: tenant-admin
  namespace: tenant-acme
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
# Tenant admin binding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: tenant-admin-binding
  namespace: tenant-acme
subjects:
- kind: User
  name: acme-admin
  apiGroup: rbac.authorization.k8s.io
- kind: Group
  name: acme-admins
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: tenant-admin
  apiGroup: rbac.authorization.k8s.io
---
# Tenant developer role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: tenant-developer
  namespace: tenant-acme
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["pods", "deployments", "services", "jobs", "cronjobs"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list"]
```

### Hierarchical Namespaces (HNC)
```yaml
# Parent namespace
apiVersion: v1
kind: Namespace
metadata:
  name: company-acme
---
# Child namespace
apiVersion: hnc.x-k8s.io/v1alpha2
kind: SubnamespaceAnchor
metadata:
  name: team-alpha
  namespace: company-acme
---
# Hierarchical configuration
apiVersion: hnc.x-k8s.io/v1alpha2
kind: HierarchyConfiguration
metadata:
  name: hierarchy
  namespace: company-acme
spec:
  allowCascadingDeletion: true
```

---

## Cost Optimization

### Resource Right-Sizing
```yaml
# Use VPA for recommendations
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: cost-optimizer-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  updatePolicy:
    updateMode: "Off"  # Recommendations only
```

### Spot/Preemptible Instances
```yaml
# Node affinity for spot instances
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch-processor
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 50
            preference:
              matchExpressions:
              - key: node.kubernetes.io/instance-type
                operator: In
                values:
                - spot
      tolerations:
      - key: node.kubernetes.io/instance-type
        operator: Equal
        value: spot
        effect: NoSchedule
```

### Cluster Autoscaler for Cost
```yaml
# Configure cluster autoscaler for cost optimization
--scale-down-enabled=true
--scale-down-delay-after-add=10m
--scale-down-unneeded-time=10m
--skip-nodes-with-system-pods=false
--balance-similar-node-groups=true
--expander=least-waste  # or priority
```

### Resource Quotas by Cost Center
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: cost-center-engineering
  namespace: engineering
  labels:
    cost-center: "CC-12345"
spec:
  hard:
    requests.cpu: "50"
    requests.memory: 100Gi
    limits.cpu: "100"
    limits.memory: 200Gi
```

---

## Compliance and Governance

### Pod Security Standards
```yaml
# Enforce pod security standard at namespace level
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### Policy Enforcement (OPA Gatekeeper)
```yaml
# Install Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml

# Constraint template
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
  - target: admission.k8s.gatekeeper.sh
    rego: |
      package k8srequiredlabels
      
      violation[{"msg": msg, "details": {"missing_labels": missing}}] {
        provided := {label | input.review.object.metadata.labels[label]}
        required := {label | label := input.parameters.labels[_]}
        missing := required - provided
        count(missing) > 0
        msg := sprintf("You must provide labels: %v", [missing])
      }
---
# Constraint
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-labels
spec:
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Namespace"]
  parameters:
    labels:
    - cost-center
    - owner
    - environment
```

### Audit Logging
```yaml
# Audit policy
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
# Log all requests at metadata level
- level: Metadata
  omitStages:
  - RequestReceived

# Don't log read-only requests
- level: None
  verbs: ["get", "list", "watch"]

# Log Secret operations at Request level
- level: Request
  resources:
  - group: ""
    resources: ["secrets"]

# Log pod exec and attach at Request level
- level: Request
  verbs: ["create"]
  resources:
  - group: ""
    resources: ["pods/exec", "pods/attach"]

# Log authentication and authorization
- level: Request
  nonResourceURLs:
  - /api*
  - /version
```

---

## Disaster Recovery Scenarios

### Scenario 1: Node Failure
```bash
# Node failure detected
kubectl get nodes

# Pods automatically rescheduled to healthy nodes
kubectl get pods -o wide

# Replace failed node
# 1. Remove old node
kubectl delete node node-1

# 2. Provision new node
# 3. Join to cluster
kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
```

### Scenario 2: Control Plane Failure
```bash
# If using HA setup, other control plane nodes continue
kubectl get componentstatuses

# Restore failed control plane node
# 1. Restore etcd from backup
# 2. Rejoin control plane

# If total control plane loss, restore from backup
etcdctl snapshot restore snapshot.db
```

### Scenario 3: Full Cluster Loss
```bash
# 1. Provision new cluster
kubeadm init

# 2. Restore etcd data
etcdctl snapshot restore

# 3. Restore application configs from Git/Backup
kubectl apply -f backup/manifests/

# 4. Restore persistent data from volume snapshots
kubectl apply -f backup/pvcs/
```

### Scenario 4: Namespace Deletion
```bash
# Immediate action - try to stop deletion
kubectl patch namespace production -p '{"metadata":{"finalizers":[]}}' --type=merge

# If too late, restore from backup
velero restore create --from-backup production-backup

# Or restore from Git
kubectl apply -f production-namespace-backup/
```

---

## Advanced Networking

### IPv4/IPv6 Dual Stack
```yaml
apiVersion: v1
kind: Service
metadata:
  name: dual-stack-service
spec:
  ipFamilyPolicy: PreferDualStack
  ipFamilies:
  - IPv4
  - IPv6
  selector:
    app: myapp
  ports:
  - port: 80
```

### Multi-Cluster Service Mesh
```yaml
# Istio multi-cluster setup
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: multi-cluster
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ISTIO_META_DNS_CAPTURE: "true"
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster-1
      network: network-1
```

### Network Policies - Advanced
```yaml
# Allow traffic from specific IP blocks and namespaces
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: complex-policy
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Allow from specific namespace and pod labels
  - from:
    - namespaceSelector:
        matchLabels:
          environment: production
      podSelector:
        matchLabels:
          tier: frontend
    # Allow from specific IP range
    - ipBlock:
        cidr: 10.0.0.0/8
        except:
        - 10.0.1.0/24
    ports:
    - protocol: TCP
      port: 8080
  egress:
  # Allow DNS
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
  # Allow to database
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
  # Allow HTTPS to external
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 443
```

---

## Kubernetes API

### API Versioning
```yaml
# Alpha (may change, disabled by default)
apiVersion: foo.example.com/v1alpha1

# Beta (well tested, enabled by default)
apiVersion: foo.example.com/v1beta1

# Stable (production ready)
apiVersion: foo.example.com/v1
```

### API Groups
```yaml
# Core group (no group name)
apiVersion: v1
kind: Pod

# Named groups
apiVersion: apps/v1
kind: Deployment

apiVersion: batch/v1
kind: Job

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
```

### Custom API Access
```bash
# List API resources
kubectl api-resources

# List API versions
kubectl api-versions

# Explain resource
kubectl explain pod
kubectl explain pod.spec.containers

# Direct API access
kubectl proxy --port=8080

# Then use curl
curl http://localhost:8080/api/v1/namespaces/default/pods
```

---

## Final Best Practices Summary

### Development
- Use namespaces for isolation
- Implement proper health checks
- Set resource requests/limits
- Use ConfigMaps and Secrets
- Version your manifests in Git
- Use Helm or Kustomize for templating

### Production
- Implement HA for control plane
- Use multiple replicas
- Configure PodDisruptionBudgets
- Implement network policies
- Enable audit logging
- Regular backups (etcd, volumes)
- Monitor everything
- Implement autoscaling (HPA, VPA, CA)

### Security
- Enable RBAC
- Use Pod Security Standards
- Scan images for vulnerabilities
- Rotate secrets regularly
- Use network policies
- Encrypt secrets at rest
- Regular security audits
- Implement admission controllers

### Operations
- Automate with GitOps
- Implement CI/CD pipelines
- Use Infrastructure as Code
- Regular cluster upgrades
- Disaster recovery testing
- Capacity planning
- Cost monitoring
- Documentation

---

## Quick Reference Commands

### Essential kubectl Commands
```bash
# Cluster info
kubectl cluster-info
kubectl get nodes
kubectl version

# Resource management
kubectl get pods -A
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/bash

# Apply manifests
kubectl apply -f manifest.yaml
kubectl apply -f ./directory/
kubectl delete -f manifest.yaml

# Scaling
kubectl scale deployment <name> --replicas=3
kubectl autoscale deployment <name> --min=2 --max=10

# Updates
kubectl set image deployment/<name> container=image:tag
kubectl rollout status deployment/<name>
kubectl rollout undo deployment/<name>

# Debugging
kubectl get events
kubectl top nodes
kubectl top pods
kubectl describe node <node-name>

# Context management
kubectl config get-contexts
kubectl config use-context <context>
kubectl config set-context --current --namespace=<namespace>
```

---

## Conclusion

This comprehensive Kubernetes documentation covers:

**Fundamentals**: Architecture, components, core objects
**Networking**: Services, Ingress, DNS, CNI, Network Policies
**Storage**: Volumes, PV/PVC, StorageClass, CSI
**Security**: RBAC, Secrets, Pod Security, Network Policies
**Scaling**: HPA, VPA, Cluster Autoscaler, PDB
**Observability**: Logging, Monitoring, Tracing
**CI/CD**: ArgoCD, Helm, Kustomize
**Advanced**: CRDs, Operators, Service Mesh, Admission Controllers
**Production**: HA, Backup/DR, Performance, Cost Optimization
**Operations**: Maintenance, Upgrades, Troubleshooting

**Next Steps:**
1. Set up a test cluster (minikube, kind, or cloud provider)
2. Practice with examples from each section
3. Build real applications
4. Implement monitoring and logging
5. Automate with CI/CD
6. Prepare for CKA/CKAD/CKS certification

**Resources:**
- Official Docs: https://kubernetes.io/docs
- GitHub: https://github.com/kubernetes/kubernetes
- CNCF Slack: https://slack.cncf.io
- Kubernetes Blog: https://kubernetes.io/blog

---

**Happy Kubernetes Journey! 🚀**
