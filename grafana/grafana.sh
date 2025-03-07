#!/bin/bash
# Generate a random admin password
ADMIN_PASSWORD=$(openssl rand -base64 12)

# Add the Grafana Helm chart repository
helm repo add grafana https://grafana.github.io/helm-charts

# Update Helm repository cache
helm repo update

# Create the 'grafana' namespace if it does not exist
kubectl create namespace grafana --dry-run=client -o yaml | kubectl apply -f ./grafana/grafana.yaml

# Install Grafana with Helm
helm install grafana grafana/grafana \
  --namespace grafana \
  --values ./grafana/grafana.yaml \
  --set persistence.enabled=true \
  --set persistence.storageClassName=microk8s-hostpath \
  --set adminPassword="$ADMIN_PASSWORD" \
  --set service.type=LoadBalancer

echo "Finishing the installation..."
sleep 60

# Get all Grafana resources
kubectl get all -n grafana

# Obtain the URL for the Grafana page
grafana_ip="$(kubectl get svc -n grafana grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"

echo "---------------------------------------------------------------------------------"
echo "You can view the Grafana page in your browser with this URL: http://$grafana_ip:80"
echo "Grafana admin password: $ADMIN_PASSWORD"
echo "---------------------------------------------------------------------------------"
