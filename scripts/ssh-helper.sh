#!/bin/bash
# SSH Helper Script for Secure Infrastructure Access
# This script provides easy access to all instances via jump host

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SSH_KEY="~/.ssh/ec2-key-pair.pem"
SSH_CONFIG="~/.ssh/config"
JUMP_HOST="172.16.2.10"
K8S_MASTER="172.16.2.12"
VPN_SERVER="172.16.2.11"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Function to check SSH key
check_ssh_key() {
    local key_path="${SSH_KEY/#\~/$HOME}"
    
    if [[ ! -f "$key_path" ]]; then
        error "SSH key not found at $key_path"
        error "Please ensure the EC2 key pair is available"
        return 1
    fi
    
    if [[ ! -r "$key_path" ]]; then
        error "SSH key is not readable. Please check permissions:"
        error "chmod 600 $key_path"
        return 1
    fi
    
    success "SSH key found and readable: $key_path"
    return 0
}

# Function to check SSH config
check_ssh_config() {
    local config_path="${SSH_CONFIG/#\~/$HOME}"
    
    if [[ ! -f "$config_path" ]]; then
        warning "SSH config not found at $config_path"
        warning "Creating SSH config from template..."
        create_ssh_config
        return $?
    fi
    
    success "SSH config found: $config_path"
    return 0
}

# Function to create SSH config
create_ssh_config() {
    local config_path="${SSH_CONFIG/#\~/$HOME}"
    local template_path="templates/ssh-config-template"
    
    if [[ ! -f "$template_path" ]]; then
        error "SSH config template not found at $template_path"
        return 1
    fi
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "$(dirname "$config_path")"
    
    # Copy template to SSH config
    cp "$template_path" "$config_path"
    chmod 600 "$config_path"
    
    success "SSH config created from template: $config_path"
    return 0
}

# Function to test connectivity
test_connectivity() {
    local host="$1"
    local description="$2"
    
    info "Testing connectivity to $description ($host)..."
    
    if ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" "echo 'Connection successful'" > /dev/null 2>&1; then
        success "✓ $description is reachable"
        return 0
    else
        error "✗ $description is not reachable"
        return 1
    fi
}

# Function to connect to jump host
connect_jump_host() {
    log "Connecting to jump host..."
    
    if ! check_ssh_key; then
        return 1
    fi
    
    if ! check_ssh_config; then
        return 1
    fi
    
    info "Connecting to jump host (Go-MySQL) at $JUMP_HOST..."
    ssh jump-host
}

# Function to connect to Kubernetes master
connect_k8s_master() {
    log "Connecting to Kubernetes master..."
    
    if ! check_ssh_key; then
        return 1
    fi
    
    if ! check_ssh_config; then
        return 1
    fi
    
    info "Connecting to Kubernetes master at $K8S_MASTER..."
    ssh control-plane
}

# Function to connect to VPN server
connect_vpn_server() {
    log "Connecting to VPN server..."
    
    if ! check_ssh_key; then
        return 1
    fi
    
    if ! check_ssh_config; then
        return 1
    fi
    
    info "Connecting to VPN server at $VPN_SERVER..."
    ssh vpn-server
}

# Function to test all connections
test_all_connections() {
    log "Testing all connections..."
    
    if ! check_ssh_key; then
        return 1
    fi
    
    if ! check_ssh_config; then
        return 1
    fi
    
    local failed=0
    
    # Test jump host
    if ! test_connectivity "jump-host" "Jump Host"; then
        ((failed++))
    fi
    
    # Test Kubernetes master
    if ! test_connectivity "control-plane" "Kubernetes Master"; then
        ((failed++))
    fi
    
    # Test VPN server
    if ! test_connectivity "vpn-server" "VPN Server"; then
        ((failed++))
    fi
    
    if [[ $failed -eq 0 ]]; then
        success "All connections successful!"
        return 0
    else
        error "$failed connection(s) failed"
        return 1
    fi
}

# Function to show connection status
show_status() {
    log "Infrastructure Connection Status"
    echo ""
    echo -e "${CYAN}Jump Host (Go-MySQL):${NC}"
    echo "  IP: $JUMP_HOST"
    echo "  FQDN: go-mysql-jump-host.internal.coderedalarmtech.com"
    echo "  Purpose: Secure gateway to all private instances"
    echo ""
    echo -e "${CYAN}Kubernetes Master:${NC}"
    echo "  IP: $K8S_MASTER"
    echo "  FQDN: kubernetes-control-plane.internal.coderedalarmtech.com"
    echo "  Purpose: Kubernetes API server and control plane"
    echo ""
    echo -e "${CYAN}VPN Server:${NC}"
    echo "  IP: $VPN_SERVER"
    echo "  FQDN: wireguard-vpn-server.internal.coderedalarmtech.com"
    echo "  Purpose: VPN gateway for secure remote access"
    echo ""
    echo -e "${CYAN}Access Flow:${NC}"
    echo "  Local Machine → VPN → Jump Host → Target Instance"
    echo ""
    echo -e "${CYAN}SSH Commands:${NC}"
    echo "  ssh jump-host      # Connect to jump host"
    echo "  ssh control-plane     # Connect to Kubernetes master"
    echo "  ssh vpn-server     # Connect to VPN server"
    echo ""
    echo -e "${CYAN}Alternative Names:${NC}"
    echo "  ssh kubernetes     # Same as control-plane"
    echo "  ssh wireguard      # Same as vpn-server"
}

# Function to show help
show_help() {
    echo -e "${PURPLE}SSH Helper Script for Secure Infrastructure Access${NC}"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  jump-host          Connect to jump host (Go-MySQL)"
    echo "  control-plane      Connect to Kubernetes control plane"
    echo "  kubernetes         Connect to Kubernetes control plane (alias)"
    echo "  vpn-server         Connect to VPN server"
    echo "  wireguard          Connect to VPN server (alias)"
    echo "  test               Test all connections"
    echo "  status             Show connection status"
    echo "  setup              Setup SSH config from template"
    echo "  help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 jump-host       # Connect to jump host"
    echo "  $0 control-plane      # Connect to Kubernetes master"
    echo "  $0 test            # Test all connections"
    echo "  $0 status          # Show status"
    echo ""
    echo "Prerequisites:"
    echo "  1. EC2 key pair at ~/.ssh/ec2-key-pair.pem"
    echo "  2. SSH config at ~/.ssh/config (created by 'setup' command)"
    echo "  3. VPN connection to access private instances"
    echo ""
    echo "Security Features:"
    echo "  - All access goes through jump host"
    echo "  - IMDSv2 enforcement on all instances"
    echo "  - Static private IPs for predictable access"
    echo "  - SSH key forwarding for seamless access"
}

# Function to setup SSH config
setup_ssh_config() {
    log "Setting up SSH configuration..."
    
    if ! check_ssh_key; then
        return 1
    fi
    
    if ! create_ssh_config; then
        return 1
    fi
    
    success "SSH configuration setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Connect to VPN: $0 vpn-server"
    echo "2. Test connections: $0 test"
    echo "3. Access instances: $0 control-plane"
}

# Main function
main() {
    case "${1:-help}" in
        "jump-host")
            connect_jump_host
            ;;
        "control-plane"|"kubernetes")
            connect_k8s_master
            ;;
        "vpn-server"|"wireguard")
            connect_vpn_server
            ;;
        "test")
            test_all_connections
            ;;
        "status")
            show_status
            ;;
        "setup")
            setup_ssh_config
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
