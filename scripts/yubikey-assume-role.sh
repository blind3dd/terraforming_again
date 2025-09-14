#!/bin/bash
# YubiKey AWS Assume Role Script
# This script provides secure AWS assume role operations with YubiKey hardware authentication

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/yubikey-aws-config.conf"
TOKEN_CACHE_FILE="${SCRIPT_DIR}/.yubikey-token-cache"
SESSION_DURATION=3600  # 1 hour default
MAX_SESSION_DURATION=43200  # 12 hours max

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

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for required tools
    command -v aws >/dev/null 2>&1 || missing_deps+=("aws-cli")
    command -v ykman >/dev/null 2>&1 || missing_deps+=("ykman")
    command -v jq >/dev/null 2>&1 || missing_deps+=("jq")
    command -v openssl >/dev/null 2>&1 || missing_deps+=("openssl")
    command -v base64 >/dev/null 2>&1 || missing_deps+=("base64")
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing_deps[*]}"
        echo "Please install:"
        echo "  - AWS CLI: https://aws.amazon.com/cli/"
        echo "  - YubiKey Manager: https://www.yubico.com/support/download/yubikey-manager/"
        echo "  - jq: https://stedolan.github.io/jq/"
        echo "  - openssl: Usually pre-installed"
        echo "  - base64: Usually pre-installed"
    fi
}

# Check YubiKey presence
check_yubikey() {
    log "Checking for YubiKey..."
    
    if ! ykman info >/dev/null 2>&1; then
        error "No YubiKey detected. Please insert your YubiKey and try again."
    fi
    
    local yubikey_info
    yubikey_info=$(ykman info)
    log "YubiKey detected: $(echo "$yubikey_info" | head -1)"
}

# Generate challenge for YubiKey authentication
generate_challenge() {
    local challenge
    challenge=$(openssl rand -base64 32)
    echo "$challenge"
}

# Authenticate with YubiKey
authenticate_yubikey() {
    local challenge="$1"
    local expected_response="$2"
    
    log "YubiKey authentication required..."
    echo "Please touch your YubiKey to authenticate..."
    
    # Use YubiKey PIV for authentication
    local response
    if response=$(ykman piv sign -a RSA2048 -s 9a -m PKCS1 "$challenge" 2>/dev/null); then
        if [[ "$response" == "$expected_response" ]]; then
            log "YubiKey authentication successful"
            return 0
        else
            error "YubiKey authentication failed - invalid response"
        fi
    else
        error "YubiKey authentication failed - please check your YubiKey"
    fi
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        warn "Configuration file not found: $CONFIG_FILE"
        create_default_config
    fi
}

# Create default configuration
create_default_config() {
    log "Creating default configuration file..."
    
    cat > "$CONFIG_FILE" << 'EOF'
# YubiKey AWS Assume Role Configuration
# This file contains configuration for YubiKey-based AWS assume role operations

# AWS Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=""
DEFAULT_ROLE_NAME=""
DEFAULT_SESSION_NAME="yubikey-session"

# YubiKey Configuration
YUBIKEY_SLOT="9a"  # PIV slot for authentication
YUBIKEY_ALGORITHM="RSA2048"

# Security Settings
REQUIRE_YUBIKEY_AUTH=true
CACHE_TOKENS=false
TOKEN_CACHE_DURATION=300  # 5 minutes

# Role Mappings (role_name:role_arn)
# Example: ROLE_MAPPINGS["admin"]="arn:aws:iam::123456789012:role/AdminRole"
declare -A ROLE_MAPPINGS=(
    ["admin"]="arn:aws:iam::ACCOUNT_ID:role/AdminRole"
    ["developer"]="arn:aws:iam::ACCOUNT_ID:role/DeveloperRole"
    ["readonly"]="arn:aws:iam::ACCOUNT_ID:role/ReadOnlyRole"
)

# MFA Configuration
MFA_SERIAL=""
MFA_REQUIRED=false
EOF
    
    info "Default configuration created at: $CONFIG_FILE"
    info "Please edit the configuration file with your specific settings"
}

# Validate configuration
validate_config() {
    if [[ -z "${AWS_ACCOUNT_ID:-}" ]]; then
        error "AWS_ACCOUNT_ID not configured. Please set it in $CONFIG_FILE"
    fi
    
    if [[ -z "${DEFAULT_ROLE_NAME:-}" ]]; then
        error "DEFAULT_ROLE_NAME not configured. Please set it in $CONFIG_FILE"
    fi
}

# Get cached token if available
get_cached_token() {
    if [[ -f "$TOKEN_CACHE_FILE" ]]; then
        local cache_time
        cache_time=$(stat -c %Y "$TOKEN_CACHE_FILE" 2>/dev/null || echo "0")
        local current_time
        current_time=$(date +%s)
        local age=$((current_time - cache_time))
        
        if [[ $age -lt ${TOKEN_CACHE_DURATION:-300} ]]; then
            cat "$TOKEN_CACHE_FILE"
            return 0
        else
            rm -f "$TOKEN_CACHE_FILE"
        fi
    fi
    return 1
}

# Cache token
cache_token() {
    local token="$1"
    if [[ "${CACHE_TOKENS:-false}" == "true" ]]; then
        echo "$token" > "$TOKEN_CACHE_FILE"
        chmod 600 "$TOKEN_CACHE_FILE"
    fi
}

# Get MFA token from YubiKey
get_mfa_token() {
    if [[ "${MFA_REQUIRED:-false}" == "true" ]]; then
        log "MFA token required..."
        echo "Please touch your YubiKey to generate MFA token..."
        
        # Use YubiKey OTP for MFA
        local mfa_token
        mfa_token=$(ykman oath accounts code -s "${MFA_SERIAL:-}" 2>/dev/null | awk '{print $2}')
        
        if [[ -n "$mfa_token" ]]; then
            log "MFA token generated successfully"
            echo "$mfa_token"
        else
            error "Failed to generate MFA token from YubiKey"
        fi
    fi
}

# Assume role with YubiKey authentication
assume_role() {
    local role_name="$1"
    local session_name="${2:-${DEFAULT_SESSION_NAME:-yubikey-session}}"
    local duration="${3:-$SESSION_DURATION}"
    
    # Validate duration
    if [[ $duration -gt $MAX_SESSION_DURATION ]]; then
        error "Session duration cannot exceed $MAX_SESSION_DURATION seconds"
    fi
    
    # Get role ARN
    local role_arn
    if [[ -n "${ROLE_MAPPINGS[$role_name]:-}" ]]; then
        role_arn="${ROLE_MAPPINGS[$role_name]}"
    else
        role_arn="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${role_name}"
    fi
    
    log "Assuming role: $role_arn"
    log "Session name: $session_name"
    log "Duration: $duration seconds"
    
    # Check for cached token
    if cached_token=$(get_cached_token); then
        log "Using cached token"
        echo "$cached_token"
        return 0
    fi
    
    # YubiKey authentication
    if [[ "${REQUIRE_YUBIKEY_AUTH:-true}" == "true" ]]; then
        local challenge
        challenge=$(generate_challenge)
        local expected_response
        expected_response=$(echo -n "$challenge" | openssl dgst -sha256 -binary | base64)
        
        authenticate_yubikey "$challenge" "$expected_response"
    fi
    
    # Get MFA token if required
    local mfa_token
    if [[ "${MFA_REQUIRED:-false}" == "true" ]]; then
        mfa_token=$(get_mfa_token)
    fi
    
    # Assume role
    local assume_role_cmd
    assume_role_cmd="aws sts assume-role --role-arn $role_arn --role-session-name $session_name --duration-seconds $duration"
    
    if [[ -n "${mfa_token:-}" ]]; then
        assume_role_cmd="$assume_role_cmd --serial-number ${MFA_SERIAL} --token-code $mfa_token"
    fi
    
    log "Executing assume role command..."
    local assume_result
    if assume_result=$($assume_role_cmd 2>&1); then
        local credentials
        credentials=$(echo "$assume_result" | jq -r '.Credentials')
        
        if [[ "$credentials" != "null" ]]; then
            # Cache the token
            cache_token "$credentials"
            
            # Set environment variables
            export AWS_ACCESS_KEY_ID=$(echo "$credentials" | jq -r '.AccessKeyId')
            export AWS_SECRET_ACCESS_KEY=$(echo "$credentials" | jq -r '.SecretAccessKey')
            export AWS_SESSION_TOKEN=$(echo "$credentials" | jq -r '.SessionToken')
            export AWS_DEFAULT_REGION="${AWS_REGION:-us-east-1}"
            
            log "Role assumed successfully"
            log "Access Key ID: ${AWS_ACCESS_KEY_ID:0:8}..."
            log "Session expires: $(echo "$credentials" | jq -r '.Expiration')"
            
            echo "$credentials"
        else
            error "Failed to extract credentials from assume role response"
        fi
    else
        error "Failed to assume role: $assume_result"
    fi
}

# List available roles
list_roles() {
    log "Available roles:"
    for role in "${!ROLE_MAPPINGS[@]}"; do
        echo "  - $role: ${ROLE_MAPPINGS[$role]}"
    done
}

# Clear cached tokens
clear_cache() {
    if [[ -f "$TOKEN_CACHE_FILE" ]]; then
        rm -f "$TOKEN_CACHE_FILE"
        log "Token cache cleared"
    else
        info "No cached tokens found"
    fi
}

# Show current AWS identity
show_identity() {
    log "Current AWS identity:"
    aws sts get-caller-identity
}

# Interactive role selection
interactive_assume_role() {
    log "Interactive role assumption..."
    
    if [[ ${#ROLE_MAPPINGS[@]} -eq 0 ]]; then
        error "No roles configured. Please configure ROLE_MAPPINGS in $CONFIG_FILE"
    fi
    
    echo "Available roles:"
    local i=1
    local roles=()
    for role in "${!ROLE_MAPPINGS[@]}"; do
        echo "  $i) $role"
        roles+=("$role")
        ((i++))
    done
    
    echo -n "Select role (1-${#roles[@]}): "
    read -r selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 ]] && [[ $selection -le ${#roles[@]} ]]; then
        local selected_role="${roles[$((selection-1))]}"
        local session_name
        echo -n "Enter session name (default: $selected_role-session): "
        read -r session_name
        session_name="${session_name:-$selected_role-session}"
        
        assume_role "$selected_role" "$session_name"
    else
        error "Invalid selection"
    fi
}

# Show usage
show_usage() {
    cat << EOF
YubiKey AWS Assume Role Script

USAGE:
    $0 [OPTIONS] COMMAND [ARGUMENTS]

COMMANDS:
    assume ROLE_NAME [SESSION_NAME] [DURATION]
        Assume the specified role with YubiKey authentication
        
    interactive
        Interactive role selection and assumption
        
    list
        List available roles
        
    identity
        Show current AWS identity
        
    clear-cache
        Clear cached tokens
        
    config
        Show current configuration
        
    help
        Show this help message

OPTIONS:
    -c, --config FILE
        Use custom configuration file
        
    -d, --duration SECONDS
        Set session duration (default: $SESSION_DURATION)
        
    -n, --no-cache
        Disable token caching
        
    -v, --verbose
        Enable verbose output
        
    --no-yubikey
        Skip YubiKey authentication (not recommended)

EXAMPLES:
    $0 assume admin
    $0 assume developer dev-session 7200
    $0 interactive
    $0 list
    $0 clear-cache

CONFIGURATION:
    Edit $CONFIG_FILE to configure:
    - AWS account ID and region
    - Role mappings
    - YubiKey settings
    - Security options

SECURITY NOTES:
    - YubiKey authentication is required by default
    - Tokens are cached for 5 minutes by default
    - All operations are logged
    - Configuration file should be secured (600 permissions)

EOF
}

# Main function
main() {
    # Parse command line arguments
    local command=""
    local args=()
    local skip_yubikey=false
    local verbose=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -d|--duration)
                SESSION_DURATION="$2"
                shift 2
                ;;
            -n|--no-cache)
                CACHE_TOKENS=false
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            --no-yubikey)
                skip_yubikey=true
                shift
                ;;
            -h|--help|help)
                show_usage
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                ;;
            *)
                if [[ -z "$command" ]]; then
                    command="$1"
                else
                    args+=("$1")
                fi
                shift
                ;;
        esac
    done
    
    # Set verbose mode
    if [[ "$verbose" == "true" ]]; then
        set -x
    fi
    
    # Override YubiKey requirement if specified
    if [[ "$skip_yubikey" == "true" ]]; then
        REQUIRE_YUBIKEY_AUTH=false
    fi
    
    # Check dependencies
    check_dependencies
    
    # Load and validate configuration
    load_config
    validate_config
    
    # Check YubiKey if required
    if [[ "${REQUIRE_YUBIKEY_AUTH:-true}" == "true" ]]; then
        check_yubikey
    fi
    
    # Execute command
    case "$command" in
        assume)
            if [[ ${#args[@]} -lt 1 ]]; then
                error "Role name required for assume command"
            fi
            assume_role "${args[0]}" "${args[1]:-}" "${args[2]:-}"
            ;;
        interactive)
            interactive_assume_role
            ;;
        list)
            list_roles
            ;;
        identity)
            show_identity
            ;;
        clear-cache)
            clear_cache
            ;;
        config)
            cat "$CONFIG_FILE"
            ;;
        "")
            show_usage
            ;;
        *)
            error "Unknown command: $command"
            ;;
    esac
}

# Run main function
main "$@"
