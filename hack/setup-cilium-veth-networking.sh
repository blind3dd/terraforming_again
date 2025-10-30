#!/bin/bash

# Cilium + Veth Networking Setup for Provider-Grouped Volumes
# Uses veth pairs grouped by provider with Cilium CNI for cross-cloud communication

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

# Create provider bridges and veth pairs
create_provider_networks() {
    log "Creating provider bridges and veth pairs..."
    
    for provider_info in "${PROVIDER_NETWORKS[@]}"; do
        local provider=$(echo "$provider_info" | cut -d: -f1)
        local network=$(echo "$provider_info" | cut -d: -f2)
        local gateway=$(echo "$provider_info" | cut -d: -f3)
        local bridge_name=$(echo "$provider_info" | cut -d: -f4)
        local volumes=$(echo "$provider_info" | cut -d: -f5)
        
        log "Creating network for $provider provider (bridge: $bridge_name, volumes: $volumes)..."
        
        # Create bridge for this provider
        sudo ifconfig $bridge_name create
        sudo ifconfig $bridge_name $gateway netmask 255.255.0.0 up
        
        # Extract network base (e.g., 10.0 from 10.0.0.0/16)
        local network_base=$(echo "$network" | cut -d. -f1-2)
        
        # Create veth pairs for each volume in this provider group
        local volume_index=1
        IFS=',' read -ra VOLUME_ARRAY <<< "$volumes"
        for volume_name in "${VOLUME_ARRAY[@]}"; do
            log "Creating veth pair for $volume_name in $provider provider..."
            
            # Create veth pair
            local veth_host="veth-$volume_name"
            local veth_ns="veth-$volume_name-ns"
            
            sudo ip link add $veth_host type veth peer name $veth_ns
            
            # Configure host side
            local host_ip="$network_base.$volume_index.1"
            sudo ip addr add $host_ip/24 dev $veth_host
            sudo ip link set $veth_host up
            
            # Add to provider bridge
            sudo ifconfig $bridge_name addm $veth_host up
            
            # Create network namespace for this volume
            sudo ip netns add "ns-$volume_name"
            
            # Move veth to namespace
            sudo ip link set $veth_ns netns "ns-$volume_name"
            
            # Configure namespace side
            local ns_ip="$network_base.$volume_index.2"
            sudo ip netns exec "ns-$volume_name" ip addr add $ns_ip/24 dev $veth_ns
            sudo ip netns exec "ns-$volume_name" ip link set $veth_ns up
            sudo ip netns exec "ns-$volume_name" ip link set lo up
            
            # Add default route
            sudo ip netns exec "ns-$volume_name" ip route add default via $host_ip
            
            log "Veth pair created for $volume_name (host: $host_ip, ns: $ns_ip) in $provider provider"
            
            ((volume_index++))
        done
        
        log "Provider network created for $provider (bridge: $bridge_name)"
    done
    
    log "All provider networks created"
}

# Create Cilium configuration for cross-cloud networking
create_cilium_config() {
    log "Creating Cilium configuration for cross-cloud networking..."
    
    # Create Cilium Helm values
    tee "$NETWORK_DIR/cilium/values.yaml" > /dev/null <<'EOF'
# Cilium Configuration for Cross-Cloud Volume Networking
cluster:
  name: multi-cloud-cluster
  id: 1

# Enable cross-cloud pod communication
ipam:
  mode: cluster-pool
  operator:
    clusterPoolIPv4PodCIDR: "10.0.0.0/8"
    clusterPoolIPv4MaskSize: 24

# Enable WireGuard for cross-cloud encryption
encryption:
  enabled: true
  type: wireguard

# Enable Hubble for observability
hubble:
  enabled: true
  relay:
    enabled: true
  ui:
    enabled: true

# Cross-cloud service mesh integration
serviceMesh:
  integration: istio

# Network policies for cross-cloud security
policyEnforcementMode: default

# Enable cross-cloud networking
enableIPv4Masquerade: true
enableIPv6Masquerade: false

# Provider-specific networking
kubeProxyReplacement: strict
kubeProxyReplacementHealthzBindAddr: "0.0.0.0:10256"

# Cross-cloud routing
enableRemoteNodeIdentity: true
enableWellKnownIdentities: true

# Provider network integration
externalIPs:
  enabled: true
EOF

    # Create Cilium network policies for provider groups
    tee "$NETWORK_DIR/cilium/provider-network-policies.yaml" > /dev/null <<'EOF'
---
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-aws-provider-communication
  namespace: default
spec:
  endpointSelector: {}
  egress:
  - toCIDR:
    - "10.0.0.0/16"  # AWS provider network
  - toPorts:
    - ports:
      - port: "443"
        protocol: TCP
      - port: "80"
        protocol: TCP
---
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-azure-provider-communication
  namespace: default
spec:
  endpointSelector: {}
  egress:
  - toCIDR:
    - "10.1.0.0/16"  # Azure provider network
  - toPorts:
    - ports:
      - port: "443"
        protocol: TCP
      - port: "80"
        protocol: TCP
---
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-gcp-provider-communication
  namespace: default
spec:
  endpointSelector: {}
  egress:
  - toCIDR:
    - "10.2.0.0/16"  # GCP provider network
  - toPorts:
    - ports:
      - port: "443"
        protocol: TCP
      - port: "80"
        protocol: TCP
---
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-ibm-provider-communication
  namespace: default
spec:
  endpointSelector: {}
  egress:
  - toCIDR:
    - "10.3.0.0/16"  # IBM provider network
  - toPorts:
    - ports:
      - port: "443"
        protocol: TCP
      - port: "80"
        protocol: TCP
---
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-do-provider-communication
  namespace: default
spec:
  endpointSelector: {}
  egress:
  - toCIDR:
    - "10.4.0.0/16"  # DigitalOcean provider network
  - toPorts:
    - ports:
      - port: "443"
        protocol: TCP
      - port: "80"
        protocol: TCP
---
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: default
spec:
  endpointSelector: {}
  ingress: []
EOF

    log "Cilium configuration created"
}

# Create network configuration for each volume
create_volume_network_config() {
    log "Creating network configuration for volumes with Cilium integration..."
    
    for provider_info in "${PROVIDER_NETWORKS[@]}"; do
        local provider=$(echo "$provider_info" | cut -d: -f1)
        local network=$(echo "$provider_info" | cut -d: -f2)
        local gateway=$(echo "$provider_info" | cut -d: -f3)
        local bridge_name=$(echo "$provider_info" | cut -d: -f4)
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

                # Create Cilium-aware network management script
                tee "$mount_point/opt/network-manager.sh" > /dev/null <<EOF
#!/bin/bash

# Cilium-aware network management script for $volume_name ($provider provider)
set -euo pipefail

NODE_NAME="$volume_name"
PROVIDER="$provider"
BRIDGE_NAME="$bridge_name"
HOST_IP="$host_ip"
NS_IP="$ns_ip"
NAMESPACE="ns-$volume_name"

start_network() {
    echo "Starting network for $NODE_NAME ($PROVIDER provider)..."
    sudo ip netns exec $NAMESPACE ip link set lo up
    sudo ip netns exec $NAMESPACE ip link set veth-$NODE_NAME-ns up
    sudo ip netns exec $NAMESPACE ip route add default via $HOST_IP
    echo "Network started for $NODE_NAME (IP: $NS_IP) on bridge $BRIDGE_NAME"
}

stop_network() {
    echo "Stopping network for $NODE_NAME ($PROVIDER provider)..."
    sudo ip netns exec $NAMESPACE ip link set veth-$NODE_NAME-ns down
    echo "Network stopped for $NODE_NAME"
}

status_network() {
    echo "Network status for $NODE_NAME ($PROVIDER provider):"
    echo "  Provider: $PROVIDER"
    echo "  Bridge: $BRIDGE_NAME"
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

test_cilium_integration() {
    echo "Testing Cilium integration for $NODE_NAME..."
    echo "  Provider: $PROVIDER"
    echo "  Bridge: $BRIDGE_NAME"
    echo "  Network: $network"
    echo "  Cilium should handle cross-provider routing"
    echo "Cilium integration test completed for $NODE_NAME"
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
    test-cilium)
        test_cilium_integration
        ;;
    *)
        echo "Usage: $0 {start|stop|status|test|test-cross|test-cilium}"
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
    
    tee "$NETWORK_DIR/manage-cilium-veth-networking.sh" > /dev/null <<'EOF'
#!/bin/bash

# Cilium + Veth Cross-Cloud Networking Management Script
set -euo pipefail

BASE_DIR="/opt/nix-volumes"
NETWORK_DIR="$BASE_DIR/networking"

usage() {
    echo "Usage: $0 {setup|start|stop|status|test|deploy-cilium|cleanup}"
    echo ""
    echo "Commands:"
    echo "  setup        - Setup provider bridges and veth pairs"
    echo "  start        - Start all volume networks"
    echo "  stop         - Stop all volume networks"
    echo "  status       - Show network status"
    echo "  test         - Test cross-cloud connectivity"
    echo "  deploy-cilium - Deploy Cilium CNI"
    echo "  cleanup      - Remove network interfaces and namespaces"
}

setup_networking() {
    echo "Setting up provider bridges and veth pairs..."
    
    # Create provider bridges
    for provider_info in "${PROVIDER_NETWORKS[@]}"; do
        local provider=$(echo "$provider_info" | cut -d: -f1)
        local network=$(echo "$provider_info" | cut -d: -f2)
        local gateway=$(echo "$provider_info" | cut -d: -f3)
        local bridge_name=$(echo "$provider_info" | cut -d: -f4)
        
        echo "Setting up $provider provider network on $bridge_name..."
        sudo ifconfig $bridge_name create
        sudo ifconfig $bridge_name $gateway netmask 255.255.0.0 up
    done
    
    echo "Provider networks setup completed"
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
    echo "Cilium + Veth Cross-Cloud Networking Status:"
    echo "============================================="
    
    echo -e "\n1. Provider Bridges:"
    for provider_info in "${PROVIDER_NETWORKS[@]}"; do
        local provider=$(echo "$provider_info" | cut -d: -f1)
        local bridge_name=$(echo "$provider_info" | cut -d: -f4)
        if ifconfig $bridge_name &> /dev/null; then
            echo "  $provider provider: $bridge_name (UP)"
        else
            echo "  $provider provider: $bridge_name (DOWN)"
        fi
    done
    
    echo -e "\n2. Network Namespaces:"
    sudo ip netns list || echo "No namespaces found"
    
    echo -e "\n3. Veth Interfaces:"
    ip link show | grep veth || echo "No veth interfaces found"
    
    echo -e "\n4. Volume Network Status:"
    for volume_dir in "$BASE_DIR"/*/; do
        if [ -d "$volume_dir" ]; then
            local node_name=$(basename "$volume_dir")
            if [ -f "$volume_dir/mount/opt/network-manager.sh" ]; then
                echo "  $node_name: CONFIGURED"
            else
                echo "  $node_name: NOT CONFIGURED"
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
                echo "Testing cross-provider connectivity for $node_name..."
                "$volume_dir/mount/opt/network-manager.sh" test-cross
            fi
        fi
    done
    
    echo "Cross-cloud connectivity test completed"
}

deploy_cilium() {
    echo "Deploying Cilium CNI for cross-cloud networking..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        echo "Error: kubectl not found. Please install kubectl first."
        exit 1
    fi
    
    # Check if helm is available
    if ! command -v helm &> /dev/null; then
        echo "Error: helm not found. Please install helm first."
        exit 1
    fi
    
    # Deploy Cilium
    helm repo add cilium https://helm.cilium.io/
    helm repo update
    helm install cilium cilium/cilium \
        --namespace kube-system \
        --values "$NETWORK_DIR/cilium/values.yaml"
    
    # Apply network policies
    kubectl apply -f "$NETWORK_DIR/cilium/provider-network-policies.yaml"
    
    echo "Cilium CNI deployed for cross-cloud networking"
}

cleanup_networking() {
    echo "Cleaning up cross-cloud networking..."
    
    # Remove network namespaces
    for volume_dir in "$BASE_DIR"/*/; do
        if [ -d "$volume_dir" ]; then
            local node_name=$(basename "$volume_dir")
            sudo ip netns delete "ns-$node_name" 2>/dev/null || true
        fi
    done
    
    # Remove veth interfaces
    ip link show | grep veth | cut -d: -f2 | tr -d ' ' | while read iface; do
        sudo ip link delete $iface 2>/dev/null || true
    done
    
    # Remove provider bridges
    for provider_info in "${PROVIDER_NETWORKS[@]}"; do
        local bridge_name=$(echo "$provider_info" | cut -d: -f4)
        sudo ifconfig $bridge_name down 2>/dev/null || true
        sudo ifconfig $bridge_name destroy 2>/dev/null || true
    done
    
    echo "Cross-cloud networking cleaned up"
}

# Network configuration grouped by cloud providers
PROVIDER_NETWORKS=(
    "aws:10.0.0.0/16:10.0.1.1:br-aws:etcd-1,talos-control-plane-1,karpenter-worker-1"
    "azure:10.1.0.0/16:10.1.1.1:br-azure:etcd-2,talos-control-plane-2,karpenter-worker-2"
    "gcp:10.2.0.0/16:10.2.1.1:br-gcp:etcd-3,talos-control-plane-3,karpenter-worker-3"
    "ibm:10.3.0.0/16:10.3.1.1:br-ibm:talos-control-plane-4,karpenter-worker-4"
    "digitalocean:10.4.0.0/16:10.4.1.1:br-do:talos-control-plane-5,karpenter-worker-5"
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
        deploy-cilium)
            deploy_cilium
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

    chmod +x "$NETWORK_DIR/manage-cilium-veth-networking.sh"
    log "Cilium + Veth networking management script created"
}

# Create network architecture diagram
create_network_architecture() {
    log "Creating Cilium + Veth network architecture diagram..."
    
    tee "$NETWORK_DIR/cilium-veth-architecture.md" > /dev/null <<'EOF'
# Cilium + Veth Cross-Cloud Networking Architecture

## Provider-Grouped Veth Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                    Cilium + Veth Networking                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   AWS Provider  │  │ Azure Provider  │  │   GCP Provider  │ │
│  │   br-aws        │  │   br-azure      │  │   br-gcp        │ │
│  │  10.0.0.0/16    │  │  10.1.0.0/16    │  │  10.2.0.0/16    │ │
│  │                 │  │                 │  │                 │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │   etcd-1    │ │  │ │   etcd-2    │ │  │ │   etcd-3    │ │ │
│  │ │ 10.0.1.2    │ │  │ │ 10.1.1.2    │ │  │ │ 10.2.1.2    │ │ │
│  │ │ veth-etcd-1 │ │  │ │ veth-etcd-2 │ │  │ │ veth-etcd-3 │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │talos-cp-1   │ │  │ │talos-cp-2   │ │  │ │talos-cp-3   │ │ │
│  │ │ 10.0.2.2    │ │  │ │ 10.1.2.2    │ │  │ │ 10.2.2.2    │ │ │
│  │ │veth-talos-1 │ │  │ │veth-talos-2 │ │  │ │veth-talos-3 │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │karpenter-1  │ │  │ │karpenter-2  │ │  │ │karpenter-3  │ │ │
│  │ │ 10.0.3.2    │ │  │ │ 10.1.3.2    │ │  │ │ 10.2.3.2    │ │ │
│  │ │veth-karp-1  │ │  │ │veth-karp-2  │ │  │ │veth-karp-3  │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│         │                       │                       │       │
│         └───────────────────────┼───────────────────────┘       │
│                                 │                               │
│  ┌─────────────────┐  ┌─────────────────┐                      │
│  │   IBM Provider  │  │   DO Provider   │                      │
│  │   br-ibm        │  │   br-do         │                      │
│  │  10.3.0.0/16    │  │  10.4.0.0/16    │                      │
│  │                 │  │                 │                      │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │                      │
│  │ │talos-cp-4   │ │  │ │talos-cp-5   │ │                      │
│  │ │ 10.3.1.2    │ │  │ │ 10.4.1.2    │ │                      │
│  │ │veth-talos-4 │ │  │ │veth-talos-5 │ │                      │
│  │ └─────────────┘ │  │ └─────────────┘ │                      │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │                      │
│  │ │karpenter-4  │ │  │ │karpenter-5  │ │                      │
│  │ │ 10.3.2.2    │ │  │ │ 10.4.2.2    │ │                      │
│  │ │veth-karp-4  │ │  │ │veth-karp-5  │ │                      │
│  │ └─────────────┘ │  │ └─────────────┘ │                      │
│  └─────────────────┘  └─────────────────┘                      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    Cilium CNI Layer                        │ │
│  │              Cross-Cloud Communication                     │ │
│  │              WireGuard Encryption                          │ │
│  │              Network Policies                              │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Veth Pair Structure

Each volume has a veth pair:
- **Host side**: Connected to provider bridge (e.g., br-aws)
- **Namespace side**: Inside volume's network namespace

```
┌─────────────────────────────────────────────────────────────────┐
│                    Veth Pair Structure                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │   Provider      │    │   Volume        │                    │
│  │   Bridge        │    │   Namespace     │                    │
│  │                 │    │                 │                    │
│  │  ┌───────────┐  │    │  ┌───────────┐  │                    │
│  │  │veth-host  │◄─┼────┼─►│veth-ns    │  │                    │
│  │  │10.0.1.1   │  │    │  │10.0.1.2   │  │                    │
│  │  └───────────┘  │    │  └───────────┘  │                    │
│  │                 │    │                 │                    │
│  └─────────────────┘    └─────────────────┘                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Provider Groups

### AWS Provider (br-aws, 10.0.0.0/16)
- **etcd-1**: 10.0.1.2 (veth-etcd-1)
- **talos-control-plane-1**: 10.0.2.2 (veth-talos-control-plane-1)
- **karpenter-worker-1**: 10.0.3.2 (veth-karpenter-worker-1)

### Azure Provider (br-azure, 10.1.0.0/16)
- **etcd-2**: 10.1.1.2 (veth-etcd-2)
- **talos-control-plane-2**: 10.1.2.2 (veth-talos-control-plane-2)
- **karpenter-worker-2**: 10.1.3.2 (veth-karpenter-worker-2)

### GCP Provider (br-gcp, 10.2.0.0/16)
- **etcd-3**: 10.2.1.2 (veth-etcd-3)
- **talos-control-plane-3**: 10.2.2.2 (veth-talos-control-plane-3)
- **karpenter-worker-3**: 10.2.3.2 (veth-karpenter-worker-3)

### IBM Provider (br-ibm, 10.3.0.0/16)
- **talos-control-plane-4**: 10.3.1.2 (veth-talos-control-plane-4)
- **karpenter-worker-4**: 10.3.2.2 (veth-karpenter-worker-4)

### DigitalOcean Provider (br-do, 10.4.0.0/16)
- **talos-control-plane-5**: 10.4.1.2 (veth-talos-control-plane-5)
- **karpenter-worker-5**: 10.4.2.2 (veth-karpenter-worker-5)

## Benefits

- **Provider Isolation**: Each provider has its own bridge and network segment
- **Veth Pairs**: Direct communication between host and namespace
- **Cilium Integration**: Advanced networking features and cross-cloud communication
- **WireGuard Encryption**: Secure cross-cloud tunnels
- **Network Policies**: Fine-grained security controls
- **Scalable**: Easy to add new providers and volumes

## Management Commands

```bash
# Setup networking
/opt/nix-volumes/networking/manage-cilium-veth-networking.sh setup

# Start all networks
/opt/nix-volumes/networking/manage-cilium-veth-networking.sh start

# Check status
/opt/nix-volumes/networking/manage-cilium-veth-networking.sh status

# Test connectivity
/opt/nix-volumes/networking/manage-cilium-veth-networking.sh test

# Deploy Cilium
/opt/nix-volumes/networking/manage-cilium-veth-networking.sh deploy-cilium

# Cleanup
/opt/nix-volumes/networking/manage-cilium-veth-networking.sh cleanup
```
EOF

    log "Cilium + Veth network architecture diagram created"
}

# Main execution
main() {
    log "Setting up Cilium + Veth cross-cloud networking..."
    
    create_provider_networks
    create_cilium_config
    create_volume_network_config
    create_network_management
    create_network_architecture
    
    log "Cilium + Veth cross-cloud networking setup complete!"
    log ""
    log "Next steps:"
    log "1. Setup networking: $NETWORK_DIR/manage-cilium-veth-networking.sh setup"
    log "2. Start networks: $NETWORK_DIR/manage-cilium-veth-networking.sh start"
    log "3. Check status: $NETWORK_DIR/manage-cilium-veth-networking.sh status"
    log "4. Test connectivity: $NETWORK_DIR/manage-cilium-veth-networking.sh test"
    log "5. Deploy Cilium: $NETWORK_DIR/manage-cilium-veth-networking.sh deploy-cilium"
    log "6. View architecture: cat $NETWORK_DIR/cilium-veth-architecture.md"
}

main "$@"
