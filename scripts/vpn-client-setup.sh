#!/bin/bash
# WireGuard VPN Client Setup Script
# This script sets up a WireGuard VPN client to connect to the secure infrastructure

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
VPN_PROFILE_DIR="$HOME/.wireguard"
VPN_PROFILE_FILE="$VPN_PROFILE_DIR/secure-infrastructure.conf"
VPN_SERVER_IP="172.16.2.11"  # Will be updated after deployment
VPN_SERVER_PORT="51820"
VPN_SUBNET="10.100.0.0/24"
VPC_SUBNET="172.16.0.0/16"

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

# Function to check if WireGuard is installed
check_wireguard_installation() {
    if command -v wg > /dev/null 2>&1; then
        success "WireGuard is installed: $(wg --version)"
        return 0
    else
        error "WireGuard is not installed"
        return 1
    fi
}

# Function to install WireGuard (macOS)
install_wireguard_macos() {
    log "Installing WireGuard on macOS..."
    
    if command -v brew > /dev/null 2>&1; then
        brew install wireguard-tools
        success "WireGuard installed via Homebrew"
    else
        error "Homebrew not found. Please install WireGuard manually:"
        error "1. Download from https://www.wireguard.com/install/"
        error "2. Or install via Mac App Store"
        return 1
    fi
}

# Function to install WireGuard (Linux)
install_wireguard_linux() {
    log "Installing WireGuard on Linux..."
    
    if command -v apt > /dev/null 2>&1; then
        sudo apt update
        sudo apt install -y wireguard
        success "WireGuard installed via apt"
    elif command -v yum > /dev/null 2>&1; then
        sudo yum install -y epel-release
        sudo yum install -y wireguard-tools
        success "WireGuard installed via yum"
    elif command -v dnf > /dev/null 2>&1; then
        sudo dnf install -y wireguard-tools
        success "WireGuard installed via dnf"
    else
        error "Package manager not supported. Please install WireGuard manually"
        return 1
    fi
}

# Function to install WireGuard
install_wireguard() {
    case "$(uname -s)" in
        "Darwin")
            install_wireguard_macos
            ;;
        "Linux")
            install_wireguard_linux
            ;;
        *)
            error "Unsupported operating system: $(uname -s)"
            error "Please install WireGuard manually"
            return 1
            ;;
    esac
}

# Function to generate client keys
generate_client_keys() {
    log "Generating WireGuard client keys..."
    
    # Create VPN profile directory
    mkdir -p "$VPN_PROFILE_DIR"
    chmod 700 "$VPN_PROFILE_DIR"
    
    # Generate client private key
    local client_private_key
    client_private_key=$(wg genkey)
    
    # Generate client public key
    local client_public_key
    client_public_key=$(echo "$client_private_key" | wg pubkey)
    
    # Store keys securely
    echo "$client_private_key" > "$VPN_PROFILE_DIR/client_private.key"
    echo "$client_public_key" > "$VPN_PROFILE_DIR/client_public.key"
    chmod 600 "$VPN_PROFILE_DIR/client_private.key"
    chmod 600 "$VPN_PROFILE_DIR/client_public.key"
    
    success "Client keys generated:"
    info "Private key: $VPN_PROFILE_DIR/client_private.key"
    info "Public key: $VPN_PROFILE_DIR/client_public.key"
    info "Public key: $client_public_key"
    
    # Return public key for server configuration
    echo "$client_public_key"
}

# Function to create VPN profile
create_vpn_profile() {
    local client_private_key="$1"
    local server_public_key="$2"
    local server_endpoint="$3"
    
    log "Creating VPN profile..."
    
    cat > "$VPN_PROFILE_FILE" << EOF
# WireGuard VPN Client Profile
# Secure Infrastructure Access
# Generated on $(date)

[Interface]
# Client private key
PrivateKey = $client_private_key

# Client IP in VPN subnet
Address = 10.100.0.2/24

# DNS servers for secure resolution
DNS = 8.8.8.8, 1.1.1.1

# MTU for optimal performance
MTU = 1420

# Post-up and Post-down scripts for additional security
PostUp = iptables -A OUTPUT -d 169.254.169.254 -p tcp --dport 80 -j DROP
PostDown = iptables -D OUTPUT -d 169.254.169.254 -p tcp --dport 80 -j DROP

[Peer]
# VPN server public key
PublicKey = $server_public_key

# VPN server endpoint
Endpoint = $server_endpoint:$VPN_SERVER_PORT

# Allowed IPs (VPN subnet and VPC subnet)
AllowedIPs = $VPN_SUBNET, $VPC_SUBNET

# Persistent keepalive
PersistentKeepalive = 25

# Connection timeout
HandshakeTimeout = 30

# Connection retry
ConnectionRetry = 5
EOF

    chmod 600 "$VPN_PROFILE_FILE"
    success "VPN profile created: $VPN_PROFILE_FILE"
}

# Function to test VPN connection
test_vpn_connection() {
    log "Testing VPN connection..."
    
    # Check if VPN is connected
    if wg show > /dev/null 2>&1; then
        success "VPN is connected"
        
        # Test connectivity to VPN server
        if ping -c 1 -W 5 "$VPN_SERVER_IP" > /dev/null 2>&1; then
            success "VPN server is reachable: $VPN_SERVER_IP"
        else
            warning "VPN server is not reachable: $VPN_SERVER_IP"
        fi
        
        # Test connectivity to jump host
        if ping -c 1 -W 5 "172.16.2.10" > /dev/null 2>&1; then
            success "Jump host is reachable: 172.16.2.10"
        else
            warning "Jump host is not reachable: 172.16.2.10"
        fi
        
        return 0
    else
        error "VPN is not connected"
        return 1
    fi
}

# Function to connect to VPN
connect_vpn() {
    log "Connecting to VPN..."
    
    if [[ ! -f "$VPN_PROFILE_FILE" ]]; then
        error "VPN profile not found: $VPN_PROFILE_FILE"
        error "Please run setup first: $0 setup"
        return 1
    fi
    
    # Connect to VPN
    if sudo wg-quick up "$VPN_PROFILE_FILE"; then
        success "VPN connected successfully"
        test_vpn_connection
    else
        error "Failed to connect to VPN"
        return 1
    fi
}

# Function to disconnect from VPN
disconnect_vpn() {
    log "Disconnecting from VPN..."
    
    if sudo wg-quick down "$VPN_PROFILE_FILE"; then
        success "VPN disconnected successfully"
    else
        error "Failed to disconnect from VPN"
        return 1
    fi
}

# Function to show VPN status
show_vpn_status() {
    log "VPN Status:"
    echo ""
    
    if wg show > /dev/null 2>&1; then
        success "VPN is connected"
        echo ""
        wg show
    else
        warning "VPN is not connected"
    fi
    
    echo ""
    echo -e "${CYAN}VPN Configuration:${NC}"
    echo "  Profile: $VPN_PROFILE_FILE"
    echo "  Server: $VPN_SERVER_IP:$VPN_SERVER_PORT"
    echo "  VPN Subnet: $VPN_SUBNET"
    echo "  VPC Subnet: $VPC_SUBNET"
    echo ""
    echo -e "${CYAN}Access Flow:${NC}"
    echo "  Local Machine → WireGuard VPN → Jump Host → Target Instances"
    echo ""
    echo -e "${CYAN}SSH Commands (after VPN connection):${NC}"
    echo "  ssh jump-host      # Connect to jump host"
    echo "  ssh k8s-master     # Connect to Kubernetes master"
    echo "  ssh vpn-server     # Connect to VPN server"
}

# Function to setup VPN client
setup_vpn_client() {
    log "Setting up WireGuard VPN client..."
    
    # Check if WireGuard is installed
    if ! check_wireguard_installation; then
        info "Installing WireGuard..."
        if ! install_wireguard; then
            return 1
        fi
    fi
    
    # Generate client keys
    local client_public_key
    client_public_key=$(generate_client_keys)
    
    # Get server configuration from user
    echo ""
    info "Please provide the following information:"
    echo "1. VPN server public key (from server deployment)"
    echo "2. VPN server endpoint (public IP or domain)"
    echo ""
    
    read -p "VPN server public key: " server_public_key
    read -p "VPN server endpoint: " server_endpoint
    
    if [[ -z "$server_public_key" || -z "$server_endpoint" ]]; then
        error "Server public key and endpoint are required"
        return 1
    fi
    
    # Get client private key
    local client_private_key
    client_private_key=$(cat "$VPN_PROFILE_DIR/client_private.key")
    
    # Create VPN profile
    create_vpn_profile "$client_private_key" "$server_public_key" "$server_endpoint"
    
    echo ""
    success "VPN client setup completed!"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. Add client public key to VPN server: $client_public_key"
    echo "2. Connect to VPN: $0 connect"
    echo "3. Test connection: $0 test"
    echo "4. Access instances: ssh jump-host"
    echo ""
    echo -e "${CYAN}Client public key for server configuration:${NC}"
    echo "$client_public_key"
}

# Function to show help
show_help() {
    echo -e "${PURPLE}WireGuard VPN Client Setup Script${NC}"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup              Setup VPN client (first time)"
    echo "  connect            Connect to VPN"
    echo "  disconnect         Disconnect from VPN"
    echo "  test               Test VPN connection"
    echo "  status             Show VPN status"
    echo "  help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup           # Setup VPN client"
    echo "  $0 connect         # Connect to VPN"
    echo "  $0 test            # Test connection"
    echo "  $0 status          # Show status"
    echo ""
    echo "Prerequisites:"
    echo "  1. VPN server must be deployed and running"
    echo "  2. Server public key and endpoint from deployment"
    echo "  3. WireGuard client installed on local machine"
    echo ""
    echo "Security Features:"
    echo "  - Strong encryption (ChaCha20-Poly1305)"
    echo "  - Perfect Forward Secrecy"
    echo "  - Zero-knowledge architecture"
    echo "  - eBPF-based network security"
    echo "  - IMDSv2 enforcement"
}

# Main function
main() {
    case "${1:-help}" in
        "setup")
            setup_vpn_client
            ;;
        "connect")
            connect_vpn
            ;;
        "disconnect")
            disconnect_vpn
            ;;
        "test")
            test_vpn_connection
            ;;
        "status")
            show_vpn_status
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
