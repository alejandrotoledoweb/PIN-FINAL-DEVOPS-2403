# Documentación de Trabajo - PIN Final (Grupo 15)

## Creación de Clúster con MicroK8s Localmente

### 1. Creación del Namespace `pin-devops`
Para crear el namespace donde desplegaremos los recursos:
```sh
kubectl create namespace pin-devops
```

---

### 2. Despliegue de Nginx

#### **Comando para correr el despliegue:**
```sh
kubectl apply -f nginx-deploy.yaml -n pin-devops
```

#### **Archivo: `nginx-deploy.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
```

#### **Verificar que Nginx esté corriendo:**
```sh
kubectl get all -n pin-devops
kubectl get svc -n pin-devops
```

---

## 3. Instalación de Prometheus

#### **Script para instalar Prometheus (`prometheus.sh`)**
```sh
#!/bin/bash

# Crear el namespace para Prometheus
kubectl create namespace prometheus

# Agregar el repositorio Helm de Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar Prometheus con Helm
t
helm install prometheus prometheus-community/prometheus --namespace prometheus \
  --set alertmanager.persistentVolume.storageClass="microk8s-hostpath" \
  --set server.persistentVolume.storageClass="microk8s-hostpath"

# Aplicar el PersistentVolumeClaim
kubectl apply -f pv-microk8s.yaml

echo "Finishing installation..."
sleep 60

# Verificar los pods de Prometheus
kubectl get pods -n prometheus
```

#### **Archivo: `pv-microk8s.yaml`**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    app.kubernetes.io/instance: prometheus
    app.kubernetes.io/name: alertmanager
  name: storage-prometheus-alertmanager-0
  namespace: prometheus
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  volumeMode: Filesystem
  storageClassName: microk8s-hostpath
```

#### **Revisar los pods y servicios de Prometheus:**
```sh
kubectl get all -n prometheus
```

Si hay pods en estado `Pending`, habilitar MetalLB y storage:
```sh
microk8s enable metallb
microk8s enable storage
```

Actualizar el servicio para usar un `LoadBalancer`:
```sh
kubectl patch svc prometheus-server -n prometheus -p '{"spec": {"type": "LoadBalancer"}}'
```

#### **Revisar que el dashboard de Prometheus esté expuesto:**
```sh
kubectl get svc -n prometheus
```
Abrir en el navegador:
```
http://10.211.56.3
```

---

## 4. Instalación de Grafana

#### **Script para instalar Grafana (`grafana.sh`)**
```sh
#!/bin/bash
# Generar una contraseña aleatoria para el admin
ADMIN_PASSWORD=$(openssl rand -base64 12)

# Agregar el repositorio de Helm de Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Crear el namespace para Grafana
kubectl create namespace grafana --dry-run=client -o yaml | kubectl apply -f -

# Instalar Grafana con Helm
helm install grafana grafana/grafana \
  --namespace grafana \
  --values ./grafana/grafana.yaml \
  --set persistence.enabled=true \
  --set persistence.storageClassName=microk8s-hostpath \
  --set adminPassword="$ADMIN_PASSWORD" \
  --set service.type=LoadBalancer

echo "Finishing the installation..."
sleep 60

# Obtener los recursos de Grafana
kubectl get all -n grafana

# Obtener la URL de Grafana
grafana_ip="$(kubectl get svc -n grafana grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "---------------------------------------------------------"
echo "You can view Grafana at: http://$grafana_ip:80"
echo "Grafana admin password: $ADMIN_PASSWORD"
echo "---------------------------------------------------------"
```

#### **Archivo: `grafana.yaml`**
```yaml
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        url: http://prometheus-server.prometheus.svc.cluster.local
        access: proxy
        isDefault: true
```

#### **Verificar el Dashboard de Grafana**
Una vez instalado, ingresar en:
```
http://10.211.56.12
```
Usuario: `admin`
Contraseña: (generada por el script)

---

## 5. Agregar Dashboards en Grafana
Para visualizar las métricas correctamente, importar los siguientes dashboards:

| Dashboard Name | ID |
|---------------|----|
| **Node Exporter Full** | `1860` |
| **Kubernetes Cluster Metrics** | `6417` |
| **Kubernetes Cluster Monitoring** | `3119` |

Para importarlos en Grafana:
1. Ir a **Grafana → Dashboards → Import**.
2. Ingresar el **ID del dashboard**.
3. Seleccionar **Prometheus como Data Source**.
4. Clic en **Import**.

---

## 🎯 **Resumen Final**
✔ Clúster creado con **MicroK8s**.
✔ Nginx desplegado en **`pin-devops`** con LoadBalancer.
✔ **Prometheus** instalado y recolectando métricas.
✔ **Grafana** configurado con dashboards de monitoreo.

🚀 **El stack está listo!** Revisa las métricas en:
```
http://10.211.56.12
```

