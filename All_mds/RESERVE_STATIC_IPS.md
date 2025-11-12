# Reserve Static IPs - Step-by-Step Guide

## Current Ephemeral IPs (That Will Be Reserved)

| Instance | Current IP      | Will Reserve As       |
|----------|-----------------|----------------------|
| master   | 34.87.248.125   | master-static-ip     |
| worker-1 | 34.116.106.218  | worker-1-static-ip   |
| worker-2 | 34.151.80.141   | worker-2-static-ip   |

---

## Method 1: Via GCP Console (Easiest - Follow This)

### Step 1: Promote Master IP to Static

1. **Go to VPC Network → IP Addresses**
   - URL: https://console.cloud.google.com/networking/addresses/list
   - Or: Navigation Menu (☰) → VPC Network → IP addresses

2. **Find Master's IP Address**
   - Look for: `34.87.248.125`
   - Type should show: `Ephemeral`
   - In use by: Your master instance

3. **Click the Three Dots (⋮) next to the IP**
   - Select: **"Reserve static address"** or **"Promote to static"**

4. **Configure Static IP:**
   - **Name**: `master-static-ip`
   - **Description**: `Static IP for K3s master node`
   - **IP address**: 34.87.248.125 (pre-filled)
   - **Type**: Regional
   - **Attached to**: Should show your master instance
   
5. **Click "RESERVE"**

✅ **Success**: Master IP is now static! It will never change.

---

### Step 2: Promote Worker-1 IP to Static

1. **On the same IP Addresses page**
   - Find: `34.116.106.218`

2. **Click Three Dots (⋮) → Reserve static address**

3. **Configure:**
   - **Name**: `worker-1-static-ip`
   - **Description**: `Static IP for K3s worker-1 node`
   - **IP address**: 34.116.106.218
   - **Attached to**: worker-1 instance

4. **Click "RESERVE"**

✅ **Success**: Worker-1 IP is now static!

---

### Step 3: Promote Worker-2 IP to Static

1. **On the same IP Addresses page**
   - Find: `34.151.80.141`

2. **Click Three Dots (⋮) → Reserve static address**

3. **Configure:**
   - **Name**: `worker-2-static-ip`
   - **Description**: `Static IP for K3s worker-2 node`
   - **IP address**: 34.151.80.141
   - **Attached to**: worker-2 instance

4. **Click "RESERVE"**

✅ **Success**: Worker-2 IP is now static!

---

### Step 4: Verify All IPs Are Static

1. **Refresh the IP Addresses page**

2. **You should see:**
   ```
   NAME                 ADDRESS          TYPE     STATUS   IN USE BY
   master-static-ip     34.87.248.125    Static   In use   master
   worker-1-static-ip   34.116.106.218   Static   In use   worker-1
   worker-2-static-ip   34.151.80.141    Static   In use   worker-2
   ```

3. **Verify Type shows "Static"** (not "Ephemeral")

✅ **All done!** Your IPs are now permanent.

---

## Visual Guide

### Before (Ephemeral):
```
╔═══════════════════════════════════════════════════════════╗
║ External IP addresses                                      ║
║ ┌───────────────────────────────────────────────────────┐ ║
║ │ ADDRESS          TYPE        STATUS    IN USE BY      │ ║
║ │ 34.87.248.125    Ephemeral   In use    master     [⋮]│ ║
║ │ 34.116.106.218   Ephemeral   In use    worker-1   [⋮]│ ║
║ │ 34.151.80.141    Ephemeral   In use    worker-2   [⋮]│ ║
║ └───────────────────────────────────────────────────────┘ ║
╚═══════════════════════════════════════════════════════════╝
                        ↓
                Click [⋮] → "Reserve static address"
                        ↓
```

### After (Static):
```
╔═══════════════════════════════════════════════════════════╗
║ External IP addresses                                      ║
║ ┌───────────────────────────────────────────────────────┐ ║
║ │ NAME               ADDRESS         TYPE    STATUS     │ ║
║ │ master-static-ip   34.87.248.125   Static  In use ✅  │ ║
║ │ worker-1-static-ip 34.116.106.218  Static  In use ✅  │ ║
║ │ worker-2-static-ip 34.151.80.141   Static  In use ✅  │ ║
║ └───────────────────────────────────────────────────────┘ ║
╚═══════════════════════════════════════════════════════════╝
```

---

## Alternative: Reserve New Static IPs (If Above Doesn't Work)

If you can't find the "Reserve static address" option, you can reserve new IPs:

### For Master:

1. **Go to**: https://console.cloud.google.com/networking/addresses/list

2. **Click "RESERVE EXTERNAL STATIC ADDRESS"** (top of page)

3. **Configure:**
   - **Name**: `master-static-ip`
   - **Network Service Tier**: Premium
   - **IP version**: IPv4
   - **Type**: Regional
   - **Region**: Select the SAME region as your master VM
   - **Attached to**: None (for now)

4. **Click "RESERVE"**

5. **Assign to Master VM:**
   - Go to: https://console.cloud.google.com/compute/instances
   - Click on `master` instance
   - Click **"EDIT"** at top
   - Under "Network interfaces" → Click **"External IPv4 address"**
   - Select your new `master-static-ip`
   - Scroll down and click **"SAVE"**
   - Click **"START/RESET"** to apply changes

⚠️ **Note**: This method will give you different IPs! Only use if promotion doesn't work.

---

## Method 2: Via gcloud CLI (Advanced)

If you have `gcloud` installed locally on your Mac:

### First, find your instances' zone and region:

```bash
# List instances to find zones
gcloud compute instances list --format="table(name,zone,EXTERNAL_IP)"

# Example output:
# NAME      ZONE               EXTERNAL_IP
# master    us-central1-a      34.87.248.125
# worker-1  us-central1-a      34.116.106.218
# worker-2  us-central1-a      34.151.80.141
```

### Reserve and attach IPs:

```bash
# Set your zone (replace with your actual zone from above)
ZONE="us-central1-a"  # ← CHANGE THIS
REGION="us-central1"  # ← CHANGE THIS

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
```

### Attach to instances:

```bash
# Master
gcloud compute instances delete-access-config master \
  --access-config-name="External NAT" \
  --zone=$ZONE

gcloud compute instances add-access-config master \
  --access-config-name="External NAT" \
  --address=master-static-ip \
  --zone=$ZONE

# Worker-1
gcloud compute instances delete-access-config worker-1 \
  --access-config-name="External NAT" \
  --zone=$ZONE

gcloud compute instances add-access-config worker-1 \
  --access-config-name="External NAT" \
  --address=worker-1-static-ip \
  --zone=$ZONE

# Worker-2
gcloud compute instances delete-access-config worker-2 \
  --access-config-name="External NAT" \
  --zone=$ZONE

gcloud compute instances add-access-config worker-2 \
  --access-config-name="External NAT" \
  --address=worker-2-static-ip \
  --zone=$ZONE
```

### Verify:

```bash
gcloud compute addresses list
```

Should show:
```
NAME                 ADDRESS          STATUS
master-static-ip     34.87.248.125    IN_USE
worker-1-static-ip   34.116.106.218   IN_USE
worker-2-static-ip   34.151.80.141    IN_USE
```

---

## After Reserving - Test Everything

### 1. Verify IPs Haven't Changed
```bash
# SSH should still work with same IPs
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125

# Check inside master
kubectl get nodes -o wide
```

### 2. Test Application
```bash
# Should still work
curl -I http://34.87.248.125:30080/elevatelearning/home/
```

### 3. Stop and Start Test
```bash
# In GCP Console:
# 1. Stop all 3 instances
# 2. Wait 1 minute
# 3. Start all 3 instances
# 4. IPs should be EXACTLY THE SAME! ✅
```

---

## Cost Breakdown

### With Static IPs:
```
Running (Instance ON):
- Compute: ~$20-50/month (VM costs)
- Static IP: FREE (no charge when attached)
- Total: ~$20-50/month

Stopped (Instance OFF):
- Compute: $0 (no VM charges)
- Static IP: ~$3-5/month per IP = $9-15 total
- Total: $9-15/month
```

### Without Static IPs:
```
Running: ~$20-50/month
Stopped: $0/month

BUT: IPs change every restart (need reconfiguration)
```

**Trade-off**: Pay $9-15/month OR spend 15 minutes reconfiguring after each restart.

---

## Troubleshooting

### Problem: Can't find IPs in IP Addresses list
**Solution**: They might be listed with the instance. Try reserving new IPs instead (see "Alternative" section above)

### Problem: "Address is already in use"
**Solution**: The IP is already attached. You need to detach first before reserving.

### Problem: IPs changed after reserving
**Solution**: You probably created NEW IPs instead of promoting existing ones. Update your ConfigMap and rejoin workers.

### Problem: Can't SSH after IP change
**Solution**: Update your SSH command with new IP, or check GCP Console for current IP.

---

## Summary Checklist

After completing this guide, verify:

- [ ] Master IP shows "Static" type in GCP Console
- [ ] Worker-1 IP shows "Static" type in GCP Console
- [ ] Worker-2 IP shows "Static" type in GCP Console
- [ ] All IPs are still the same: 34.87.248.125, 34.116.106.218, 34.151.80.141
- [ ] Can SSH to master: `ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125`
- [ ] Application works: http://34.87.248.125:30080/elevatelearning/home/
- [ ] Tested stop/start and IPs stayed the same

---

## Next Steps

Once IPs are static:

1. ✅ **Stop instances anytime** - IPs won't change
2. ✅ **No reconfiguration needed** after restart
3. ✅ **Document in your report**: "Static IPs were reserved to ensure stable access points"
4. ✅ **Take screenshots** showing static IPs in GCP Console

---

**Estimated Time**: 5-10 minutes  
**Difficulty**: Easy (just clicking in GCP Console)  
**Cost**: $9-15/month when stopped, FREE when running  
**Benefit**: Never worry about IP changes again! 🎉

---

**Ready?** Open https://console.cloud.google.com/networking/addresses/list and follow Step 1! 🚀
