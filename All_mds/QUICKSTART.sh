#!/bin/bash
###############################################################################
# Quick Start Guide for K3s Cluster Setup
# This script provides step-by-step instructions
###############################################################################

cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║           Elevate Learning - K3s Cluster Setup Guide                    ║
║                    3-Node Kubernetes Deployment                          ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝

📋 PREREQUISITES CHECKLIST:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

□ 3 VM instances created (1 master + 2 workers)
□ All VMs running Ubuntu 20.04 or newer
□ SSH access configured to all nodes
□ Port 6443 open for K3s communication
□ At least 2 CPUs and 4GB RAM per node

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


🚀 STEP-BY-STEP SETUP INSTRUCTIONS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1: Create Worker Nodes in GCP
──────────────────────────────────────────────────────────────────────────

Option A - Using GCP Console:
  1. Go to Compute Engine → VM Instances
  2. Click "Create Instance"
  3. Settings:
     - Name: elevatelearning-worker-1
     - Region: Same as master (australia-southeast1)
     - Machine type: e2-standard-2
     - Boot disk: Ubuntu 20.04 LTS, 20GB
     - Firewall: ✓ Allow HTTP traffic
  4. Click "Create"
  5. Repeat for worker-2

Option B - Using gcloud CLI:
  
  gcloud compute instances create elevatelearning-worker-1 \
    --zone=australia-southeast1-a \
    --machine-type=e2-standard-2 \
    --image-family=ubuntu-2004-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=20GB \
    --tags=http-server

  gcloud compute instances create elevatelearning-worker-2 \
    --zone=australia-southeast1-a \
    --machine-type=e2-standard-2 \
    --image-family=ubuntu-2004-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=20GB \
    --tags=http-server

──────────────────────────────────────────────────────────────────────────

STEP 2: Setup SSH Access to Workers
──────────────────────────────────────────────────────────────────────────

From your local machine:

  # Get worker IPs from GCP console, then:
  export WORKER1_IP=<WORKER_1_INTERNAL_IP>
  export WORKER2_IP=<WORKER_2_INTERNAL_IP>
  
  # Copy SSH key to workers (run from your master node)
  ssh-copy-id -i ~/.ssh/remote-server-myproject.pub t_abhishek345@$WORKER1_IP
  ssh-copy-id -i ~/.ssh/remote-server-myproject.pub t_abhishek345@$WORKER2_IP
  
  # Test SSH connection
  ssh t_abhishek345@$WORKER1_IP "echo 'Worker 1 connected'"
  ssh t_abhishek345@$WORKER2_IP "echo 'Worker 2 connected'"

──────────────────────────────────────────────────────────────────────────

STEP 3: Install K3s on Master Node (35.244.96.92)
──────────────────────────────────────────────────────────────────────────

SSH into master node:

  ssh -i ../mykeys/remote-server-myproject t_abhishek345@35.244.96.92

Transfer setup files:

  # From your local machine
  cd /Users/abhishektanguturi/Master_of_Information_Tech/Sem_3_2025/INFS7202/s4845110_Abhishek_Tanguturi/ProjectCode/INFS7202/elevatelearning
  
  scp -i ../mykeys/remote-server-myproject -r k8s t_abhishek345@35.244.96.92:~/elevatelearning/

On the master node, run:

  cd ~/elevatelearning/k8s
  chmod +x *.sh
  sudo bash install-k3s-master.sh

⚠️  IMPORTANT: Copy the token that appears at the end!
   Example: K10abc123def456ghi789jkl012mno345pqr678stu901vwx::server:abc123

──────────────────────────────────────────────────────────────────────────

STEP 4: Install K3s on Worker Nodes
──────────────────────────────────────────────────────────────────────────

On Worker 1:

  ssh t_abhishek345@$WORKER1_IP
  
  # Replace <MASTER_IP> and <TOKEN> with your values
  curl -sfL https://get.k3s.io | \
    K3S_URL=https://35.244.96.92:6443 \
    K3S_TOKEN=<YOUR_TOKEN_HERE> \
    sh -s - agent --node-name worker-1

On Worker 2:

  ssh t_abhishek345@$WORKER2_IP
  
  curl -sfL https://get.k3s.io | \
    K3S_URL=https://35.244.96.92:6443 \
    K3S_TOKEN=<YOUR_TOKEN_HERE> \
    sh -s - agent --node-name worker-2

Verify cluster (on master):

  sudo kubectl get nodes
  
  # Expected output:
  # NAME       STATUS   ROLES                  AGE
  # master     Ready    control-plane,master   5m
  # worker-1   Ready    <none>                 2m
  # worker-2   Ready    <none>                 1m

──────────────────────────────────────────────────────────────────────────

STEP 5: Distribute Docker Image to Workers
──────────────────────────────────────────────────────────────────────────

On master node:

  cd ~/elevatelearning/k8s
  
  # Edit the script with your worker IPs
  bash distribute-image.sh $WORKER1_IP $WORKER2_IP ~/.ssh/id_rsa t_abhishek345

This will:
  ✓ Build Docker image
  ✓ Save to tar file
  ✓ Copy to worker nodes
  ✓ Import on worker nodes

──────────────────────────────────────────────────────────────────────────

STEP 6: Deploy Application to Kubernetes
──────────────────────────────────────────────────────────────────────────

On master node:

  cd ~/elevatelearning/k8s
  sudo bash deploy-to-k8s.sh

This will:
  ✓ Create namespace
  ✓ Deploy MySQL database
  ✓ Deploy Django app (2 replicas)
  ✓ Deploy Nginx load balancer
  ✓ Show access URLs

──────────────────────────────────────────────────────────────────────────

STEP 7: Verify Deployment
──────────────────────────────────────────────────────────────────────────

Check pods distribution:

  sudo kubectl get pods -n elevatelearning -o wide
  
  # You should see Django pods on worker-1 and worker-2

Check services:

  sudo kubectl get svc -n elevatelearning

Access application:

  # Get NodePort
  NODEPORT=$(sudo kubectl get svc nginx-service -n elevatelearning -o jsonpath='{.spec.ports[0].nodePort}')
  echo "Access at: http://35.244.96.92:$NODEPORT/elevatelearning/home/"

──────────────────────────────────────────────────────────────────────────

STEP 8: Demonstrate Orchestration Features
──────────────────────────────────────────────────────────────────────────

A) Scale replicas:
   sudo kubectl scale deployment django-web -n elevatelearning --replicas=3
   sudo kubectl get pods -n elevatelearning -o wide

B) Self-healing:
   # Delete a pod
   POD=$(sudo kubectl get pods -n elevatelearning -l app=django-web -o jsonpath='{.items[0].metadata.name}')
   sudo kubectl delete pod $POD -n elevatelearning
   
   # Watch it recreate
   sudo kubectl get pods -n elevatelearning -w

C) View logs:
   sudo kubectl logs -l app=django-web -n elevatelearning --tail=50

D) Load balancing test:
   for i in {1..10}; do
     curl http://localhost:$NODEPORT/elevatelearning/home/ | grep "Elevate Learning"
     echo "Request $i"
   done

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


📸 SCREENSHOTS FOR ASSIGNMENT:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Capture these commands and outputs:

1. ✓ sudo kubectl get nodes
   (Shows 3 nodes: master + 2 workers)

2. ✓ sudo kubectl get pods -n elevatelearning -o wide
   (Shows pods distributed across workers)

3. ✓ sudo kubectl get svc -n elevatelearning
   (Shows services and ports)

4. ✓ Browser screenshot of application running
   (Home page at http://35.244.96.92:NODEPORT/elevatelearning/home/)

5. ✓ sudo kubectl scale deployment django-web -n elevatelearning --replicas=3
   (Shows scaling in action)

6. ✓ Self-healing demonstration
   (Delete pod, watch recreation)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


🎯 SUCCESS CRITERIA:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ 3-node K3s cluster operational
✓ Django deployed with 2+ replicas
✓ Pods running on different worker nodes
✓ Application accessible via browser
✓ Load balancing working
✓ Self-healing demonstrated
✓ Scaling demonstrated

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


📚 USEFUL COMMANDS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Cluster Management:
  sudo kubectl get nodes
  sudo kubectl get pods -n elevatelearning
  sudo kubectl get svc -n elevatelearning
  sudo kubectl describe pod <pod-name> -n elevatelearning
  sudo kubectl logs <pod-name> -n elevatelearning
  sudo kubectl logs -l app=django-web -n elevatelearning

Scaling:
  sudo kubectl scale deployment django-web -n elevatelearning --replicas=<N>

Self-Healing Test:
  sudo kubectl delete pod <pod-name> -n elevatelearning
  sudo kubectl get pods -n elevatelearning -w

Port Forwarding (alternative access):
  sudo kubectl port-forward -n elevatelearning svc/nginx-service 8080:80 --address=0.0.0.0

Cleanup:
  sudo kubectl delete namespace elevatelearning

Uninstall K3s:
  sudo /usr/local/bin/k3s-uninstall.sh          # Master
  sudo /usr/local/bin/k3s-agent-uninstall.sh    # Workers

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


🆘 TROUBLESHOOTING:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Issue: Worker not joining cluster
  → Check: sudo systemctl status k3s-agent
  → Check: sudo journalctl -u k3s-agent -f
  → Verify: Port 6443 is open between nodes

Issue: Pods not starting
  → Check: sudo kubectl describe pod <pod-name> -n elevatelearning
  → Check logs: sudo kubectl logs <pod-name> -n elevatelearning

Issue: Image not found
  → Verify: sudo ctr -n k8s.io images ls | grep elevatelearning
  → Re-import: sudo ctr -n k8s.io images import ~/elevatelearning-web.tar

Issue: Can't access application
  → Check service: sudo kubectl get svc -n elevatelearning
  → Check pods: sudo kubectl get pods -n elevatelearning
  → Port forward: sudo kubectl port-forward -n elevatelearning svc/nginx-service 8080:80

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Need help? Refer to:
  • K3S_SETUP_GUIDE.md for detailed documentation
  • https://docs.k3s.io/ for K3s documentation
  • https://kubernetes.io/docs/ for Kubernetes documentation

Good luck! 🚀

EOF
