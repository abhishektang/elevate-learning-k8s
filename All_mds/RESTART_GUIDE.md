# Complete Guide: Stop and Restart Your Website

## 📋 Current Setup

**Your Website**: http://34.87.248.125:30080/elevatelearning/home/

**Instances:**
- Master: 34.87.248.125
- Worker-1: 34.116.106.218
- Worker-2: 34.151.80.141

**External IPs**: Ephemeral (will change when stopped, unless you reserve static IPs)

---

## 🛑 STOPPING INSTANCES

### Step 1: Stop All Instances via GCP Console

1. **Go to**: https://console.cloud.google.com/compute/instances

2. **Select all 3 instances**:
   - ☑️ master
   - ☑️ worker-1
   - ☑️ worker-2

3. **Click "STOP" button** at the top

4. **Confirm** when prompted

5. **Wait** for all instances to show status: "STOPPED" (~30-60 seconds)

### What Happens:
- ✅ All VMs shut down
- ✅ Data is preserved (MySQL database, configurations)
- ✅ Docker images remain cached
- ⚠️ External IPs will change (unless you reserved static IPs)
- 💰 Compute charges stop

---

## ▶️ RESTARTING INSTANCES & WEBSITE

### Step 1: Start All Instances

1. **Go to**: https://console.cloud.google.com/compute/instances

2. **Select all 3 instances**:
   - ☑️ master
   - ☑️ worker-1
   - ☑️ worker-2

3. **Click "START" button** at the top

4. **Wait** for all instances to show status: "RUNNING" (~30-60 seconds)

### ⚠️ IMPORTANT: Check If IPs Changed

After starting, check the "External IP" column:

**If IPs are THE SAME** (you reserved static IPs):
- ✅ Skip to Step 3 - Everything will work automatically!

**If IPs CHANGED** (ephemeral IPs):
- ⚠️ You need to reconfigure the cluster (follow Step 2)

---

## 🔧 Step 2: Reconfigure Cluster (ONLY if IPs Changed)

### 2A: Get the New Master IP

From GCP Console, note the new master external IP:
```
Old Master IP: 34.87.248.125
New Master IP: <note this down>
```

### 2B: SSH to Master and Get Token

```bash
# Replace NEW_MASTER_IP with the actual new IP
ssh -i mykeys/remote-server-myproject t_abhishek345@NEW_MASTER_IP

# Get the K3s token (you'll need this for workers)
sudo cat /var/lib/rancher/k3s/server/node-token

# Copy this token - it looks like:
# K10e4c47a233da4a967a2cf8f7f45508db6932982dea8ad749ec686d1a93c5b18ee::server:00355c79f8fd65145263437fdad8af59

# Exit master
exit
```

### 2C: Rejoin Worker-1

```bash
# Get worker-1's new IP from GCP Console
ssh -i mykeys/remote-server-myproject t_abhishek345@NEW_WORKER1_IP

# Stop K3s agent
sudo systemctl stop k3s-agent

# Remove old configuration
sudo rm -rf /var/lib/rancher/k3s/agent

# Rejoin with master's NEW IP and token
curl -sfL https://get.k3s.io | K3S_URL=https://NEW_MASTER_IP:6443 \
  K3S_TOKEN=<paste-token-here> \
  sh -

# Exit worker-1
exit
```

### 2D: Rejoin Worker-2

```bash
# Get worker-2's new IP from GCP Console
ssh -i mykeys/remote-server-myproject t_abhishek345@NEW_WORKER2_IP

# Stop K3s agent
sudo systemctl stop k3s-agent

# Remove old configuration
sudo rm -rf /var/lib/rancher/k3s/agent

# Rejoin with master's NEW IP and token
curl -sfL https://get.k3s.io | K3S_URL=https://NEW_MASTER_IP:6443 \
  K3S_TOKEN=<paste-token-here> \
  sh -

# Exit worker-2
exit
```

### 2E: Update ConfigMap with New Master IP

```bash
# SSH back to master
ssh -i mykeys/remote-server-myproject t_abhishek345@NEW_MASTER_IP

# Update ConfigMap
kubectl edit configmap elevatelearning-config -n elevatelearning

# Find this line:
#   CSRF_TRUSTED_ORIGINS: "http://34.87.248.125"
# Change to:
#   CSRF_TRUSTED_ORIGINS: "http://NEW_MASTER_IP"

# Save and exit (press 'i' to edit, then ESC + ':wq' + ENTER)

# Restart Django pods to apply changes
kubectl rollout restart deployment django-web -n elevatelearning

# Exit master
exit
```

---

## ✅ Step 3: Verify Everything is Working

### 3A: Check Cluster Status

```bash
# SSH to master (use NEW IP if it changed)
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125

# Check all nodes are Ready (wait 2-3 minutes if not ready yet)
kubectl get nodes
# Should show:
# NAME       STATUS   ROLES                  AGE   VERSION
# master     Ready    control-plane,master   ...   v1.33.5+k3s1
# worker-1   Ready    <none>                 ...   v1.33.5+k3s1
# worker-2   Ready    <none>                 ...   v1.33.5+k3s1

# Check all pods are Running (may take 1-2 minutes)
kubectl get pods -n elevatelearning
# Should show:
# NAME                          READY   STATUS    RESTARTS   AGE
# django-web-5d446d7b47-xxxxx   1/1     Running   ...        ...
# django-web-5d446d7b47-xxxxx   1/1     Running   ...        ...
# django-web-5d446d7b47-xxxxx   1/1     Running   ...        ...
# mysql-7c856546c-xxxxx         1/1     Running   ...        ...
# nginx-5ccfbc5f77-xxxxx        1/1     Running   ...        ...

# Test website from inside master
curl -I http://localhost:30080/elevatelearning/home/
# Should show: HTTP/1.1 200 OK

# Exit
exit
```

### 3B: Test Website from Your Browser

Open in your browser:
```
http://NEW_MASTER_IP:30080/elevatelearning/home/
```

**If it doesn't load:**
- Wait 2-3 more minutes for all pods to fully start
- Check firewall allows port 30080 (should still be open)

**If it loads:**
- ✅ Homepage works
- ✅ Try logging into admin: http://NEW_MASTER_IP:30080/admin/
  - Username: `admin`
  - Password: `admin123`

---

## 🎯 Quick Reference Commands

### Check if everything is running:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@MASTER_IP "kubectl get nodes && kubectl get pods -n elevatelearning"
```

### Restart a service if needed:
```bash
# Restart all Django pods
ssh -i mykeys/remote-server-myproject t_abhishek345@MASTER_IP "kubectl rollout restart deployment django-web -n elevatelearning"

# Restart Nginx
ssh -i mykeys/remote-server-myproject t_abhishek345@MASTER_IP "kubectl rollout restart deployment nginx -n elevatelearning"

# Restart MySQL (careful - may cause brief downtime)
ssh -i mykeys/remote-server-myproject t_abhishek345@MASTER_IP "kubectl rollout restart deployment mysql -n elevatelearning"
```

### View logs if something is wrong:
```bash
# Check pod logs
ssh -i mykeys/remote-server-myproject t_abhishek345@MASTER_IP "kubectl logs -l app=django-web -n elevatelearning --tail=50"

# Check events
ssh -i mykeys/remote-server-myproject t_abhishek345@MASTER_IP "kubectl get events -n elevatelearning --sort-by='.lastTimestamp'"
```

---

## ⏱️ Expected Timeline

### With Static IPs (Recommended):
```
Stop instances:         30 seconds
Start instances:        60 seconds
K3s auto-starts:        30 seconds
Pods auto-restart:      60 seconds
Website accessible:     3-4 minutes total ✅
```

### Without Static IPs (Need Reconfiguration):
```
Stop instances:         30 seconds
Start instances:        60 seconds
Note new IPs:           1 minute
Rejoin workers:         5 minutes
Update ConfigMap:       2 minutes
Pods restart:           2 minutes
Website accessible:     15-20 minutes total ⚠️
```

---

## 🚨 Troubleshooting

### Problem: Nodes show "NotReady"

**Solution:**
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@MASTER_IP

# Check K3s service
sudo systemctl status k3s

# If not running, restart
sudo systemctl restart k3s

# Wait 30 seconds and check again
kubectl get nodes
```

### Problem: Pods stuck in "Pending" or "ContainerCreating"

**Solution:**
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@MASTER_IP

# Check pod details
kubectl describe pod <pod-name> -n elevatelearning

# Common issues:
# - Worker nodes not ready: Wait or rejoin workers
# - Image not found: Import image again to workers
# - PVC issues: Check persistent volume status
```

### Problem: Website shows "Connection Refused"

**Solution 1:** Pods still starting
```bash
# Wait 2-3 more minutes and try again
ssh -i mykeys/remote-server-myproject t_abhishek345@MASTER_IP "kubectl get pods -n elevatelearning"
```

**Solution 2:** Firewall issue
- Check GCP Console → VPC Network → Firewall
- Ensure port 30080 is allowed from 0.0.0.0/0

**Solution 3:** IP changed but ConfigMap not updated
- Follow Step 2E to update CSRF_TRUSTED_ORIGINS

### Problem: K3s won't start (port 6444 in use)

**Solution:**
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@MASTER_IP

# Find process using port
sudo ss -tlnp | grep 6444

# Kill the process (replace PID)
sudo kill -9 <PID>

# Restart K3s
sudo systemctl restart k3s
```

**If that doesn't work:**
```bash
# Uninstall and reinstall K3s (preserves data)
sudo /usr/local/bin/k3s-uninstall.sh
curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode 644 --disable traefik --node-name master --flannel-backend=vxlan

# Wait for master to be Ready
kubectl get nodes

# Rejoin workers (see Step 2C and 2D)
```

---

## 💡 Pro Tips

### 1. Reserve Static IPs to Avoid Reconfiguration

See `RESERVE_STATIC_IPS.md` for instructions.

**Cost**: $9-15/month when stopped, FREE when running
**Benefit**: Zero reconfiguration needed!

### 2. Create a Startup Script

Save this as `restart-cluster.sh`:
```bash
#!/bin/bash
MASTER_IP="34.87.248.125"  # Update if IP changes

echo "Checking cluster status..."
ssh -i mykeys/remote-server-myproject t_abhishek345@$MASTER_IP "kubectl get nodes"

echo "Checking pods..."
ssh -i mykeys/remote-server-myproject t_abhishek345@$MASTER_IP "kubectl get pods -n elevatelearning"

echo "Testing website..."
curl -I http://$MASTER_IP:30080/elevatelearning/home/

echo "Done! Visit http://$MASTER_IP:30080/elevatelearning/home/"
```

Make it executable:
```bash
chmod +x restart-cluster.sh
```

### 3. Document Your IPs

Keep a file with your current IPs:
```
# my-cluster-ips.txt
Master:   34.87.248.125
Worker-1: 34.116.106.218
Worker-2: 34.151.80.141
Updated:  October 23, 2025
```

Update this file whenever IPs change.

---

## 📝 Summary Checklist

When restarting instances:

**If IPs Stayed Same (Static IPs):**
- [ ] Start all instances in GCP Console
- [ ] Wait 3-4 minutes
- [ ] Open http://MASTER_IP:30080/elevatelearning/home/
- [ ] ✅ Done!

**If IPs Changed (Ephemeral IPs):**
- [ ] Start all instances
- [ ] Note new master IP
- [ ] SSH to master, get K3s token
- [ ] Rejoin worker-1 with new master IP
- [ ] Rejoin worker-2 with new master IP
- [ ] Update ConfigMap with new master IP
- [ ] Restart Django pods
- [ ] Wait 5 minutes
- [ ] Open http://NEW_MASTER_IP:30080/elevatelearning/home/
- [ ] ✅ Done!

---

## 🎓 For Your Assignment

**To Document:**
```
"The application can be stopped and restarted with minimal 
downtime. With static IPs, the restart is fully automated 
and takes approximately 3-4 minutes. All data persists 
across restarts thanks to Kubernetes PersistentVolumes 
for MySQL and the declarative nature of Kubernetes 
deployments."
```

**Screenshots to Take:**
1. Before stopping: All pods running
2. GCP Console: Stopped instances
3. GCP Console: Starting instances
4. After restart: All nodes Ready
5. After restart: All pods Running
6. Website accessible in browser

---

**Created**: October 23, 2025  
**Author**: Abhishek Tanguturi (s4845110)  
**Course**: INFS7202
