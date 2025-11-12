#!/bin/bash
###############################################################################
# Prepare and Distribute Docker Image to Worker Nodes
# Run this on the master node
###############################################################################

set -e

echo "=========================================="
echo "Docker Image Distribution"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check arguments
if [ "$#" -lt 2 ]; then
    echo -e "${RED}Usage: $0 <WORKER1_IP> <WORKER2_IP> [SSH_KEY_PATH] [USERNAME]${NC}"
    echo ""
    echo "Example:"
    echo "  $0 10.0.1.2 10.0.1.3"
    echo "  $0 10.0.1.2 10.0.1.3 ~/.ssh/id_rsa username"
    exit 1
fi

WORKER1_IP=$1
WORKER2_IP=$2
SSH_KEY=${3:-"$HOME/.ssh/id_rsa"}
SSH_USER=${4:-"$(whoami)"}

APP_DIR="$HOME/elevatelearning"
IMAGE_NAME="elevatelearning-web:latest"
IMAGE_FILE="elevatelearning-web.tar"

echo -e "${YELLOW}Configuration:${NC}"
echo "  Worker 1 IP: $WORKER1_IP"
echo "  Worker 2 IP: $WORKER2_IP"
echo "  SSH Key: $SSH_KEY"
echo "  SSH User: $SSH_USER"
echo "  Image: $IMAGE_NAME"
echo ""

cd $APP_DIR

echo -e "${BLUE}Step 1: Building Docker image...${NC}"
sudo docker build -t $IMAGE_NAME .
echo -e "${GREEN}✓ Image built${NC}"
echo ""

echo -e "${BLUE}Step 2: Saving image to tar file...${NC}"
sudo docker save $IMAGE_NAME -o $IMAGE_FILE
sudo chmod 644 $IMAGE_FILE
echo -e "${GREEN}✓ Image saved to $IMAGE_FILE${NC}"
echo ""

echo -e "${BLUE}Step 3: Copying image to Worker 1 ($WORKER1_IP)...${NC}"
scp -i $SSH_KEY $IMAGE_FILE $SSH_USER@$WORKER1_IP:~/
echo -e "${GREEN}✓ Copied to Worker 1${NC}"
echo ""

echo -e "${BLUE}Step 4: Copying image to Worker 2 ($WORKER2_IP)...${NC}"
scp -i $SSH_KEY $IMAGE_FILE $SSH_USER@$WORKER2_IP:~/
echo -e "${GREEN}✓ Copied to Worker 2${NC}"
echo ""

echo -e "${BLUE}Step 5: Importing image on Worker 1...${NC}"
ssh -i $SSH_KEY $SSH_USER@$WORKER1_IP "sudo ctr -n k8s.io images import ~/$IMAGE_FILE && echo 'Image imported on Worker 1'"
echo -e "${GREEN}✓ Imported on Worker 1${NC}"
echo ""

echo -e "${BLUE}Step 6: Importing image on Worker 2...${NC}"
ssh -i $SSH_KEY $SSH_USER@$WORKER2_IP "sudo ctr -n k8s.io images import ~/$IMAGE_FILE && echo 'Image imported on Worker 2'"
echo -e "${GREEN}✓ Imported on Worker 2${NC}"
echo ""

echo -e "${BLUE}Step 7: Verifying image on workers...${NC}"
echo "Worker 1:"
ssh -i $SSH_KEY $SSH_USER@$WORKER1_IP "sudo ctr -n k8s.io images ls | grep elevatelearning || echo 'Image not found!'"
echo ""
echo "Worker 2:"
ssh -i $SSH_KEY $SSH_USER@$WORKER2_IP "sudo ctr -n k8s.io images ls | grep elevatelearning || echo 'Image not found!'"
echo ""

echo -e "${BLUE}Step 8: Cleaning up tar file on workers...${NC}"
ssh -i $SSH_KEY $SSH_USER@$WORKER1_IP "rm -f ~/$IMAGE_FILE"
ssh -i $SSH_KEY $SSH_USER@$WORKER2_IP "rm -f ~/$IMAGE_FILE"
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

echo -e "${GREEN}=========================================="
echo "Image Distribution Complete!"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}Next step:${NC}"
echo "  Run: sudo bash ~/elevatelearning/k8s/deploy-to-k8s.sh"
echo ""
