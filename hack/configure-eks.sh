#!/bin/bash

# Configure kubectl for EKS Cluster
# This script configures kubectl to connect to the EKS cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME=""
REGION=""

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c, --cluster-name NAME    EKS cluster name"
    echo "  -r, --region REGION        AWS region (default: from AWS CLI config)"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -c sandbox-go-mysql-api-cluster"
    echo "  $0 -c sandbox-go-mysql-api-cluster -r us-east-1"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--cluster-name)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if cluster name is provided
if [ -z "$CLUSTER_NAME" ]; then
    log_error "Cluster name is required. Use -c or --cluster-name option."
    show_usage
    exit 1
fi

# Check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    log_success "AWS CLI found"
}

# Check if kubectl is installed
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    log_success "kubectl found"
}

# Get AWS region
get_aws_region() {
    if [ -z "$REGION" ]; then
        REGION=$(aws configure get region)
        if [ -z "$REGION" ]; then
            log_error "AWS region not configured. Please set it with 'aws configure' or use --region option."
            exit 1
        fi
    fi
    log_info "Using AWS region: $REGION"
}

# Check if cluster exists
check_cluster_exists() {
    log_info "Checking if cluster '$CLUSTER_NAME' exists..."
    
    if aws eks describe-cluster --region "$REGION" --name "$CLUSTER_NAME" &> /dev/null; then
        log_success "Cluster '$CLUSTER_NAME' exists"
    else
        log_error "Cluster '$CLUSTER_NAME' does not exist in region '$REGION'"
        exit 1
    fi
}

# Get cluster status
get_cluster_status() {
    log_info "Getting cluster status..."
    
    CLUSTER_STATUS=$(aws eks describe-cluster --region "$REGION" --name "$CLUSTER_NAME" --query 'cluster.status' --output text)
    
    if [ "$CLUSTER_STATUS" = "ACTIVE" ]; then
        log_success "Cluster is ACTIVE"
    else
        log_error "Cluster is not ACTIVE. Current status: $CLUSTER_STATUS"
        exit 1
    fi
}

# Update kubeconfig
update_kubeconfig() {
    log_info "Updating kubeconfig for cluster '$CLUSTER_NAME'..."
    
    aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
    
    if [ $? -eq 0 ]; then
        log_success "kubeconfig updated successfully"
    else
        log_error "Failed to update kubeconfig"
        exit 1
    fi
}

# Test cluster connectivity
test_cluster_connectivity() {
    log_info "Testing cluster connectivity..."
    
    if kubectl cluster-info &> /dev/null; then
        log_success "Successfully connected to cluster"
        
        # Show cluster info
        echo ""
        log_info "Cluster Information:"
        kubectl cluster-info
        
        # Show nodes
        echo ""
        log_info "Cluster Nodes:"
        kubectl get nodes
        
        # Show namespaces
        echo ""
        log_info "Namespaces:"
        kubectl get namespaces
        
    else
        log_error "Failed to connect to cluster"
        exit 1
    fi
}

# Install Istio (optional)
install_istio() {
    read -p "Do you want to install Istio? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installing Istio..."
        
        # Check if istioctl is installed
        if ! command -v istioctl &> /dev/null; then
            log_warning "istioctl is not installed. Please install it first."
            log_info "You can install it with: curl -L https://istio.io/downloadIstio | sh -"
            return 1
        fi
        
        # Install Istio with demo profile
        istioctl install --set profile=demo -y
        
        if [ $? -eq 0 ]; then
            log_success "Istio installed successfully"
            
            # Show Istio components
            echo ""
            log_info "Istio Components:"
            kubectl get pods -n istio-system
            
            # Enable Istio injection for default namespace
            kubectl label namespace default istio-injection=enabled
            
        else
            log_error "Failed to install Istio"
            return 1
        fi
    else
        log_info "Skipping Istio installation"
    fi
}

# Install metrics server
install_metrics_server() {
    log_info "Installing metrics server..."
    
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    if [ $? -eq 0 ]; then
        log_success "Metrics server installed successfully"
        
        # Wait for metrics server to be ready
        log_info "Waiting for metrics server to be ready..."
        kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=300s
        
        # Test metrics
        if kubectl top nodes &> /dev/null; then
            log_success "Metrics server is working"
        else
            log_warning "Metrics server may not be fully ready yet"
        fi
    else
        log_error "Failed to install metrics server"
    fi
}

# Create namespace for the application
create_namespace() {
    log_info "Creating namespace for the application..."
    
    NAMESPACE="go-mysql-api"
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_info "Namespace '$NAMESPACE' already exists"
    else
        kubectl create namespace "$NAMESPACE"
        log_success "Namespace '$NAMESPACE' created"
    fi
    
    # Enable Istio injection if Istio is installed
    if kubectl get namespace istio-system &> /dev/null; then
        kubectl label namespace "$NAMESPACE" istio-injection=enabled --overwrite
        log_info "Istio injection enabled for namespace '$NAMESPACE'"
    fi
}

# Generate kubeconfig file
generate_kubeconfig() {
    log_info "Generating kubeconfig file..."
    
    cat > kubeconfig.yaml <<EOF
# Kubeconfig for EKS Cluster
apiVersion: v1
kind: Config
clusters:
- name: ${CLUSTER_NAME}
  cluster:
    server: $(kubectl config view --minify --output jsonpath='{.clusters[0].cluster.server}')
    certificate-authority-data: $(kubectl config view --minify --output jsonpath='{.clusters[0].cluster.certificate-authority-data}')

contexts:
- name: ${CLUSTER_NAME}
  context:
    cluster: ${CLUSTER_NAME}
    user: ${CLUSTER_NAME}

current-context: ${CLUSTER_NAME}

users:
- name: ${CLUSTER_NAME}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - eks
        - get-token
        - --cluster-name
        - ${CLUSTER_NAME}
        - --region
        - ${REGION}
EOF
    
    log_success "Kubeconfig file generated: kubeconfig.yaml"
}

# Main execution
main() {
    log_info "Configuring kubectl for EKS Cluster"
    log_info "Cluster: $CLUSTER_NAME"
    log_info "Region: $REGION"
    
    # Pre-flight checks
    check_aws_cli
    check_kubectl
    get_aws_region
    
    # Validate cluster
    check_cluster_exists
    get_cluster_status
    
    # Configure kubectl
    update_kubeconfig
    test_cluster_connectivity
    
    # Install components
    install_metrics_server
    create_namespace
    install_istio
    
    # Generate kubeconfig file
    generate_kubeconfig
    
    log_success "EKS cluster configuration completed!"
    log_info "Next steps:"
    log_info "1. Deploy your application: helm install go-mysql-api ./go-mysql-api/chart"
    log_info "2. Check cluster status: kubectl get nodes"
    log_info "3. View cluster info: kubectl cluster-info"
    log_info "4. Use kubeconfig file: export KUBECONFIG=./kubeconfig.yaml"
}

# Run main function
main "$@"
