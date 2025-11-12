# Elevate Learning - Quick Start Guide

## 🚀 One-Command Deployment

### On your local machine:

```bash
# Navigate to project directory
cd /Users/abhishektanguturi/Master_of_Information_Tech/Sem_3_2025/INFS7202/s4845110_Abhishek_Tanguturi/ProjectCode/INFS7202/elevatelearning

# Transfer files to GCP instance
rsync -avz -e "ssh -i ../mykeys/remote-server-myproject" \
  --exclude='venv' --exclude='__pycache__' --exclude='*.pyc' --exclude='db.sqlite3' \
  . t_abhishek345@35.244.96.92:~/elevatelearning/
```

### On GCP instance:

```bash
# SSH to GCP instance
ssh remote-server-myproject

# Navigate to project
cd ~/elevatelearning

# Make deploy script executable
chmod +x deploy.sh

# Run deployment script
./deploy.sh
```

That's it! The script will guide you through the deployment process.

---

## 📋 What Gets Deployed

### Microservices Architecture:
1. **Django Web Application** (2 replicas)
   - Port: 8000
   - Handles all business logic
   - Serves dynamic content

2. **MySQL Database** (1 replica)
   - Port: 3306
   - Persistent storage
   - 10GB volume

3. **Nginx Reverse Proxy** (1 replica)
   - Port: 80
   - Load balancing
   - Static file serving

4. **Redis Cache** (1 replica) - Optional
   - Port: 6379
   - Session caching
   - Performance optimization

---

## ✅ Requirements Compliance

### 1. Frontend UI ✓
- Functional user interface
- Interactive course pages
- Dashboard with role-based views
- Responsive design with Tailwind CSS

### 2. 4+ Functionalities ✓
1. **User Authentication** - Register, login, role-based access
2. **Course Management** - Create, edit, delete courses
3. **Progress Tracking** - Track learner progress, certificates
4. **Social Features** - Likes, comments, sharing
5. **QR Code Generation** - For easy course access
6. **Certificate Generation** - Upon course completion

### 3. Backend Database ✓
- MySQL database with 7 models
- Proper relationships (ForeignKey, ManyToMany, OneToOne)
- Django ORM for database operations

### 4. Docker Containerization ✓
- Multiple containers:
  - Django application container
  - MySQL database container
  - Nginx proxy container
  - Redis cache container
- Microservices architecture
- Docker Compose for local development

### 5. Orchestration ✓
**Choose one:**
- **Docker Swarm** - Built-in Docker orchestration
- **Kubernetes** - Production-grade orchestration

**Features:**
- Multiple replicas for high availability
- Load balancing
- Health checks
- Auto-restart on failure
- Rolling updates
- Scalability

---

## 🔧 Manual Deployment Steps

If you prefer manual deployment:

### Docker Compose:
```bash
docker build -t elevatelearning-web:latest .
docker-compose up -d
```

### Docker Swarm:
```bash
docker swarm init
docker build -t elevatelearning-web:latest .
docker stack deploy -c docker-compose.yml elevatelearning
```

### Kubernetes:
```bash
# Install K3s
curl -sfL https://get.k3s.io | sh -

# Build and deploy
docker build -t elevatelearning-web:latest .
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/mysql-deployment.yaml
kubectl apply -f k8s/django-deployment.yaml
kubectl apply -f k8s/nginx-deployment.yaml
```

---

## 🌐 Access Your Application

After deployment:
- **Application:** http://35.244.96.92 (or your GCP IP)
- **Admin Panel:** http://35.244.96.92/elevatelearning/admin/
- **API Health:** http://35.244.96.92/health

Default admin credentials:
- Username: `admin`
- Password: `admin123`

---

## 📊 Monitoring

### View Logs:

**Docker Compose:**
```bash
docker-compose logs -f
```

**Docker Swarm:**
```bash
docker service logs -f elevatelearning_web
```

**Kubernetes:**
```bash
kubectl logs -f deployment/django-web -n elevatelearning
```

### Check Status:

**Docker Compose:**
```bash
docker-compose ps
```

**Docker Swarm:**
```bash
docker service ls
docker stack ps elevatelearning
```

**Kubernetes:**
```bash
kubectl get all -n elevatelearning
kubectl get pods -n elevatelearning
```

---

## 🔄 Scaling

### Docker Swarm:
```bash
docker service scale elevatelearning_web=3
```

### Kubernetes:
```bash
kubectl scale deployment django-web --replicas=3 -n elevatelearning
```

---

## 🛑 Stop/Remove

### Docker Compose:
```bash
docker-compose down
```

### Docker Swarm:
```bash
docker stack rm elevatelearning
```

### Kubernetes:
```bash
kubectl delete namespace elevatelearning
```

---

## 🆘 Troubleshooting

### Database connection issues:
```bash
# Check if MySQL is running
docker ps | grep mysql

# Check logs
docker logs elevatelearning_db
```

### Application not accessible:
```bash
# Check firewall
sudo ufw status
sudo ufw allow 80/tcp

# Check service status
docker-compose ps
```

### Clear everything and restart:
```bash
docker-compose down -v
docker system prune -a
./deploy.sh
```

---

## 📝 Next Steps

1. Change default passwords in `.env`
2. Update `SECRET_KEY` in production
3. Configure domain name
4. Set up HTTPS/SSL
5. Configure automated backups
6. Set up monitoring (Prometheus/Grafana)

---

For detailed documentation, see [DEPLOYMENT.md](DEPLOYMENT.md)
