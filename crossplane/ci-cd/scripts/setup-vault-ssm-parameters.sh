#!/bin/bash

# =============================================================================
# Setup Vault Operator SSM Parameters
# =============================================================================
# This script sets up AWS SSM Parameter Store parameters for the Vault operator
# to securely manage secrets and inject Ansible Vault passwords.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
VAULT_ADDR="${VAULT_ADDR:-https://internal.coderedalarmtech.com/vault}"

# Function to print colored output
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

# Function to check if AWS CLI is installed and configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed. Please install it first."
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS CLI is not configured. Please run 'aws configure' first."
    fi
    
    log "AWS CLI is installed and configured"
}

# Function to create SSM parameter
create_ssm_parameter() {
    local parameter_name="$1"
    local parameter_value="$2"
    local description="$3"
    local parameter_type="${4:-SecureString}"
    
    log "Creating SSM parameter: $parameter_name"
    
    aws ssm put-parameter \
        --name "$parameter_name" \
        --value "$parameter_value" \
        --description "$description" \
        --type "$parameter_type" \
        --region "$AWS_REGION" \
        --overwrite || {
        warn "Parameter $parameter_name might already exist or failed to create"
    }
}

# Function to generate a secure random token
generate_secure_token() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to generate Ansible Vault password
generate_ansible_vault_password() {
    openssl rand -base64 32
}

# Main function
main() {
    log "Setting up Vault Operator SSM Parameters"
    log "Environment: $ENVIRONMENT"
    log "AWS Region: $AWS_REGION"
    log "Vault Address: $VAULT_ADDR"
    
    # Check prerequisites
    check_aws_cli
    
    # Generate secure tokens
    log "Generating secure tokens..."
    VAULT_TOKEN=$(generate_secure_token)
    ANSIBLE_VAULT_PASSWORD=$(generate_ansible_vault_password)
    
    # Create Vault operator parameters
    log "Creating Vault operator SSM parameters..."
    
    # Vault token for operator authentication
    create_ssm_parameter \
        "/vault/operator/token" \
        "$VAULT_TOKEN" \
        "Vault token for operator authentication" \
        "SecureString"
    
    # Vault configuration
    create_ssm_parameter \
        "/vault/operator/config" \
        "{\"address\":\"$VAULT_ADDR\",\"namespace\":\"vault\",\"auth_method\":\"token\"}" \
        "Vault operator configuration" \
        "SecureString"
    
    # Ansible Vault password
    create_ssm_parameter \
        "/ansible/vault/password" \
        "$ANSIBLE_VAULT_PASSWORD" \
        "Ansible Vault password for secret management" \
        "SecureString"
    
    # Environment-specific parameters
    create_ssm_parameter \
        "/vault/operator/environment" \
        "$ENVIRONMENT" \
        "Current environment for Vault operator" \
        "String"
    
    # AWS credentials (placeholder - should be replaced with actual credentials)
    create_ssm_parameter \
        "/vault/operator/aws-credentials" \
        "{\"access_key_id\":\"YOUR_ACCESS_KEY\",\"secret_access_key\":\"YOUR_SECRET_KEY\"}" \
        "AWS credentials for Vault operator (PLACEHOLDER - UPDATE WITH REAL CREDENTIALS)" \
        "SecureString"
    
    # Custom secrets (examples)
    create_ssm_parameter \
        "/app/database/password" \
        "$(generate_secure_token)" \
        "Database password for application" \
        "SecureString"
    
    create_ssm_parameter \
        "/app/api/keys" \
        "$(generate_secure_token)" \
        "API keys for application" \
        "SecureString"
    
    log "✅ Vault Operator SSM parameters created successfully!"
    
    # Display summary
    echo
    log "📋 Summary of created parameters:"
    echo "   • /vault/operator/token - Vault authentication token"
    echo "   • /vault/operator/config - Vault configuration"
    echo "   • /ansible/vault/password - Ansible Vault password"
    echo "   • /vault/operator/environment - Current environment"
    echo "   • /vault/operator/aws-credentials - AWS credentials (PLACEHOLDER)"
    echo "   • /app/database/password - Database password"
    echo "   • /app/api/keys - API keys"
    
    echo
    warn "⚠️  IMPORTANT: Update /vault/operator/aws-credentials with real AWS credentials!"
    warn "⚠️  Store the generated tokens securely - they won't be displayed again!"
    
    echo
    log "🚀 Next steps:"
    echo "   1. Update AWS credentials in SSM Parameter Store"
    echo "   2. Deploy Vault operator with Helm"
    echo "   3. Configure internal DNS routing for vault.coderedalarmtech.com"
    echo "   4. Test Vault operator connectivity"
}

# Run main function
main "$@"
