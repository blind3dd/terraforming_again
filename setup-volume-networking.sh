#!/bin/bash

# Setup Dedicated Network Interfaces for Multi-Volume Cross-Cloud Networking
# Each volume gets dedicated network interfaces to simulate cross-cloud communication

set -euo pipefail

# Configuration
BASE_DIR="/opt/nix-volumes"
NETWORK_DIR="$BASE_DIR/networking"

# Network configuration grouped by cloud providers
PROVIDER_NETWORKS=(
    "aws:10.0.0.0/16:10.0.1.1:en0:etcd-1,talos-control-plane-1,karpenter-worker-1"
    "azure:10.1.0.0/16:10.1.1.1:en1:etcd-2,talos-control-plane-2,karpenter-worker-2"
    "gcp:10.2.0.0/16:10.2.1.1:en2:etcd-3,talos-control-plane-3,karpenter-worker-3"
    "ibm:10.3.0.0/16:10.3.1.1:en3:talos-control-plane-4,karpenter-worker-4"
    "digitalocean:10.4.0.0/16:10.4.1.1:en4:talos-control-plane-5,karpenter-worker-5"
)

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Create virtual network interfaces for each cloud provider
create_virtual_interfaces() {
    log "Creating virtual network interfaces for cross-cloud networking..."
    
    # Create bridge interfaces for each cloud provider
    for provider_info in "${PROVIDER_NETWORKS[@]}"; do
        local provider=$(echo "$provider_info" | cut -d: -f1)
        local network=$(echo "$provider_info" | cut -d: -f2)
        local gateway=$(echo "$provider_info" | cut -d: -f3)
        local interface=$(echo "$provider_info" | cut -d: -f4)
        local volumes=$(echo "$provider_info" | cut -d: -f5)
        
        log "Creating virtual interface for $provider provider (volumes: $volumes)..."
        
        # Create bridge interface for this provider
        local bridge_name="br-$provider"
        sudo ifconfig $bridge_name create
        
        # Create virtual interface
        sudo ifconfig $interface create
        
        # Configure the interface
        sudo ifconfig $interface $gateway netmask 255.255.0.0 up
        
        # Add to bridge
        sudo ifconfig $bridge_name addm $interface up
        
        log "Virtual interface $interface created for $provider provider"
    done
    
    log "Virtual network interfaces created"
}

# Create network namespace for each volume grouped by provider
create_network_namespaces() {
    log "Creating network namespaces for volumes grouped by provider..."
    
    # Process each provider group
    for provider_info in "${PROVIDER_NETWORKS[@]}"; do
        local provider=$(echo "$provider_info" | cut -d: -f1)
        local network=$(echo "$provider_info" | cut -d: -f2)
        local gateway=$(echo "$provider_info" | cut -d: -f3)
        local interface=$(echo "$provider_info" | cut -d: -f4)
        local volumes=$(echo "$provider_info" | cut -d: -f5)
        
        log "Creating network namespaces for $provider provider (volumes: $volumes)..."
        
        # Extract network base (e.g., 10.0 from 10.0.0.0/16)
        local network_base=$(echo "$network" | cut -d. -f1-2)
        
        # Create namespaces for each volume in this provider group
        local volume_index=1
        IFS=',' read -ra VOLUME_ARRAY <<< "$volumes"
        for volume_name in "${VOLUME_ARRAY[@]}"; do
            log "Creating network namespace for $volume_name in $provider provider..."
            
            # Create network namespace
            sudo ip netns add "ns-$volume_name"
            
            # Create veth pair
            sudo ip link add "veth-$volume_name" type veth peer name "veth-$volume_name-ns"
            
            # Move one end to namespace
            sudo ip link set "veth-$volume_name-ns" netns "ns-$volume_name"
            
            # Configure host interface
            local host_ip="$network_base.$volume_index.1"
            sudo ip addr add "$host_ip/24" dev "veth-$volume_name"
            sudo ip link set "veth-$volume_name" up
            
            # Add to provider bridge
            local bridge_name="br-$provider"
            sudo ifconfig $bridge_name addm "veth-$volume_name" up
            
            # Configure namespace interface
            local ns_ip="$network_base.$volume_index.2"
            sudo ip netns exec "ns-$volume_name" ip addr add "$ns_ip/24" dev "veth-$volume_name-ns"
            sudo ip netns exec "ns-$volume_name" ip link set "veth-$volume_name-ns" up
            sudo ip netns exec "ns-$volume_name" ip link set lo up
            
            # Add default route
            sudo ip netns exec "ns-$volume_name" ip route add default via "$host_ip"
            
            log "Network namespace created for $volume_name (IP: $ns_ip) in $provider provider"
            
            ((volume_index++))
        done
    done
    
    log "Network namespaces created for all volumes grouped by provider"
}

# Create cross-cloud routing
create_cross_cloud_routing() {
    log "Creating cross-cloud routing..."
    
    # Enable IP forwarding
    sudo sysctl -w net.inet.ip.forwarding=1
    
    # Create routing table for each cloud provider
    for provider_info in "${PROVIDER_NETWORKS[@]}"; do
        local provider=$(echo "$provider_info" | cut -d: -f1)
        local network=$(echo "$provider_info" | cut -d: -f2)
        local gateway=$(echo "$provider_info" | cut -d: -f3)
        local interface=$(echo "$provider_info" | cut -d: -f4)
        local volumes=$(echo "$provider_info" | cut -d: -f5)
        
        log "Creating routing for $provider provider network $network (volumes: $volumes)..."
        
        # Add route for this provider network
        sudo route add -net $network $gateway
        
        # Create bridge interface if not exists
        local bridge_name="br-$provider"
        if ! ifconfig $bridge_name &> /dev/null; then
            sudo ifconfig $bridge_name create
            sudo ifconfig $bridge_name $gateway netmask 255.255.0.0 up
        fi
        
        # Create pfctl rules for cross-cloud communication
        sudo pfctl -f /dev/stdin <<EOF
# Cross-cloud routing for $provider provider
pass in on $interface from $network to any
pass out on $interface from any to $network
pass in on $bridge_name from $network to any
pass out on $bridge_name from any to $network
EOF
        
        log "Routing configured for $provider provider"
    done
    
    log "Cross-cloud routing created"
}

# Create network configuration for each volume grouped by provider
create_volume_network_config() {
    log "Creating network configuration for volumes grouped by provider..."
    
    # Process each provider group
    for provider_info in "${PROVIDER_NETWORKS[@]}"; do
        local provider=$(echo "$provider_info" | cut -d: -f1)
        local network=$(echo "$provider_info" | cut -d: -f2)
        local gateway=$(echo "$provider_info" | cut -d: -f3)
        local interface=$(echo "$provider_info" | cut -d: -f4)
        local volumes=$(echo "$provider_info" | cut -d: -f5)
        
        log "Creating network configs for $provider provider (volumes: $volumes)..."
        
        # Extract network base (e.g., 10.0 from 10.0.0.0/16)
        local network_base=$(echo "$network" | cut -d. -f1-2)
        
        # Create network configs for each volume in this provider group
        local volume_index=1
        IFS=',' read -ra VOLUME_ARRAY <<< "$volumes"
        for volume_name in "${VOLUME_ARRAY[@]}"; do
            local volume_dir="$BASE_DIR/$volume_name"
            local mount_point="$volume_dir/mount"
            
            if [ -d "$mount_point" ]; then
                log "Creating network config for $volume_name in $provider provider..."
                
                # Create network configuration directory
                mkdir -p "$mount_point/etc/network"
                
                # Calculate IP addresses
                local host_ip="$network_base.$volume_index.1"
                local ns_ip="$network_base.$volume_index.2"
                
                # Create network configuration
                tee "$mount_point/etc/network/interfaces" > /dev/null <<EOF
# Network configuration for $volume_name ($provider provider)
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address $ns_ip
    netmask 255.255.255.0
    gateway $host_ip
    dns-nameservers 8.8.8.8 8.8.4.4
EOF

                # Create systemd network configuration
                mkdir -p "$mount_point/etc/systemd/network"
                tee "$mount_point/etc/systemd/network/eth0.network" > /dev/null <<EOF
[Match]
Name=eth0

[Network]
Address=$ns_ip/24
Gateway=$host_ip
DNS=8.8.8.8
DNS=8.8.4.4
EOF

                # Create network management script
                tee "$mount_point/opt/network-manager.sh" > /dev/null <<EOF
#!/bin/bash

# Network management script for $volume_name ($provider provider)
set -euo pipefail

NODE_NAME="$volume_name"
PROVIDER="$provider"
NAMESPACE="ns-$volume_name"
HOST_IP="$host_ip"
NS_IP="$ns_ip"

start_network() {
    echo "Starting network for $NODE_NAME ($PROVIDER provider)..."
    sudo ip netns exec $NAMESPACE ip link set lo up
    sudo ip netns exec $NAMESPACE ip link set veth-$NODE_NAME-ns up
    sudo ip netns exec $NAMESPACE ip route add default via $HOST_IP
    echo "Network started for $NODE_NAME (IP: $NS_IP)"
}

stop_network() {
    echo "Stopping network for $NODE_NAME ($PROVIDER provider)..."
    sudo ip netns exec $NAMESPACE ip link set veth-$NODE_NAME-ns down
    echo "Network stopped for $NODE_NAME"
}

status_network() {
    echo "Network status for $NODE_NAME ($PROVIDER provider):"
    echo "  Provider: $PROVIDER"
    echo "  Namespace: $NAMESPACE"
    echo "  Host IP: $HOST_IP"
    echo "  Node IP: $NS_IP"
    sudo ip netns exec $NAMESPACE ip addr show
    sudo ip netns exec $NAMESPACE ip route show
}

test_connectivity() {
    echo "Testing connectivity for $NODE_NAME ($PROVIDER provider)..."
    sudo ip netns exec $NAMESPACE ping -c 3 8.8.8.8
    sudo ip netns exec $NAMESPACE ping -c 3 $HOST_IP
    echo "Connectivity test completed for $NODE_NAME"
}

test_cross_provider() {
    echo "Testing cross-provider connectivity for $NODE_NAME..."
    # Test connectivity to other provider networks
    for other_provider_info in "${PROVIDER_NETWORKS[@]}"; do
        local other_provider=$(echo "$other_provider_info" | cut -d: -f1)
        local other_network=$(echo "$other_provider_info" | cut -d: -f2)
        local other_gateway=$(echo "$other_provider_info" | cut -d: -f3)
        
        if [[ "$other_provider" != "$PROVIDER" ]]; then
            echo "  Testing connectivity to $other_provider provider ($other_gateway)..."
            sudo ip netns exec $NAMESPACE ping -c 2 $other_gateway || echo "    No connectivity to $other_provider"
        fi
    done
}

case "\${1:-}" in
    start)
        start_network
        ;;
    stop)
        stop_network
        ;;
    status)
        status_network
        ;;
    test)
        test_connectivity
        ;;
    test-cross)
        test_cross_provider
        ;;
    *)
        echo "Usage: $0 {start|stop|status|test|test-cross}"
        exit 1
        ;;
esac
EOF

                chmod +x "$mount_point/opt/network-manager.sh"
                
                log "Network configuration created for $volume_name (IP: $ns_ip) in $provider provider"
            fi
            
            ((volume_index++))
        done
    done
    
    log "Volume network configurations created for all providers"
}

# Create cross-cloud network management script
create_network_management() {
    log "Creating cross-cloud network management script..."
    
    tee "$NETWORK_DIR/manage-volume-networking.sh" > /dev/null <<'EOF'
#!/bin/bash

# Cross-Cloud Volume Networking Management Script
set -euo pipefail

BASE_DIR="/opt/nix-volumes"
NETWORK_DIR="$BASE_DIR/networking"

usage() {
    echo "Usage: $0 {setup|start|stop|status|test|cleanup}"
    echo ""
    echo "Commands:"
    echo "  setup   - Setup virtual interfaces and namespaces"
    echo "  start   - Start all volume networks"
    echo "  stop    - Stop all volume networks"
    echo "  status  - Show network status"
    echo "  test    - Test cross-cloud connectivity"
    echo "  cleanup - Remove network interfaces and namespaces"
}

setup_networking() {
    echo "Setting up cross-cloud volume networking..."
    
    # Create virtual interfaces
    for cluster_info in "${CLUSTER_NETWORKS[@]}"; do
        local provider=$(echo "$cluster_info" | cut -d: -f1)
        local network=$(echo "$cluster_info" | cut -d: -f2)
        local gateway=$(echo "$cluster_info" | cut -d: -f3)
        local interface=$(echo "$cluster_info" | cut -d: -f4)
        
        echo "Setting up $provider network on $interface..."
        sudo ifconfig $interface $gateway netmask 255.255.0.0 up
    done
    
    # Create network namespaces
    for volume_dir in "$BASE_DIR"/*/; do
        if [ -d "$volume_dir" ]; then
            local node_name=$(basename "$volume_dir")
            echo "Creating namespace for $node_name..."
            sudo ip netns add "ns-$node_name" 2>/dev/null || true
        fi
    done
    
    echo "Cross-cloud networking setup completed"
}

start_networking() {
    echo "Starting cross-cloud volume networking..."
    
    for volume_dir in "$BASE_DIR"/*/; do
        if [ -d "$volume_dir" ]; then
            local node_name=$(basename "$volume_dir")
            if [ -f "$volume_dir/mount/opt/network-manager.sh" ]; then
                echo "Starting network for $node_name..."
                "$volume_dir/mount/opt/network-manager.sh" start
            fi
        fi
    done
    
    echo "All volume networks started"
}

stop_networking() {
    echo "Stopping cross-cloud volume networking..."
    
    for volume_dir in "$BASE_DIR"/*/; do
        if [ -d "$volume_dir" ]; then
            local node_name=$(basename "$volume_dir")
            if [ -f "$volume_dir/mount/opt/network-manager.sh" ]; then
                echo "Stopping network for $node_name..."
                "$volume_dir/mount/opt/network-manager.sh" stop
            fi
        fi
    done
    
    echo "All volume networks stopped"
}

status_networking() {
    echo "Cross-Cloud Volume Networking Status:"
    echo "====================================="
    
    echo -e "\n1. Virtual Interfaces:"
    ifconfig | grep -E "(en[0-9]|bridge[0-9])" || echo "No virtual interfaces found"
    
    echo -e "\n2. Network Namespaces:"
    sudo ip netns list || echo "No namespaces found"
    
    echo -e "\n3. Volume Network Status:"
    for volume_dir in "$BASE_DIR"/*/; do
        if [ -d "$volume_dir" ]; then
            local node_name=$(basename "$volume_dir")
            if [ -f "$volume_dir/mount/opt/network-manager.sh" ]; then
                echo "  $node_name:"
                "$volume_dir/mount/opt/network-manager.sh" status | head -5
            fi
        fi
    done
}

test_connectivity() {
    echo "Testing cross-cloud connectivity..."
    
    for volume_dir in "$BASE_DIR"/*/; do
        if [ -d "$volume_dir" ]; then
            local node_name=$(basename "$volume_dir")
            if [ -f "$volume_dir/mount/opt/network-manager.sh" ]; then
                echo "Testing connectivity for $node_name..."
                "$volume_dir/mount/opt/network-manager.sh" test
            fi
        fi
    done
    
    echo "Cross-cloud connectivity test completed"
}

cleanup_networking() {
    echo "Cleaning up cross-cloud volume networking..."
    
    # Remove network namespaces
    for volume_dir in "$BASE_DIR"/*/; do
        if [ -d "$volume_dir" ]; then
            local node_name=$(basename "$volume_dir")
            sudo ip netns delete "ns-$node_name" 2>/dev/null || true
        fi
    done
    
    # Remove virtual interfaces
    for cluster_info in "${CLUSTER_NETWORKS[@]}"; do
        local interface=$(echo "$cluster_info" | cut -d: -f4)
        sudo ifconfig $interface down 2>/dev/null || true
        sudo ifconfig $interface destroy 2>/dev/null || true
    done
    
    echo "Cross-cloud networking cleaned up"
}

# Network configuration grouped by cloud providers
PROVIDER_NETWORKS=(
    "aws:10.0.0.0/16:10.0.1.1:en0:etcd-1,talos-control-plane-1,karpenter-worker-1"
    "azure:10.1.0.0/16:10.1.1.1:en1:etcd-2,talos-control-plane-2,karpenter-worker-2"
    "gcp:10.2.0.0/16:10.2.1.1:en2:etcd-3,talos-control-plane-3,karpenter-worker-3"
    "ibm:10.3.0.0/16:10.3.1.1:en3:talos-control-plane-4,karpenter-worker-4"
    "digitalocean:10.4.0.0/16:10.4.1.1:en4:talos-control-plane-5,karpenter-worker-5"
)

main() {
    case "${1:-}" in
        setup)
            setup_networking
            ;;
        start)
            start_networking
            ;;
        stop)
            stop_networking
            ;;
        status)
            status_networking
            ;;
        test)
            test_connectivity
            ;;
        cleanup)
            cleanup_networking
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
EOF

    chmod +x "$NETWORK_DIR/manage-volume-networking.sh"
    log "Volume networking management script created"
}

# Create network architecture diagram
create_network_architecture() {
    log "Creating network architecture diagram..."
    
    tee "$NETWORK_DIR/volume-networking-architecture.md" > /dev/null <<'EOF'
# Volume Networking Architecture

## Provider-Grouped Network Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                    Provider-Grouped Networking                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   AWS Provider  │  │ Azure Provider  │  │   GCP Provider  │ │
│  │  10.0.0.0/16    │  │  10.1.0.0/16    │  │  10.2.0.0/16    │ │
│  │                 │  │                 │  │                 │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │   etcd-1    │ │  │ │   etcd-2    │ │  │ │   etcd-3    │ │ │
│  │ │ 10.0.1.2    │ │  │ │ 10.1.1.2    │ │  │ │ 10.2.1.2    │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │talos-cp-1   │ │  │ │talos-cp-2   │ │  │ │talos-cp-3   │ │ │
│  │ │ 10.0.2.2    │ │  │ │ 10.1.2.2    │ │  │ │ 10.2.2.2    │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │karpenter-1  │ │  │ │karpenter-2  │ │  │ │karpenter-3  │ │ │
│  │ │ 10.0.3.2    │ │  │ │ 10.1.3.2    │ │  │ │ 10.2.3.2    │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│         │                       │                       │       │
│         └───────────────────────┼───────────────────────┘       │
│                                 │                               │
│  ┌─────────────────┐  ┌─────────────────┐                      │
│  │   IBM Provider  │  │   DO Provider   │                      │
│  │  10.3.0.0/16    │  │  10.4.0.0/16    │                      │
│  │                 │  │                 │                      │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │                      │
│  │ │talos-cp-4   │ │  │ │talos-cp-5   │ │                      │
│  │ │ 10.3.1.2    │ │  │ │ 10.4.1.2    │ │                      │
│  │ └─────────────┘ │  │ └─────────────┘ │                      │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │                      │
│  │ │karpenter-4  │ │  │ │karpenter-5  │ │                      │
│  │ │ 10.3.2.2    │ │  │ │ 10.4.2.2    │ │                      │
│  │ └─────────────┘ │  │ └─────────────┘ │                      │
│  └─────────────────┘  └─────────────────┘                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Network Namespace Isolation

Each volume runs in its own network namespace:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Network Namespace Isolation                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   ns-etcd-1     │  │ ns-talos-cp-1   │  │ ns-karpenter-1  │ │
│  │                 │  │                 │  │                 │ │
│  │ veth-etcd-1-ns  │  │veth-talos-cp-1-ns│ │veth-karpenter-1-ns│ │
│  │ 10.0.1.2/24     │  │ 10.0.1.2/24     │  │ 10.0.1.2/24     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   ns-etcd-2     │  │ ns-talos-cp-2   │  │ ns-karpenter-2  │ │
│  │                 │  │                 │  │                 │ │
│  │ veth-etcd-2-ns  │  │veth-talos-cp-2-ns│ │veth-karpenter-2-ns│ │
│  │ 10.1.2.2/24     │  │ 10.1.2.2/24     │  │ 10.1.2.2/24     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Cross-Cloud Communication Flow

1. **Volume A** (AWS) → **en0** → **Bridge** → **en1** → **Volume B** (Azure)
2. **Network Namespace** isolation ensures no interference
3. **Dedicated IP ranges** per cloud provider
4. **Veth pairs** for namespace communication

## Benefits

- **True isolation**: Each volume has dedicated network interfaces
- **Cross-cloud simulation**: Realistic multi-cloud networking
- **Scalable**: Easy to add new cloud providers
- **Secure**: Network namespace isolation
- **Manageable**: Centralized network management

## Management Commands

```bash
# Setup networking
/opt/nix-volumes/networking/manage-volume-networking.sh setup

# Start all networks
/opt/nix-volumes/networking/manage-volume-networking.sh start

# Check status
/opt/nix-volumes/networking/manage-volume-networking.sh status

# Test connectivity
/opt/nix-volumes/networking/manage-volume-networking.sh test

# Cleanup
/opt/nix-volumes/networking/manage-volume-networking.sh cleanup
```
EOF

    log "Network architecture diagram created"
}

# Main execution
main() {
    log "Setting up dedicated network interfaces for cross-cloud volume networking..."
    
    create_virtual_interfaces
    create_network_namespaces
    create_cross_cloud_routing
    create_volume_network_config
    create_network_management
    create_network_architecture
    
    log "Volume networking setup complete!"
    log ""
    log "Next steps:"
    log "1. Setup networking: $NETWORK_DIR/manage-volume-networking.sh setup"
    log "2. Start networks: $NETWORK_DIR/manage-volume-networking.sh start"
    log "3. Check status: $NETWORK_DIR/manage-volume-networking.sh status"
    log "4. Test connectivity: $NETWORK_DIR/manage-volume-networking.sh test"
    log "5. View architecture: cat $NETWORK_DIR/volume-networking-architecture.md"
}

main "$@"
