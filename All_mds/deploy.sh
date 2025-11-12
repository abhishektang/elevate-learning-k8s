#!/bin/bash

# Elevate Learning - Automated Deployment Script
# This script automates the deployment process on GCP

set -e

echo "=================================="
echo "Elevate Learning Deployment Script"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    print_success "Docker installed successfully"
    print_info "Please logout and login again, then run this script"
    exit 0
else
    print_success "Docker is installed"
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Installing..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed successfully"
else
    print_success "Docker Compose is installed"
fi

echo ""
echo "Select deployment method:"
echo "1) Docker Compose (Simple, recommended for development)"
echo "2) Docker Swarm (Scalable, good for production)"
echo "3) Kubernetes (Production-ready, advanced)"
echo ""
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        print_info "Deploying with Docker Compose..."
        
        # Build Docker image
        print_info "Building Docker image..."
        docker build -t elevatelearning-web:latest .
        print_success "Docker image built successfully"
        
        # Start services
        print_info "Starting services..."
        docker-compose up -d
        print_success "Services started successfully"
        
        # Wait for services to be ready
        print_info "Waiting for services to be ready..."
        sleep 10
        
        # Check status
        print_info "Checking service status..."
        docker-compose ps
        
        echo ""
        print_success "Deployment completed successfully!"
        echo ""
        print_info "Access your application at: http://$(curl -s ifconfig.me)"
        echo ""
        print_info "Useful commands:"
        echo "  - View logs: docker-compose logs -f"
        echo "  - Stop services: docker-compose down"
        echo "  - Restart services: docker-compose restart"
        ;;
        
    2)
        print_info "Deploying with Docker Swarm..."
        
        # Initialize Swarm if not already initialized
        if ! docker info | grep -q "Swarm: active"; then
            print_info "Initializing Docker Swarm..."
            docker swarm init
            print_success "Docker Swarm initialized"
        else
            print_success "Docker Swarm already initialized"
        fi
        
        # Build Docker image
        print_info "Building Docker image..."
        docker build -t elevatelearning-web:latest .
        print_success "Docker image built successfully"
        
        # Deploy stack
        print_info "Deploying stack..."
        docker stack deploy -c docker-compose.yml elevatelearning
        print_success "Stack deployed successfully"
        
        # Wait for services
        print_info "Waiting for services to be ready..."
        sleep 15
        
        # Check status
        print_info "Checking service status..."
        docker service ls
        
        echo ""
        print_success "Deployment completed successfully!"
        echo ""
        print_info "Access your application at: http://$(curl -s ifconfig.me)"
        echo ""
        print_info "Useful commands:"
        echo "  - View services: docker service ls"
        echo "  - View logs: docker service logs elevatelearning_web"
        echo "  - Scale service: docker service scale elevatelearning_web=3"
        echo "  - Remove stack: docker stack rm elevatelearning"
        ;;
        
    3)
        print_info "Deploying with Kubernetes..."
        
        # Check if kubectl is installed
        if ! command -v kubectl &> /dev/null; then
            print_error "kubectl is not installed. Installing K3s..."
            curl -sfL https://get.k3s.io | sh -
            mkdir -p ~/.kube
            sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
            sudo chown $USER:$USER ~/.kube/config
            export KUBECONFIG=~/.kube/config
            print_success "K3s installed successfully"
        else
            print_success "kubectl is installed"
        fi
        
        # Build Docker image
        print_info "Building Docker image..."
        docker build -t elevatelearning-web:latest .
        print_success "Docker image built successfully"
        
        # Apply Kubernetes configurations
        print_info "Applying Kubernetes configurations..."
        kubectl apply -f k8s/namespace.yaml
        kubectl apply -f k8s/configmap.yaml
        kubectl apply -f k8s/mysql-deployment.yaml
        
        print_info "Waiting for MySQL to be ready..."
        kubectl wait --for=condition=ready pod -l app=mysql -n elevatelearning --timeout=300s
        
        kubectl apply -f k8s/django-deployment.yaml
        kubectl apply -f k8s/nginx-deployment.yaml
        
        print_success "Kubernetes resources created successfully"
        
        # Wait for deployments
        print_info "Waiting for deployments to be ready..."
        kubectl wait --for=condition=available deployment/django-web -n elevatelearning --timeout=300s
        kubectl wait --for=condition=available deployment/nginx -n elevatelearning --timeout=300s
        
        # Patch service to NodePort for GCP
        print_info "Configuring service access..."
        kubectl patch svc nginx-service -n elevatelearning -p '{"spec":{"type":"NodePort"}}'
        
        # Get service details
        NODEPORT=$(kubectl get svc nginx-service -n elevatelearning -o jsonpath='{.spec.ports[0].nodePort}')
        
        echo ""
        print_success "Deployment completed successfully!"
        echo ""
        print_info "Access your application at: http://$(curl -s ifconfig.me):${NODEPORT}"
        echo ""
        print_info "Useful commands:"
        echo "  - View all resources: kubectl get all -n elevatelearning"
        echo "  - View logs: kubectl logs -f deployment/django-web -n elevatelearning"
        echo "  - Scale deployment: kubectl scale deployment django-web --replicas=3 -n elevatelearning"
        echo "  - Delete all: kubectl delete namespace elevatelearning"
        ;;
        
    *)
        print_error "Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo ""
print_info "Default credentials:"
echo "  - Admin username: admin"
echo "  - Admin password: admin123"
echo ""
print_info "Please change default passwords for production use!"
