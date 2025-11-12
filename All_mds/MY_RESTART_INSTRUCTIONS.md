# 🚀 Quick Restart Guide (WITH STATIC IPs)

## ✅ Your Setup (CONFIRMED)

**You have STATIC IPs reserved!** This means restarting is super easy.

**Your Website**: http://34.87.248.125:30080/elevatelearning/home/

**Static IPs:**
- Master: 34.87.248.125 ✅ (Won't change!)
- Worker-1: 34.116.106.218 ✅ (Won't change!)
- Worker-2: 34.151.80.141 ✅ (Won't change!)

---

## 🛑 TO STOP YOUR WEBSITE

### Method 1: Using GCP Console (Easiest)

1. Go to: https://console.cloud.google.com/compute/instances

2. **Select all 3 instances**:
   - ☑️ master
   - ☑️ worker-1
   - ☑️ worker-2

3. **Click "STOP"** button at the top

4. **Confirm** and wait 30-60 seconds

**Result**: 💰 You stop paying compute charges! (Only ~$11/month for static IPs)

---

## ▶️ TO START YOUR WEBSITE

### Step 1: Start Instances (2 minutes)

1. Go to: https://console.cloud.google.com/compute/instances

2. **Select all 3 instances**:
   - ☑️ master
   - ☑️ worker-1
   - ☑️ worker-2

3. **Click "START"** button at the top

4. Wait for all to show "RUNNING" (30-60 seconds)

### Step 2: Wait for Automatic Startup (2-3 minutes)

**Everything happens automatically!**

- ✅ K3s starts on master
- ✅ Workers reconnect automatically
- ✅ All pods restart automatically
- ✅ Website becomes accessible

**Just wait 3-4 minutes total after clicking START**

### Step 3: Verify Website is Live

Open in your browser:
```
http://34.87.248.125:30080/elevatelearning/home/
```

**Admin Panel:**
```
http://34.87.248.125:30080/admin/
Username: admin
Password: admin123
```

---

## ⏱️ Total Time: 3-4 Minutes

```
Click START           → 30 seconds
Instances boot        → 60 seconds  
K3s auto-starts       → 60 seconds
Pods auto-restart     → 60 seconds
Website accessible    → DONE! ✅
```

---

## 🎯 Quick Verification Commands

### Check if everything is running:

```bash
# Check cluster and pods
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 \
  "kubectl get nodes && echo '' && kubectl get pods -n elevatelearning"
```

**Should show:**
- 3 nodes: Ready
- 5 pods: Running

### Test website:

```bash
# Quick HTTP test
curl -I http://34.87.248.125:30080/elevatelearning/home/
```

**Should show:** `HTTP/1.1 200 OK`

---

## 🚨 Troubleshooting (Rare Issues)

### Problem: Website not loading after 5 minutes

**Solution 1**: Check if pods are still starting
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 \
  "kubectl get pods -n elevatelearning"
```

Wait if pods show "ContainerCreating" or "Pending"

**Solution 2**: Restart K3s if needed
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 \
  "sudo systemctl status k3s"
```

If not running:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 \
  "sudo systemctl restart k3s"
```

**Solution 3**: Restart pods manually
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 \
  "kubectl rollout restart deployment django-web -n elevatelearning && \
   kubectl rollout restart deployment nginx -n elevatelearning"
```

### Problem: Nodes show "NotReady"

Wait 2-3 minutes - they're still connecting.

If still not ready after 5 minutes:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 \
  "sudo systemctl restart k3s"
```

---

## 💰 Cost Summary

**When Running:**
- Compute: ~$50-70/month
- Static IPs: FREE (no charge when attached)
- **Total: ~$50-70/month**

**When Stopped:**
- Compute: $0 (stopped)
- Static IPs: ~$11/month (only charge when stopped)
- **Total: ~$11/month**

---

## 📝 Simple Checklist

**To Stop:**
- [ ] GCP Console → Select 3 instances
- [ ] Click STOP
- [ ] ✅ Done! (Saves ~$50-60/month)

**To Start:**
- [ ] GCP Console → Select 3 instances
- [ ] Click START
- [ ] Wait 3-4 minutes
- [ ] Open http://34.87.248.125:30080/elevatelearning/home/
- [ ] ✅ Done!

---

## 🎓 Benefits of Static IPs (Your Setup)

✅ **Same URLs**: Never changes  
✅ **Zero reconfiguration**: No worker rejoining needed  
✅ **Fast restarts**: 3-4 minutes every time  
✅ **No ConfigMap updates**: CSRF_TRUSTED_ORIGINS stays valid  
✅ **Assignment-ready**: Can stop/start anytime without issues  

---

## 🎥 For Your Assignment Documentation

**You can mention:**

> "The cluster uses static IP addresses, allowing seamless stop/start operations. 
> When instances are stopped, all data persists in Kubernetes PersistentVolumes. 
> Upon restart, the K3s cluster automatically reforms, and all containers restart 
> without any manual intervention. Total restart time is approximately 3-4 minutes, 
> demonstrating the resilience and automation capabilities of Kubernetes orchestration."

**Screenshots to capture:**
1. GCP Console showing 3 stopped instances with static IPs
2. Click START on all 3 instances
3. `kubectl get nodes` showing all Ready
4. `kubectl get pods -n elevatelearning` showing all Running
5. Browser showing website: http://34.87.248.125:30080/elevatelearning/home/
6. GCP Console showing static IPs remained unchanged

---

## 🎉 You're All Set!

Your static IP setup means:
- **Easiest possible restarts** (just click START and wait)
- **No IP changes** ever
- **Same URLs** always work
- **Minimal downtime** (3-4 minutes)

---

**Your IPs (PERMANENT):**
- Master: 34.87.248.125
- Worker-1: 34.116.106.218  
- Worker-2: 34.151.80.141

**Your Website (PERMANENT):**
- http://34.87.248.125:30080/elevatelearning/home/
- http://34.87.248.125:30080/admin/

**Created**: October 23, 2025  
**Author**: Abhishek Tanguturi (s4845110)  
**Course**: INFS7202
