# 🚀 Kubernetes Go App Deployment (Minikube)

This project contains all necessary files and scripts to build, deploy, and expose a simple Go-based API using **Kubernetes** with **Minikube** on Ubuntu.

---

## 📁 Project Structure

| File / Script         | Description |
|-----------------------|-------------|
| `Dockerfile`          | Defines how to build the Docker image for the Go API. |
| `deployment.yaml`     | Kubernetes Deployment manifest for the Go API. |
| `service.yaml`        | Kubernetes Service manifest to expose the API. |
| `install_docker.sh`   | Script to install Docker on Ubuntu. |
| `install_kubectl.sh`  | Script to install `kubectl` CLI on Ubuntu. |
| `minikube_setup.sh`   | Script to install and start Minikube. |
| `run_kubernetes.sh`   | Script to build Docker image, apply Kubernetes manifests, and expose the service. |

---

## 🛠️ Setup Instructions

### 1. Install Docker
```bash
./install_docker.sh

### 2. Install kubectl

./install_kubectl.sh
### 3. Install and start Minikube
./minikube_setup.sh
### 4. Build & Deploy Go API on Kubernetes

./run_kubernetes.sh ```
