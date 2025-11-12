# How to Preserve External IPs

## Problem: Ephemeral IPs Change on Restart

Your current instances have **ephemeral (temporary)** external IPs:
- Master:   34.87.248.125
- Worker-1: 34.116.106.218
- Worker-2: 34.151.80.141

**These WILL CHANGE** when you stop/start the instances! ⚠️

---

## Solution 1: Reserve Static IPs (Recommended)

### Cost:
- **~$3-5 per month per IP** while instance is STOPPED
- **FREE** while instance is RUNNING
- Total: ~$9-15/month when stopped (but preserves your setup)

### Steps to Reserve Static IPs:

#### Method A: Via GCP Console

**For Master Node:**
1. Go to: https://console.cloud.google.com/networking/addresses/list
2. Click **"RESERVE EXTERNAL STATIC ADDRESS"**
3. Configure:
   - **Name**: `master-static-ip`
   - **IP version**: IPv4
   - **Type**: Regional
   - **Region**: Same as your master VM
   - **Attached to**: Select your master VM instance
4. Click **"RESERVE"**

**Repeat for Worker-1 and Worker-2:**
- Name: `worker-1-static-ip` (attach to worker-1)
- Name: `worker-2-static-ip` (attach to worker-2)

#### Method B: Via gcloud CLI (Faster)

First, find your VM zone:
```bash
# You'll need to run this in GCP Console or locally with gcloud
gcloud compute instances list --format="table(name,zone,EXTERNAL_IP)"
```

Then reserve and attach IPs:
```bash
# Replace <ZONE> with your actual zone (e.g., us-central1-a)
ZONE="<your-zone>"
REGION="${ZONE%-*}"  # Extracts region from zone

# Reserve master IP
gcloud compute addresses create master-static-ip \
  --addresses 34.87.248.125 \
  --region $REGION

# Reserve worker-1 IP
gcloud compute addresses create worker-1-static-ip \
  --addresses 34.116.106.218 \
  --region $REGION

# Reserve worker-2 IP
gcloud compute addresses create worker-2-static-ip \
  --addresses 34.151.80.141 \
  --region $REGION

# Attach IPs to instances
gcloud compute instances delete-access-config master --zone=$ZONE
gcloud compute instances add-access-config master \
  --zone=$ZONE \
  --address=34.87.248.125

gcloud compute instances delete-access-config worker-1 --zone=$ZONE
gcloud compute instances add-access-config worker-1 \
  --zone=$ZONE \
  --address=34.116.106.218

gcloud compute instances delete-access-config worker-2 --zone=$ZONE
gcloud compute instances add-access-config worker-2 \
  --zone=$ZONE \
  --address=34.151.80.141
```

### Verify Static IPs:
```bash
gcloud compute addresses list
```

Should show:
```
NAME               ADDRESS          STATUS
master-static-ip   34.87.248.125    IN_USE
worker-1-static-ip 34.116.106.218   IN_USE
worker-2-static-ip 34.151.80.141    IN_USE
```

---

## Solution 2: Accept IP Changes (Free but Requires Reconfiguration)

If you don't want to pay for static IPs, you'll need to reconfigure after each restart:

### After Restarting Instances:

#### Step 1: Get New IPs
```bash
# Via GCP Console:
# https://console.cloud.google.com/compute/instances
# Copy the new external IPs

# Or via gcloud:
gcloud compute instances list --format="table(name,EXTERNAL_IP)"
```

#### Step 2: Update K3s Workers
```bash
# SSH to each worker with NEW IP
ssh -i mykeys/remote-server-myproject t_abhishek345@NEW_WORKER_IP

# Stop K3s
sudo systemctl stop k3s-agent

# Remove old config
sudo rm -rf /var/lib/rancher/k3s/agent

# Rejoin cluster with master's NEW IP
curl -sfL https://get.k3s.io | K3S_URL=https://NEW_MASTER_IP:6443 \
  K3S_TOKEN=K10e4c47a233da4a967a2cf8f7f45508db6932982dea8ad749ec686d1a93c5b18ee::server:00355c79f8fd65145263437fdad8af59 \
  sh -
```

#### Step 3: Update ConfigMap
```bash
# SSH to master with NEW IP
ssh -i mykeys/remote-server-myproject t_abhishek345@NEW_MASTER_IP

# Update ConfigMap
kubectl edit configmap elevatelearning-config -n elevatelearning

# Change this line:
CSRF_TRUSTED_ORIGINS: "http://NEW_MASTER_IP"
```

#### Step 4: Restart Django Pods
```bash
kubectl rollout restart deployment django-web -n elevatelearning
```

#### Step 5: Update Your Local SSH Config
```bash
# Edit your SSH config or remember new IPs
# New application URL: http://NEW_MASTER_IP:30080/elevatelearning/home/
```

---

## Solution 3: Use Domain Name (Best Long-Term)

### Why Use a Domain?
- ✅ IP can change, domain stays the same
- ✅ More professional (myapp.com vs 34.87.248.125)
- ✅ Can use HTTPS with SSL certificate

### Steps:

#### Option A: Free Domain (Cloudflare, Freenom)
1. Register a free domain (e.g., yourdomain.tk)
2. Point A record to your master IP
3. Use domain in ConfigMap: `http://yourdomain.tk`

#### Option B: Google Domains ($12/year)
1. Buy domain: https://domains.google/
2. Add DNS A record: `@ → 34.87.248.125`
3. Wait 5-10 minutes for DNS propagation
4. Update ConfigMap with domain

---

## Comparison Table

| Method | Cost | Pros | Cons |
|--------|------|------|------|
| **Static IPs** | $9-15/month when stopped | ✅ No reconfiguration<br>✅ IPs never change<br>✅ Easy | ❌ Monthly cost<br>❌ Still using IP addresses |
| **Accept Changes** | FREE | ✅ No cost<br>✅ Works for testing | ❌ Manual reconfiguration<br>❌ Cluster needs rejoining<br>❌ Time-consuming |
| **Domain Name** | $0-12/year | ✅ Professional<br>✅ Can add HTTPS<br>✅ IP can change freely | ❌ Need to buy domain<br>❌ DNS propagation delay |

---

## Recommendation

### For Assignment/Testing:
**Option 2** (Accept IP Changes) - It's free and shows you understand the architecture

### For Production/Portfolio:
**Option 1** (Static IPs) + **Option 3** (Domain) - Professional and reliable

---

## Quick Decision Guide

**Choose Static IPs if:**
- ✅ You plan to stop/start frequently
- ✅ You want zero reconfiguration hassle
- ✅ $9-15/month is acceptable
- ✅ You're keeping this running for a while

**Accept IP Changes if:**
- ✅ This is just for assignment submission
- ✅ You'll delete everything after grading
- ✅ You're comfortable reconfiguring
- ✅ You want zero ongoing costs

**Use Domain Name if:**
- ✅ This is a portfolio project
- ✅ You want professional presentation
- ✅ You want to add HTTPS later
- ✅ You want stable access point

---

## What I Recommend for You

Based on your assignment context:

### Before Stopping Instances:
```bash
# 1. Take screenshots of everything working
# 2. Document current IPs in your report
# 3. Stop instances (IPs will change)
# 4. For restart: Follow "Accept IP Changes" process
```

### For Your Report:
```
"The application was deployed using ephemeral external IPs. 
In a production environment, static IPs or domain names would 
be used to ensure stable access points. This demonstrates 
understanding of cloud networking best practices."
```

---

## Emergency Recovery (If IPs Changed)

If you already stopped instances and IPs changed:

```bash
# 1. Find new master IP in GCP Console
NEW_MASTER_IP="<new-ip-here>"

# 2. SSH to master
ssh -i mykeys/remote-server-myproject t_abhishek345@$NEW_MASTER_IP

# 3. Check K3s status
kubectl get nodes
# Master should be Ready, workers likely NotReady

# 4. Get K3s token
sudo cat /var/lib/rancher/k3s/server/node-token

# 5. Rejoin workers (see Solution 2 steps above)
```

---

**Bottom Line**: 
- **With Static IPs**: Everything works after restart (no changes needed)
- **Without Static IPs**: IPs change, need to reconfigure cluster (~15 minutes work)

Choose based on your time vs. money trade-off! 💰⏱️
