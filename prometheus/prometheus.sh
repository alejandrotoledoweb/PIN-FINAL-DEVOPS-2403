#!/bin/bash

# Ensure namespace exists
kubectl get namespace prometheus >/dev/null 2>&1 || kubectl create namespace prometheus

# Add the Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus using Helm
helm install prometheus prometheus-community/prometheus --namespace prometheus \
  --set alertmanager.persistentVolume.storageClass="microk8s-hostpath" \
  --set server.persistentVolume.storageClass="microk8s-hostpath"

# Apply PersistentVolumeClaim if the file exists
if [ -f "./prometheus/pv.yaml" ]; then
    kubectl apply -f ./prometheus/pv.yaml --namespace prometheus
else
    echo "Warning: ./prometheus/pv.yaml not found, skipping PVC creation"
fi

echo "Finishing installation..."
sleep 1

# Check pod status
kubectl get pods -n prometheus
