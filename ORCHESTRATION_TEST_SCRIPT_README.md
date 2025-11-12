# Orchestration Tests Script - README

## Overview

This automated test script (`run-orchestration-tests.sh`) comprehensively tests all Kubernetes orchestration capabilities of your K3s cluster.

## Tests Included

### ✅ Test 1: Self-Healing
- **What it tests:** Kubernetes automatically recreates deleted pods
- **How:** Deletes one Django pod and verifies automatic recreation
- **Success criteria:** Pod count restored, all pods ready within 120 seconds

### ✅ Test 2: Load Balancing
- **What it tests:** Traffic distribution across multiple pod replicas
- **How:** Sends 15 HTTP requests and tracks distribution
- **Success criteria:** 100% success rate, requests distributed across all pods

### ✅ Test 3: Scaling (Replica Management)
- **What it tests:** Dynamic horizontal scaling capabilities
- **How:** Scales deployment 3→5→3 replicas
- **Success criteria:** All replicas ready, correct final count

### ✅ Test 4: Rolling Update (Rollout)
- **What it tests:** Zero-downtime deployment updates
- **How:** Updates environment variables, monitors availability
- **Success criteria:** Update completes, no HTTP errors during rollout

### ✅ Test 5: Rollback
- **What it tests:** Instant recovery to previous deployment version
- **How:** Rolls back to previous revision, tests availability
- **Success criteria:** Rollback completes, no HTTP errors

---

## Prerequisites

Before running the script, ensure:

1. ✅ K3s cluster is running (master + workers)
2. ✅ Application is deployed in `elevatelearning` namespace
3. ✅ SSH key is available at `mykeys/remote-server-myproject`
4. ✅ You can SSH to master node: `34.87.248.125`

---

## Usage

### Quick Start

```bash
# Navigate to project directory
cd /path/to/INFS7202

# Run the test script
./run-orchestration-tests.sh
```

### What to Expect

1. **Pre-Test Checks** - Verifies SSH connection, cluster status, namespace
2. **Initial State** - Shows current cluster and pod status
3. **5 Automated Tests** - Each test runs sequentially with clear output
4. **Final Summary** - Shows pass/fail status for all tests

### Sample Output

```
╔════════════════════════════════════════════════════════╗
║     KUBERNETES ORCHESTRATION TEST SUITE                ║
╚════════════════════════════════════════════════════════╝

=== PRE-TEST CHECKS ===
✅ SSH connection: OK
✅ Namespace 'elevatelearning' exists

=== TEST 1: SELF-HEALING ===
Deleting pod: django-web-84c8b5dddb-xxxxx
✅ Self-Healing Test PASSED - Pod automatically recreated

=== TEST 2: LOAD BALANCING ===
Request 1: HTTP 200 ✓
Request 2: HTTP 200 ✓
...
✅ Load Balancing Test PASSED - 100% success rate

=== TEST SUMMARY ===
Total Tests: 5
Passed: 5
Failed: 0

✅ ALL TESTS PASSED! 🎉
```

---

## Configuration

You can customize the script by editing these variables at the top:

```bash
MASTER_IP="34.87.248.125"          # Your master node IP
SSH_KEY="mykeys/remote-server-myproject"  # Path to SSH key
SSH_USER="t_abhishek345"           # SSH username
NAMESPACE="elevatelearning"        # Kubernetes namespace
DEPLOYMENT="django-web"            # Deployment to test
```

---

## Troubleshooting

### Issue: "Permission denied" error
```bash
# Make script executable
chmod +x run-orchestration-tests.sh
```

### Issue: "SSH connection failed"
```bash
# Verify SSH key path
ls -la mykeys/remote-server-myproject

# Test SSH manually
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125
```

### Issue: "Namespace not found"
```bash
# Verify namespace exists
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get namespace"
```

### Issue: Tests timeout
- Increase timeout values in script (default: 120-180 seconds)
- Check if pods are stuck in pending/error state
- Verify cluster has sufficient resources

---

## Features

### Color-Coded Output
- 🔵 **Blue**: Section headers
- 🟢 **Green**: Success messages
- 🔴 **Red**: Error messages
- 🟡 **Yellow**: Information messages

### Timing Metrics
- Each test reports execution time
- Useful for performance analysis
- Shows scaling/rollout duration

### Comprehensive Verification
- Checks pod status before/after
- Verifies HTTP availability
- Confirms rollout history
- Tests zero-downtime claims

---

## Advanced Usage

### Run Specific Test

Edit the `main()` function to comment out unwanted tests:

```bash
# Run only scaling test
test_scaling
```

### Change Number of Requests

For load balancing test, modify:

```bash
REQUESTS=15  # Change to 30, 50, etc.
```

### Save Test Results

```bash
# Save output to file
./run-orchestration-tests.sh | tee test-results-$(date +%Y%m%d-%H%M%S).log
```

---

## Script Structure

```
run-orchestration-tests.sh
├── Configuration Variables
├── Helper Functions
│   ├── print_header()
│   ├── print_success()
│   ├── run_ssh_command()
│   └── test_passed/failed()
├── Pre-Test Checks
│   ├── SSH connection
│   ├── Cluster status
│   └── Namespace verification
├── Test Functions
│   ├── test_self_healing()
│   ├── test_load_balancing()
│   ├── test_scaling()
│   ├── test_rollout()
│   └── test_rollback()
├── Summary Function
└── Main Execution
```

---

## Test Results Tracking

The script tracks:
- ✅ Tests passed count
- ❌ Tests failed count
- ⏱️ Execution time per test
- 📊 Success rate percentages

---

## Exit Codes

- `0` - All tests passed
- `1` - One or more tests failed
- `1` - Pre-test checks failed

---

## Integration with CI/CD

This script can be integrated into CI/CD pipelines:

```bash
# GitHub Actions example
- name: Run Orchestration Tests
  run: |
    chmod +x run-orchestration-tests.sh
    ./run-orchestration-tests.sh
```

---

## Example Test Session

```bash
$ ./run-orchestration-tests.sh

╔════════════════════════════════════════════════════════╗
║     KUBERNETES ORCHESTRATION TEST SUITE                ║
╚════════════════════════════════════════════════════════╝

Testing K3s cluster orchestration capabilities
Master Node: 34.87.248.125
Namespace: elevatelearning

Press Enter to start tests (or Ctrl+C to cancel)...

=== PRE-TEST CHECKS ===
✅ SSH connection: OK
Nodes in cluster: 3
✅ Namespace 'elevatelearning' exists

[Tests run automatically...]

╔════════════════════════════════════════════════════════╗
║           ORCHESTRATION TESTS COMPLETE                 ║
╚════════════════════════════════════════════════════════╝

Total Tests: 5
Passed: 5
Failed: 0

✅ ALL TESTS PASSED! 🎉
```

---

## Notes

- **Non-Destructive**: Tests don't permanently modify your deployment
- **Automated**: No manual intervention needed after starting
- **Comprehensive**: Covers all major orchestration features
- **Production-Safe**: Uses kubectl commands safely
- **Time Required**: Approximately 8-12 minutes for full test suite

---

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review test output for specific error messages
3. Verify cluster is healthy: `kubectl get nodes`
4. Check pod status: `kubectl get pods -n elevatelearning`

---

**Author:** Abhishek Tanguturi (s4845110)  
**Date:** October 30, 2025  
**Version:** 1.0  
**License:** Educational Use
