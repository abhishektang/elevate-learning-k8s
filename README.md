# 🎓 Elevate Learning - Cloud-Native LMS on Kubernetes

[![Django](https://img.shields.io/badge/Django-5.1.7-green.svg)](https://www.djangoproject.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-K3s-blue.svg)](https://k3s.io/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-orange.svg)](https://www.mysql.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A production-ready Learning Management System (LMS) deployed on Kubernetes with comprehensive orchestration features including self-healing, auto-scaling, zero-downtime deployments, and load balancing.

## 🌟 Features

- **🔐 User Management**: Role-based access control (Admin, Educator, Learner)
- **📚 Course Management**: Create, update, archive courses with rich content
- **📊 Progress Tracking**: Automated learner progress monitoring
- **🎖️ Certificate Generation**: Automatic digital certificates on completion
- **📱 QR Code Integration**: Quick course access via mobile devices
- **💬 Social Learning**: Comments and interactions on courses
- **🔄 Zero-Downtime Deployments**: Rolling updates with Kubernetes
- **⚡ Auto-Scaling**: Dynamic scaling based on load
- **🛡️ Self-Healing**: Automatic pod recovery and health checks

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Load Balancer                        │
│                  (NodePort: 30080)                       │
└────────────────────────┬────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
   ┌────▼─────┐    ┌────▼─────┐    ┌────▼─────┐
   │  Nginx   │    │  Django  │    │  Django  │
   │  Proxy   │    │  Web-1   │    │  Web-2   │
   └──────────┘    └─────┬────┘    └─────┬────┘
                         │                │
                    ┌────▼────────────────▼────┐
                    │       MySQL 8.0          │
                    │    (Persistent Volume)    │
                    └──────────────────────────┘
```

### Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| **Framework** | Django | 5.1.7 |
| **Database** | MySQL | 8.0 |
| **Web Server** | Nginx | 1.29.3 |
| **Container Runtime** | containerd | 2.1.4 |
| **Orchestration** | K3s | v1.33.5 |
| **OS** | Ubuntu | 22.04 LTS |

## 📋 Prerequisites

- **3 Linux VMs** (1 master + 2 workers)
  - Master: 2 vCPU, 4GB RAM
  - Workers: 2 vCPU, 2GB RAM each
- **Ubuntu 22.04 LTS** or later
- **Static IP addresses** for external access
- **SSH access** to all nodes
- **Docker** (for image building)

## 🚀 Quick Start

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/abhishektang/elevate-learning-k8s.git
cd elevate-learning-k8s
```

### 2️⃣ Deploy K3s Cluster

**On Master Node:**
```bash
cd All_mds
chmod +x install-k3s-master.sh
sudo ./install-k3s-master.sh
```

**On Each Worker Node:**
```bash
# Copy token from master: sudo cat /var/lib/rancher/k3s/server/node-token
chmod +x install-k3s-worker.sh
# Edit script with your master IP and token
sudo ./install-k3s-worker.sh
```

### 3️⃣ Build and Deploy Application

```bash
# Build Docker image
cd elevatelearning
docker build -t elevatelearning-web:latest .

# Import to K3s
sudo k3s ctr images import elevatelearning-web.tar

# Deploy to Kubernetes
cd k8s
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f mysql-deployment.yaml
kubectl apply -f django-deployment.yaml
kubectl apply -f nginx-deployment.yaml
```

### 4️⃣ Access the Application

```
http://<MASTER_IP>:30080/elevatelearning/home/
```

**Default Admin Credentials:**
- Username: `admin`
- Password: `admin123`

## 🧪 Orchestration Tests

Run comprehensive tests to verify Kubernetes orchestration features:

```bash
chmod +x run-orchestration-tests.sh
./run-orchestration-tests.sh
```

**Tests Included:**
- ✅ **Self-Healing**: Automatic pod recovery
- ✅ **Load Balancing**: Traffic distribution across pods
- ✅ **Auto-Scaling**: Dynamic replica management (3→5→3)
- ✅ **Rolling Updates**: Zero-downtime deployments
- ✅ **Rollback**: Instant recovery to previous versions

Expected output: **5/5 tests passed** ✨

## 📁 Project Structure

```
elevate-learning-k8s/
├── elevatelearning/              # Django application
│   ├── elevatelearning/          # Project settings
│   ├── elevatelearningapp/       # Main app (views, models, URLs)
│   ├── templates/                # HTML templates
│   ├── k8s/                      # Kubernetes manifests
│   │   ├── namespace.yaml
│   │   ├── configmap.yaml
│   │   ├── mysql-deployment.yaml
│   │   ├── django-deployment.yaml
│   │   └── nginx-deployment.yaml
│   ├── Dockerfile                # Container image definition
│   ├── requirements.txt          # Python dependencies
│   ├── entrypoint.sh            # Container startup script
│   └── nginx.conf               # Nginx reverse proxy config
├── All_mds/                      # Documentation & scripts
│   ├── install-k3s-master.sh    # Master node setup
│   ├── install-k3s-worker.sh    # Worker node setup
│   ├── deploy-to-k8s.sh         # Deployment automation
│   ├── K3S_SETUP_GUIDE.md       # Cluster setup guide
│   ├── DEPLOYMENT.md            # Deployment instructions
│   ├── ARCHITECTURE.md          # Architecture documentation
│   └── PROJECT_PROPOSAL.md      # Project overview
├── run-orchestration-tests.sh   # Automated test suite
├── ORCHESTRATION_TEST_SCRIPT_README.md
├── QUICK_START_TESTS.md
├── .gitignore                   # Git ignore rules
└── README.md                    # This file
```

## 🔧 Configuration

### Environment Variables (ConfigMap)

Key configurations in `k8s/configmap.yaml`:

```yaml
CSRF_TRUSTED_ORIGINS: "http://<YOUR_IP>:30080"
ALLOWED_HOSTS: "*"
DB_HOST: "mysql-service"
DB_NAME: "elevatelearning_db"
DB_USER: "djangouser"
DEBUG: "False"
```

### Kubernetes Resources

| Resource | Replicas | CPU | Memory |
|----------|----------|-----|--------|
| Django | 3 | 250m-500m | 512Mi-1Gi |
| MySQL | 1 | - | 2Gi |
| Nginx | 1 | - | 256Mi |

## 🔐 Security

- ✅ **CSRF Protection**: Token-based form validation
- ✅ **Secret Management**: Kubernetes secrets for sensitive data
- ✅ **Role-Based Access**: Admin, Educator, Learner roles
- ✅ **Network Policies**: Pod-to-pod communication restrictions
- ✅ **Security Headers**: X-Frame-Options, CSP, HSTS

**⚠️ Important:** Never commit:
- SSH private keys
- Database passwords
- Django SECRET_KEY
- `.env` files

All sensitive files are excluded via `.gitignore`.

## 📊 Monitoring & Health

**Health Check Endpoints:**
- Liveness Probe: `/elevatelearning/home/`
- Readiness Probe: `/elevatelearning/home/`

**Check Cluster Status:**
```bash
kubectl get nodes -o wide
kubectl get pods -n elevatelearning -o wide
kubectl get services -n elevatelearning
```

## 🌐 Multi-Cloud Deployment

This project is **cloud-agnostic** and can be deployed on:

- ✅ **GCP** - Compute Engine VMs
- ✅ **AWS** - EC2 instances with EKS or K3s
- ✅ **Azure** - Azure VMs with AKS or K3s
- ✅ **On-Premises** - Any Linux infrastructure

See documentation for migration guides.

## 📚 Documentation

- [📖 K3s Setup Guide](All_mds/K3S_SETUP_GUIDE.md) - Complete cluster setup
- [🚀 Deployment Instructions](All_mds/DEPLOYMENT.md) - Step-by-step deployment
- [🏛️ Architecture Overview](All_mds/ARCHITECTURE.md) - System design
- [✅ Requirements Verification](All_mds/REQUIREMENTS_VERIFICATION.md) - Feature checklist
- [🔄 Orchestration Tests](All_mds/ORCHESTRATION_TESTS.md) - Testing documentation
- [📸 Screenshot Guide](All_mds/SCREENSHOT_GUIDE.md) - Documentation capture

## 🤝 Contributing

This is an academic project, but suggestions are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

##  Support

For issues or questions:
1. Check the [documentation](All_mds/)
2. Review [troubleshooting guides](All_mds/K3S_SETUP_GUIDE.md#troubleshooting)
3. Open an issue on GitHub

---

⭐ **Star this repo if you find it helpful!** ⭐

Built with ❤️ using Django, Kubernetes, and Cloud Native technologies.
