#!/bin/bash
# Deploy Kubernetes Control Plane with Calico, cert-manager, and CoreDNS
# This script sets up a complete self-managed Kubernetes cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        error "Terraform is not installed. Please install Terraform first."
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed. Please install AWS CLI first."
    fi
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS credentials are not configured. Please run 'aws configure' first."
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        warn "kubectl is not installed. It will be installed on the control plane nodes."
    fi
    
    # Check if Helm is installed
    if ! command -v helm &> /dev/null; then
        warn "Helm is not installed. It will be installed on the control plane nodes."
    fi
    
    log "✅ Prerequisites check completed"
}

# Function to validate Terraform configuration
validate_terraform() {
    log "Validating Terraform configuration..."
    
    # Initialize Terraform
    terraform init
    
    # Validate configuration
    if ! terraform validate; then
        error "Terraform configuration validation failed"
    fi
    
    log "✅ Terraform configuration is valid"
}

# Function to plan Terraform deployment
plan_terraform() {
    log "Planning Terraform deployment..."
    
    # Create plan file
    terraform plan -out=kubernetes-control-plane.tfplan
    
    log "✅ Terraform plan created"
    log "📋 Review the plan and run: terraform apply kubernetes-control-plane.tfplan"
}

# Function to apply Terraform deployment
apply_terraform() {
    log "Applying Terraform deployment..."
    
    # Check if plan file exists
    if [ ! -f "kubernetes-control-plane.tfplan" ]; then
        error "Plan file not found. Run 'terraform plan -out=kubernetes-control-plane.tfplan' first."
    fi
    
    # Apply the plan
    terraform apply kubernetes-control-plane.tfplan
    
    log "✅ Terraform deployment completed"
}

# Function to wait for control plane instances
wait_for_instances() {
    log "Waiting for control plane instances to be ready..."
    
    # Get instance IDs
    local instance_ids=$(aws ec2 describe-instances \
        --filters "Name=tag:Role,Values=kubernetes-control-plane" \
        --query 'Reservations[*].Instances[*].[InstanceId]' \
        --output text)
    
    if [ -z "$instance_ids" ]; then
        error "No control plane instances found"
    fi
    
    log "Found control plane instances: $instance_ids"
    
    # Wait for instances to be running
    for instance_id in $instance_ids; do
        log "Waiting for instance $instance_id to be running..."
        aws ec2 wait instance-running --instance-ids "$instance_id"
        
        # Wait for status checks to pass
        log "Waiting for instance $instance_id status checks to pass..."
        aws ec2 wait instance-status-ok --instance-ids "$instance_id"
    done
    
    log "✅ All control plane instances are ready"
}

# Function to get control plane endpoint
get_control_plane_endpoint() {
    log "Getting control plane endpoint..."
    
    # Get the first control plane instance
    local instance_id=$(aws ec2 describe-instances \
        --filters "Name=tag:Role,Values=kubernetes-control-plane" \
        --query 'Reservations[0].Instances[0].[InstanceId]' \
        --output text)
    
    if [ "$instance_id" = "None" ] || [ -z "$instance_id" ]; then
        error "No control plane instances found"
    fi
    
    # Get public IP
    local public_ip=$(aws ec2 describe-instances \
        --instance-ids "$instance_id" \
        --query 'Reservations[0].Instances[0].[PublicIpAddress]' \
        --output text)
    
    if [ "$public_ip" = "None" ] || [ -z "$public_ip" ]; then
        error "Could not get public IP for instance $instance_id"
    fi
    
    echo "$public_ip"
}

# Function to configure kubectl
configure_kubectl() {
    log "Configuring kubectl..."
    
    local control_plane_ip=$(get_control_plane_endpoint)
    
    # Create kubeconfig directory
    mkdir -p ~/.kube
    
    # Download kubeconfig from control plane
    log "Downloading kubeconfig from control plane..."
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        ec2-user@${control_plane_ip}:/home/ec2-user/.kube/config ~/.kube/config
    
    # Test connection
    if kubectl cluster-info &> /dev/null; then
        log "✅ kubectl configured successfully"
    else
        warn "⚠️  kubectl configuration may need manual setup"
        log "📋 You may need to manually copy the kubeconfig from the control plane:"
        log "   scp ec2-user@${control_plane_ip}:/home/ec2-user/.kube/config ~/.kube/config"
    fi
}

# Function to verify cluster components
verify_cluster_components() {
    log "Verifying cluster components..."
    
    # Check nodes
    log "Checking nodes..."
    kubectl get nodes
    
    # Check pods
    log "Checking pods..."
    kubectl get pods --all-namespaces
    
    # Check services
    log "Checking services..."
    kubectl get services --all-namespaces
    
    # Check CoreDNS
    log "Checking CoreDNS..."
    kubectl get pods -n kube-system -l k8s-app=kube-dns
    
    # Check Calico
    log "Checking Calico..."
    kubectl get pods -n kube-system -l k8s-app=calico-node
    
    # Check cert-manager
    log "Checking cert-manager..."
    kubectl get pods -n cert-manager
    
    # Test DNS resolution
    log "Testing DNS resolution..."
    kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never -- nslookup kubernetes.default.svc.cluster.local || warn "DNS test failed"
    
    log "✅ Cluster components verification completed"
}

# Function to create test certificate
create_test_certificate() {
    log "Creating test certificate with cert-manager..."
    
    # Create test namespace
    kubectl create namespace cert-test --dry-run=client -o yaml | kubectl apply -f -
    
    # Create test certificate
    cat > /tmp/test-certificate.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-certificate
  namespace: cert-test
spec:
  secretName: test-certificate-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - test.${ENVIRONMENT}-${SERVICE_NAME}.${DOMAIN_NAME}
EOF
    
    kubectl apply -f /tmp/test-certificate.yaml
    
    # Wait for certificate to be ready
    log "Waiting for certificate to be ready..."
    kubectl wait --for=condition=ready --timeout=300s certificate/test-certificate -n cert-test
    
    log "✅ Test certificate created successfully"
}

# Function to display cluster information
display_cluster_info() {
    log "🎉 Kubernetes Control Plane Deployment Completed!"
    echo ""
    echo "📊 Cluster Information:"
    echo "   Environment: ${ENVIRONMENT}"
    echo "   Service: ${SERVICE_NAME}"
    echo "   Cluster Name: ${ENVIRONMENT}-${SERVICE_NAME}-cluster"
    echo "   Control Plane Endpoint: $(get_control_plane_endpoint):6443"
    echo ""
    echo "🔧 Installed Components:"
    echo "   ✅ Kubernetes Control Plane (3 nodes)"
    echo "   ✅ Calico CNI (v${CALICO_VERSION})"
    echo "   ✅ CoreDNS (configured)"
    echo "   ✅ cert-manager (v1.13.3)"
    echo "   ✅ Let's Encrypt ClusterIssuer"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Add worker nodes to the cluster"
    echo "   2. Deploy your Go MySQL API application"
    echo "   3. Configure ingress controller"
    echo "   4. Set up monitoring and logging"
    echo "   5. Configure backup and disaster recovery"
    echo ""
    echo "🔗 Useful Commands:"
    echo "   kubectl get nodes"
    echo "   kubectl get pods --all-namespaces"
    echo "   kubectl get certificates --all-namespaces"
    echo "   kubectl cluster-info"
    echo ""
}

# Main execution
main() {
    log "🚀 Starting Kubernetes Control Plane Deployment"
    
    # Source environment variables
    if [ -f ".env" ]; then
        source .env
    fi
    
    # Set default values
    ENVIRONMENT=${ENVIRONMENT:-"test"}
    SERVICE_NAME=${SERVICE_NAME:-"go-mysql-api"}
    CALICO_VERSION=${CALICO_VERSION:-"3.26.1"}
    DOMAIN_NAME=${DOMAIN_NAME:-"example.com"}
    
    log "Environment: $ENVIRONMENT"
    log "Service: $SERVICE_NAME"
    log "Calico Version: $CALICO_VERSION"
    log "Domain: $DOMAIN_NAME"
    
    # Check prerequisites
    check_prerequisites
    
    # Validate Terraform
    validate_terraform
    
    # Plan deployment
    plan_terraform
    
    # Ask for confirmation
    echo ""
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Deployment cancelled"
        exit 0
    fi
    
    # Apply deployment
    apply_terraform
    
    # Wait for instances
    wait_for_instances
    
    # Configure kubectl
    configure_kubectl
    
    # Verify components
    verify_cluster_components
    
    # Create test certificate
    create_test_certificate
    
    # Display information
    display_cluster_info
    
    # Fun completion message
    if command -v cowsay &> /dev/null && command -v fortune &> /dev/null; then
        echo ""
        fortune | cowsay
    fi
}

# Run main function
main "$@"
