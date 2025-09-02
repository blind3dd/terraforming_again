#!/bin/bash
# AWS Setup Script
# This script helps you configure AWS credentials and set up the environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -p, --profile PROFILE     AWS profile name (default: default)
    -r, --region REGION       AWS region (default: us-east-1)
    -k, --access-key KEY      AWS Access Key ID
    -s, --secret-key SECRET   AWS Secret Access Key
    -t, --token TOKEN         AWS Session Token (optional)
    -i, --interactive         Interactive mode (prompt for credentials)
    -c, --check               Check current AWS configuration
    -h, --help                Show this help message

Examples:
    $0 -i                          # Interactive setup
    $0 -k AKIA... -s secret...     # Direct credential setup
    $0 -c                          # Check current configuration

EOF
}

# Default values
AWS_PROFILE="default"
AWS_REGION="us-east-1"
ACCESS_KEY=""
SECRET_KEY=""
SESSION_TOKEN=""
INTERACTIVE=false
CHECK_ONLY=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--profile)
            AWS_PROFILE="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -k|--access-key)
            ACCESS_KEY="$2"
            shift 2
            ;;
        -s|--secret-key)
            SECRET_KEY="$2"
            shift 2
            ;;
        -t|--token)
            SESSION_TOKEN="$2"
            shift 2
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        -c|--check)
            CHECK_ONLY=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            error "Unknown option: $1"
            ;;
        *)
            error "Unknown argument: $1"
            ;;
    esac
done

# Function to check AWS CLI
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed. Please install it first."
    fi
    
    log "AWS CLI version: $(aws --version)"
}

# Function to check current AWS configuration
check_aws_config() {
    log "Checking AWS configuration..."
    
    # Check if credentials file exists
    if [[ -f ~/.aws/credentials ]]; then
        log "AWS credentials file found: ~/.aws/credentials"
        echo "Available profiles:"
        grep -E "^\[.*\]" ~/.aws/credentials | sed 's/\[//;s/\]//' || echo "No profiles found"
    else
        warn "AWS credentials file not found: ~/.aws/credentials"
    fi
    
    # Check if config file exists
    if [[ -f ~/.aws/config ]]; then
        log "AWS config file found: ~/.aws/config"
    else
        warn "AWS config file not found: ~/.aws/config"
    fi
    
    # Try to get caller identity
    if aws sts get-caller-identity &> /dev/null; then
        log "✅ AWS credentials are working!"
        local identity
        identity=$(aws sts get-caller-identity --query 'Arn' --output text)
        log "Current identity: $identity"
        
        local account_id
        account_id=$(aws sts get-caller-identity --query 'Account' --output text)
        log "Account ID: $account_id"
        
        local user_id
        user_id=$(aws sts get-caller-identity --query 'UserId' --output text)
        log "User ID: $user_id"
    else
        warn "❌ AWS credentials are not working or not configured"
        echo "Run: aws configure"
        echo "Or use this script with -i for interactive setup"
    fi
}

# Function to setup credentials interactively
setup_interactive() {
    log "Interactive AWS credentials setup"
    
    echo ""
    echo "Please provide your AWS credentials:"
    echo "You can get these from the AWS Console > IAM > Users > Security credentials"
    echo ""
    
    read -p "AWS Access Key ID: " ACCESS_KEY
    read -s -p "AWS Secret Access Key: " SECRET_KEY
    echo ""
    read -p "AWS Session Token (optional, press Enter to skip): " SESSION_TOKEN
    
    if [[ -z "$ACCESS_KEY" || -z "$SECRET_KEY" ]]; then
        error "Access Key ID and Secret Access Key are required"
    fi
}

# Function to configure AWS credentials
configure_aws() {
    log "Configuring AWS credentials for profile: $AWS_PROFILE"
    
    # Create AWS directory if it doesn't exist
    mkdir -p ~/.aws
    
    # Configure credentials
    if [[ -n "$SESSION_TOKEN" ]]; then
        aws configure set aws_access_key_id "$ACCESS_KEY" --profile "$AWS_PROFILE"
        aws configure set aws_secret_access_key "$SECRET_KEY" --profile "$AWS_PROFILE"
        aws configure set aws_session_token "$SESSION_TOKEN" --profile "$AWS_PROFILE"
        aws configure set region "$AWS_REGION" --profile "$AWS_PROFILE"
        log "Configured with session token"
    else
        aws configure set aws_access_key_id "$ACCESS_KEY" --profile "$AWS_PROFILE"
        aws configure set aws_secret_access_key "$SECRET_KEY" --profile "$AWS_PROFILE"
        aws configure set region "$AWS_REGION" --profile "$AWS_PROFILE"
        log "Configured without session token"
    fi
    
    # Test the configuration
    if aws sts get-caller-identity --profile "$AWS_PROFILE" &> /dev/null; then
        log "✅ AWS credentials configured successfully!"
        local identity
        identity=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query 'Arn' --output text)
        log "Identity: $identity"
    else
        error "Failed to configure AWS credentials"
    fi
}

# Function to create a Terraform role
create_terraform_role() {
    log "Creating Terraform role for easier deployments..."
    
    local account_id
    account_id=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query 'Account' --output text)
    
    log "Account ID: $account_id"
    
    # Create trust policy
    local trust_policy
    trust_policy=$(cat << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${account_id}:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {}
        }
    ]
}
EOF
)
    
    # Create policy document
    local policy_document
    policy_document=$(cat << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "rds:*",
                "iam:*",
                "s3:*",
                "route53:*",
                "acm:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "eks:*",
                "ssm:*",
                "kms:*",
                "cloudwatch:*",
                "logs:*",
                "ecr:*",
                "sts:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
)
    
    # Create the role
    log "Creating IAM role: terraform-role"
    aws iam create-role \
        --profile "$AWS_PROFILE" \
        --role-name "terraform-role" \
        --assume-role-policy-document "$trust_policy" \
        --description "Role for Terraform deployments" || warn "Role may already exist"
    
    # Attach the policy
    log "Attaching policy to role"
    aws iam put-role-policy \
        --profile "$AWS_PROFILE" \
        --role-name "terraform-role" \
        --policy-name "terraform-policy" \
        --policy-document "$policy_document" || warn "Policy may already exist"
    
    local role_arn="arn:aws:iam::${account_id}:role/terraform-role"
    log "✅ Terraform role created: $role_arn"
    
    echo ""
    echo "You can now use the role assumption script:"
    echo "./scripts/assume-role.sh -e $role_arn"
    echo ""
}

# Main execution
main() {
    log "🚀 AWS Setup Script"
    
    check_aws_cli
    
    if [[ "$CHECK_ONLY" == "true" ]]; then
        check_aws_config
        exit 0
    fi
    
    # If interactive mode is requested
    if [[ "$INTERACTIVE" == "true" ]]; then
        setup_interactive
    fi
    
    # If credentials are provided via command line
    if [[ -n "$ACCESS_KEY" && -n "$SECRET_KEY" ]]; then
        configure_aws
    elif [[ "$INTERACTIVE" == "false" ]]; then
        error "No credentials provided. Use -i for interactive mode or provide -k and -s"
    fi
    
    # Check the configuration
    check_aws_config
    
    # Ask if user wants to create a Terraform role
    echo ""
    read -p "Do you want to create a Terraform role for easier deployments? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_terraform_role
    fi
    
    log "✅ AWS setup completed!"
    
    echo ""
    echo "Next steps:"
    echo "1. If you created a Terraform role, use: ./scripts/assume-role.sh -e arn:aws:iam::ACCOUNT:role/terraform-role"
    echo "2. Run: terraform plan"
    echo "3. Run: terraform apply"
    echo ""
}

# Run main function
main "$@"
