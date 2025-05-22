#!/bin/bash

set -e

echo "[+] Fetching latest kubectl version..."
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

echo "[+] Downloading kubectl $KUBECTL_VERSION..."
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

echo "[+] Verifying kubectl binary..."
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"
echo "$(<kubectl.sha256)  kubectl" | sha256sum --check

echo "[+] Making kubectl executable..."
chmod +x kubectl

echo "[+] Moving kubectl to /usr/local/bin..."
sudo mv kubectl /usr/local/bin/

echo "[+] Cleaning up..."
rm kubectl.sha256

echo "[✓] kubectl installed successfully!"
kubectl version --client

