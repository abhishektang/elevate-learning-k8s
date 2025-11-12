#!/bin/bash
###############################################################################
# Deploy Elevate Learning to Kubernetes
# Run this script on the master node after K3s cluster is set up
###############################################################################

set -e

echo "=========================================="
echo "Deploying Elevate Learning to Kubernetes"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run with sudo${NC}"
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl not found. Is K3s installed?${NC}"
    exit 1
fi

K8S_DIR="$HOME/elevatelearning/k8s"

if [ ! -d "$K8S_DIR" ]; then
    echo -e "${RED}K8s manifests directory not found: $K8S_DIR${NC}"
    exit 1
fi

cd $K8S_DIR

echo -e "${BLUE}Step 1: Verify cluster status...${NC}"
kubectl get nodes
echo ""

echo -e "${BLUE}Step 2: Create namespace...${NC}"
kubectl apply -f namespace.yaml
echo ""

echo -e "${BLUE}Step 3: Create ConfigMap and Secrets...${NC}"
kubectl apply -f configmap.yaml
echo ""

echo -e "${BLUE}Step 4: Deploy MySQL database...${NC}"
kubectl apply -f mysql-deployment.yaml
echo ""

echo -e "${YELLOW}Waiting for MySQL to be ready (this may take 2-3 minutes)...${NC}"
kubectl wait --for=condition=ready pod -l app=mysql -n elevatelearning --timeout=300s || {
    echo -e "${RED}MySQL pod failed to start. Checking logs:${NC}"
    kubectl logs -l app=mysql -n elevatelearning --tail=50
    exit 1
}
echo -e "${GREEN}✓ MySQL is ready${NC}"
echo ""

echo -e "${BLUE}Step 5: Deploy Django web application (2 replicas)...${NC}"
kubectl apply -f django-deployment.yaml
echo ""

echo -e "${YELLOW}Waiting for Django pods to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=django-web -n elevatelearning --timeout=300s || {
    echo -e "${RED}Django pods failed to start. Checking logs:${NC}"
    kubectl logs -l app=django-web -n elevatelearning --tail=50
    exit 1
}
echo -e "${GREEN}✓ Django pods are ready${NC}"
echo ""

echo -e "${BLUE}Step 6: Deploy Nginx load balancer...${NC}"
kubectl apply -f nginx-deployment.yaml
echo ""

echo -e "${YELLOW}Waiting for Nginx to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=nginx -n elevatelearning --timeout=180s || true
echo -e "${GREEN}✓ Nginx is ready${NC}"
echo ""

echo -e "${GREEN}=========================================="
echo "Deployment Complete!"
echo "==========================================${NC}"
echo ""

echo -e "${BLUE}Cluster Status:${NC}"
kubectl get nodes
echo ""

echo -e "${BLUE}Pod Distribution:${NC}"
kubectl get pods -n elevatelearning -o wide
echo ""

echo -e "${BLUE}Services:${NC}"
kubectl get svc -n elevatelearning
echo ""

# Get NodePort
NODEPORT=$(kubectl get svc nginx-service -n elevatelearning -o jsonpath='{.spec.ports[0].nodePort}')
MASTER_IP=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}=========================================="
echo "Application Access Information"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}Public URL:${NC}"
echo "  http://${MASTER_IP}:${NODEPORT}/elevatelearning/home/"
echo ""
echo -e "${YELLOW}Admin Panel:${NC}"
echo "  http://${MASTER_IP}:${NODEPORT}/elevatelearning/admin/"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo -e "${YELLOW}Login Page:${NC}"
echo "  http://${MASTER_IP}:${NODEPORT}/elevatelearning/login/"
echo ""

echo -e "${BLUE}Useful Commands:${NC}"
echo "  View pods:        sudo kubectl get pods -n elevatelearning -o wide"
echo "  View logs:        sudo kubectl logs -l app=django-web -n elevatelearning"
echo "  Scale replicas:   sudo kubectl scale deployment django-web -n elevatelearning --replicas=3"
echo "  Delete pod:       sudo kubectl delete pod <pod-name> -n elevatelearning"
echo "  Describe pod:     sudo kubectl describe pod <pod-name> -n elevatelearning"
echo ""

echo -e "${GREEN}🎉 Your application is now running on Kubernetes with orchestration!${NC}"
