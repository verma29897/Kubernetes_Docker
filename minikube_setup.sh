#!/bin/bash

# Install the latest Minikube stable release on x86-64 Linux
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

# Start your cluster
minikube start

# Interact with your cluster
kubectl get po -A

# Alternatively, use minikube's built-in kubectl
minikube kubectl -- get po -A

# Setup alias (optional for convenience)
alias kubectl="minikube kubectl --"

# Launch Kubernetes dashboard
minikube dashboard

# -------------------------------
# Deploy Applications
# -------------------------------

# 1. NodePort Service
kubectl create deployment hello-minikube --image=kicbase/echo-server:1.0
kubectl expose deployment hello-minikube --type=NodePort --port=8080
kubectl get services hello-minikube
minikube service hello-minikube
# Or use port-forward
kubectl port-forward service/hello-minikube 7080:8080

# 2. LoadBalancer Service
kubectl create deployment balanced --image=kicbase/echo-server:1.0
kubectl expose deployment balanced --type=LoadBalancer --port=8080

# In a separate terminal, start tunnel
# (This command needs to run continuously)
# minikube tunnel

# Get LoadBalancer IP
kubectl get services balanced

# 3. Ingress
minikube addons enable ingress
kubectl apply -f https://storage.googleapis.com/minikube-site-examples/ingress-example.yaml

# -------------------------------
# Manage Cluster
# -------------------------------

# Pause Kubernetes
minikube pause

# Resume Kubernetes
minikube unpause

# Stop the cluster
minikube stop

# Change memory allocation (requires restart)
minikube config set memory 9001

# List available addons
minikube addons list

# Create a second cluster with an older Kubernetes version
minikube start -p aged --kubernetes-version=v1.16.1

# Delete all clusters
minikube delete --all

