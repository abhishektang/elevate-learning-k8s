#!/bin/bash
###############################################################################
# K3s Master Node Installation Script
# This script installs K3s on the master/control plane node
###############################################################################

set -e

echo "=========================================="
echo "K3s Master Node Installation"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run with sudo${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Stopping Docker Compose (if running)...${NC}"
cd ~/elevatelearning 2>/dev/null || true
sg docker -c 'docker-compose down' 2>/dev/null || true

echo -e "${YELLOW}Step 2: Installing K3s as master node...${NC}"
curl -sfL https://get.k3s.io | sh -s - server \
  --write-kubeconfig-mode 644 \
  --disable traefik \
  --node-name master \
  --flannel-backend=vxlan

echo -e "${YELLOW}Step 3: Waiting for K3s to be ready...${NC}"
sleep 10

# Check K3s status
systemctl status k3s --no-pager || true

echo -e "${YELLOW}Step 4: Verifying installation...${NC}"
kubectl get nodes

echo -e "${GREEN}=========================================="
echo "K3s Master Installation Complete!"
echo "==========================================${NC}"

echo ""
echo -e "${YELLOW}IMPORTANT: Save this token for worker nodes:${NC}"
echo "-------------------------------------------"
cat /var/lib/rancher/k3s/server/node-token
echo "-------------------------------------------"

echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. Copy the token above"
echo "2. Note your master node IP: $(hostname -I | awk '{print $1}')"
echo "3. Run the worker installation script on worker nodes"
echo ""
echo -e "${YELLOW}To add a worker node, run this on the worker:${NC}"
echo "curl -sfL https://get.k3s.io | K3S_URL=https://$(hostname -I | awk '{print $1}'):6443 K3S_TOKEN=<YOUR_TOKEN> sh -s - agent --node-name worker-1"
