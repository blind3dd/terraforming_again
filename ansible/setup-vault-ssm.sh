#!/bin/bash

# Setup Ansible Vault with SSM Parameter Store
# This script helps you set up secure Ansible Vault password storage

set -e

# Configuration
VAULT_PASSWORD_PARAM="/ansible/vault/password"
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_PROFILE="${AWS_PROFILE:-default}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Check Ansible
    if ! command -v ansible-vault &> /dev/null; then
        print_error "Ansible is not installed. Please install it first."
        exit 1
    fi
    
    print_success "All prerequisites met!"
}

# Function to create SSM parameter
create_ssm_parameter() {
    local password="$1"
    
    print_status "Creating SSM parameter: $VAULT_PASSWORD_PARAM"
    
    if aws ssm put-parameter \
        --name "$VAULT_PASSWORD_PARAM" \
        --value "$password" \
        --type "SecureString" \
        --description "Ansible Vault Password for database-ci project" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" \
        --overwrite &> /dev/null; then
        print_success "SSM parameter created successfully!"
    else
        print_error "Failed to create SSM parameter"
        exit 1
    fi
}

# Function to test SSM parameter retrieval
test_ssm_parameter() {
    print_status "Testing SSM parameter retrieval..."
    
    if ./get-vault-password.sh view &> /dev/null; then
        print_success "SSM parameter retrieval test passed!"
    else
        print_error "SSM parameter retrieval test failed!"
        exit 1
    fi
}

# Function to encrypt vault file
encrypt_vault_file() {
    local vault_file="group_vars/vault.yml"
    
    if [[ -f "$vault_file" ]]; then
        print_status "Encrypting vault file: $vault_file"
        
        if ansible-vault encrypt "$vault_file" --vault-password-file ./get-vault-password.sh; then
            print_success "Vault file encrypted successfully!"
        else
            print_error "Failed to encrypt vault file"
            exit 1
        fi
    else
        print_warning "Vault file $vault_file not found. Creating it..."
        touch "$vault_file"
        echo "# Ansible Vault - Sensitive Configuration Variables" > "$vault_file"
        echo "# This file contains encrypted sensitive data" >> "$vault_file"
        echo "" >> "$vault_file"
        echo "# Database Configuration (Sensitive)" >> "$vault_file"
        echo "rds_host: \"rds-endpoint.example.com\"" >> "$vault_file"
        echo "rds_username: \"admin\"" >> "$vault_file"
        echo "rds_password: \"your-secure-password-here\"" >> "$vault_file"
        
        encrypt_vault_file
    fi
}

# Function to test vault operations
test_vault_operations() {
    print_status "Testing vault operations..."
    
    # Test view
    if ansible-vault view group_vars/vault.yml --vault-password-file ./get-vault-password.sh &> /dev/null; then
        print_success "Vault view operation test passed!"
    else
        print_error "Vault view operation test failed!"
        exit 1
    fi
    
    # Test edit (dry run)
    if ansible-vault edit group_vars/vault.yml --vault-password-file ./get-vault-password.sh --check &> /dev/null; then
        print_success "Vault edit operation test passed!"
    else
        print_warning "Vault edit operation test failed (this might be expected)"
    fi
}

# Function to show usage instructions
show_usage() {
    echo ""
    print_success "Setup completed successfully!"
    echo ""
    echo "Usage instructions:"
    echo "=================="
    echo ""
    echo "1. Edit vault file:"
    echo "   ansible-vault edit group_vars/vault.yml"
    echo ""
    echo "2. View vault file:"
    echo "   ansible-vault view group_vars/vault.yml"
    echo ""
    echo "3. Run playbooks:"
    echo "   ansible-playbook playbook.yml"
    echo ""
    echo "4. Update vault password:"
    echo "   ./get-vault-password.sh update [new-password]"
    echo ""
    echo "5. View current password:"
    echo "   ./get-vault-password.sh view"
    echo ""
    echo "Environment variables:"
    echo "  AWS_REGION=$AWS_REGION"
    echo "  AWS_PROFILE=$AWS_PROFILE"
    echo "  VAULT_PASSWORD_PARAM=$VAULT_PASSWORD_PARAM"
    echo ""
}

# Main function
main() {
    echo "=========================================="
    echo "Ansible Vault SSM Setup Script"
    echo "=========================================="
    echo ""
    
    # Check if we're in the ansible directory
    if [[ ! -f "ansible.cfg" ]]; then
        print_error "Please run this script from the ansible directory"
        exit 1
    fi
    
    # Check prerequisites
    check_prerequisites
    
    # Generate or use provided password
    local password
    if [[ -n "$1" ]]; then
        password="$1"
        print_status "Using provided password"
    else
        password=$(openssl rand -base64 32)
        print_status "Generated random password"
    fi
    
    # Create SSM parameter
    create_ssm_parameter "$password"
    
    # Test SSM parameter retrieval
    test_ssm_parameter
    
    # Encrypt vault file
    encrypt_vault_file
    
    # Test vault operations
    test_vault_operations
    
    # Show usage instructions
    show_usage
}

# Run main function
main "$@"
