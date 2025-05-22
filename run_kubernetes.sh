#!/bin/bash

# Point Docker CLI to Minikube's Docker daemon
eval $(minikube docker-env)

# Build the Docker image inside Minikube's Docker
docker build -t go-api:v1 .

# Apply Kubernetes configs
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Get the service URL
minikube service go-api-service --url
