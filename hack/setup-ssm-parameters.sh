#!/bin/bash

# Setup SSM Parameters for Operators
# This script creates SSM parameters for Ansible Vault, AWS credentials, and Vault tokens

set -euo pipefail

# Configuration
AWS_REGION="${AWS_REGION:-us-west-2}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
KMS_KEY_ID="${KMS_KEY_ID:-}"

# SSM Parameter paths
ANSIBLE_VAULT_PASSWORD_PARAM="/ansible/vault/password"
AWS_CREDENTIALS_PARAM="/aws/credentials"
VAULT_TOKEN_PARAM="/vault/token"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    log_success "AWS CLI is installed"
}

# Check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    local caller_identity
    caller_identity=$(aws sts get-caller-identity)
    local account_id
    account_id=$(echo "$caller_identity" | jq -r '.Account')
    local user_arn
    user_arn=$(echo "$caller_identity" | jq -r '.Arn')
    
    log_success "AWS credentials configured"
    log_info "Account ID: $account_id"
    log_info "User ARN: $user_arn"
}

# Generate random password
generate_password() {
    openssl rand -base64 32
}

# Create SSM parameter
create_ssm_parameter() {
    local param_name="$1"
    local param_value="$2"
    local param_type="${3:-SecureString}"
    local description="$4"
    
    log_info "Creating SSM parameter: $param_name"
    
    local kms_args=""
    if [[ -n "$KMS_KEY_ID" ]]; then
        kms_args="--key-id $KMS_KEY_ID"
    fi
    
    if aws ssm put-parameter \
        --name "$param_name" \
        --value "$param_value" \
        --type "$param_type" \
        --description "$description" \
        --overwrite \
        $kms_args \
        --region "$AWS_REGION" &> /dev/null; then
        log_success "Created SSM parameter: $param_name"
    else
        log_error "Failed to create SSM parameter: $param_name"
        return 1
    fi
}

# Create Ansible Vault password parameter
create_ansible_vault_password() {
    local vault_password
    vault_password=$(generate_password)
    
    create_ssm_parameter \
        "$ANSIBLE_VAULT_PASSWORD_PARAM" \
        "$vault_password" \
        "SecureString" \
        "Ansible Vault password for operators"
    
    log_info "Ansible Vault password: $vault_password"
    log_warning "Save this password securely! It won't be shown again."
}

# Create AWS credentials parameters
create_aws_credentials() {
    log_info "Creating AWS credentials parameters"
    
    # Get current AWS credentials
    local access_key_id
    access_key_id=$(aws configure get aws_access_key_id)
    local secret_access_key
    secret_access_key=$(aws configure get aws_secret_access_key)
    local session_token
    session_token=$(aws configure get aws_session_token || echo "")
    
    if [[ -z "$access_key_id" || -z "$secret_access_key" ]]; then
        log_error "AWS credentials not found in configuration"
        return 1
    fi
    
    create_ssm_parameter \
        "$AWS_CREDENTIALS_PARAM/access-key-id" \
        "$access_key_id" \
        "SecureString" \
        "AWS Access Key ID for operators"
    
    create_ssm_parameter \
        "$AWS_CREDENTIALS_PARAM/secret-access-key" \
        "$secret_access_key" \
        "SecureString" \
        "AWS Secret Access Key for operators"
    
    if [[ -n "$session_token" ]]; then
        create_ssm_parameter \
            "$AWS_CREDENTIALS_PARAM/session-token" \
            "$session_token" \
            "SecureString" \
            "AWS Session Token for operators"
    fi
    
    log_success "AWS credentials parameters created"
}

# Create Vault token parameter
create_vault_token() {
    local vault_token
    vault_token=$(generate_password)
    
    create_ssm_parameter \
        "$VAULT_TOKEN_PARAM" \
        "$vault_token" \
        "SecureString" \
        "HashiCorp Vault token for operators"
    
    log_info "Vault token: $vault_token"
    log_warning "Save this token securely! It won't be shown again."
}

# Verify SSM parameters
verify_ssm_parameters() {
    log_info "Verifying SSM parameters..."
    
    local params=(
        "$ANSIBLE_VAULT_PASSWORD_PARAM"
        "$AWS_CREDENTIALS_PARAM/access-key-id"
        "$AWS_CREDENTIALS_PARAM/secret-access-key"
        "$VAULT_TOKEN_PARAM"
    )
    
    for param in "${params[@]}"; do
        if aws ssm get-parameter --name "$param" --region "$AWS_REGION" &> /dev/null; then
            log_success "Parameter exists: $param"
        else
            log_error "Parameter missing: $param"
            return 1
        fi
    done
    
    log_success "All SSM parameters verified"
}

# Display usage information
display_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Setup SSM Parameters for Kubernetes Operators

OPTIONS:
    -r, --region REGION     AWS region (default: us-west-2)
    -e, --environment ENV   Environment (default: dev)
    -k, --kms-key-id ID     KMS key ID for encryption
    -h, --help              Show this help message

EXAMPLES:
    $0                                    # Use defaults
    $0 -r us-east-1 -e prod              # Specify region and environment
    $0 -k alias/ssm-encryption-key       # Use specific KMS key

ENVIRONMENT VARIABLES:
    AWS_REGION        AWS region
    ENVIRONMENT       Environment name
    KMS_KEY_ID        KMS key ID for encryption

EOF
}

# Main function
main() {
    log_info "Setting up SSM parameters for operators"
    log_info "Region: $AWS_REGION"
    log_info "Environment: $ENVIRONMENT"
    
    if [[ -n "$KMS_KEY_ID" ]]; then
        log_info "KMS Key ID: $KMS_KEY_ID"
    fi
    
    # Check prerequisites
    check_aws_cli
    check_aws_credentials
    
    # Create SSM parameters
    create_ansible_vault_password
    create_aws_credentials
    create_vault_token
    
    # Verify parameters
    verify_ssm_parameters
    
    log_success "SSM parameters setup completed successfully!"
    
    cat << EOF

Next steps:
1. Deploy operators using: ansible-playbook operators-helm-ssm.yml
2. The operators will automatically retrieve secrets from SSM
3. Update Ansible Vault with the generated password

SSM Parameter paths:
- Ansible Vault: $ANSIBLE_VAULT_PASSWORD_PARAM
- AWS Credentials: $AWS_CREDENTIALS_PARAM/*
- Vault Token: $VAULT_TOKEN_PARAM

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -k|--kms-key-id)
            KMS_KEY_ID="$2"
            shift 2
            ;;
        -h|--help)
            display_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            display_usage
            exit 1
            ;;
    esac
done

# Run main function
main "$@"
