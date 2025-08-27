#!/bin/bash

# Setup script for Dynamic Inventory
# This script installs dependencies and configures the dynamic inventory

set -e

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

# Check if Python 3 is installed
check_python() {
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is not installed. Please install Python 3 first."
        exit 1
    fi
    log_success "Python 3 found: $(python3 --version)"
}

# Install Python dependencies
install_dependencies() {
    log_info "Installing Python dependencies..."
    
    if command -v pip3 &> /dev/null; then
        pip3 install -r requirements.txt
        log_success "Python dependencies installed"
    elif command -v pip &> /dev/null; then
        pip install -r requirements.txt
        log_success "Python dependencies installed"
    else
        log_error "Neither pip3 nor pip is available. Please install pip first."
        exit 1
    fi
}

# Make inventory script executable
make_executable() {
    log_info "Making inventory script executable..."
    chmod +x ec2.py
    log_success "Inventory script is now executable"
}

# Test AWS credentials
test_aws_credentials() {
    log_info "Testing AWS credentials..."
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Test AWS credentials
    if aws sts get-caller-identity &> /dev/null; then
        log_success "AWS credentials are valid"
        log_info "Account ID: $(aws sts get-caller-identity --query 'Account' --output text)"
        log_info "Region: $(aws configure get region)"
    else
        log_error "AWS credentials are not valid or not configured."
        log_info "Please run 'aws configure' to set up your credentials."
        exit 1
    fi
}

# Test dynamic inventory
test_inventory() {
    log_info "Testing dynamic inventory..."
    
    # Test --list
    if python3 ec2.py --list &> /dev/null; then
        log_success "Dynamic inventory --list test passed"
    else
        log_warning "Dynamic inventory --list test failed (this is normal if no instances exist yet)"
    fi
    
    # Test with pretty output
    log_info "Current inventory structure:"
    python3 ec2.py --list --pretty 2>/dev/null || echo "No instances found"
}

# Create SSH key directory
setup_ssh() {
    log_info "Setting up SSH configuration..."
    
    # Create .ssh directory if it doesn't exist
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    log_success "SSH directory configured"
}

# Main execution
main() {
    log_info "Setting up Dynamic Inventory for Ansible"
    
    check_python
    install_dependencies
    make_executable
    test_aws_credentials
    setup_ssh
    test_inventory
    
    log_success "Dynamic inventory setup completed!"
    log_info ""
    log_info "Usage examples:"
    log_info "  ansible webservers -m ping"
    log_info "  ansible go_mysql_api_instances -m shell -a 'whoami'"
    log_info "  ansible-playbook database-init.yml"
    log_info ""
    log_info "The inventory will automatically discover EC2 instances with tags:"
    log_info "  Service: go-mysql-api"
    log_info "  Environment: [your-environment]"
}

# Run main function
main "$@"
