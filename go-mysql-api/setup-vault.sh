#!/bin/bash

# Setup HashiCorp Vault for Go MySQL API
# This script initializes Vault and populates it with application secrets

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="default"
RELEASE_NAME="go-mysql-api"
VAULT_ADDR="http://localhost:8200"

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
    echo "  -r, --release RELEASE        Helm release name (default: go-mysql-api)"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 -n my-app -r my-release"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -r|--release)
            RELEASE_NAME="$2"
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

# Check if kubectl is installed
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    log_success "kubectl found"
}

# Check if helm is installed
check_helm() {
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed. Please install it first."
        exit 1
    fi
    log_success "helm found"
}

# Check if vault CLI is installed
check_vault() {
    if ! command -v vault &> /dev/null; then
        log_error "vault CLI is not installed. Please install it first."
        exit 1
    fi
    log_success "vault CLI found"
}

# Wait for Vault to be ready
wait_for_vault() {
    log_info "Waiting for Vault to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=go-mysql-api,app.kubernetes.io/component=vault" --field-selector=status.phase=Running | grep -q "vault"; then
            log_success "Vault is ready"
            return 0
        fi
        
        log_info "Attempt $attempt/$max_attempts: Vault not ready yet, waiting..."
        sleep 10
        ((attempt++))
    done
    
    log_error "Vault failed to become ready within the expected time"
    exit 1
}

# Port forward to Vault
setup_port_forward() {
    log_info "Setting up port forward to Vault..."
    
    # Kill any existing port forward
    pkill -f "kubectl port-forward.*vault.*8200" || true
    
    # Start port forward in background
    kubectl port-forward -n "$NAMESPACE" svc/"$RELEASE_NAME"-vault 8200:8200 &
    PF_PID=$!
    
    # Wait for port forward to be ready
    sleep 5
    
    # Test connection
    if curl -s "$VAULT_ADDR/v1/sys/health" > /dev/null; then
        log_success "Port forward established"
    else
        log_error "Failed to establish port forward to Vault"
        kill $PF_PID 2>/dev/null || true
        exit 1
    fi
}

# Initialize Vault
initialize_vault() {
    log_info "Initializing Vault..."
    
    # Check if Vault is already initialized
    if vault status -address="$VAULT_ADDR" 2>/dev/null | grep -q "Initialized.*true"; then
        log_info "Vault is already initialized"
        return 0
    fi
    
    # Initialize Vault
    local init_output
    init_output=$(vault operator init -address="$VAULT_ADDR" -key-shares=1 -key-threshold=1 -format=json)
    
    if [ $? -eq 0 ]; then
        # Extract root token and unseal key
        ROOT_TOKEN=$(echo "$init_output" | jq -r '.root_token')
        UNSEAL_KEY=$(echo "$init_output" | jq -r '.keys_b64[0]')
        
        # Save credentials to file
        cat > vault-credentials.txt <<EOF
# Vault Credentials - KEEP THESE SECURE!
ROOT_TOKEN=$ROOT_TOKEN
UNSEAL_KEY=$UNSEAL_KEY
EOF
        
        log_success "Vault initialized successfully"
        log_warning "Credentials saved to vault-credentials.txt - KEEP THIS FILE SECURE!"
        
        # Unseal Vault
        vault operator unseal -address="$VAULT_ADDR" "$UNSEAL_KEY"
        
        # Login with root token
        vault login -address="$VAULT_ADDR" "$ROOT_TOKEN"
        
    else
        log_error "Failed to initialize Vault"
        exit 1
    fi
}

# Enable secrets engine
enable_secrets_engine() {
    log_info "Enabling secrets engine..."
    
    # Enable KV v2 secrets engine
    vault secrets enable -address="$VAULT_ADDR" -path=secret kv-v2 || true
    
    log_success "Secrets engine enabled"
}

# Enable Kubernetes auth
enable_kubernetes_auth() {
    log_info "Enabling Kubernetes authentication..."
    
    # Enable Kubernetes auth
    vault auth enable -address="$VAULT_ADDR" kubernetes || true
    
    # Get Kubernetes service account token
    SA_TOKEN=$(kubectl get secret -n "$NAMESPACE" -o jsonpath='{.data.token}' "$(kubectl get serviceaccount -n "$NAMESPACE" "$RELEASE_NAME"-vault -o jsonpath='{.secrets[0].name}')" | base64 -d)
    
    # Get Kubernetes CA certificate
    KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d)
    
    # Configure Kubernetes auth
    vault write -address="$VAULT_ADDR" auth/kubernetes/config \
        kubernetes_host="https://kubernetes.default.svc.cluster.local" \
        kubernetes_ca_cert="$KUBE_CA_CERT" \
        token_reviewer_jwt="$SA_TOKEN"
    
    log_success "Kubernetes authentication enabled"
}

# Create Vault policy
create_vault_policy() {
    log_info "Creating Vault policy..."
    
    # Create policy for the application
    vault policy write -address="$VAULT_ADDR" go-mysql-api-policy - <<EOF
# Policy for Go MySQL API
path "secret/data/go-mysql-api/*" {
  capabilities = ["read"]
}

path "secret/metadata/go-mysql-api/*" {
  capabilities = ["read"]
}
EOF
    
    log_success "Vault policy created"
}

# Create Kubernetes auth role
create_k8s_auth_role() {
    log_info "Creating Kubernetes auth role..."
    
    # Create role for the application
    vault write -address="$VAULT_ADDR" auth/kubernetes/role/go-mysql-api \
        bound_service_account_names="$RELEASE_NAME-vault" \
        bound_service_account_namespaces="$NAMESPACE" \
        policies=go-mysql-api-policy \
        ttl=1h
    
    log_success "Kubernetes auth role created"
}

# Populate secrets
populate_secrets() {
    log_info "Populating Vault with secrets..."
    
    # Database secrets
    vault kv put -address="$VAULT_ADDR" secret/go-mysql-api/database \
        password="SecurePassword123!" \
        host="localhost" \
        port="3306" \
        name="mock_user" \
        user="db_user"
    
    # Application secrets
    vault kv put -address="$VAULT_ADDR" secret/go-mysql-api/app \
        api_key="your-secure-api-key" \
        log_level="info" \
        environment="production"
    
    # AWS secrets
    vault kv put -address="$VAULT_ADDR" secret/go-mysql-api/aws \
        access_key_id="your-aws-access-key" \
        secret_access_key="your-aws-secret-key" \
        region="us-east-1"
    
    log_success "Secrets populated in Vault"
}

# Test Vault access
test_vault_access() {
    log_info "Testing Vault access..."
    
    # Test reading a secret
    if vault kv get -address="$VAULT_ADDR" secret/go-mysql-api/database > /dev/null; then
        log_success "Vault access test successful"
    else
        log_error "Vault access test failed"
        exit 1
    fi
}

# Generate application configuration
generate_app_config() {
    log_info "Generating application configuration..."
    
    cat > vault-app-config.yaml <<EOF
# Vault-enabled Helm values
vault:
  enabled: true
  auth:
    method: "kubernetes"
    role: "go-mysql-api"
  secrets:
    db_password: "secret/data/go-mysql-api/database"
    api_key: "secret/data/go-mysql-api/app"
    aws_credentials: "secret/data/go-mysql-api/aws"

# Disable direct environment variables when using Vault
env: {}

# Application will read secrets from Vault at runtime
EOF
    
    log_success "Application configuration generated: vault-app-config.yaml"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up..."
    
    # Kill port forward
    if [ ! -z "$PF_PID" ]; then
        kill $PF_PID 2>/dev/null || true
    fi
    
    log_success "Cleanup completed"
}

# Main execution
main() {
    log_info "Setting up HashiCorp Vault for Go MySQL API"
    log_info "Namespace: $NAMESPACE"
    log_info "Release: $RELEASE_NAME"
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    # Pre-flight checks
    check_kubectl
    check_helm
    check_vault
    
    # Wait for Vault to be ready
    wait_for_vault
    
    # Setup port forward
    setup_port_forward
    
    # Initialize Vault
    initialize_vault
    
    # Enable features
    enable_secrets_engine
    enable_kubernetes_auth
    create_vault_policy
    create_k8s_auth_role
    
    # Populate secrets
    populate_secrets
    
    # Test access
    test_vault_access
    
    # Generate configuration
    generate_app_config
    
    log_success "Vault setup completed successfully!"
    log_info "Next steps:"
    log_info "1. Review vault-credentials.txt (keep secure!)"
    log_info "2. Use vault-app-config.yaml for Helm deployment"
    log_info "3. Update your application to read secrets from Vault"
}

# Run main function
main "$@"
