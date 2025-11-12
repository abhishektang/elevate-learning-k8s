# Kubernetes (K3s) Cluster Setup Guide
## 3-Node Cluster Deployment for Elevate Learning

---

## 📋 Prerequisites

### Required Resources:
- **3 GCP VM Instances** (or any cloud provider)
  - 1 Master Node (Control Plane) - your existing: 35.244.96.92
  - 2 Worker Nodes (new instances needed)
  
### VM Specifications (Each):
- **OS**: Ubuntu 20.04 LTS or newer
- **CPU**: 2 vCPUs (e2-standard-2)
- **RAM**: 4-8 GB
- **Storage**: 20 GB
- **Network**: All nodes must be able to communicate with each other

---

## 🚀 Step 1: Create Worker Nodes in GCP

### Option A: Using GCP Console
1. Go to **Compute Engine** → **VM Instances**
2. Click **"Create Instance"**
3. Configure:
   - Name: `elevatelearning-worker-1`
   - Region: Same as master (e.g., `australia-southeast1`)
   - Machine type: `e2-standard-2`
   - Boot disk: Ubuntu 20.04 LTS, 20 GB
   - Firewall: Allow HTTP, HTTPS
4. Repeat for `elevatelearning-worker-2`

### Option B: Using gcloud CLI
```bash
# Create Worker 1
gcloud compute instances create elevatelearning-worker-1 \
  --zone=australia-southeast1-a \
  --machine-type=e2-standard-2 \
  --image-family=ubuntu-2004-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=20GB \
  --tags=http-server,https-server

# Create Worker 2
gcloud compute instances create elevatelearning-worker-2 \
  --zone=australia-southeast1-a \
  --machine-type=e2-standard-2 \
  --image-family=ubuntu-2004-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=20GB \
  --tags=http-server,https-server
```

### Configure SSH Access
```bash
# Copy your SSH key to worker nodes
gcloud compute config-ssh

# Or manually copy your key
ssh-copy-id -i ~/.ssh/remote-server-myproject.pub t_abhishek345@WORKER_1_IP
ssh-copy-id -i ~/.ssh/remote-server-myproject.pub t_abhishek345@WORKER_2_IP
```

---

## 🎯 Step 2: Install K3s on Master Node

### On Master Node (35.244.96.92):

```bash
# SSH into master
ssh -i ../mykeys/remote-server-myproject t_abhishek345@35.244.96.92

# Stop existing Docker Compose deployment
cd ~/elevatelearning
sg docker -c 'docker-compose down'

# Install K3s (master node)
curl -sfL https://get.k3s.io | sh -s - server \
  --write-kubeconfig-mode 644 \
  --disable traefik \
  --node-name master

# Wait for K3s to be ready
sudo systemctl status k3s

# Get node token (you'll need this for worker nodes)
sudo cat /var/lib/rancher/k3s/server/node-token

# Save this token! It looks like:
# K10abc123def456ghi789jkl012mno345pqr678stu901vwx234yz::server:abc123def456ghi789
```

### Verify Master Installation:
```bash
sudo kubectl get nodes
# Should show: master   Ready   control-plane,master   1m   v1.28.x+k3s1
```

---

## 🔗 Step 3: Join Worker Nodes to Cluster

### On Worker Node 1:

```bash
# SSH into worker 1
ssh -i ../mykeys/remote-server-myproject t_abhishek345@WORKER_1_IP

# Install K3s agent (replace TOKEN and MASTER_IP)
curl -sfL https://get.k3s.io | K3S_URL=https://35.244.96.92:6443 \
  K3S_TOKEN=YOUR_TOKEN_FROM_MASTER \
  sh -s - agent --node-name worker-1

# Check status
sudo systemctl status k3s-agent
```

### On Worker Node 2:

```bash
# SSH into worker 2
ssh -i ../mykeys/remote-server-myproject t_abhishek345@WORKER_2_IP

# Install K3s agent
curl -sfL https://get.k3s.io | K3S_URL=https://35.244.96.92:6443 \
  K3S_TOKEN=YOUR_TOKEN_FROM_MASTER \
  sh -s - agent --node-name worker-2

# Check status
sudo systemctl status k3s-agent
```

### Verify Cluster (on Master):
```bash
sudo kubectl get nodes

# Expected output:
# NAME       STATUS   ROLES                  AGE   VERSION
# master     Ready    control-plane,master   5m    v1.28.x+k3s1
# worker-1   Ready    <none>                 2m    v1.28.x+k3s1
# worker-2   Ready    <none>                 1m    v1.28.x+k3s1
```

---

## 📦 Step 4: Prepare Docker Image for K8s

### On Master Node:

```bash
cd ~/elevatelearning

# Build and tag image
sudo docker build -t elevatelearning-web:latest .

# Save image to tar file
sudo docker save elevatelearning-web:latest -o elevatelearning-web.tar

# Copy image to worker nodes
scp elevatelearning-web.tar t_abhishek345@WORKER_1_IP:~/
scp elevatelearning-web.tar t_abhishek345@WORKER_2_IP:~/
```

### On Worker 1 and Worker 2:

```bash
# Load Docker image
sudo ctr images import elevatelearning-web.tar

# Verify
sudo ctr images ls | grep elevatelearning
```

---

## 🚀 Step 5: Deploy Application to K8s

### On Master Node:

```bash
cd ~/elevatelearning/k8s

# Create namespace
sudo kubectl apply -f namespace.yaml

# Create ConfigMap and Secrets
sudo kubectl apply -f configmap.yaml

# Deploy MySQL (database)
sudo kubectl apply -f mysql-deployment.yaml

# Wait for MySQL to be ready
sudo kubectl wait --for=condition=ready pod -l app=mysql -n elevatelearning --timeout=300s

# Deploy Django application
sudo kubectl apply -f django-deployment.yaml

# Deploy Nginx (load balancer)
sudo kubectl apply -f nginx-deployment.yaml

# Check all pods
sudo kubectl get pods -n elevatelearning -o wide

# Check services
sudo kubectl get svc -n elevatelearning
```

---

## ✅ Step 6: Verify Deployment

### Check Pod Distribution:
```bash
sudo kubectl get pods -n elevatelearning -o wide

# You should see Django pods distributed across worker-1 and worker-2
# Example:
# NAME                      NODE       STATUS
# django-xxx-abc           worker-1   Running
# django-xxx-def           worker-2   Running
# mysql-xxx-ghi            master     Running
# nginx-xxx-jkl            worker-1   Running
```

### Check Services:
```bash
sudo kubectl get svc -n elevatelearning

# Get the NodePort for nginx-service
# Example: nginx-service   LoadBalancer   10.43.x.x   <pending>   80:30080/TCP
```

### Test Application:
```bash
# Test from master node
curl http://localhost:30080/elevatelearning/home/

# Test from external
# http://35.244.96.92:30080/elevatelearning/home/
```

---

## 🎯 Step 7: Demonstrate Orchestration Features

### View Cluster Status:
```bash
sudo kubectl get nodes
sudo kubectl get pods -n elevatelearning -o wide
sudo kubectl top nodes
```

### Scale Django Replicas:
```bash
# Scale to 3 replicas
sudo kubectl scale deployment django -n elevatelearning --replicas=3

# Watch pods being created
sudo kubectl get pods -n elevatelearning -w
```

### Test Self-Healing:
```bash
# Delete a pod
sudo kubectl delete pod <django-pod-name> -n elevatelearning

# Watch K8s automatically recreate it
sudo kubectl get pods -n elevatelearning -w
```

### Test Load Balancing:
```bash
# Make multiple requests and see which pod handles them
for i in {1..10}; do
  curl -s http://localhost:30080/elevatelearning/home/ | grep -o "Elevate Learning"
  echo "Request $i completed"
done
```

### View Logs:
```bash
# Django logs
sudo kubectl logs -l app=django -n elevatelearning --tail=50

# MySQL logs
sudo kubectl logs -l app=mysql -n elevatelearning --tail=50
```

---

## 📊 Step 8: Access Your Application

### NodePort Access:
- **URL**: `http://35.244.96.92:30080/elevatelearning/home/`
- **Admin**: `http://35.244.96.92:30080/elevatelearning/admin/`

### Port Forwarding (Alternative):
```bash
sudo kubectl port-forward -n elevatelearning svc/nginx-service 8080:80 --address=0.0.0.0
# Access: http://35.244.96.92:8080/elevatelearning/home/
```

---

## 🔍 Troubleshooting

### Pods Not Starting:
```bash
sudo kubectl describe pod <pod-name> -n elevatelearning
sudo kubectl logs <pod-name> -n elevatelearning
```

### Worker Node Not Joining:
```bash
# On worker node
sudo systemctl status k3s-agent
sudo journalctl -u k3s-agent -f

# Check firewall (port 6443 must be open)
sudo ufw status
```

### Image Pull Errors:
```bash
# Verify image exists on worker nodes
sudo ctr -n k8s.io images ls | grep elevatelearning

# Re-import if needed
sudo ctr -n k8s.io images import elevatelearning-web.tar
```

---

## 📸 Screenshots to Capture

For your assignment, capture these:

1. ✅ `kubectl get nodes` - showing 3 nodes (master + 2 workers)
2. ✅ `kubectl get pods -n elevatelearning -o wide` - showing pods on different nodes
3. ✅ Application running in browser
4. ✅ `kubectl get svc -n elevatelearning` - showing services
5. ✅ `kubectl scale` command and pod scaling
6. ✅ Self-healing demonstration (delete pod, watch recreate)

---

## 🎉 Success Criteria

✅ 3-node K3s cluster running
✅ Django application deployed with 2+ replicas
✅ Pods distributed across worker nodes
✅ Load balancing working
✅ Self-healing demonstrated
✅ Application accessible via browser

---

## 🧹 Cleanup (Optional)

### Remove Deployment:
```bash
sudo kubectl delete namespace elevatelearning
```

### Uninstall K3s:
```bash
# On master
sudo /usr/local/bin/k3s-uninstall.sh

# On workers
sudo /usr/local/bin/k3s-agent-uninstall.sh
```

---

## 📚 Additional Resources

- K3s Documentation: https://docs.k3s.io/
- Kubernetes Concepts: https://kubernetes.io/docs/concepts/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
