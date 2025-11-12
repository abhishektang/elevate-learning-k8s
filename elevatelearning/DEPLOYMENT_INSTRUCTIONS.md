# Complete Deployment Instructions for Elevate Learning on GCP

**Project:** Django Learning Management System with Kubernetes Orchestration  
**Author:** Abhishek Tanguturi (s4845110)  
**Date:** October 24, 2025  
**Estimated Time:** 60-90 minutes

---

##  Table of Contents

1. [Prerequisites](#prerequisites)
2. [GCP Setup](#gcp-setup)
3. [VM Creation](#vm-creation)
4. [Master Node Setup](#master-node-setup)
5. [Worker Nodes Setup](#worker-nodes-setup)
6. [Application Deployment](#application-deployment)
7. [Verification](#verification)
8. [Optional: Static IPs](#optional-static-ips)

---

## 1. PREREQUISITES

### Required Tools on Your Local Machine:

**For macOS:**
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install --cask google-cloud-sdk
```

**For Windows:**
```powershell
# Download and install:
# - Google Cloud SDK: https://cloud.google.com/sdk/docs/install
```

**For Linux:**
```bash
# Install gcloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

```

### GCP Account Setup:

1. **Create GCP Account**: https://console.cloud.google.com
2. **Create Project**: 
   - Go to https://console.cloud.google.com/projectcreate
   - Project Name: `elevatelearning` (or your choice)
   - Note your Project ID

---

## 2. GCP SETUP

### 2.1 Initialize gcloud on Your Local Machine

```bash
# Login to GCP
gcloud auth login

# Set your project (replace PROJECT_ID with your actual project ID)
gcloud config set project PROJECT_ID

# Set default region and zone
gcloud config set compute/region australia-southeast1
gcloud config set compute/zone australia-southeast1-b

# Verify configuration
gcloud config list
```

### 2.2 Enable Required APIs

```bash
# Enable Compute Engine API
gcloud services enable compute.googleapis.com

# Verify API is enabled
gcloud services list --enabled | grep compute
```

### 2.3 Create SSH Key Pair

```bash
# Create directory for keys
mkdir -p ~/mykeys
cd ~/mykeys

# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f remote-server-myproject -C "your-email@example.com/GCP USER ID" -N ""

# This creates two files:
# - remote-server-myproject (private key)
# - remote-server-myproject.pub (public key)

# View public key (you'll need this later)
cat remote-server-myproject.pub
```

---

## 3. VM CREATION

### 3.1 Create Master Node

```bash
# Create master VM
gcloud compute instances create master \
  --zone=australia-southeast1-b \
  --machine-type=e2-medium \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=20GB \
  --boot-disk-type=pd-standard \
  --metadata=ssh-keys="t_abhishek345:$(cat ~/mykeys/remote-server-myproject.pub)" \-----> this is the key from the remote-server-myproject.pub file
  --tags=k8s-master,http-server,https-server

# Note: Replace 't_abhishek345' with your desired username
```

### 3.2 Create Worker Node 1

```bash
# Create worker-1 VM
gcloud compute instances create worker-1 \
  --zone=australia-southeast1-b \
  --machine-type=e2-medium \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=20GB \
  --boot-disk-type=pd-standard \
  --metadata=ssh-keys="t_abhishek345:$(cat ~/mykeys/remote-server-myproject.pub)" \-----> this is the key from the remote-server-myproject.pub file
  --tags=k8s-worker
```

### 3.3 Create Worker Node 2

```bash
# Create worker-2 VM
gcloud compute instances create worker-2 \
  --zone=australia-southeast1-b \
  --machine-type=e2-medium \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=20GB \
  --boot-disk-type=pd-standard \
  --metadata=ssh-keys="t_abhishek345:$(cat ~/mykeys/remote-server-myproject.pub)" \-----> this is the key from the remote-server-myproject.pub file
  --tags=k8s-worker
```

### 3.4 Create Firewall Rules

```bash
# Allow NodePort access (30000-32767)
gcloud compute firewall-rules create k8s-nodeport \
  --allow tcp:30000-32767 \
  --source-ranges 0.0.0.0/0 \
  --target-tags k8s-master,k8s-worker \
  --description "Allow NodePort access for Kubernetes services"

# Allow internal cluster communication
gcloud compute firewall-rules create k8s-internal \
  --allow tcp:0-65535,udp:0-65535,icmp \
  --source-ranges 10.0.0.0/8 \
  --target-tags k8s-master,k8s-worker \
  --description "Allow internal Kubernetes cluster communication"

# Allow K3s API server
gcloud compute firewall-rules create k8s-api \
  --allow tcp:6443 \
  --source-ranges 0.0.0.0/0 \
  --target-tags k8s-master \
  --description "Allow Kubernetes API server access"
```

### 3.5 Get VM External IPs

```bash
# List all instances with their IPs
gcloud compute instances list

# Save these IPs - you'll need them:
# - master: MASTER_IP
# - worker-1: WORKER1_IP
# - worker-2: WORKER2_IP
```

---

## 4. MASTER NODE SETUP

### 4.1 SSH to Master Node

```bash
# SSH to master (replace MASTER_IP with actual IP)
ssh -i ~/mykeys/remote-server-myproject USERNAME@MASTER_IP

# You should now be logged into the master node
```

### 4.2 Update System and Install Docker

```bash
# Update package lists
sudo apt-get update -y

# Install Docker
sudo apt-get install -y docker.io

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER

# Verify Docker installation
docker --version
```

### 4.3 Install K3s Master

```bash
# Install K3s server (master node)
curl -sfL https://get.k3s.io | sh -s - server \
  --write-kubeconfig-mode 644 \
  --disable traefik \
  --node-name master \
  --flannel-backend=vxlan

# Wait for K3s to be ready (30-60 seconds)
sleep 60

# Verify K3s is running
sudo systemctl status k3s

# Verify node is ready
kubectl get nodes

# Should show:
# NAME     STATUS   ROLES                  AGE   VERSION
# master   Ready    control-plane,master   1m    v1.33.5+k3s1
```

### 4.4 Get K3s Token (IMPORTANT - Save This!)

```bash
# Get the K3s token - you'll need this for worker nodes
sudo cat /var/lib/rancher/k3s/server/node-token

# Example output:
# K10e4c47a233da4a967a2cf8f7f45508db6932982dea8ad749ec686d1a93c5b18ee::server:00355c79f8fd65145263437fdad8af59

# SAVE THIS TOKEN - you'll use it on worker nodes
```

### 4.5 Get Master Internal IP

```bash
# Get master internal IP
hostname -I | awk '{print $1}'

# Example: 10.152.0.4
# SAVE THIS IP
```

### 4.6 Add Master Node Taint (Best Practice)

```bash
# Prevent application pods from running on master
kubectl taint nodes master node-role.kubernetes.io/control-plane:NoSchedule

# Verify taint
kubectl describe node master | grep Taints
# Should show: Taints: node-role.kubernetes.io/control-plane:NoSchedule
```

### 4.7 Exit Master Node

```bash
# Exit SSH session
exit
```

---

## 5. WORKER NODES SETUP

### 5.1 Setup Worker-1

```bash
# SSH to worker-1 (replace WORKER1_IP)
ssh -i ~/mykeys/remote-server-myproject USERNAME@WORKER1_IP

# Update system
sudo apt-get update -y

# Install Docker
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Verify Docker
docker --version

# Install K3s agent (replace MASTER_IP and K3S_TOKEN with actual values)
curl -sfL https://get.k3s.io | K3S_URL=https://MASTER_IP:6443 \
  K3S_TOKEN=YOUR_K3S_TOKEN_HERE \
  sh -

# Wait for agent to start (30 seconds)
sleep 30

# Verify K3s agent is running
sudo systemctl status k3s-agent

# Exit worker-1
exit
```

### 5.2 Setup Worker-2

```bash
# SSH to worker-2 (replace WORKER2_IP)
ssh -i ~/mykeys/remote-server-myproject USERNAME@WORKER2_IP

# Update system
sudo apt-get update -y

# Install Docker
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Verify Docker
docker --version

# Install K3s agent (replace MASTER_IP and K3S_TOKEN)
curl -sfL https://get.k3s.io | K3S_URL=https://MASTER_IP:6443 \
  K3S_TOKEN=YOUR_K3S_TOKEN_HERE \
  sh -

# Wait for agent to start
sleep 30

# Verify K3s agent is running
sudo systemctl status k3s-agent

# Exit worker-2
exit
```

### 5.3 Verify Cluster (From Master)

```bash
# SSH back to master
ssh -i ~/mykeys/remote-server-myproject USERNAME@MASTER_IP

# Check all nodes
kubectl get nodes -o wide

# Should show all 3 nodes Ready:
# NAME       STATUS   ROLES                  AGE   VERSION
# master     Ready    control-plane,master   10m   v1.33.5+k3s1
# worker-1   Ready    <none>                 5m    v1.33.5+k3s1
# worker-2   Ready    <none>                 5m    v1.33.5+k3s1
```

---

## 6. APPLICATION DEPLOYMENT

### 6.1 Upload Project Files to Master Node

**IMPORTANT:** This project includes all necessary files:
- Django application code (Python files, models, views, templates)
- Docker configuration (`Dockerfile`, `requirements.txt`, `entrypoint.sh`)
- Kubernetes manifests (`k8s/*.yaml` files)
- Configuration files (`nginx.conf`, `settings.py`, etc.)

**Option A: Upload from Your Local Machine (Recommended)**

```bash
# From your LOCAL machine, navigate to project directory
cd /path/to/your/project/elevatelearning

# Create a tar archive of the project (excluding unnecessary files)
tar -czf elevatelearning.tar.gz \
  --exclude='*.pyc' \
  --exclude='__pycache__' \
  --exclude='*.sqlite3' \
  --exclude='.git' \
  --exclude='*.tar.gz' \
  --exclude='mykeys' \
  --exclude='*.md' \
  .

# Upload to master node (replace MASTER_IP with your master node IP)
scp -i ~/mykeys/remote-server-myproject elevatelearning.tar.gz USERNAME@MASTER_IP:~/

# SSH to master node
ssh -i ~/mykeys/remote-server-myproject USERNAME@MASTER_IP

# Extract the project
cd ~
tar -xzf elevatelearning.tar.gz -C elevatelearning/
cd elevatelearning

# Verify files are present
ls -la
# Should see: Dockerfile, requirements.txt, entrypoint.sh, manage.py, k8s/, etc.
```


**Option B: Use SCP to Transfer Individual Directories**

```bash
# From your LOCAL machine
# Upload entire project directory
scp -i ~/mykeys/remote-server-myproject -r \
  /path/to/your/elevatelearning \
  USERNAME@MASTER_IP:~/
```

### 6.2 Verify Project Structure

```bash
# On master node, verify all required files exist
cd ~/elevatelearning

# Check main files
ls -l Dockerfile requirements.txt entrypoint.sh manage.py

# Check Django app directory
ls -l elevatelearning/
ls -l elevatelearningapp/

# Check Kubernetes manifests
ls -l k8s/

# Expected output should show:
# - Dockerfile
# - requirements.txt
# - entrypoint.sh
# - manage.py
# - k8s/namespace.yaml
# - k8s/configmap.yaml
# - k8s/secret.yaml
# - k8s/mysql-deployment.yaml
# - k8s/django-deployment.yaml
# - k8s/nginx-deployment.yaml
```

### 6.3 Update ConfigMap with Master IP

```bash
# Still on master node, get external IP
MASTER_EXTERNAL_IP=$(curl -s ifconfig.me)
echo "Master IP: $MASTER_EXTERNAL_IP"

# Update the ConfigMap file with your actual IP
cd ~/elevatelearning/k8s
sed -i "s|CSRF_TRUSTED_ORIGINS:.*|CSRF_TRUSTED_ORIGINS: \"http://${MASTER_EXTERNAL_IP}\"|g" configmap.yaml

# Verify the change
grep CSRF_TRUSTED_ORIGINS configmap.yaml
```

### 6.4 Build Docker Image

```bash
# Navigate to project root (where Dockerfile is located)
cd ~/elevatelearning

# Make entrypoint.sh executable (if not already)
chmod +x entrypoint.sh

# Build the Docker image (this will take 5-10 minutes)
docker build -t elevatelearning-web:latest .

# You should see output like:
# Step 1/X : FROM python:3.12-slim
# Step 2/X : ENV PYTHONDONTWRITEBYTECODE=1
# ...
# Successfully built [image_id]
# Successfully tagged elevatelearning-web:latest

# Verify image was created
docker images | grep elevatelearning

# Expected output:
# REPOSITORY              TAG       IMAGE ID       CREATED          SIZE
# elevatelearning-web     latest    xxxxxxxxxxxx   2 minutes ago    ~500MB
```

### 6.5 Import Image to K3s (Master)

```bash
# Import image to K3s containerd on master node
docker save elevatelearning-web:latest | sudo k3s ctr images import -

# Wait for import to complete
sleep 10

# Verify import was successful
sudo k3s ctr images ls | grep elevatelearning

# Expected output:
# docker.io/library/elevatelearning-web:latest    application/vnd.docker.distribution.manifest.v2+json    sha256:xxxxx    XXX.X MiB
```

### 6.6 Import Image to Worker-1

```bash
# Save Docker image to tar file
docker save elevatelearning-web:latest -o elevatelearning-web.tar

# Verify tar file was created
ls -lh elevatelearning-web.tar
# Should show file size around 400-500 MB

# Transfer to worker-1 (open NEW TERMINAL on your LOCAL machine)
scp -i ~/mykeys/remote-server-myproject \
  elevatelearning-web.tar \
 USERNAME@WORKER1_IP:~/

# SSH to worker-1
ssh -i ~/mykeys/remote-server-myproject USERNAME@WORKER1_IP

# Import image to K3s on worker-1
sudo k3s ctr images import elevatelearning-web.tar

# Wait for import
sleep 10

# Verify import
sudo k3s ctr images ls | grep elevatelearning

# Clean up tar file (optional)
rm elevatelearning-web.tar

# Exit worker-1
exit
```

### 6.7 Import Image to Worker-2

```bash
# From your LOCAL machine, transfer tar file to worker-2
scp -i ~/mykeys/remote-server-myproject \
  elevatelearning-web.tar \
  USERNAME@WORKER2_IP:~/

# SSH to worker-2
ssh -i ~/mykeys/remote-server-myproject USERNAME@WORKER2_IP

# Import image to K3s on worker-2
sudo k3s ctr images import elevatelearning-web.tar

# Wait for import
sleep 10

# Verify import
sudo k3s ctr images ls | grep elevatelearning

# Clean up tar file (optional)
rm elevatelearning-web.tar

# Exit worker-2
exit
```

### 6.8 Verify Kubernetes Manifests (On Master)

```bash
# SSH back to master node
ssh -i ~/mykeys/remote-server-myproject USERNAME@MASTER_IP

# Navigate to k8s directory
cd ~/elevatelearning/k8s

# List all manifest files
ls -la

# Expected files:
# - namespace.yaml
# - configmap.yaml
# - secret.yaml
# - mysql-deployment.yaml
# - django-deployment.yaml
# - nginx-deployment.yaml

# Verify ConfigMap has correct IP
cat configmap.yaml | grep CSRF_TRUSTED_ORIGINS

# Should show your master's external IP:
# CSRF_TRUSTED_ORIGINS: "http://YOUR_MASTER_IP"
```

### 6.9 Deploy Application

```bash
# Ensure you're in the k8s directory on master node
cd ~/elevatelearning/k8s

# Apply manifests in order (dependencies first)
echo "Creating namespace..."
kubectl apply -f namespace.yaml

echo "Creating ConfigMap and Secret..."
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

echo "Deploying MySQL..."
kubectl apply -f mysql-deployment.yaml

# Wait for MySQL to be ready (2-3 minutes)
echo "Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n elevatelearning --timeout=300s

# Check MySQL status
kubectl get pods -n elevatelearning | grep mysql

echo "Deploying Django application..."
kubectl apply -f django-deployment.yaml

# Wait for Django to be ready (2-3 minutes)
echo "Waiting for Django pods to be ready..."
kubectl wait --for=condition=ready pod -l app=django-web -n elevatelearning --timeout=300s

# Check Django status
kubectl get pods -n elevatelearning | grep django

echo "Deploying Nginx..."
kubectl apply -f nginx-deployment.yaml

# Wait for Nginx to be ready (1 minute)
echo "Waiting for Nginx to be ready..."
kubectl wait --for=condition=ready pod -l app=nginx -n elevatelearning --timeout=120s

echo ""
echo "=== DEPLOYMENT COMPLETE ==="
echo "Checking all resources..."
kubectl get all -n elevatelearning
```


## 7. VERIFICATION

### 7.1 Check All Resources

```bash
# Check all pods
kubectl get pods -n elevatelearning -o wide

# Should show:
# NAME                          READY   STATUS    RESTARTS   AGE
# django-web-xxx-xxxxx          1/1     Running   0          5m
# django-web-xxx-xxxxx          1/1     Running   0          5m
# django-web-xxx-xxxxx          1/1     Running   0          5m
# mysql-xxx-xxxxx               1/1     Running   0          8m
# nginx-xxx-xxxxx               1/1     Running   0          3m

# Check services
kubectl get svc -n elevatelearning

# Check deployments
kubectl get deployments -n elevatelearning
```

### 7.2 Test Website Internally

```bash
# Test from master node
curl -I http://localhost:30080/elevatelearning/home/

# Should return: HTTP/1.1 200 OK
```

### 7.3 Test Website Externally

```bash
# Get master external IP
curl ifconfig.me

# From your local machine browser, visit:
# http://MASTER_EXTERNAL_IP:30080/elevatelearning/home/

# Admin panel:
# http://MASTER_EXTERNAL_IP:30080/admin/
# Username: admin
# Password: admin123
```

### 7.4 Check Logs (If Issues)

```bash
# Django logs
kubectl logs -l app=django-web -n elevatelearning --tail=50

# MySQL logs
kubectl logs -l app=mysql -n elevatelearning --tail=50

# Nginx logs
kubectl logs -l app=nginx -n elevatelearning --tail=50

# Check events
kubectl get events -n elevatelearning --sort-by='.lastTimestamp'
```

---

## 8. OPTIONAL: STATIC IPS

### 8.1 Reserve Static IP Addresses

**From your LOCAL machine:**

```bash
# Reserve static IP for master
gcloud compute addresses create master-static-ip \
  --region=australia-southeast1

# Reserve static IP for worker-1
gcloud compute addresses create worker1-static-ip \
  --region=australia-southeast1

# Reserve static IP for worker-2
gcloud compute addresses create worker2-static-ip \
  --region=australia-southeast1

# List reserved IPs
gcloud compute addresses list
```

### 8.2 Assign Static IPs to Instances

```bash
# Stop instances first
gcloud compute instances stop master worker-1 worker-2 --zone=australia-southeast1-b

# Get reserved IP addresses
MASTER_STATIC_IP=$(gcloud compute addresses describe master-static-ip --region=australia-southeast1 --format="get(address)")
WORKER1_STATIC_IP=$(gcloud compute addresses describe worker1-static-ip --region=australia-southeast1 --format="get(address)")
WORKER2_STATIC_IP=$(gcloud compute addresses describe worker2-static-ip --region=australia-southeast1 --format="get(address)")

# Assign static IPs
gcloud compute instances delete-access-config master --zone=australia-southeast1-b
gcloud compute instances add-access-config master --zone=australia-southeast1-b --address=$MASTER_STATIC_IP

gcloud compute instances delete-access-config worker-1 --zone=australia-southeast1-b
gcloud compute instances add-access-config worker-1 --zone=australia-southeast1-b --address=$WORKER1_STATIC_IP

gcloud compute instances delete-access-config worker-2 --zone=australia-southeast1-b
gcloud compute instances add-access-config worker-2 --zone=australia-southeast1-b --address=$WORKER2_STATIC_IP

# Start instances
gcloud compute instances start master worker-1 worker-2 --zone=australia-southeast1-b

# Wait 3-4 minutes for cluster to come back online
sleep 240

# Verify
gcloud compute instances list
```

### 8.3 Update ConfigMap with New Static IP

```bash
# SSH to master (use new static IP)
ssh -i ~/mykeys/remote-server-myproject t_abhishek345@$MASTER_STATIC_IP

# Update ConfigMap
kubectl edit configmap elevatelearning-config -n elevatelearning

# Change CSRF_TRUSTED_ORIGINS to new static IP
# Save and exit (ESC + :wq)

# Restart Django pods
kubectl rollout restart deployment django-web -n elevatelearning

# Wait for rollout
kubectl rollout status deployment django-web -n elevatelearning
```

---

## 9. TROUBLESHOOTING

### Issue: Pods Stuck in Pending

```bash
# Check pod events
kubectl describe pod POD_NAME -n elevatelearning

# Common causes:
# 1. Insufficient resources: Scale down replicas
kubectl scale deployment django-web --replicas=2 -n elevatelearning

# 2. Image not found: Re-import image to that node
```

### Issue: Pods Stuck in ImagePullBackOff

```bash
# Check which node the pod is on
kubectl get pods -n elevatelearning -o wide

# SSH to that node and import image
ssh -i ~/mykeys/remote-server-myproject t_abhishek345@NODE_IP
docker save elevatelearning-web:latest | sudo k3s ctr images import -
```

### Issue: Website Returns 502 Bad Gateway

```bash
# Check Django pods are running
kubectl get pods -n elevatelearning | grep django

# Check Django logs
kubectl logs -l app=django-web -n elevatelearning --tail=100

# Usually means Django isn't ready yet - wait 2-3 minutes
```

### Issue: Website Returns CSRF Error

```bash
# Update ConfigMap with correct IP
kubectl edit configmap elevatelearning-config -n elevatelearning

# Set CSRF_TRUSTED_ORIGINS to your actual external IP
# Example: "http://34.87.248.125"

# Restart Django
kubectl rollout restart deployment django-web -n elevatelearning
```

### Issue: MySQL Connection Refused

```bash
# Check MySQL is running
kubectl get pods -n elevatelearning | grep mysql

# Check MySQL logs
kubectl logs -l app=mysql -n elevatelearning --tail=100

# If not ready, wait 2-3 minutes for initialization
```

### Issue: K3s Service Not Starting

```bash
# Check K3s logs
sudo journalctl -u k3s -n 100

# Common issue: Port 6444 in use
sudo ss -tlnp | grep 6444
sudo kill -9 PID  # Kill conflicting process
sudo systemctl restart k3s
```

### Issue: Worker Not Joining Cluster

```bash
# On worker node, check k3s-agent logs
sudo journalctl -u k3s-agent -n 100

# Verify token is correct
# Verify master IP is correct
# Re-run K3s agent installation with correct values
```

---

## 10. USEFUL COMMANDS

### Cluster Management

```bash
# View all nodes
kubectl get nodes -o wide

# View all pods in namespace
kubectl get pods -n elevatelearning -o wide

# View all services
kubectl get svc -n elevatelearning

# View all resources
kubectl get all -n elevatelearning

# Describe a resource
kubectl describe pod POD_NAME -n elevatelearning
```

### Scaling

```bash
# Scale Django deployment
kubectl scale deployment django-web --replicas=5 -n elevatelearning

# Check scaling progress
kubectl get pods -n elevatelearning -w
```

### Rolling Updates

```bash
# Update environment variable
kubectl set env deployment/django-web -n elevatelearning APP_VERSION=v2.0

# Check rollout status
kubectl rollout status deployment/django-web -n elevatelearning

# View rollout history
kubectl rollout history deployment/django-web -n elevatelearning

# Rollback
kubectl rollout undo deployment/django-web -n elevatelearning
```

### Logs

```bash
# View logs
kubectl logs POD_NAME -n elevatelearning

# Follow logs
kubectl logs -f POD_NAME -n elevatelearning

# View logs from all pods with label
kubectl logs -l app=django-web -n elevatelearning --tail=50
```

### Exec into Pod

```bash
# Open shell in pod
kubectl exec -it POD_NAME -n elevatelearning -- bash

# Run command in pod
kubectl exec POD_NAME -n elevatelearning -- python manage.py migrate
```

### Cleanup

```bash
# Delete entire namespace (removes all resources)
kubectl delete namespace elevatelearning

# Delete specific deployment
kubectl delete deployment django-web -n elevatelearning

# Delete all resources in namespace
kubectl delete all --all -n elevatelearning
```

---

## 11. STOP/START INSTANCES

### Stop Instances (Save Costs)

```bash
# From local machine
gcloud compute instances stop master worker-1 worker-2 --zone=australia-southeast1-b

# Cost when stopped (with static IPs): ~$11/month
# Cost when stopped (without static IPs): $0/month (but IPs change)
```

### Start Instances

```bash
# From local machine
gcloud compute instances start master worker-1 worker-2 --zone=australia-southeast1-b

# Wait 3-4 minutes for cluster to initialize
sleep 240

# Test website (replace with your IP)
curl -I http://MASTER_IP:30080/elevatelearning/home/
```
---
 
**Author:** Abhishek Tanguturi (s4845110)  


In this assessment, I used ChatGPT to assist me for understanding the concept
of container orchestration and project trouble shooting(debuging code).

I critically reviewed and edited all AI-generated content to ensure it reflects 
my own understanding and perspective.

I have applied the GenAI and MT Usage Framework to ensure my use of these tools 
supports my learning objectives and adheres to academic integrity standards.