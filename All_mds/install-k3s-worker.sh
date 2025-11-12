#!/bin/bash
###############################################################################
# K3s Worker Node Installation Script
# This script installs K3s agent on worker nodes
###############################################################################

set -e

echo "=========================================="
echo "K3s Worker Node Installation"
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

# Check for required arguments
if [ "$#" -ne 3 ]; then
    echo -e "${RED}Usage: sudo $0 <MASTER_IP> <TOKEN> <WORKER_NAME>${NC}"
    echo ""
    echo "Example:"
    echo "  sudo $0 35.244.96.92 K10abc123... worker-1"
    echo ""
    exit 1
fi

MASTER_IP=$1
K3S_TOKEN=$2
WORKER_NAME=$3

echo -e "${YELLOW}Configuration:${NC}"
echo "  Master IP: $MASTER_IP"
echo "  Worker Name: $WORKER_NAME"
echo "  Token: ${K3S_TOKEN:0:20}..."
echo ""

echo -e "${YELLOW}Step 1: Installing K3s agent...${NC}"
curl -sfL https://get.k3s.io | K3S_URL=https://${MASTER_IP}:6443 \
  K3S_TOKEN=${K3S_TOKEN} \
  sh -s - agent --node-name ${WORKER_NAME}

echo -e "${YELLOW}Step 2: Waiting for K3s agent to be ready...${NC}"
sleep 10

# Check K3s agent status
systemctl status k3s-agent --no-pager || true

echo -e "${GREEN}=========================================="
echo "K3s Worker Installation Complete!"
echo "==========================================${NC}"

echo ""
echo -e "${GREEN}This worker node (${WORKER_NAME}) should now appear in the cluster.${NC}"
echo ""
echo -e "${YELLOW}On the master node, run:${NC}"
echo "  sudo kubectl get nodes"
echo ""
