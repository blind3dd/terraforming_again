#!/bin/bash
# IMDSv2 Helper Script
# This script provides secure access to AWS Instance Metadata Service v2
# It handles token retrieval and subsequent metadata requests with proper headers

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# IMDSv2 Configuration
METADATA_BASE_URL="http://169.254.169.254"
TOKEN_TTL=21600  # 6 hours (maximum allowed)
TOKEN_FILE="/tmp/imdsv2_token"

# Function to get IMDSv2 token
get_imdsv2_token() {
    local ttl=${1:-$TOKEN_TTL}
    
    log "Requesting IMDSv2 token with TTL: ${ttl} seconds"
    
    # Request token with PUT method
    local token_response
    if token_response=$(curl -s -X PUT \
        -H "X-aws-ec2-metadata-token-ttl-seconds: ${ttl}" \
        "${METADATA_BASE_URL}/latest/api/token" 2>/dev/null); then
        
        if [[ -n "$token_response" && ${#token_response} -gt 10 ]]; then
            echo "$token_response"
            return 0
        else
            error "Invalid token response received"
        fi
    else
        error "Failed to retrieve IMDSv2 token"
    fi
}

# Function to get metadata with IMDSv2 token
get_metadata() {
    local path="$1"
    local token="$2"
    
    if [[ -z "$token" ]]; then
        error "IMDSv2 token is required"
    fi
    
    if [[ -z "$path" ]]; then
        error "Metadata path is required"
    fi
    
    # Remove leading slash if present
    path="${path#/}"
    
    log "Retrieving metadata: ${path}"
    
    # Get metadata with token header
    if curl -s -H "X-aws-ec2-metadata-token: ${token}" \
        "${METADATA_BASE_URL}/latest/meta-data/${path}"; then
        return 0
    else
        error "Failed to retrieve metadata: ${path}"
    fi
}

# Function to get user data with IMDSv2 token
get_user_data() {
    local token="$1"
    
    if [[ -z "$token" ]]; then
        error "IMDSv2 token is required"
    fi
    
    log "Retrieving user data"
    
    # Get user data with token header
    if curl -s -H "X-aws-ec2-metadata-token: ${token}" \
        "${METADATA_BASE_URL}/latest/user-data"; then
        return 0
    else
        error "Failed to retrieve user data"
    fi
}

# Function to check if token is valid
is_token_valid() {
    local token="$1"
    
    if [[ -z "$token" ]]; then
        return 1
    fi
    
    # Try to get instance ID to validate token
    if get_metadata "instance-id" "$token" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to get or refresh token
ensure_valid_token() {
    local token=""
    
    # Check if we have a cached token
    if [[ -f "$TOKEN_FILE" ]]; then
        token=$(cat "$TOKEN_FILE" 2>/dev/null || echo "")
        
        # Validate cached token
        if is_token_valid "$token"; then
            log "Using cached IMDSv2 token"
            echo "$token"
            return 0
        else
            warn "Cached token is invalid, requesting new token"
            rm -f "$TOKEN_FILE"
        fi
    fi
    
    # Get new token
    token=$(get_imdsv2_token)
    
    # Cache the token
    echo "$token" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    
    log "New IMDSv2 token obtained and cached"
    echo "$token"
}

# Function to get common metadata
get_instance_id() {
    local token
    token=$(ensure_valid_token)
    get_metadata "instance-id" "$token"
}

get_availability_zone() {
    local token
    token=$(ensure_valid_token)
    get_metadata "placement/availability-zone" "$token"
}

get_region() {
    local az
    az=$(get_availability_zone)
    echo "${az%?}"  # Remove last character (zone letter)
}

get_instance_type() {
    local token
    token=$(ensure_valid_token)
    get_metadata "instance-type" "$token"
}

get_public_ip() {
    local token
    token=$(ensure_valid_token)
    get_metadata "public-ipv4" "$token"
}

get_private_ip() {
    local token
    token=$(ensure_valid_token)
    get_metadata "local-ipv4" "$token"
}

get_security_groups() {
    local token
    token=$(ensure_valid_token)
    get_metadata "security-groups" "$token"
}

get_iam_role() {
    local token
    token=$(ensure_valid_token)
    get_metadata "iam/security-credentials" "$token"
}

# Function to get IAM credentials
get_iam_credentials() {
    local role_name="$1"
    local token
    token=$(ensure_valid_token)
    
    if [[ -z "$role_name" ]]; then
        error "IAM role name is required"
    fi
    
    log "Retrieving IAM credentials for role: ${role_name}"
    get_metadata "iam/security-credentials/${role_name}" "$token"
}

# Function to validate IMDSv2 is working
validate_imdsv2() {
    log "Validating IMDSv2 configuration..."
    
    # Test token retrieval
    if ! get_imdsv2_token 60 >/dev/null 2>&1; then
        error "IMDSv2 token retrieval failed"
    fi
    
    # Test metadata access
    local token
    token=$(get_imdsv2_token 60)
    
    if ! get_metadata "instance-id" "$token" >/dev/null 2>&1; then
        error "IMDSv2 metadata access failed"
    fi
    
    log "IMDSv2 validation successful"
}

# Function to show usage
show_usage() {
    cat << EOF
IMDSv2 Helper Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    token [TTL]              Get IMDSv2 token (default TTL: 21600 seconds)
    metadata <path>          Get metadata at specified path
    user-data                Get user data
    instance-id              Get instance ID
    availability-zone        Get availability zone
    region                   Get region
    instance-type            Get instance type
    public-ip                Get public IP
    private-ip               Get private IP
    security-groups          Get security groups
    iam-role                 Get IAM role name
    iam-credentials <role>   Get IAM credentials for role
    validate                 Validate IMDSv2 configuration
    help                     Show this help

Examples:
    $0 token 3600                    # Get token with 1 hour TTL
    $0 metadata instance-id          # Get instance ID
    $0 metadata iam/security-credentials  # Get IAM role
    $0 iam-credentials MyRole        # Get credentials for MyRole
    $0 validate                      # Validate IMDSv2 setup

Environment Variables:
    METADATA_BASE_URL        Base URL for metadata service (default: http://169.254.169.254)
    TOKEN_TTL               Default token TTL in seconds (default: 21600)
    TOKEN_FILE              Token cache file path (default: /tmp/imdsv2_token)

EOF
}

# Main script logic
main() {
    local command="${1:-help}"
    
    case "$command" in
        "token")
            local ttl="${2:-$TOKEN_TTL}"
            get_imdsv2_token "$ttl"
            ;;
        "metadata")
            local path="$2"
            local token
            token=$(ensure_valid_token)
            get_metadata "$path" "$token"
            ;;
        "user-data")
            local token
            token=$(ensure_valid_token)
            get_user_data "$token"
            ;;
        "instance-id")
            get_instance_id
            ;;
        "availability-zone")
            get_availability_zone
            ;;
        "region")
            get_region
            ;;
        "instance-type")
            get_instance_type
            ;;
        "public-ip")
            get_public_ip
            ;;
        "private-ip")
            get_private_ip
            ;;
        "security-groups")
            get_security_groups
            ;;
        "iam-role")
            get_iam_role
            ;;
        "iam-credentials")
            local role_name="$2"
            get_iam_credentials "$role_name"
            ;;
        "validate")
            validate_imdsv2
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            error "Unknown command: $command"
            show_usage
            ;;
    esac
}

# Run main function with all arguments
main "$@"
