# Elevate Learning - Docker & Kubernetes Deployment Guide

## Project Overview
This Django application demonstrates a microservices architecture with:
- **Django Web Application** (2 replicas for high availability)
- **MySQL Database** (persistent storage)
- **Nginx Reverse Proxy** (load balancing)
- **Redis Cache** (optional, for performance)

## Architecture
```
Internet → Nginx (Port 80) → Django App (Port 8000) → MySQL DB (Port 3306)
                                                    → Redis (Port 6379)
```

---

## Prerequisites on GCP Instance

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version
docker-compose --version
```

---

## Option 1: Deploy with Docker Compose (Simple)

### Step 1: Transfer files to GCP instance
```bash
# On your local machine
cd /Users/abhishektanguturi/Master_of_Information_Tech/Sem_3_2025/INFS7202/s4845110_Abhishek_Tanguturi/ProjectCode/INFS7202/elevatelearning
rsync -avz -e "ssh -i ../mykeys/remote-server-myproject" \
  --exclude='venv' --exclude='__pycache__' --exclude='*.pyc' \
  . t_abhishek345@35.244.96.92:~/elevatelearning/
```

### Step 2: Build and run containers
```bash
# SSH to GCP instance
ssh remote-server-myproject

# Navigate to project
cd ~/elevatelearning

# Build Docker image
docker build -t elevatelearning-web:latest .

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

### Step 3: Access the application
Open browser: `http://35.244.96.92`/(Click on the external IP of the instance)


---

## Option 3: Deploy with Kubernetes (Production-ready)

### Step 1: Install Kubernetes (Minikube or K3s)

#### Using K3s (Lightweight Kubernetes)
```bash
# Install K3s
curl -sfL https://get.k3s.io | sh -

# Check installation
sudo k3s kubectl get nodes

# Setup kubectl access
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
```

### Step 2: Build and load Docker image
```bash
cd ~/elevatelearning

# Build image
docker build -t elevatelearning-web:latest .

# Import to K3s
sudo k3s ctr images import elevatelearning-web:latest
```

### Step 3: Deploy to Kubernetes
```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Apply configurations
kubectl apply -f k8s/configmap.yaml

# Deploy MySQL
kubectl apply -f k8s/mysql-deployment.yaml

# Wait for MySQL to be ready
kubectl wait --for=condition=ready pod -l app=mysql -n elevatelearning --timeout=300s

# Deploy Django application
kubectl apply -f k8s/django-deployment.yaml

# Deploy Nginx
kubectl apply -f k8s/nginx-deployment.yaml

# Check all resources
kubectl get all -n elevatelearning

# Check pod logs
kubectl logs -f deployment/django-web -n elevatelearning

# Get external IP (LoadBalancer)
kubectl get svc nginx-service -n elevatelearning
```

### Step 4: Access the application
```bash
# Get the LoadBalancer external IP
kubectl get svc nginx-service -n elevatelearning

# If using NodePort (for GCP single node)
kubectl patch svc nginx-service -n elevatelearning -p '{"spec":{"type":"NodePort"}}'
kubectl get svc nginx-service -n elevatelearning

# Access via: http://35.244.96.92:<NodePort>
```

---

## Kubernetes Management Commands

```bash
# Scale Django replicas
kubectl scale deployment django-web --replicas=3 -n elevatelearning

# Update application (rolling update)
docker build -t elevatelearning-web:v2 .
kubectl set image deployment/django-web django=elevatelearning-web:v2 -n elevatelearning

# Rollback deployment
kubectl rollout undo deployment/django-web -n elevatelearning

# View rollout status
kubectl rollout status deployment/django-web -n elevatelearning

# Delete all resources
kubectl delete namespace elevatelearning
```

---

## Monitoring & Troubleshooting

### Docker Compose
```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs web

# Execute command in container
docker-compose exec web python manage.py shell

# Restart a service
docker-compose restart web

# Rebuild and restart
docker-compose up -d --build
```

### Docker Swarm
```bash
# Service logs
docker service logs -f elevatelearning_web

# Inspect service
docker service inspect elevatelearning_web

# List tasks
docker service ps elevatelearning_web

# Execute command in service container
docker exec -it $(docker ps -q -f name=elevatelearning_web) python manage.py shell
```

### Kubernetes
```bash
# Pod logs
kubectl logs -f deployment/django-web -n elevatelearning

# Execute command in pod
kubectl exec -it deployment/django-web -n elevatelearning -- python manage.py shell

# Describe pod (debugging)
kubectl describe pod <pod-name> -n elevatelearning

# Port forward for testing
kubectl port-forward svc/django-service 8000:8000 -n elevatelearning

# View events
kubectl get events -n elevatelearning --sort-by='.lastTimestamp'
```

---

## Database Management

### Run migrations
```bash
# Docker Compose
docker-compose exec web python manage.py migrate

# Kubernetes
kubectl exec -it deployment/django-web -n elevatelearning -- python manage.py migrate
```

### Create superuser
```bash
# Docker Compose
docker-compose exec web python manage.py createsuperuser

# Kubernetes
kubectl exec -it deployment/django-web -n elevatelearning -- python manage.py createsuperuser
```

### Backup database
```bash
# Docker Compose
docker-compose exec db mysqldump -u djangouser -pdjangopassword123 elevatelearning_db > backup.sql

# Kubernetes
kubectl exec -it deployment/mysql -n elevatelearning -- mysqldump -u djangouser -pdjangopassword123 elevatelearning_db > backup.sql
```

---

## Firewall Configuration

```bash
# Allow HTTP traffic
sudo ufw allow 80/tcp

# Allow HTTPS traffic
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

---

## Production Checklist

- [ ] Change SECRET_KEY in .env file
- [ ] Set DEBUG=False
- [ ] Update ALLOWED_HOSTS with your domain
- [ ] Change all default passwords
- [ ] Enable HTTPS/SSL
- [ ] Set up automated backups
- [ ] Configure monitoring (Prometheus/Grafana)
- [ ] Set up logging aggregation
- [ ] Configure resource limits
- [ ] Enable auto-scaling
- [ ] Set up CI/CD pipeline

---

## URLs

- **Application:** http://35.244.96.92
- **Admin Panel:** http://35.244.96.92/elevatelearning/admin/
- **Health Check:** http://35.244.96.92/health

---

## Support

For issues or questions, refer to:
- Docker documentation: https://docs.docker.com/
- Kubernetes documentation: https://kubernetes.io/docs/
- Django deployment: https://docs.djangoproject.com/en/stable/howto/deployment/

---

## Microservices Architecture Compliance

✅ **4+ Different Functionalities:**
1. User Authentication (Register/Login)
2. Course Management (Create/Edit/Delete courses)
3. Learning Progress Tracking
4. Social Interactions (Likes/Comments)
5. QR Code Generation
6. Certificate Generation

✅ **Database Backend:** MySQL with Django ORM

✅ **Containerization:** Docker with multiple containers:
- Django Web (Application layer)
- MySQL (Data layer)
- Nginx (Presentation/Proxy layer)
- Redis (Cache layer)

✅ **Orchestration:** 
- Docker Swarm OR Kubernetes
- Multiple replicas for high availability
- Load balancing through Nginx
- Health checks and auto-recovery
