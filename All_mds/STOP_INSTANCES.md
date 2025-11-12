# How to Stop All GCP Instances

## Instance Information

Your Kubernetes cluster consists of 3 GCP VM instances:

| Instance Name | External IP      | Role       | Location        |
|---------------|------------------|------------|-----------------|
| master        | 34.87.248.125    | Master     | K3s control plane |
| worker-1      | 34.116.106.218   | Worker     | Compute node    |
| worker-2      | 34.151.80.141    | Worker     | Compute node    |

---

## ⚠️ Warning: What Happens When You Stop All Instances

### Immediate Impact:
- ❌ **Complete cluster shutdown**
- ❌ **Website goes offline**: http://34.87.248.125:30080
- ❌ **All 5 pods stopped** (3 Django, 1 MySQL, 1 Nginx)
- ❌ **All services unavailable**

### Data Persistence:
- ✅ **MySQL data SURVIVES** (stored in PersistentVolume on worker-2's disk)
- ✅ **Configuration survives** (ConfigMaps, Secrets, Deployments)
- ✅ **Docker images survive** (cached on each node)
- ✅ **All code survives** (project files in /home/t_abhishek345/elevatelearning)

### When You Restart:
- ⏱️ **~2-3 minutes** for full recovery
- ✅ All pods automatically recreate
- ✅ Application comes back online
- ✅ Data intact (no loss)

---

## Option 1: Stop via GCP Console (Recommended)

### Step 1: Go to GCP Console
1. Open: https://console.cloud.google.com/compute/instances
2. Log in with your Google account

### Step 2: Select All Instances
- ☑️ Check the boxes next to:
  - master
  - worker-1  
  - worker-2

### Step 3: Stop Instances
1. Click the **"STOP"** button at the top
2. Confirm when prompted
3. Wait 30-60 seconds for status to change to "STOPPED"

### Visual Guide:
```
╔════════════════════════════════════════════════════╗
║ VM instances                                        ║
║ ┌────────────────────────────────────────────────┐ ║
║ │ ☑️ master      34.87.248.125    RUNNING       │ ║
║ │ ☑️ worker-1    34.116.106.218   RUNNING       │ ║
║ │ ☑️ worker-2    34.151.80.141    RUNNING       │ ║
║ └────────────────────────────────────────────────┘ ║
║                                                     ║
║ [🛑 STOP]  [▶️ START]  [🔄 RESET]  [🗑️ DELETE]    ║
╚════════════════════════════════════════════════════╝
```

---

## Option 2: Stop via gcloud CLI (If Installed)

If you have `gcloud` installed locally, run these commands:

```bash
# Stop master
gcloud compute instances stop master --zone=<your-zone>

# Stop worker-1
gcloud compute instances stop worker-1 --zone=<your-zone>

# Stop worker-2
gcloud compute instances stop worker-2 --zone=<your-zone>

# Or stop all at once (if you know the zone)
gcloud compute instances stop master worker-1 worker-2 --zone=<your-zone>
```

**Note**: Replace `<your-zone>` with your actual GCP zone (e.g., `us-central1-a`, `asia-southeast1-b`, etc.)

---

## Option 3: Stop Individual Instances

If you want to stop them one at a time to see the effect:

### Stop Worker-1 First (Least Disruptive)
- Lost pods: 2 Django, 1 Nginx
- Impact: Some requests may fail, MySQL survives
- Kubernetes will reschedule to worker-2

### Stop Worker-2 Second (More Disruptive)
- Lost pods: 1 Django, 1 MySQL
- Impact: **Database goes down**, app becomes unavailable
- Kubernetes tries to reschedule but MySQL PVC is on worker-2

### Stop Master Last (Control Plane Down)
- Lost: Kubernetes API server
- Impact: Cannot manage cluster anymore
- Existing pods keep running but cannot create new ones

---

## How to Restart Later

### Via GCP Console:
1. Go to: https://console.cloud.google.com/compute/instances
2. Select all three instances
3. Click **"START"** button
4. Wait ~2-3 minutes for full recovery

### Via gcloud CLI:
```bash
gcloud compute instances start master worker-1 worker-2 --zone=<your-zone>
```

### Startup Sequence (Automatic):
```
1. VMs boot up (30 seconds)
   ↓
2. K3s services auto-start (30 seconds)
   ↓
3. Master becomes Ready (10 seconds)
   ↓
4. Workers join cluster (20 seconds)
   ↓
5. Pods get scheduled (30 seconds)
   ↓
6. Containers start (30 seconds)
   ↓
7. Health probes pass (30 seconds)
   ↓
8. ✅ Application ONLINE
```

### Verify After Restart:
```bash
# SSH to master
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125

# Check nodes
kubectl get nodes

# Check pods
kubectl get pods -n elevatelearning

# Check services
kubectl get svc -n elevatelearning

# Test application
curl -I http://localhost:30080/elevatelearning/home/
```

---

## Cost Savings

### When Stopped:
- ✅ **No compute charges** (CPU/RAM)
- ⚠️ **Still charged for disk storage** (boot disks, PVs)
- ⚠️ **Still charged for reserved external IPs**

### To Save More:
1. **Delete instances** (loses everything)
2. **Release static IPs** (if you reserved any)
3. **Delete persistent disks** (if you don't need data)

---

## Before You Stop - Quick Backup

If you want to save your work:

```bash
# 1. Take a snapshot of worker-2's disk (contains MySQL data)
gcloud compute disks snapshot worker-2 \
  --snapshot-names=elevate-learning-backup-$(date +%Y%m%d) \
  --zone=<your-zone>

# 2. Export Kubernetes configurations
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 \
  "kubectl get all -n elevatelearning -o yaml > ~/elevatelearning-backup.yaml"

# 3. Download the backup
scp -i mykeys/remote-server-myproject \
  t_abhishek345@34.87.248.125:~/elevatelearning-backup.yaml \
  ./elevatelearning-backup.yaml
```

---

## Summary

### To Stop All Instances:
**Easiest Method**: GCP Console → Select all → Click STOP

### Recovery Time:
**~2-3 minutes** from stopped → fully operational

### Data Safety:
**✅ All data survives** (MySQL, configurations, images)

### Cost Impact:
**Compute charges stop**, but disk/IP charges continue

---

## Need Help?

If you encounter issues after restart:

```bash
# Check node status
kubectl get nodes

# Check pod status  
kubectl get pods -n elevatelearning -o wide

# Check pod logs
kubectl logs -l app=django-web -n elevatelearning

# Restart a deployment if needed
kubectl rollout restart deployment django-web -n elevatelearning
```

---

**Prepared by**: Abhishek Tanguturi (s4845110)  
**Date**: October 22, 2025
