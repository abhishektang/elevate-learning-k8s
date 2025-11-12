# Quick Start Guide - Orchestration Tests

## 🚀 How to Run the Tests

### Step 1: Navigate to Project Directory
```bash
cd /Users/abhishektanguturi/Master_of_Information_Tech/Sem_3_2025/INFS7202/s4845110_Abhishek_Tanguturi/ProjectCode/INFS7202
```

### Step 2: Make Script Executable (if not already)
```bash
chmod +x run-orchestration-tests.sh
```

### Step 3: Run the Test Suite
```bash
./run-orchestration-tests.sh
```

### Step 4: Press Enter When Prompted
The script will:
1. ✅ Check SSH connection
2. ✅ Verify cluster status
3. ✅ Show initial pod state
4. ⏸️ **Wait for your confirmation** - Press Enter to continue
5. 🧪 Run all 5 tests automatically
6. 📊 Display comprehensive results

---

## 📋 What Gets Tested

| Test # | Test Name | What It Does | Expected Result |
|--------|-----------|--------------|-----------------|
| 1 | Self-Healing | Deletes a pod | Kubernetes recreates it automatically |
| 2 | Load Balancing | Sends 15 requests | All succeed, distributed across pods |
| 3 | Scaling | Scales 3→5→3 | All replicas ready in < 2 minutes |
| 4 | Rolling Update | Adds environment vars | Zero downtime, all requests succeed |
| 5 | Rollback | Reverts to previous version | Instant recovery, no downtime |

---

## ⏱️ Expected Duration

- **Total Time:** 8-12 minutes
- **Per Test:** 1-3 minutes each
- **Longest:** Rolling Update & Rollback (~2 minutes each)

---

## 📊 Sample Output

```bash
╔════════════════════════════════════════════════════════╗
║     KUBERNETES ORCHESTRATION TEST SUITE                ║
╚════════════════════════════════════════════════════════╝

Testing K3s cluster orchestration capabilities
Master Node: 34.87.248.125
Namespace: elevatelearning

=== PRE-TEST CHECKS ===
✅ SSH connection: OK
Nodes in cluster: 3
✅ Namespace 'elevatelearning' exists

Press Enter to start tests (or Ctrl+C to cancel)...

=== TEST 1: SELF-HEALING ===
ℹ️  Deleting pod: django-web-84c8b5dddb-xxxxx
✅ Self-Healing Test PASSED - Pod automatically recreated

=== TEST 2: LOAD BALANCING ===
Request 1: HTTP 200 ✓
Request 2: HTTP 200 ✓
...
✅ Load Balancing Test PASSED - 100% success rate

=== TEST 3: SCALING ===
✅ Scaled up to 5 replicas in 33 seconds
✅ Scaled down to 3 replicas in 5 seconds
✅ Scaling Test PASSED

=== TEST 4: ROLLING UPDATE ===
✅ Rollout completed in 97 seconds
✅ Rolling Update Test PASSED - Zero downtime

=== TEST 5: ROLLBACK ===
✅ Rollback completed in 99 seconds
✅ Rollback Test PASSED

╔════════════════════════════════════════════════════════╗
║           ORCHESTRATION TESTS COMPLETE                 ║
╚════════════════════════════════════════════════════════╝

Total Tests: 5
Passed: 5
Failed: 0

✅ ALL TESTS PASSED! 🎉
```

---

## 🎨 Color Legend

- 🔵 **Blue** = Section headers
- 🟢 **Green** = Success/Passed
- 🔴 **Red** = Errors/Failed
- 🟡 **Yellow** = Information
- ⚪ **Cyan** = Main headers

---

## 🔧 Customization

Edit these lines in `run-orchestration-tests.sh` to customize:

```bash
# Line 24-28
MASTER_IP="34.87.248.125"          # Your master IP
SSH_KEY="mykeys/remote-server-myproject"  # SSH key path
SSH_USER="t_abhishek345"           # Your username
NAMESPACE="elevatelearning"        # Kubernetes namespace
DEPLOYMENT="django-web"            # Deployment name
```

---

## 💾 Save Test Results

To save test output to a file:

```bash
# With timestamp
./run-orchestration-tests.sh | tee test-results-$(date +%Y%m%d-%H%M%S).log

# Simple filename
./run-orchestration-tests.sh | tee test-results.log
```

This creates a log file you can review later or include in your documentation.

---

## 🐛 Troubleshooting

### "Permission denied"
```bash
chmod +x run-orchestration-tests.sh
```

### "SSH connection failed"
```bash
# Test SSH manually first
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125
```

### "Namespace not found"
```bash
# Check if application is deployed
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get pods -n elevatelearning"
```

### Tests taking too long
- Normal: 8-12 minutes total
- Worker nodes may be slow to respond
- Check cluster resources: `kubectl top nodes`

---

## 📸 For Assignment Documentation

After running tests, capture:

1. **Terminal output** showing all 5 tests passing
2. **Final cluster state** (automatically displayed)
3. **Pod distribution** across worker nodes
4. **Rollout history** showing multiple revisions

---

## ✅ Checklist Before Running

- [ ] K3s cluster is running
- [ ] All 3 nodes are Ready
- [ ] Application is deployed
- [ ] Can SSH to master node
- [ ] SSH key is in correct location
- [ ] You have 10-15 minutes available

---

## 🎯 Success Criteria

All tests should show:
- ✅ Test 1: Pod recreated automatically
- ✅ Test 2: 100% success rate (15/15)
- ✅ Test 3: Replicas scaled successfully
- ✅ Test 4: Zero downtime during rollout
- ✅ Test 5: Successful rollback

If all pass, you have a **production-ready** Kubernetes cluster! 🚀

---

**Ready to run?** Execute: `./run-orchestration-tests.sh`
