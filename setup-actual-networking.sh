#!/bin/bash

# Actual Networking Implementation for Multi-Cloud Kubernetes Volumes
# Creates real network interfaces, namespaces, bridges, and NAT for volume communication

set -euo pipefail

# Configuration
BASE_DIR="/opt/nix-volumes"
NETWORK_DIR="$BASE_DIR/networking"

# Network configuration grouped by cloud providers
PROVIDER_NETWORKS=(
    "aws:10.0.0.0/16:10.0.1.1:br-aws:etcd-1,talos-control-plane-1,karpenter-worker-1"
    "azure:10.1.0.0/16:10.1.1.1:br-azure:etcd-2,talos-control-plane-2,karpenter-worker-2"
    "gcp:10.2.0.0/16:10.2.1.1:br-gcp:etcd-3,talos-control-plane-3,karpenter-worker-3"
    "ibm:10.3.0.0/16:10.3.1.1:br-ibm:talos-control-plane-4,karpenter-worker-4"
    "digitalocean:10.4.0.0/16:10.4.1.1:br-do:talos-control-plane-5,karpenter-worker-5"
)

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log "This script must be run as root for network operations"
        exit 1
    fi
}

# Create network namespaces for each volume
create_network_namespaces() {
    log "Creating network namespaces for all volumes..."
    
    for volume_dir in "$BASE_DIR"/*/; do
        if [ -d "$volume_dir" ]; then
            local node_name=$(basename "$volume_dir")
            local ns_name="ns-$node_name"
            
            # Create network namespace if it doesn't exist
            if ! ip netns list | grep -q "$ns_name"; then
                ip netns add "$ns_name"
                log "Created network namespace: $ns_name"
            else
                log "Network namespace $ns_name already exists"
            fi
        fi
    done
    
    log "Network namespaces created for all volumes"
}

# Create provider bridges
create_provider_bridges() {
    log "Creating provider bridges..."
    
    for provider_info in "${PROVIDER_NETWORKS[@]}"; do
        local provider=$(echo "$provider_info" | cut -d: -f1)
        local network=$(echo "$provider_info" | cut -d: -f2)
        local gateway=$(echo "$provider_info" | cut -d: -f3)
        local bridge_name=$(echo "$provider_info" | cut -d: -f4)
        
        # Create bridge if it doesn't exist
        if ! ip link show "$bridge_name" &>/dev/null; then
            ip link add name "$bridge_name" type bridge
            ip link set "$bridge_name" up
            log "Created bridge: $bridge_name for $provider provider"
        else
            log "Bridge $bridge_name already exists"
        fi
        
        # Set bridge IP and bring it up
        ip addr add "$gateway/24" dev "$bridge_name" 2>/dev/null || true
        ip link set "$bridge_name" up
        log "Configured bridge $bridge_name with IP $gateway/24"
    done
    
    log "Provider bridges created and configured"
}

# Create veth pairs and connect volumes to bridges
create_veth_connections() {
    log "Creating veth pairs and connecting volumes to provider bridges..."
    
    for provider_info in "${PROVIDER_NETWORKS[@]}"; do
        local provider=$(echo "$provider_info" | cut -d: -f1)
        local network=$(echo "$provider_info" | cut -d: -f2)
        local gateway=$(echo "$provider_info" | cut -d: -f3)
        local bridge_name=$(echo "$provider_info" | cut -d: -f4)
        local volumes=$(echo "$provider_info" | cut -d: -f5)
        
        # Extract network base (e.g., 10.0 from 10.0.0.0/16)
        local network_base=$(echo "$network" | cut -d. -f1-2)
        
        # Create veth pairs for each volume in this provider group
        local volume_index=1
        IFS=',' read -ra VOLUME_ARRAY <<< "$volumes"
        for volume_name in "${VOLUME_ARRAY[@]}"; do
            local ns_name="ns-$volume_name"
            local veth_host="veth-$volume_name"
            local veth_ns="veth-$volume_name-ns"
            local ns_ip="$network_base.$volume_index.2"
            
            # Create veth pair if it doesn't exist
            if ! ip link show "$veth_host" &>/dev/null; then
                ip link add "$veth_host" type veth peer name "$veth_ns"
                log "Created veth pair: $veth_host <-> $veth_ns for $volume_name"
            else
                log "Veth pair for $volume_name already exists"
            fi
            
            # Move veth-ns to the volume's namespace
            ip link set "$veth_ns" netns "$ns_name"
            
            # Configure veth-ns inside the namespace
            ip netns exec "$ns_name" ip addr add "$ns_ip/24" dev "$veth_ns"
            ip netns exec "$ns_name" ip link set "$veth_ns" up
            ip netns exec "$ns_name" ip link set lo up
            
            # Set default route in namespace
            ip netns exec "$ns_name" ip route add default via "$gateway"
            
            # Connect veth-host to bridge
            ip link set "$veth_host" master "$bridge_name"
            ip link set "$veth_host" up
            
            log "Connected $volume_name ($ns_ip) to $bridge_name via $veth_host"
            
            ((volume_index++))
        done
    done
    
    log "Veth pairs created and connected to provider bridges"
}

# Enable IP forwarding and NAT
setup_nat_and_routing() {
    log "Setting up NAT and routing for cross-provider communication..."
    
    # Enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    log "Enabled IP forwarding"
    
    # Create NAT rules for each provider bridge
    for provider_info in "${PROVIDER_NETWORKS[@]}"; do
        local provider=$(echo "$provider_info" | cut -d: -f1)
        local network=$(echo "$provider_info" | cut -d: -f2)
        local bridge_name=$(echo "$provider_info" | cut -d: -f4)
        
        # Extract network base (e.g., 10.0 from 10.0.0.0/16)
        local network_base=$(echo "$network" | cut -d. -f1-2)
        
        # Add NAT rule for this provider network
        iptables -t nat -A POSTROUTING -s "$network_base.0.0/16" -j MASQUERADE 2>/dev/null || true
        log "Added NAT rule for $provider provider ($network_base.0.0/16)"
    done
    
    # Add routing rules for cross-provider communication
    for provider_info in "${PROVIDER_NETWORKS[@]}"; do
        local provider=$(echo "$provider_info" | cut -d: -f1)
        local network=$(echo "$provider_info" | cut -d: -f2)
        local gateway=$(echo "$provider_info" | cut -d: -f3)
        local bridge_name=$(echo "$provider_info" | cut -d: -f4)
        
        # Extract network base (e.g., 10.0 from 10.0.0.0/16)
        local network_base=$(echo "$network" | cut -d. -f1-2)
        
        # Add route for this provider network
        ip route add "$network_base.0.0/16" dev "$bridge_name" 2>/dev/null || true
        log "Added route for $provider provider ($network_base.0.0/16) via $bridge_name"
    done
    
    log "NAT and routing configured for cross-provider communication"
}

# Create localhost connectivity
setup_localhost_connectivity() {
    log "Setting up localhost connectivity for volumes..."
    
    # Create a special bridge for localhost connectivity
    local localhost_bridge="br-localhost"
    if ! ip link show "$localhost_bridge" &>/dev/null; then
        ip link add name "$localhost_bridge" type bridge
        ip link set "$localhost_bridge" up
        ip addr add "127.0.1.1/24" dev "$localhost_bridge"
        log "Created localhost bridge: $localhost_bridge"
    fi
    
    # Connect each volume to localhost bridge
    for volume_dir in "$BASE_DIR"/*/; do
        if [ -d "$volume_dir" ]; then
            local node_name=$(basename "$volume_dir")
            local ns_name="ns-$node_name"
            local localhost_veth="localhost-$node_name"
            local localhost_veth_ns="localhost-$node_name-ns"
            local localhost_ip="127.0.1.$((RANDOM % 254 + 2))"
            
            # Create localhost veth pair
            if ! ip link show "$localhost_veth" &>/dev/null; then
                ip link add "$localhost_veth" type veth peer name "$localhost_veth_ns"
                log "Created localhost veth pair for $node_name"
            fi
            
            # Move veth-ns to the volume's namespace
            ip link set "$localhost_veth_ns" netns "$ns_name"
            
            # Configure veth-ns inside the namespace
            ip netns exec "$ns_name" ip addr add "$localhost_ip/24" dev "$localhost_veth_ns"
            ip netns exec "$ns_name" ip link set "$localhost_veth_ns" up
            
            # Connect veth-host to localhost bridge
            ip link set "$localhost_veth" master "$localhost_bridge"
            ip link set "$localhost_veth" up
            
            log "Connected $node_name to localhost bridge with IP $localhost_ip"
        fi
    done
    
    log "Localhost connectivity configured for all volumes"
}

# Create network management script
create_network_management() {
    log "Creating actual network management script..."
    
    tee "$NETWORK_DIR/manage-actual-networking.sh" > /dev/null <<'EOF'
#!/bin/bash

# Actual Networking Management Script for Multi-Cloud Kubernetes Volumes
set -euo pipefail

BASE_DIR="/opt/nix-volumes"
NETWORK_DIR="$BASE_DIR/networking"

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "This script must be run as root for network operations"
        exit 1
    fi
}

usage() {
    echo "Usage: $0 {status|start|stop|test|cleanup|logs}"
    echo ""
    echo "Commands:"
    echo "  status  - Show network status for all volumes"
    echo "  start   - Start all networking components"
    echo "  stop    - Stop all networking components"
    echo "  test    - Test connectivity between volumes"
    echo "  cleanup - Clean up all network components"
    echo "  logs    - Show network logs and statistics"
}

status_networking() {
    echo "Actual Networking Status:"
    echo "========================"
    
    echo -e "\nNetwork Namespaces:"
    ip netns list | while read ns; do
        echo "  $ns"
    done
    
    echo -e "\nBridges:"
    ip link show type bridge | grep -E "^[0-9]+:" | while read line; do
        local bridge_name=$(echo "$line" | cut -d: -f2 | tr -d ' ')
        if [[ "$bridge_name" =~ ^br- ]]; then
            echo "  $bridge_name"
        fi
    done
    
    echo -e "\nVeth Pairs:"
    ip link show type veth | grep -E "^[0-9]+:" | while read line; do
        local veth_name=$(echo "$line" | cut -d: -f2 | tr -d ' ')
        echo "  $veth_name"
    done
    
    echo -e "\nIP Routes:"
    ip route show | grep -E "10\.[0-9]+\.[0-9]+\.[0-9]+" | while read route; do
        echo "  $route"
    done
    
    echo -e "\nNAT Rules:"
    iptables -t nat -L POSTROUTING | grep MASQUERADE | while read rule; do
        echo "  $rule"
    done
}

start_networking() {
    echo "Starting actual networking components..."
    
    # Enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    # Start bridges
    for bridge in br-aws br-azure br-gcp br-ibm br-do br-localhost; do
        if ip link show "$bridge" &>/dev/null; then
            ip link set "$bridge" up
            echo "Started bridge: $bridge"
        fi
    done
    
    echo "Networking components started"
}

stop_networking() {
    echo "Stopping networking components..."
    
    # Stop bridges
    for bridge in br-aws br-azure br-gcp br-ibm br-do br-localhost; do
        if ip link show "$bridge" &>/dev/null; then
            ip link set "$bridge" down
            echo "Stopped bridge: $bridge"
        fi
    done
    
    echo "Networking components stopped"
}

test_connectivity() {
    echo "Testing connectivity between volumes..."
    
    # Test localhost connectivity
    echo -e "\nTesting localhost connectivity:"
    for volume_dir in "$BASE_DIR"/*/; do
        if [ -d "$volume_dir" ]; then
            local node_name=$(basename "$volume_dir")
            local ns_name="ns-$node_name"
            
            if ip netns list | grep -q "$ns_name"; then
                echo "Testing $node_name -> localhost..."
                ip netns exec "$ns_name" ping -c 1 127.0.0.1 &>/dev/null && echo "  ✓ localhost reachable" || echo "  ✗ localhost unreachable"
            fi
        fi
    done
    
    # Test cross-provider connectivity
    echo -e "\nTesting cross-provider connectivity:"
    local test_ips=("10.0.1.2" "10.1.1.2" "10.2.1.2" "10.3.1.2" "10.4.1.2")
    
    for volume_dir in "$BASE_DIR"/*/; do
        if [ -d "$volume_dir" ]; then
            local node_name=$(basename "$volume_dir")
            local ns_name="ns-$node_name"
            
            if ip netns list | grep -q "$ns_name"; then
                echo "Testing $node_name cross-provider connectivity..."
                for test_ip in "${test_ips[@]}"; do
                    ip netns exec "$ns_name" ping -c 1 "$test_ip" &>/dev/null && echo "  ✓ $test_ip reachable" || echo "  ✗ $test_ip unreachable"
                done
            fi
        fi
    done
    
    echo "Connectivity test completed"
}

cleanup_networking() {
    echo "Cleaning up all network components..."
    
    # Remove all network namespaces
    ip netns list | while read ns; do
        ip netns delete "$ns"
        echo "Removed namespace: $ns"
    done
    
    # Remove all bridges
    for bridge in br-aws br-azure br-gcp br-ibm br-do br-localhost; do
        if ip link show "$bridge" &>/dev/null; then
            ip link delete "$bridge"
            echo "Removed bridge: $bridge"
        fi
    done
    
    # Remove all veth pairs
    ip link show type veth | grep -E "^[0-9]+:" | while read line; do
        local veth_name=$(echo "$line" | cut -d: -f2 | tr -d ' ')
        ip link delete "$veth_name"
        echo "Removed veth: $veth_name"
    done
    
    # Clear NAT rules
    iptables -t nat -F POSTROUTING
    
    # Clear routes
    ip route flush table main
    
    echo "Network cleanup completed"
}

show_logs() {
    echo "Network Logs and Statistics:"
    echo "============================"
    
    echo -e "\nNetwork Interface Statistics:"
    ip -s link show
    
    echo -e "\nBridge Statistics:"
    for bridge in br-aws br-azure br-gcp br-ibm br-do br-localhost; do
        if ip link show "$bridge" &>/dev/null; then
            echo -e "\n$bridge:"
            bridge link show dev "$bridge"
        fi
    done
    
    echo -e "\nNamespace Statistics:"
    for ns in $(ip netns list); do
        echo -e "\n$ns:"
        ip netns exec "$ns" ip -s link show
    done
}

main() {
    check_root
    
    case "${1:-}" in
        status)
            status_networking
            ;;
        start)
            start_networking
            ;;
        stop)
            stop_networking
            ;;
        test)
            test_connectivity
            ;;
        cleanup)
            cleanup_networking
            ;;
        logs)
            show_logs
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
EOF

    chmod +x "$NETWORK_DIR/manage-actual-networking.sh"
    log "Actual network management script created"
}

# Create network architecture documentation
create_network_architecture() {
    log "Creating actual network architecture documentation..."
    
    tee "$NETWORK_DIR/actual-networking-architecture.md" > /dev/null <<'EOF'
# Actual Networking Architecture for Multi-Cloud Kubernetes Volumes

## Overview

This implementation creates real network interfaces, namespaces, bridges, and NAT for actual communication between mounted volumes and localhost.

## Network Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                    Host Network Stack                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   AWS Bridge    │  │ Azure Bridge    │  │   GCP Bridge    │ │
│  │   br-aws        │  │   br-azure      │  │   br-gcp        │ │
│  │   10.0.1.1/24   │  │   10.1.1.1/24   │  │   10.2.1.1/24   │ │
│  │                 │  │                 │  │                 │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │ veth-etcd-1 │ │  │ │veth-etcd-2  │ │  │ │veth-etcd-3  │ │ │
│  │ │     │       │ │  │ │     │       │ │  │ │     │       │ │ │
│  │ │ ┌─────────┐ │ │  │ │ ┌─────────┐ │ │  │ │ ┌─────────┐ │ │ │
│  │ │ │ns-etcd-1│ │ │  │ │ │ns-etcd-2│ │ │  │ │ │ns-etcd-3│ │ │ │
│  │ │ │10.0.1.2 │ │ │  │ │ │10.1.1.2 │ │ │  │ │ │10.2.1.2 │ │ │ │
│  │ │ └─────────┘ │ │  │ │ └─────────┘ │ │  │ │ └─────────┘ │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│         │                       │                       │       │
│         └───────────────────────┼───────────────────────┘       │
│                                 │                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   IBM Bridge    │  │   DO Bridge     │  │ Localhost Bridge│ │
│  │   br-ibm        │  │   br-do         │  │   br-localhost  │ │
│  │   10.3.1.1/24   │  │   10.4.1.1/24   │  │   127.0.1.1/24  │ │
│  │                 │  │                 │  │                 │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │veth-talos-4 │ │  │ │veth-talos-5 │ │  │ │localhost-*  │ │ │
│  │ │     │       │ │  │ │     │       │ │  │ │     │       │ │ │
│  │ │ ┌─────────┐ │ │  │ │ ┌─────────┐ │ │  │ │ ┌─────────┐ │ │ │
│  │ │ │ns-talos4│ │ │  │ │ │ns-talos5│ │ │  │ │ │ns-*     │ │ │ │
│  │ │ │10.3.1.2 │ │ │  │ │ │10.4.1.2 │ │ │  │ │ │127.0.1.*│ │ │ │
│  │ │ └─────────┘ │ │  │ │ └─────────┘ │ │  │ │ └─────────┘ │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### Network Namespaces
- **Purpose**: Isolate network stacks for each volume
- **Naming**: `ns-{volume-name}` (e.g., `ns-etcd-1`)
- **Isolation**: Each volume has its own network stack

### Provider Bridges
- **AWS Bridge**: `br-aws` (10.0.1.1/24)
- **Azure Bridge**: `br-azure` (10.1.1.1/24)
- **GCP Bridge**: `br-gcp` (10.2.1.1/24)
- **IBM Bridge**: `br-ibm` (10.3.1.1/24)
- **DigitalOcean Bridge**: `br-do` (10.4.1.1/24)
- **Localhost Bridge**: `br-localhost` (127.0.1.1/24)

### Veth Pairs
- **Purpose**: Connect network namespaces to bridges
- **Naming**: `veth-{volume-name}` (host) <-> `veth-{volume-name}-ns` (namespace)
- **Function**: Virtual ethernet pairs for namespace connectivity

### NAT and Routing
- **IP Forwarding**: Enabled for cross-provider communication
- **NAT Rules**: MASQUERADE for each provider network
- **Routes**: Direct routes to provider networks via bridges

## Communication Flow

### Internal Communication (Same Provider)
```
Volume A (10.0.1.2) -> br-aws (10.0.1.1) -> Volume B (10.0.2.2)
```

### Cross-Provider Communication
```
Volume A (10.0.1.2) -> br-aws -> Host Routing -> br-azure -> Volume B (10.1.1.2)
```

### Localhost Communication
```
Volume A -> br-localhost (127.0.1.1) -> Host localhost (127.0.0.1)
```

## Management Commands

```bash
# Check network status
sudo /opt/nix-volumes/networking/manage-actual-networking.sh status

# Start networking
sudo /opt/nix-volumes/networking/manage-actual-networking.sh start

# Stop networking
sudo /opt/nix-volumes/networking/manage-actual-networking.sh stop

# Test connectivity
sudo /opt/nix-volumes/networking/manage-actual-networking.sh test

# Clean up all networking
sudo /opt/nix-volumes/networking/manage-actual-networking.sh cleanup

# Show network logs
sudo /opt/nix-volumes/networking/manage-actual-networking.sh logs
```

## Network Configuration

### Provider Networks
- **AWS**: 10.0.0.0/16 (gateway: 10.0.1.1)
- **Azure**: 10.1.0.0/16 (gateway: 10.1.1.1)
- **GCP**: 10.2.0.0/16 (gateway: 10.2.1.1)
- **IBM**: 10.3.0.0/16 (gateway: 10.3.1.1)
- **DigitalOcean**: 10.4.0.0/16 (gateway: 10.4.1.1)

### Volume IP Assignments
- **etcd-1**: 10.0.1.2 (AWS)
- **etcd-2**: 10.1.1.2 (Azure)
- **etcd-3**: 10.2.1.2 (GCP)
- **talos-control-plane-1**: 10.0.2.2 (AWS)
- **talos-control-plane-2**: 10.1.2.2 (Azure)
- **talos-control-plane-3**: 10.2.2.2 (GCP)
- **talos-control-plane-4**: 10.3.1.2 (IBM)
- **talos-control-plane-5**: 10.4.1.2 (DigitalOcean)
- **karpenter-worker-1**: 10.0.3.2 (AWS)
- **karpenter-worker-2**: 10.1.3.2 (Azure)
- **karpenter-worker-3**: 10.2.3.2 (GCP)
- **karpenter-worker-4**: 10.3.2.2 (IBM)
- **karpenter-worker-5**: 10.4.2.2 (DigitalOcean)

## Security Features

- **Network Isolation**: Each volume in its own namespace
- **Provider Grouping**: Logical separation by cloud provider
- **NAT**: Masquerading for external connectivity
- **Controlled Routing**: Explicit routes for cross-provider communication

## Benefits

- **Real Networking**: Actual network interfaces and communication
- **Provider Isolation**: Each provider has its own bridge and network
- **Cross-Provider Communication**: Volumes can communicate across providers
- **Localhost Access**: Volumes can reach host localhost
- **Scalable**: Easy to add new providers and volumes
- **Manageable**: Centralized network management
EOF

    log "Actual network architecture documentation created"
}

# Main execution
main() {
    log "Setting up actual networking for multi-cloud Kubernetes volumes..."
    
    check_root
    create_network_namespaces
    create_provider_bridges
    create_veth_connections
    setup_nat_and_routing
    setup_localhost_connectivity
    create_network_management
    create_network_architecture
    
    log "Actual networking setup complete!"
    log ""
    log "Next steps:"
    log "1. Check status: sudo $NETWORK_DIR/manage-actual-networking.sh status"
    log "2. Test connectivity: sudo $NETWORK_DIR/manage-actual-networking.sh test"
    log "3. View architecture: cat $NETWORK_DIR/actual-networking-architecture.md"
    log ""
    log "Network components created:"
    log "- Network namespaces for each volume"
    log "- Provider bridges (br-aws, br-azure, br-gcp, br-ibm, br-do, br-localhost)"
    log "- Veth pairs connecting volumes to bridges"
    log "- NAT and routing for cross-provider communication"
    log "- Localhost connectivity for all volumes"
}

main "$@"
