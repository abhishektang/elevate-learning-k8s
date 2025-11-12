# Screenshot Guide for Assignment Submission

## 📸 Required Screenshots & Commands

### 1. Cluster Nodes Overview
**What to show**: 3-node cluster (1 master + 2 workers) all in Ready status

**Command**:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get nodes -o wide"
```

**Expected Output**:
```
NAME       STATUS   ROLES                  AGE   VERSION
master     Ready    control-plane,master   73m   v1.33.5+k3s1
worker-1   Ready    <none>                 51m   v1.33.5+k3s1
worker-2   Ready    <none>                 51m   v1.33.5+k3s1
```

---

### 2. Pod Distribution Across Nodes
**What to show**: 5 pods (3 Django, 1 MySQL, 1 Nginx) distributed across workers

**Command**:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get pods -n elevatelearning -o wide"
```

**Expected Output**:
```
NAME                          READY   STATUS    NODE
django-web-5d446d7b47-dt99q   1/1     Running   worker-1
django-web-5d446d7b47-fv66j   1/1     Running   worker-1
django-web-5d446d7b47-lrnck   1/1     Running   worker-2
mysql-7c856546c-9kj7n         1/1     Running   worker-2
nginx-5ccfbc5f77-p6n5h        1/1     Running   worker-1
```

---

### 3. Services & Load Balancing
**What to show**: 3 services with ClusterIP and NodePort types

**Command**:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get svc -n elevatelearning"
```

**Expected Output**:
```
NAME             TYPE        CLUSTER-IP     PORT(S)
django-service   ClusterIP   10.43.73.10    8000/TCP
mysql-service    ClusterIP   10.43.35.241   3306/TCP
nginx-service    NodePort    10.43.11.28    80:30080/TCP
```

---

### 4. Deployments Status
**What to show**: 3 deployments all ready and available

**Command**:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get deployments -n elevatelearning"
```

**Expected Output**:
```
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
django-web   3/3     3            3           38m
mysql        1/1     1            1           39m
nginx        1/1     1            1           13m
```

---

### 5. Application Homepage
**What to show**: Elevate Learning homepage accessible via browser

**URL**: `http://34.87.248.125:30080/elevatelearning/home/`

**Note**: You need to create the firewall rule first:
1. Go to GCP Console → VPC Network → Firewall
2. Create rule: Name=`allow-k8s-nodeport`, TCP port=`30080`, Source=`0.0.0.0/0`

**What should be visible**:
- Elevate Learning logo
- Navigation menu
- Homepage content
- No error messages

---

### 6. Django Admin Panel
**What to show**: Admin login page accessible

**URL**: `http://34.87.248.125:30080/admin/`

**Credentials**:
- Username: `admin`
- Password: `admin123`

**What should be visible**:
- Django administration login page
- Authentication form
- Django version info

---

### 7. Scaling Demonstration (Before)
**What to show**: Initial state before scaling

**Command**:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get pods -n elevatelearning | grep django-web"
```

**Expected**: 3 Django pods running

---

### 8. Scaling Demonstration (During)
**What to show**: Scaling operation in progress

**Commands**:
```bash
# Scale up to 5 replicas
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl scale deployment django-web --replicas=5 -n elevatelearning"

# Watch the scaling happen
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get pods -n elevatelearning -w"
```

**Expected**: See pods in "ContainerCreating" status

---

### 9. Scaling Demonstration (After)
**What to show**: 5 Django pods all running

**Command**:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get pods -n elevatelearning | grep django-web"
```

**Expected**: 5 Django pods all showing `1/1 Running`

---

### 10. Self-Healing Demo (Before)
**What to show**: Current pod state before deletion

**Command**:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get pods -n elevatelearning -o wide"
```

**Note the pod names and ages**

---

### 11. Self-Healing Demo (Delete Pod)
**What to show**: Pod deletion command

**Commands**:
```bash
# Get a pod name
POD_NAME=$(ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get pods -n elevatelearning -l app=django-web -o jsonpath='{.items[0].metadata.name}'")

# Delete the pod
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl delete pod $POD_NAME -n elevatelearning"
```

**Expected**: "pod deleted" message

---

### 12. Self-Healing Demo (After)
**What to show**: New pod automatically created

**Command**:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get pods -n elevatelearning -o wide"
```

**Expected**: 
- Original pod missing
- New pod with different name/age
- Same total number of pods maintained

---

### 13. Deployment Details
**What to show**: Deployment configuration and strategy

**Command**:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl describe deployment django-web -n elevatelearning"
```

**Key sections to capture**:
- Replicas: 3 desired, 3 current
- StrategyType: RollingUpdate
- Pod Template (image, resources, health checks)
- Events

---

### 14. Service Discovery Test
**What to show**: Internal DNS resolution working

**Command**:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl exec -n elevatelearning deployment/django-web -- nc -zv mysql-service 3306"
```

**Expected**: 
```
mysql-service.elevatelearning.svc.cluster.local [10.43.35.241] 3306 (mysql) open
```

---

### 15. Resource Limits
**What to show**: CPU and memory limits configured

**Command**:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl describe deployment django-web -n elevatelearning | grep -A 10 'Limits'"
```

**Expected**:
```
Limits:
  cpu:     500m
  memory:  1Gi
Requests:
  cpu:      250m
  memory:   512Mi
```

---

### 16. Health Probes Configuration
**What to show**: Liveness and readiness probes

**Command**:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl describe deployment django-web -n elevatelearning | grep -A 3 'Liveness\\|Readiness'"
```

**Expected**:
```
Liveness:   http-get http://:8000/elevatelearning/home/ delay=60s timeout=1s period=10s
Readiness:  http-get http://:8000/elevatelearning/home/ delay=30s timeout=1s period=5s
```

---

### 17. Complete Cluster Overview
**What to show**: All resources in one view

**Command**:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get all -n elevatelearning -o wide"
```

**Expected**: Shows pods, services, deployments, and replicasets

---

### 18. Load Balancing Test
**What to show**: Multiple successful requests

**Command**:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "for i in {1..10}; do curl -s http://localhost:30080/elevatelearning/home/ -I | grep HTTP; done"
```

**Expected**: 10 lines of `HTTP/1.1 200 OK`

---

### 19. ConfigMap Contents
**What to show**: Configuration management

**Command**:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get configmap elevatelearning-config -n elevatelearning -o yaml"
```

**Key data to show**:
- DB_HOST: mysql-service
- DB_NAME: elevatelearning_db
- CSRF_TRUSTED_ORIGINS

---

### 20. Persistent Volume
**What to show**: PVC for MySQL data

**Command**:
```bash
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get pvc -n elevatelearning"
```

**Expected**:
```
NAME        STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS
mysql-pvc   Bound    pvc-xxx   10Gi       RWO            local-path
```

---

## 🎯 Quick Screenshot Checklist

- [ ] 1. Cluster nodes (3 nodes Ready)
- [ ] 2. Pods distribution (5 pods across workers)
- [ ] 3. Services (ClusterIP + NodePort)
- [ ] 4. Deployments (3/3 ready)
- [ ] 5. Homepage in browser
- [ ] 6. Admin panel in browser
- [ ] 7. Before scaling (3 pods)
- [ ] 8. During scaling (ContainerCreating)
- [ ] 9. After scaling (5 pods)
- [ ] 10. Before pod deletion
- [ ] 11. Pod deletion command
- [ ] 12. After deletion (self-healing)
- [ ] 13. Deployment details
- [ ] 14. Service discovery test
- [ ] 15. Resource limits
- [ ] 16. Health probes
- [ ] 17. Complete overview
- [ ] 18. Load balancing test
- [ ] 19. ConfigMap
- [ ] 20. Persistent volume

---

## 📝 Notes

1. **Firewall Rule Required**: Before taking browser screenshots, create the GCP firewall rule for port 30080
2. **Terminal Font**: Use a clear, readable terminal font
3. **Full Screen**: Capture full terminal output, avoid truncation
4. **Timestamps**: Include command execution timestamps if possible
5. **Colors**: Terminal colors help distinguish output types
6. **Organization**: Name screenshots clearly (e.g., `01_cluster_nodes.png`)

---

## 🚀 Complete Test Sequence

Run this sequence to demonstrate all features:

```bash
# 1. Show initial state
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get all -n elevatelearning -o wide"

# 2. Scale up
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl scale deployment django-web --replicas=5 -n elevatelearning"

# 3. Watch scaling
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get pods -n elevatelearning -w"
# Press Ctrl+C after seeing all 5 pods Running

# 4. Delete a pod (self-healing)
POD=$(ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get pods -n elevatelearning -l app=django-web -o jsonpath='{.items[0].metadata.name}'")
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl delete pod $POD -n elevatelearning"

# 5. Watch self-healing
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get pods -n elevatelearning -w"
# Press Ctrl+C after seeing replacement pod Running

# 6. Test load balancing
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "for i in {1..20}; do curl -s http://localhost:30080/elevatelearning/home/ -I | grep HTTP; done"

# 7. Test service discovery
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl exec -n elevatelearning deployment/django-web -- nc -zv mysql-service 3306"

# 8. Scale back to 3
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl scale deployment django-web --replicas=3 -n elevatelearning"

# 9. Final state
ssh -i mykeys/remote-server-myproject t_abhishek345@34.87.248.125 "kubectl get all -n elevatelearning -o wide"
```

---

**Prepared by**: Abhishek Tanguturi (s4845110)  
**Date**: October 22, 2025
