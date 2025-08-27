#!/bin/bash

# SSH Key Setup Script for EC2 Access
# This script generates SSH keys and stores them securely

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_KEYS_DIR="${SCRIPT_DIR}/ssh_keys"
KEY_NAME="ec2-access-key"
ENVIRONMENT="${ENVIRONMENT:-sandbox}"
SERVICE_NAME="${SERVICE_NAME:-go-mysql-api}"

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
    log_success "AWS CLI found"
}

# Check AWS credentials
check_aws_credentials() {
    log_info "Checking AWS credentials..."
    
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

# Create SSH keys directory
create_ssh_dir() {
    log_info "Creating SSH keys directory..."
    mkdir -p "$SSH_KEYS_DIR"
    chmod 700 "$SSH_KEYS_DIR"
    log_success "SSH keys directory created: $SSH_KEYS_DIR"
}

# Generate SSH key pair
generate_ssh_keys() {
    log_info "Generating SSH key pair..."
    
    PRIVATE_KEY_PATH="${SSH_KEYS_DIR}/${KEY_NAME}"
    PUBLIC_KEY_PATH="${SSH_KEYS_DIR}/${KEY_NAME}.pub"
    
    # Check if keys already exist
    if [ -f "$PRIVATE_KEY_PATH" ] && [ -f "$PUBLIC_KEY_PATH" ]; then
        log_warning "SSH keys already exist at $PRIVATE_KEY_PATH"
        read -p "Do you want to overwrite them? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Using existing SSH keys"
            return
        fi
    fi
    
    # Generate new SSH key pair
    ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY_PATH" -N "" -C "ec2-user@${ENVIRONMENT}-${SERVICE_NAME}"
    
    # Set proper permissions
    chmod 600 "$PRIVATE_KEY_PATH"
    chmod 644 "$PUBLIC_KEY_PATH"
    
    log_success "SSH key pair generated successfully"
    log_info "Private key: $PRIVATE_KEY_PATH"
    log_info "Public key: $PUBLIC_KEY_PATH"
}

# Store keys in AWS SSM Parameter Store
store_keys_in_ssm() {
    log_info "Storing SSH keys in AWS SSM Parameter Store..."
    
    PRIVATE_KEY_PATH="${SSH_KEYS_DIR}/${KEY_NAME}"
    PUBLIC_KEY_PATH="${SSH_KEYS_DIR}/${KEY_NAME}.pub"
    
    # Read key contents
    PRIVATE_KEY_CONTENT=$(cat "$PRIVATE_KEY_PATH")
    PUBLIC_KEY_CONTENT=$(cat "$PUBLIC_KEY_PATH")
    
    # Store private key (encrypted)
    aws ssm put-parameter \
        --name "/${ENVIRONMENT}/${SERVICE_NAME}/ssh/private_key" \
        --description "SSH private key for ${ENVIRONMENT}-${SERVICE_NAME}" \
        --type "SecureString" \
        --value "$PRIVATE_KEY_CONTENT" \
        --overwrite
    
    # Store public key (plain text)
    aws ssm put-parameter \
        --name "/${ENVIRONMENT}/${SERVICE_NAME}/ssh/public_key" \
        --description "SSH public key for ${ENVIRONMENT}-${SERVICE_NAME}" \
        --type "String" \
        --value "$PUBLIC_KEY_CONTENT" \
        --overwrite
    
    log_success "SSH keys stored in SSM Parameter Store"
    log_info "Private key parameter: /${ENVIRONMENT}/${SERVICE_NAME}/ssh/private_key"
    log_info "Public key parameter: /${ENVIRONMENT}/${SERVICE_NAME}/ssh/public_key"
}

# Create AWS Key Pair
create_aws_key_pair() {
    log_info "Creating AWS Key Pair..."
    
    KEY_PAIR_NAME="${ENVIRONMENT}-${SERVICE_NAME}-key"
    PUBLIC_KEY_PATH="${SSH_KEYS_DIR}/${KEY_NAME}.pub"
    
    # Check if key pair already exists
    if aws ec2 describe-key-pairs --key-names "$KEY_PAIR_NAME" &> /dev/null; then
        log_warning "AWS Key Pair '$KEY_PAIR_NAME' already exists"
        read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            aws ec2 delete-key-pair --key-name "$KEY_PAIR_NAME"
            log_info "Deleted existing key pair"
        else
            log_info "Using existing AWS Key Pair"
            return
        fi
    fi
    
    # Import the public key to AWS
    aws ec2 import-key-pair \
        --key-name "$KEY_PAIR_NAME" \
        --public-key-material "fileb://${PUBLIC_KEY_PATH}" \
        --tag-specifications "ResourceType=key-pair,Tags=[{Key=Environment,Value=${ENVIRONMENT}},{Key=Service,Value=${SERVICE_NAME}}]"
    
    log_success "AWS Key Pair created: $KEY_PAIR_NAME"
}

# Create SSH configuration file
create_ssh_config() {
    log_info "Creating SSH configuration file..."
    
    SSH_CONFIG_PATH="${SSH_KEYS_DIR}/config"
    PRIVATE_KEY_PATH="${SSH_KEYS_DIR}/${KEY_NAME}"
    
    cat > "$SSH_CONFIG_PATH" << EOF
# SSH Configuration for ${ENVIRONMENT}-${SERVICE_NAME}
# Generated on $(date)

Host ${ENVIRONMENT}-${SERVICE_NAME}
    HostName %h
    User ec2-user
    IdentityFile ${PRIVATE_KEY_PATH}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60
    ServerAliveCountMax 3
    Compression yes

Host *.amazonaws.com
    User ec2-user
    IdentityFile ${PRIVATE_KEY_PATH}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host 10.* 172.* 192.168.*
    User ec2-user
    IdentityFile ${PRIVATE_KEY_PATH}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
    
    chmod 600 "$SSH_CONFIG_PATH"
    log_success "SSH configuration created: $SSH_CONFIG_PATH"
}

# Create connection script
create_connection_script() {
    log_info "Creating connection script..."
    
    CONNECTION_SCRIPT="${SSH_KEYS_DIR}/connect.sh"
    PRIVATE_KEY_PATH="${SSH_KEYS_DIR}/${KEY_NAME}"
    
    cat > "$CONNECTION_SCRIPT" << 'EOF'
#!/bin/bash
# Connection script for EC2 instances
# Usage: ./connect.sh <instance-ip>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SSH_KEY="$(dirname "$0")/ec2-access-key"
SSH_USER="ec2-user"
ENVIRONMENT="${ENVIRONMENT:-sandbox}"
SERVICE_NAME="${SERVICE_NAME:-go-mysql-api}"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check arguments
if [ $# -eq 0 ]; then
    log_error "Usage: $0 <instance-ip>"
    log_info "Example: $0 1.2.3.4"
    exit 1
fi

INSTANCE_IP="$1"

# Check if SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    log_error "SSH private key not found at $SSH_KEY"
    exit 1
fi

# Set proper permissions
chmod 600 "$SSH_KEY"

# Connect to instance
log_info "Connecting to ${ENVIRONMENT}-${SERVICE_NAME} instance at $INSTANCE_IP..."
ssh -i "$SSH_KEY" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ServerAliveInterval=60 \
    -o ServerAliveCountMax=3 \
    "$SSH_USER@$INSTANCE_IP"
EOF
    
    chmod +x "$CONNECTION_SCRIPT"
    log_success "Connection script created: $CONNECTION_SCRIPT"
}

# Display summary
show_summary() {
    log_info ""
    log_info "🎉 SSH Key Setup Completed Successfully!"
    log_info "========================================"
    log_info ""
    log_info "📁 Files Created:"
    log_info "  Private Key: ${SSH_KEYS_DIR}/${KEY_NAME}"
    log_info "  Public Key: ${SSH_KEYS_DIR}/${KEY_NAME}.pub"
    log_info "  SSH Config: ${SSH_KEYS_DIR}/config"
    log_info "  Connection Script: ${SSH_KEYS_DIR}/connect.sh"
    log_info ""
    log_info "☁️  AWS Resources:"
    log_info "  Key Pair: ${ENVIRONMENT}-${SERVICE_NAME}-key"
    log_info "  SSM Private Key: /${ENVIRONMENT}/${SERVICE_NAME}/ssh/private_key"
    log_info "  SSM Public Key: /${ENVIRONMENT}/${SERVICE_NAME}/ssh/public_key"
    log_info ""
    log_info "🔗 Usage Examples:"
    log_info "  Connect to instance: ${SSH_KEYS_DIR}/connect.sh <instance-ip>"
    log_info "  Manual SSH: ssh -i ${SSH_KEYS_DIR}/${KEY_NAME} ec2-user@<instance-ip>"
    log_info "  Copy files: scp -i ${SSH_KEYS_DIR}/${KEY_NAME} file.txt ec2-user@<instance-ip>:/path/"
    log_info ""
    log_info "🔒 Security Notes:"
    log_info "  - Private key permissions set to 600"
    log_info "  - Keys stored securely in AWS SSM Parameter Store"
    log_info "  - AWS Key Pair created for EC2 instance access"
    log_info ""
}

# Main execution
main() {
    log_info "Starting SSH Key Setup for ${ENVIRONMENT}-${SERVICE_NAME}"
    
    check_aws_cli
    check_aws_credentials
    create_ssh_dir
    generate_ssh_keys
    store_keys_in_ssm
    create_aws_key_pair
    create_ssh_config
    create_connection_script
    show_summary
}

# Run main function
main "$@"
