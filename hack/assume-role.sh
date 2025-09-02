#!/bin/bash
# AWS Role Assumption Script
# This script helps you assume AWS roles and generate temporary credentials

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
Usage: $0 [OPTIONS] ROLE_ARN

Options:
    -d, --duration SECONDS    Duration in seconds for the temporary credentials (default: 3600)
    -s, --session-name NAME   Session name for the assumed role (default: terraform-session)
    -p, --profile PROFILE     AWS profile to use (default: default)
    -r, --region REGION       AWS region (default: us-east-1)
    -e, --export              Export credentials to environment variables
    -f, --file FILE           Save credentials to file (default: ~/.aws/credentials)
    -h, --help                Show this help message

Examples:
    $0 arn:aws:iam::123456789012:role/terraform-role
    $0 -d 7200 -s my-session arn:aws:iam::123456789012:role/terraform-role
    $0 -e -p my-profile arn:aws:iam::123456789012:role/terraform-role
    $0 -f ~/.aws/temp-creds arn:aws:iam::123456789012:role/terraform-role

EOF
}

# Default values
DURATION=3600
SESSION_NAME="terraform-session"
AWS_PROFILE="default"
AWS_REGION="us-east-1"
EXPORT_ENV=false
CREDENTIALS_FILE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        -s|--session-name)
            SESSION_NAME="$2"
            shift 2
            ;;
        -p|--profile)
            AWS_PROFILE="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -e|--export)
            EXPORT_ENV=true
            shift
            ;;
        -f|--file)
            CREDENTIALS_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            error "Unknown option: $1"
            ;;
        *)
            ROLE_ARN="$1"
            shift
            ;;
    esac
done

# Check if role ARN is provided
if [[ -z "$ROLE_ARN" ]]; then
    error "Role ARN is required. Use -h for help."
fi

# Validate role ARN format
if [[ ! "$ROLE_ARN" =~ ^arn:aws:iam::[0-9]{12}:role/[a-zA-Z0-9+=,.@_-]+$ ]]; then
    error "Invalid role ARN format: $ROLE_ARN"
fi

# Function to check AWS CLI
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed. Please install it first."
    fi
    
    if ! aws --version &> /dev/null; then
        error "AWS CLI is not working properly."
    fi
    
    log "AWS CLI version: $(aws --version)"
}

# Function to check AWS credentials
check_aws_credentials() {
    log "Checking AWS credentials for profile: $AWS_PROFILE"
    
    if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &> /dev/null; then
        error "AWS credentials not configured for profile: $AWS_PROFILE"
    fi
    
    local identity
    identity=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query 'Arn' --output text)
    log "Current identity: $identity"
}

# Function to assume role
assume_role() {
    log "Assuming role: $ROLE_ARN"
    log "Session name: $SESSION_NAME"
    log "Duration: $DURATION seconds"
    
    # Assume the role
    local assume_role_output
    assume_role_output=$(aws sts assume-role \
        --profile "$AWS_PROFILE" \
        --role-arn "$ROLE_ARN" \
        --role-session-name "$SESSION_NAME" \
        --duration-seconds "$DURATION" \
        --output json)
    
    if [[ $? -ne 0 ]]; then
        error "Failed to assume role: $ROLE_ARN"
    fi
    
    # Extract credentials
    local access_key_id
    local secret_access_key
    local session_token
    local expiration
    
    access_key_id=$(echo "$assume_role_output" | jq -r '.Credentials.AccessKeyId')
    secret_access_key=$(echo "$assume_role_output" | jq -r '.Credentials.SecretAccessKey')
    session_token=$(echo "$assume_role_output" | jq -r '.Credentials.SessionToken')
    expiration=$(echo "$assume_role_output" | jq -r '.Credentials.Expiration')
    
    # Validate extracted values
    if [[ "$access_key_id" == "null" || "$secret_access_key" == "null" || "$session_token" == "null" ]]; then
        error "Failed to extract credentials from assume-role response"
    fi
    
    log "Successfully assumed role!"
    log "Credentials expire at: $expiration"
    
    # Export to environment variables if requested
    if [[ "$EXPORT_ENV" == "true" ]]; then
        export AWS_ACCESS_KEY_ID="$access_key_id"
        export AWS_SECRET_ACCESS_KEY="$secret_access_key"
        export AWS_SESSION_TOKEN="$session_token"
        export AWS_DEFAULT_REGION="$AWS_REGION"
        
        log "Credentials exported to environment variables"
        log "You can now run Terraform commands"
    fi
    
    # Save to file if requested
    if [[ -n "$CREDENTIALS_FILE" ]]; then
        mkdir -p "$(dirname "$CREDENTIALS_FILE")"
        cat > "$CREDENTIALS_FILE" << EOF
[terraform-temp]
aws_access_key_id = $access_key_id
aws_secret_access_key = $secret_access_key
aws_session_token = $session_token
region = $AWS_REGION
EOF
        log "Credentials saved to: $CREDENTIALS_FILE"
        log "Use with: aws --profile terraform-temp"
    fi
    
    # Display credentials summary
    echo ""
    echo "=== Temporary Credentials Summary ==="
    echo "Access Key ID: ${access_key_id:0:8}..."
    echo "Secret Access Key: ${secret_access_key:0:8}..."
    echo "Session Token: ${session_token:0:20}..."
    echo "Expiration: $expiration"
    echo "Region: $AWS_REGION"
    echo ""
    
    if [[ "$EXPORT_ENV" == "true" ]]; then
        echo "Credentials are now available in your shell environment."
        echo "You can run: terraform plan, terraform apply, etc."
    elif [[ -n "$CREDENTIALS_FILE" ]]; then
        echo "To use these credentials with AWS CLI:"
        echo "aws --profile terraform-temp sts get-caller-identity"
        echo ""
        echo "To use with Terraform, set these environment variables:"
        echo "export AWS_PROFILE=terraform-temp"
        echo "export AWS_DEFAULT_REGION=$AWS_REGION"
    fi
}

# Function to create a role for Terraform
create_terraform_role() {
    log "Creating Terraform role..."
    
    local account_id
    account_id=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query 'Account' --output text)
    
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
    aws iam create-role \
        --profile "$AWS_PROFILE" \
        --role-name "terraform-role" \
        --assume-role-policy-document "$trust_policy" \
        --description "Role for Terraform deployments" || warn "Role may already exist"
    
    # Attach the policy
    aws iam put-role-policy \
        --profile "$AWS_PROFILE" \
        --role-name "terraform-role" \
        --policy-name "terraform-policy" \
        --policy-document "$policy_document" || warn "Policy may already exist"
    
    local role_arn="arn:aws:iam::${account_id}:role/terraform-role"
    log "Terraform role created: $role_arn"
    echo "You can now use: $0 $role_arn"
}

# Main execution
main() {
    log "🚀 AWS Role Assumption Script"
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        error "jq is required but not installed. Please install jq first."
    fi
    
    check_aws_cli
    check_aws_credentials
    
    # Check if user wants to create a role
    if [[ "$1" == "create-role" ]]; then
        create_terraform_role
        exit 0
    fi
    
    assume_role
    
    log "✅ Role assumption completed successfully!"
}

# Run main function
main "$@"
