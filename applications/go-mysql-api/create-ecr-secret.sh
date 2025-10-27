#!/bin/bash

# Create ECR Image Pull Secret for Kubernetes
# This script creates a Kubernetes secret for pulling images from AWS ECR

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRET_NAME="ecr-secret"
NAMESPACE="default"
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
    echo "  -n, --namespace NAMESPACE    Kubernetes namespace (default: default)"
    echo "  -s, --secret-name NAME       Secret name (default: ecr-secret)"
    echo "  -r, --region REGION          AWS region (default: from AWS CLI config)"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 -n my-app -s my-ecr-secret -r us-east-1"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -s|--secret-name)
            SECRET_NAME="$2"
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

# Get ECR login token
get_ecr_token() {
    log_info "Getting ECR login token..."
    
    # Get ECR login token
    ECR_TOKEN=$(aws ecr get-login-password --region "$REGION")
    
    if [ -z "$ECR_TOKEN" ]; then
        log_error "Failed to get ECR login token"
        exit 1
    fi
    
    log_success "ECR login token obtained"
}

# Create Kubernetes secret
create_k8s_secret() {
    log_info "Creating Kubernetes secret '$SECRET_NAME' in namespace '$NAMESPACE'..."
    
    # Create namespace if it doesn't exist
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_info "Creating namespace '$NAMESPACE'..."
        kubectl create namespace "$NAMESPACE"
    fi
    
    # Get ECR registry URL
    ECR_REGISTRY=$(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$REGION.amazonaws.com
    
    # Create Docker config JSON
    DOCKER_CONFIG=$(cat <<EOF
{
  "auths": {
    "$ECR_REGISTRY": {
      "username": "AWS",
      "password": "$ECR_TOKEN",
      "email": "not-used@example.com",
      "auth": "$(echo -n "AWS:$ECR_TOKEN" | base64)"
    }
  }
}
EOF
)
    
    # Create the secret
    kubectl create secret docker-registry "$SECRET_NAME" \
        --docker-server="$ECR_REGISTRY" \
        --docker-username="AWS" \
        --docker-password="$ECR_TOKEN" \
        --docker-email="not-used@example.com" \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    if [ $? -eq 0 ]; then
        log_success "Secret '$SECRET_NAME' created successfully in namespace '$NAMESPACE'"
    else
        log_error "Failed to create secret"
        exit 1
    fi
}

# Verify the secret
verify_secret() {
    log_info "Verifying secret..."
    
    if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &> /dev/null; then
        log_success "Secret verification successful"
        
        # Show secret details
        echo ""
        log_info "Secret details:"
        kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o yaml | grep -E "(name:|type:|namespace:)"
    else
        log_error "Secret verification failed"
        exit 1
    fi
}

# Generate Helm values snippet
generate_helm_values() {
    log_info "Generating Helm values snippet..."
    
    ECR_REGISTRY=$(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$REGION.amazonaws.com
    
    cat <<EOF

# Add this to your Helm values or use --set:
imagePullSecrets:
  - name: $SECRET_NAME
    create: false  # Secret already exists

# Or if you want Helm to create the secret:
imagePullSecrets:
  - name: $SECRET_NAME
    create: true
    registry: "$ECR_REGISTRY"
    password: "$ECR_TOKEN"
    email: "not-used@example.com"
    auth: "$(echo -n "AWS:$ECR_TOKEN" | base64)"

EOF
}

# Main execution
main() {
    log_info "Creating ECR Image Pull Secret"
    log_info "Secret name: $SECRET_NAME"
    log_info "Namespace: $NAMESPACE"
    
    # Pre-flight checks
    check_aws_cli
    check_kubectl
    get_aws_region
    get_ecr_token
    
    # Create secret
    create_k8s_secret
    verify_secret
    
    # Generate Helm values
    generate_helm_values
    
    log_success "ECR image pull secret setup completed!"
    log_info "You can now use this secret in your Helm deployments"
}

# Run main function
main "$@"
