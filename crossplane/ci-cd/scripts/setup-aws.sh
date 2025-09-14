#!/bin/bash
# AWS Credentials Setup Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed. Please install it first: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    fi
    success "AWS CLI is installed"
}

# Function to configure AWS credentials
configure_aws() {
    log "Configuring AWS credentials..."
    
    # Check if credentials file exists
    if [ -f "$HOME/.aws/credentials" ]; then
        warn "AWS credentials file already exists at $HOME/.aws/credentials"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Keeping existing credentials"
            return
        fi
    fi
    
    # Create AWS directory if it doesn't exist
    mkdir -p "$HOME/.aws"
    
    # Get credentials from user
    read -p "Enter AWS Access Key ID: " aws_access_key_id
    read -s -p "Enter AWS Secret Access Key: " aws_secret_access_key
    echo
    read -p "Enter AWS Region (default: us-east-1): " aws_region
    aws_region=${aws_region:-us-east-1}
    
    # Create credentials file
    cat > "$HOME/.aws/credentials" <<EOF
[default]
aws_access_key_id = $aws_access_key_id
aws_secret_access_key = $aws_secret_access_key
EOF
    
    # Create config file
    cat > "$HOME/.aws/config" <<EOF
[default]
region = $aws_region
output = json
EOF
    
    # Set proper permissions
    chmod 600 "$HOME/.aws/credentials"
    chmod 600 "$HOME/.aws/config"
    
    success "AWS credentials configured successfully"
}

# Function to test AWS credentials
test_aws_credentials() {
    log "Testing AWS credentials..."
    
    if aws sts get-caller-identity &> /dev/null; then
        success "AWS credentials are working correctly"
        aws sts get-caller-identity
    else
        error "AWS credentials test failed. Please check your configuration."
    fi
}

# Function to setup AWS SSM session manager
setup_ssm() {
    log "Setting up AWS SSM Session Manager..."
    
    # Install session-manager-plugin if not present
    if ! command -v session-manager-plugin &> /dev/null; then
        log "Installing session-manager-plugin..."
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
            unzip sessionmanager-bundle.zip
            sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
            rm -rf sessionmanager-bundle*
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"
            sudo yum install -y session-manager-plugin.rpm
            rm session-manager-plugin.rpm
        else
            warn "Unsupported OS for automatic session-manager-plugin installation"
        fi
    else
        success "session-manager-plugin is already installed"
    fi
}

# Main execution
main() {
    log "🚀 AWS Setup Script"
    log "This script will help you configure AWS credentials for local development"
    
    check_aws_cli
    configure_aws
    test_aws_credentials
    setup_ssm
    
    success "✅ AWS setup completed successfully!"
    log "📋 Next steps:"
    log "   1. Update terraform.tfvars with your AWS credentials"
    log "   2. Run: ./deploy-kubernetes-control-plane.sh"
    log "   3. Or run manually: terraform init && terraform plan && terraform apply"
}

# Run main function
main "$@"
