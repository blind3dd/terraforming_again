#!/bin/bash

# Ansible Vault Password Script
# Retrieves the vault password from AWS Systems Manager Parameter Store
# 
# Usage: 
#   chmod +x get-vault-password.sh
#   export ANSIBLE_VAULT_PASSWORD_FILE=./get-vault-password.sh
#   ansible-playbook playbook.yml --ask-vault-pass
#
# Or set in ansible.cfg:
#   vault_password_file = ./get-vault-password.sh

set -e

# Configuration
VAULT_PASSWORD_PARAM="/ansible/vault/password"
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_PROFILE="${AWS_PROFILE:-default}"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

# Function to get vault password from SSM
get_vault_password() {
    local param_name="$1"
    local region="$2"
    local profile="$3"
    
    log "Retrieving vault password from SSM Parameter: $param_name"
    
    # Try with profile if specified
    if [[ -n "$profile" && "$profile" != "default" ]]; then
        aws ssm get-parameter \
            --name "$param_name" \
            --with-decryption \
            --region "$region" \
            --profile "$profile" \
            --query 'Parameter.Value' \
            --output text
    else
        aws ssm get-parameter \
            --name "$param_name" \
            --with-decryption \
            --region "$region" \
            --query 'Parameter.Value' \
            --output text
    fi
}

# Function to create vault password in SSM (for initial setup)
create_vault_password() {
    local param_name="$1"
    local region="$2"
    local profile="$3"
    local password="$4"
    
    log "Creating vault password in SSM Parameter: $param_name"
    
    if [[ -n "$profile" && "$profile" != "default" ]]; then
        aws ssm put-parameter \
            --name "$param_name" \
            --value "$password" \
            --type "SecureString" \
            --description "Ansible Vault Password" \
            --region "$region" \
            --profile "$profile" \
            --overwrite
    else
        aws ssm put-parameter \
            --name "$param_name" \
            --value "$password" \
            --type "SecureString" \
            --description "Ansible Vault Password" \
            --region "$region" \
            --overwrite
    fi
}

# Function to generate a secure random password
generate_password() {
    openssl rand -base64 32
}

# Main execution
main() {
    # Check if AWS CLI is available
    if ! command -v aws &> /dev/null; then
        log "ERROR: AWS CLI is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we're being called to create the password
    if [[ "$1" == "create" ]]; then
        local password="${2:-$(generate_password)}"
        create_vault_password "$VAULT_PASSWORD_PARAM" "$AWS_REGION" "$AWS_PROFILE" "$password"
        log "Vault password created successfully in SSM"
        log "Password: $password"
        log "Parameter: $VAULT_PASSWORD_PARAM"
        exit 0
    fi
    
    # Check if we're being called to view the password
    if [[ "$1" == "view" ]]; then
        get_vault_password "$VAULT_PASSWORD_PARAM" "$AWS_REGION" "$AWS_PROFILE"
        exit 0
    fi
    
    # Check if we're being called to update the password
    if [[ "$1" == "update" ]]; then
        local password="${2:-$(generate_password)}"
        create_vault_password "$VAULT_PASSWORD_PARAM" "$AWS_REGION" "$AWS_PROFILE" "$password"
        log "Vault password updated successfully in SSM"
        log "New password: $password"
        exit 0
    fi
    
    # Normal operation: retrieve password for Ansible
    try {
        get_vault_password "$VAULT_PASSWORD_PARAM" "$AWS_REGION" "$AWS_PROFILE"
    } catch {
        log "ERROR: Failed to retrieve vault password from SSM"
        log "Make sure you have:"
        log "1. AWS credentials configured"
        log "2. Permission to access SSM Parameter Store"
        log "3. The parameter exists: $VAULT_PASSWORD_PARAM"
        log ""
        log "To create the parameter, run:"
        log "  $0 create [password]"
        exit 1
    }
}

# Run main function
main "$@"
