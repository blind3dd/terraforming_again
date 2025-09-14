#!/bin/bash

# AWS Credentials from SSM Script
# Retrieves AWS credentials from AWS Systems Manager Parameter Store
# 
# Usage: 
#   source ./get-aws-creds-from-ssm.sh
#   # or
#   eval $(./get-aws-creds-from-ssm.sh)

set -e

# Configuration
AWS_CREDS_PARAM="/ansible/aws/credentials"
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_PROFILE="${AWS_PROFILE:-default}"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

# Function to get AWS credentials from SSM
get_aws_credentials() {
    local param_name="$1"
    local region="$2"
    local profile="$3"
    
    log "Retrieving AWS credentials from SSM Parameter: $param_name"
    
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

# Function to export AWS credentials as environment variables
export_aws_credentials() {
    local creds_json="$1"
    
    # Parse JSON and export as environment variables
    export AWS_ACCESS_KEY_ID=$(echo "$creds_json" | jq -r '.access_key_id')
    export AWS_SECRET_ACCESS_KEY=$(echo "$creds_json" | jq -r '.secret_access_key')
    export AWS_SESSION_TOKEN=$(echo "$creds_json" | jq -r '.session_token // empty')
    export AWS_DEFAULT_REGION="${AWS_REGION}"
    
    log "AWS credentials exported to environment variables"
}

# Function to create AWS credentials in SSM (for initial setup)
create_aws_credentials() {
    local param_name="$1"
    local region="$2"
    local profile="$3"
    local access_key="$4"
    local secret_key="$5"
    local session_token="${6:-}"
    
    local creds_json=$(cat <<EOF
{
  "access_key_id": "$access_key",
  "secret_access_key": "$secret_key",
  "session_token": "$session_token"
}
EOF
)
    
    log "Creating AWS credentials in SSM Parameter: $param_name"
    
    if [[ -n "$profile" && "$profile" != "default" ]]; then
        aws ssm put-parameter \
            --name "$param_name" \
            --value "$creds_json" \
            --type "SecureString" \
            --description "AWS Credentials for Ansible" \
            --region "$region" \
            --profile "$profile" \
            --overwrite
    else
        aws ssm put-parameter \
            --name "$param_name" \
            --value "$creds_json" \
            --type "SecureString" \
            --description "AWS Credentials for Ansible" \
            --region "$region" \
            --overwrite
    fi
}

# Function to generate AWS credentials output for Ansible
generate_ansible_output() {
    local creds_json="$1"
    
    echo "export AWS_ACCESS_KEY_ID='$(echo "$creds_json" | jq -r '.access_key_id')'"
    echo "export AWS_SECRET_ACCESS_KEY='$(echo "$creds_json" | jq -r '.secret_access_key')'"
    echo "export AWS_SESSION_TOKEN='$(echo "$creds_json" | jq -r '.session_token // empty')'"
    echo "export AWS_DEFAULT_REGION='${AWS_REGION}'"
}

# Main execution
main() {
    # Check if AWS CLI is available
    if ! command -v aws &> /dev/null; then
        log "ERROR: AWS CLI is not installed or not in PATH"
        exit 1
    fi
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        log "ERROR: jq is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we're being called to create credentials
    if [[ "$1" == "create" ]]; then
        local access_key="${2:-}"
        local secret_key="${3:-}"
        local session_token="${4:-}"
        
        if [[ -z "$access_key" || -z "$secret_key" ]]; then
            log "ERROR: Access key and secret key are required"
            log "Usage: $0 create <access_key> <secret_key> [session_token]"
            exit 1
        fi
        
        create_aws_credentials "$AWS_CREDS_PARAM" "$AWS_REGION" "$AWS_PROFILE" "$access_key" "$secret_key" "$session_token"
        log "AWS credentials created successfully in SSM"
        exit 0
    fi
    
    # Check if we're being called to view credentials
    if [[ "$1" == "view" ]]; then
        get_aws_credentials "$AWS_CREDS_PARAM" "$AWS_REGION" "$AWS_PROFILE"
        exit 0
    fi
    
    # Check if we're being called to export credentials
    if [[ "$1" == "export" ]]; then
        local creds_json
        creds_json=$(get_aws_credentials "$AWS_CREDS_PARAM" "$AWS_REGION" "$AWS_PROFILE")
        export_aws_credentials "$creds_json"
        exit 0
    fi
    
    # Normal operation: generate output for Ansible
    try {
        local creds_json
        creds_json=$(get_aws_credentials "$AWS_CREDS_PARAM" "$AWS_REGION" "$AWS_PROFILE")
        generate_ansible_output "$creds_json"
    } catch {
        log "ERROR: Failed to retrieve AWS credentials from SSM"
        log "Make sure you have:"
        log "1. AWS credentials configured"
        log "2. Permission to access SSM Parameter Store"
        log "3. The parameter exists: $AWS_CREDS_PARAM"
        log ""
        log "To create the parameter, run:"
        log "  $0 create <access_key> <secret_key> [session_token]"
        exit 1
    }
}

# Run main function
main "$@"
