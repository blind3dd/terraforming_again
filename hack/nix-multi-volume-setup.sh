#!/bin/bash

# Multi-Volume Nix Kubernetes Setup
# Creates separate volumes for each Kubernetes node with different cloud providers

set -euo pipefail

# Configuration
BASE_DIR="/opt/nix-volumes"
VOLUME_SIZE="50G"
K8S_NODES=(
    "etcd-1:aws"
    "etcd-2:azure" 
    "etcd-3:gcp"
    "control-plane-1:aws"
    "control-plane-2:azure"
    "control-plane-3:gcp"
    "worker-1:aws"
    "worker-2:azure"
    "worker-3:gcp"
    "worker-4:ibm"
    "worker-5:ibm"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Create base directory structure
create_base_structure() {
    log "Creating base directory structure..."
    sudo mkdir -p "$BASE_DIR"
    sudo chmod 755 "$BASE_DIR"
}

# Create Nix users for each provider
create_nix_users() {
    log "Creating Nix users for each cloud provider..."
    
    local providers=("aws" "azure" "gcp" "ibm")
    
    for provider in "${providers[@]}"; do
        local username="nix-${provider}"
        
        if ! id "$username" &>/dev/null; then
            log "Creating user: $username"
            
            # Create user with proper UID allocation
            local uid=$((501 + $(echo "${providers[@]}" | tr ' ' '\n' | grep -n "$provider" | cut -d: -f1)))
            
            sudo dscl . -create "/Users/$username"
            sudo dscl . -create "/Users/$username" UserShell /bin/bash
            sudo dscl . -create "/Users/$username" RealName "Nix $provider User"
            sudo dscl . -create "/Users/$username" UniqueID $uid
            sudo dscl . -create "/Users/$username" PrimaryGroupID 20
            sudo dscl . -create "/Users/$username" NFSHomeDirectory "/Users/$username"
            sudo dscl . -passwd "/Users/$username" "$username"
            
            # Create home directory
            sudo mkdir -p "/Users/$username"
            sudo chown "$username:staff" "/Users/$username"
            
            # Add to nix-users group if it exists
            if dscl . -read /Groups/nix-users &>/dev/null; then
                sudo dscl . -append /Groups/nix-users GroupMembership "$username"
            fi
        else
            log "User $username already exists"
        fi
    done
}

# Create encrypted volume for each Kubernetes node
create_volumes() {
    log "Creating encrypted volumes for Kubernetes nodes..."
    
    for node_info in "${K8S_NODES[@]}"; do
        IFS=':' read -r node_name provider <<< "$node_info"
        local volume_path="$BASE_DIR/$node_name"
        local nix_user="nix-$provider"
        local encrypted_volume="/dev/disk1s${node_name//[^0-9]/}"
        
        log "Creating encrypted volume for $node_name (provider: $provider)"
        
        # Create encrypted disk image
        local disk_image="$BASE_DIR/${node_name}.dmg"
        log "Creating encrypted disk image: $disk_image"
        
        # Create encrypted disk image with APFS encryption
        sudo hdiutil create -size "$VOLUME_SIZE" -type SPARSE -fs APFS -encryption AES-256 -passphrase "$node_name-$(date +%s)" -volname "$node_name" "$disk_image"
        
        # Mount the encrypted volume
        local mount_point="/Volumes/$node_name"
        sudo hdiutil attach "$disk_image" -mountpoint "$mount_point"
        
        # Create symlink to the mounted volume
        sudo ln -sf "$mount_point" "$volume_path"
        
        # Set proper ownership
        sudo chown "$nix_user:staff" "$volume_path"
        sudo chown "$nix_user:staff" "$mount_point"
        
        # Create Nix configuration for this volume
        create_nix_config "$volume_path" "$provider" "$nix_user"
        
        # Create Kubernetes node configuration
        create_k8s_node_config "$volume_path" "$node_name" "$provider"
        
        # Create volume management script
        create_volume_management "$node_name" "$disk_image" "$mount_point"
    done
}

# Create Nix configuration for each volume/provider
create_nix_config() {
    local volume_path="$1"
    local provider="$2"
    local nix_user="$3"
    local config_dir="$volume_path/.config/nix"
    
    log "Creating Nix configuration for $provider in $volume_path"
    
    sudo mkdir -p "$config_dir"
    sudo chown "$nix_user:staff" "$config_dir"
    
    # Create provider-specific Nix configuration
    case "$provider" in
        "aws")
            sudo -u "$nix_user" tee "$config_dir/nix.conf" > /dev/null <<EOF
# AWS Nix Configuration
experimental-features = nix-command
max-jobs = auto
keep-derivations = true
keep-outputs = true
auto-optimise-store = true
sandbox = true

# AWS-specific substituters
substituters = https://cache.nixos.org https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=

# AWS environment variables
extra-env = AWS_REGION=us-east-1
extra-env = AWS_DEFAULT_REGION=us-east-1
EOF
            ;;
        "azure")
            sudo -u "$nix_user" tee "$config_dir/nix.conf" > /dev/null <<EOF
# Azure Nix Configuration
experimental-features = nix-command
max-jobs = auto
keep-derivations = true
keep-outputs = true
auto-optimise-store = true
sandbox = true

# Azure-specific substituters
substituters = https://cache.nixos.org https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=

# Azure environment variables
extra-env = AZURE_LOCATION=eastus
extra-env = AZURE_DEFAULT_LOCATION=eastus
EOF
            ;;
        "gcp")
            sudo -u "$nix_user" tee "$config_dir/nix.conf" > /dev/null <<EOF
# GCP Nix Configuration
experimental-features = nix-command
max-jobs = auto
keep-derivations = true
keep-outputs = true
auto-optimise-store = true
sandbox = true

# GCP-specific substituters
substituters = https://cache.nixos.org https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=

# GCP environment variables
extra-env = GOOGLE_CLOUD_PROJECT=my-project
extra-env = GOOGLE_CLOUD_REGION=us-central1
EOF
            ;;
        "ibm")
            sudo -u "$nix_user" tee "$config_dir/nix.conf" > /dev/null <<EOF
# IBM Nix Configuration
experimental-features = nix-command
max-jobs = auto
keep-derivations = true
keep-outputs = true
auto-optimise-store = true
sandbox = true

# IBM-specific substituters
substituters = https://cache.nixos.org https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=

# IBM environment variables
extra-env = IBM_CLOUD_REGION=us-south
extra-env = IBM_CLOUD_DEFAULT_REGION=us-south
EOF
            ;;
    esac
}

# Create Kubernetes node configuration
create_k8s_node_config() {
    local volume_path="$1"
    local node_name="$2"
    local provider="$3"
    local k8s_dir="$volume_path/kubernetes"
    
    log "Creating Kubernetes configuration for $node_name"
    
    sudo mkdir -p "$k8s_dir"
    sudo chown "nix-$provider:staff" "$k8s_dir"
    
    # Create node-specific configuration
    sudo -u "nix-$provider" tee "$k8s_dir/node-config.yaml" > /dev/null <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
nodeRegistration:
  name: $node_name
  kubeletExtraArgs:
    cloud-provider: $provider
    cloud-config: /etc/kubernetes/cloud.conf
discovery:
  bootstrapToken:
    apiServerEndpoint: "k8s-api.example.com:6443"
    token: "abc123.def456ghi789"
    unsafeSkipCAVerification: true
EOF

    # Create cloud provider configuration
    case "$provider" in
        "aws")
            sudo -u "nix-$provider" tee "$k8s_dir/cloud.conf" > /dev/null <<EOF
[Global]
Zone = us-east-1a
VPC = vpc-12345678
SubnetID = subnet-12345678
RouteTableID = rtb-12345678
DisableSecurityGroupIngress = false
ElbSecurityGroup = sg-12345678
KubernetesClusterTag = kubernetes.io/cluster/my-cluster
KubernetesClusterID = my-cluster
EOF
            ;;
        "azure")
            sudo -u "nix-$provider" tee "$k8s_dir/cloud.conf" > /dev/null <<EOF
{
    "cloud": "AzurePublicCloud",
    "tenantId": "tenant-id",
    "subscriptionId": "subscription-id",
    "aadClientId": "client-id",
    "aadClientSecret": "client-secret",
    "resourceGroup": "my-resource-group",
    "location": "eastus",
    "subnetName": "my-subnet",
    "securityGroupName": "my-security-group",
    "vnetName": "my-vnet",
    "vnetResourceGroup": "my-resource-group",
    "routeTableName": "my-route-table",
    "primaryAvailabilitySetName": "my-availability-set",
    "useInstanceMetadata": true,
    "useManagedIdentityExtension": false,
    "userAssignedIdentityID": ""
}
EOF
            ;;
        "gcp")
            sudo -u "nix-$provider" tee "$k8s_dir/cloud.conf" > /dev/null <<EOF
[global]
project-id = my-project
network-name = my-network
subnetwork-name = my-subnet
node-instance-prefix = my-cluster
multizone = true
regional = true
EOF
            ;;
        "ibm")
            sudo -u "nix-$provider" tee "$k8s_dir/cloud.conf" > /dev/null <<EOF
[Global]
version = "1.0.0"
region = "us-south"
clusterID = "my-cluster"
accountID = "account-id"
g2Credentials = "/etc/kubernetes/ibmcloud_api_key"
g2ResourceGroupID = "resource-group-id"
g2VpcID = "vpc-id"
g2VpcSubnetID = "subnet-id"
g2VpcSubnetName = "my-subnet"
g2WorkerServiceAccountID = "worker-service-account-id"
EOF
            ;;
    esac
}

# Install Kubernetes tools via Nix for each volume
install_k8s_tools() {
    log "Installing Kubernetes tools via Nix for each volume..."
    
    for node_info in "${K8S_NODES[@]}"; do
        IFS=':' read -r node_name provider <<< "$node_info"
        local volume_path="$BASE_DIR/$node_name"
        local nix_user="nix-$provider"
        
        log "Installing K8s tools for $node_name (provider: $provider)"
        
        # Switch to the volume's Nix environment
        sudo -u "$nix_user" bash -c "
            cd '$volume_path'
            export HOME='$volume_path'
            export NIX_PATH='nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz'
            
            # Install Kubernetes tools
            nix-env -iA nixpkgs.kubernetes
            nix-env -iA nixpkgs.kubectl
            nix-env -iA nixpkgs.kubeadm
            nix-env -iA nixpkgs.kubelet
            nix-env -iA nixpkgs.etcd
            nix-env -iA nixpkgs.containerd
            nix-env -iA nixpkgs.runc
            nix-env -iA nixpkgs.cni
        "
    done
}

# Create cluster initialization script
create_cluster_init() {
    log "Creating cluster initialization script..."
    
    local init_script="$BASE_DIR/init-cluster.sh"
    
    sudo tee "$init_script" > /dev/null <<'EOF'
#!/bin/bash

# Kubernetes Cluster Initialization Script
# This script initializes the cluster across multiple volumes

set -euo pipefail

BASE_DIR="/opt/nix-volumes"
CLUSTER_NAME="multi-volume-cluster"
POD_CIDR="10.244.0.0/16"
SERVICE_CIDR="10.96.0.0/12"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Initialize etcd cluster
init_etcd() {
    log "Initializing etcd cluster..."
    
    local etcd_nodes=("etcd-1" "etcd-2" "etcd-3")
    local etcd_endpoints=""
    
    for i in "${!etcd_nodes[@]}"; do
        local node="${etcd_nodes[$i]}"
        local volume_path="$BASE_DIR/$node"
        local nix_user="nix-$(echo $node | cut -d'-' -f1)"
        
        if [ $i -eq 0 ]; then
            etcd_endpoints="https://$node:2379"
        else
            etcd_endpoints="$etcd_endpoints,https://$node:2379"
        fi
        
        log "Configuring etcd on $node"
        sudo -u "$nix_user" bash -c "
            cd '$volume_path'
            export HOME='$volume_path'
            
            # Create etcd configuration
            mkdir -p etcd
            cat > etcd/etcd.conf <<EOL
name: $node
data-dir: /var/lib/etcd
listen-client-urls: https://0.0.0.0:2379
advertise-client-urls: https://$node:2379
listen-peer-urls: https://0.0.0.0:2380
initial-advertise-peer-urls: https://$node:2380
initial-cluster: etcd-1=https://etcd-1:2380,etcd-2=https://etcd-2:2380,etcd-3=https://etcd-3:2380
initial-cluster-token: etcd-cluster-1
initial-cluster-state: new
client-transport-security:
  cert-file: /etc/kubernetes/pki/etcd/server.crt
  key-file: /etc/kubernetes/pki/etcd/server.key
  trusted-ca-file: /etc/kubernetes/pki/etcd/ca.crt
peer-transport-security:
  cert-file: /etc/kubernetes/pki/etcd/server.crt
  key-file: /etc/kubernetes/pki/etcd/server.key
  trusted-ca-file: /etc/kubernetes/pki/etcd/ca.crt
EOL
        "
    done
    
    echo "$etcd_endpoints"
}

# Initialize control plane
init_control_plane() {
    log "Initializing control plane..."
    
    local control_planes=("control-plane-1" "control-plane-2" "control-plane-3")
    local etcd_endpoints="$1"
    
    for i in "${!control_planes[@]}"; do
        local node="${control_planes[$i]}"
        local volume_path="$BASE_DIR/$node"
        local nix_user="nix-$(echo $node | cut -d'-' -f1)"
        
        log "Configuring control plane on $node"
        sudo -u "$nix_user" bash -c "
            cd '$volume_path'
            export HOME='$volume_path'
            
            # Create kubeadm configuration
            mkdir -p kubernetes
            cat > kubernetes/kubeadm-config.yaml <<EOL
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.28.0
clusterName: $CLUSTER_NAME
controlPlaneEndpoint: k8s-api.example.com:6443
etcd:
  external:
    endpoints:
$(echo "$etcd_endpoints" | tr ',' '\n' | sed 's/^/      - /')
    caFile: /etc/kubernetes/pki/etcd/ca.crt
    certFile: /etc/kubernetes/pki/etcd/server.crt
    keyFile: /etc/kubernetes/pki/etcd/server.key
networking:
  podSubnet: $POD_CIDR
  serviceSubnet: $SERVICE_CIDR
apiServer:
  extraArgs:
    cloud-provider: $(echo $node | cut -d'-' -f1)
EOL
        "
    done
}

# Initialize worker nodes
init_workers() {
    log "Initializing worker nodes..."
    
    local workers=("worker-1" "worker-2" "worker-3" "worker-4" "worker-5")
    
    for worker in "${workers[@]}"; do
        local volume_path="$BASE_DIR/$worker"
        local nix_user="nix-$(echo $worker | cut -d'-' -f1)"
        
        log "Configuring worker node $worker"
        sudo -u "$nix_user" bash -c "
            cd '$volume_path'
            export HOME='$volume_path'
            
            # Create worker configuration
            mkdir -p kubernetes
            cat > kubernetes/worker-config.yaml <<EOL
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
nodeRegistration:
  name: $worker
  kubeletExtraArgs:
    cloud-provider: $(echo $worker | cut -d'-' -f1)
discovery:
  bootstrapToken:
    apiServerEndpoint: k8s-api.example.com:6443
    token: abc123.def456ghi789
    unsafeSkipCAVerification: true
EOL
        "
    done
}

# Main initialization
main() {
    log "Starting multi-volume Kubernetes cluster initialization..."
    
    # Initialize etcd
    etcd_endpoints=$(init_etcd)
    
    # Initialize control plane
    init_control_plane "$etcd_endpoints"
    
    # Initialize workers
    init_workers
    
    log "Cluster initialization complete!"
    log "Next steps:"
    log "1. Generate certificates for etcd and control plane"
    log "2. Start etcd cluster"
    log "3. Initialize first control plane node"
    log "4. Join remaining control plane nodes"
    log "5. Join worker nodes"
}

main "$@"
EOF

    sudo chmod +x "$init_script"
}

# Create volume management script for each volume
create_volume_management() {
    local node_name="$1"
    local disk_image="$2"
    local mount_point="$3"
    local volume_path="$BASE_DIR/$node_name"
    local mgmt_script="$volume_path/manage-volume.sh"
    
    log "Creating volume management script for $node_name"
    
    sudo tee "$mgmt_script" > /dev/null <<EOF
#!/bin/bash

# Volume Management Script for $node_name
# Manages encrypted volume mounting/unmounting

set -euo pipefail

DISK_IMAGE="$disk_image"
MOUNT_POINT="$mount_point"
VOLUME_PATH="$volume_path"
NODE_NAME="$node_name"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] \$1"
}

mount_volume() {
    if mount | grep -q "\$MOUNT_POINT"; then
        log "Volume \$NODE_NAME is already mounted"
        return 0
    fi
    
    log "Mounting encrypted volume \$NODE_NAME..."
    sudo hdiutil attach "\$DISK_IMAGE" -mountpoint "\$MOUNT_POINT"
    log "Volume \$NODE_NAME mounted successfully"
}

unmount_volume() {
    if ! mount | grep -q "\$MOUNT_POINT"; then
        log "Volume \$NODE_NAME is not mounted"
        return 0
    fi
    
    log "Unmounting volume \$NODE_NAME..."
    sudo hdiutil detach "\$MOUNT_POINT"
    log "Volume \$NODE_NAME unmounted successfully"
}

status_volume() {
    if mount | grep -q "\$MOUNT_POINT"; then
        log "Volume \$NODE_NAME is mounted at \$MOUNT_POINT"
        df -h "\$MOUNT_POINT"
    else
        log "Volume \$NODE_NAME is not mounted"
    fi
}

compact_volume() {
    log "Compacting volume \$NODE_NAME..."
    sudo hdiutil compact "\$DISK_IMAGE"
    log "Volume \$NODE_NAME compacted successfully"
}

usage() {
    echo "Usage: \$0 {mount|unmount|status|compact}"
    echo ""
    echo "Commands:"
    echo "  mount   - Mount the encrypted volume"
    echo "  unmount - Unmount the encrypted volume"
    echo "  status  - Show volume status"
    echo "  compact - Compact the sparse disk image"
}

main() {
    case "\${1:-}" in
        mount)
            mount_volume
            ;;
        unmount)
            unmount_volume
            ;;
        status)
            status_volume
            ;;
        compact)
            compact_volume
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "\$@"
EOF

    sudo chmod +x "$mgmt_script"
}

# Create management script
create_management_script() {
    log "Creating cluster management script..."
    
    local mgmt_script="$BASE_DIR/manage-cluster.sh"
    
    sudo tee "$mgmt_script" > /dev/null <<'EOF'
#!/bin/bash

# Multi-Volume Kubernetes Cluster Management Script

set -euo pipefail

BASE_DIR="/opt/nix-volumes"

usage() {
    echo "Usage: $0 {start|stop|status|logs|shell} [node-name]"
    echo ""
    echo "Commands:"
    echo "  start [node]    - Start services on node or all nodes"
    echo "  stop [node]     - Stop services on node or all nodes"
    echo "  status [node]   - Show status of node or all nodes"
    echo "  logs [node]     - Show logs for node or all nodes"
    echo "  shell [node]    - Open shell for specific node"
    echo ""
    echo "Available nodes:"
    echo "  etcd-1, etcd-2, etcd-3"
    echo "  control-plane-1, control-plane-2, control-plane-3"
    echo "  worker-1, worker-2, worker-3, worker-4, worker-5"
}

get_nodes() {
    if [ $# -eq 1 ]; then
        echo "$1"
    else
        echo "etcd-1 etcd-2 etcd-3 control-plane-1 control-plane-2 control-plane-3 worker-1 worker-2 worker-3 worker-4 worker-5"
    fi
}

start_node() {
    local node="$1"
    local volume_path="$BASE_DIR/$node"
    local nix_user="nix-$(echo $node | cut -d'-' -f1)"
    
    echo "Starting services on $node..."
    sudo -u "$nix_user" bash -c "
        cd '$volume_path'
        export HOME='$volume_path'
        
        # Start appropriate services based on node type
        if [[ $node == etcd-* ]]; then
            echo 'Starting etcd...'
            # etcd --config-file=etcd/etcd.conf &
        elif [[ $node == control-plane-* ]]; then
            echo 'Starting kubelet and kube-apiserver...'
            # systemctl start kubelet
        elif [[ $node == worker-* ]]; then
            echo 'Starting kubelet...'
            # systemctl start kubelet
        fi
    "
}

stop_node() {
    local node="$1"
    local volume_path="$BASE_DIR/$node"
    local nix_user="nix-$(echo $node | cut -d'-' -f1)"
    
    echo "Stopping services on $node..."
    sudo -u "$nix_user" bash -c "
        cd '$volume_path'
        export HOME='$volume_path'
        
        # Stop appropriate services based on node type
        if [[ $node == etcd-* ]]; then
            echo 'Stopping etcd...'
            # pkill etcd
        elif [[ $node == control-plane-* ]]; then
            echo 'Stopping kubelet and kube-apiserver...'
            # systemctl stop kubelet
        elif [[ $node == worker-* ]]; then
            echo 'Stopping kubelet...'
            # systemctl stop kubelet
        fi
    "
}

status_node() {
    local node="$1"
    local volume_path="$BASE_DIR/$node"
    local nix_user="nix-$(echo $node | cut -d'-' -f1)"
    
    echo "Status of $node:"
    sudo -u "$nix_user" bash -c "
        cd '$volume_path'
        export HOME='$volume_path'
        
        echo 'Node: $node'
        echo 'Provider: $(echo $node | cut -d'-' -f1)'
        echo 'Volume: $volume_path'
        echo 'User: $nix_user'
        echo 'Installed packages:'
        nix-env -q || echo 'No packages installed'
    "
}

logs_node() {
    local node="$1"
    local volume_path="$BASE_DIR/$node"
    local nix_user="nix-$(echo $node | cut -d'-' -f1)"
    
    echo "Logs for $node:"
    sudo -u "$nix_user" bash -c "
        cd '$volume_path'
        export HOME='$volume_path'
        
        # Show relevant logs based on node type
        if [[ $node == etcd-* ]]; then
            echo 'ETCD logs:'
            # journalctl -u etcd
        elif [[ $node == control-plane-* ]]; then
            echo 'Kubelet logs:'
            # journalctl -u kubelet
        elif [[ $node == worker-* ]]; then
            echo 'Kubelet logs:'
            # journalctl -u kubelet
        fi
    "
}

shell_node() {
    local node="$1"
    local volume_path="$BASE_DIR/$node"
    local nix_user="nix-$(echo $node | cut -d'-' -f1)"
    
    echo "Opening shell for $node..."
    sudo -u "$nix_user" bash -c "
        cd '$volume_path'
        export HOME='$volume_path'
        export PS1='[$node:\$(echo \$PWD | sed \"s|$BASE_DIR/||\")] \$ '
        bash
    "
}

main() {
    if [ $# -lt 1 ]; then
        usage
        exit 1
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        start)
            for node in $(get_nodes "$@"); do
                start_node "$node"
            done
            ;;
        stop)
            for node in $(get_nodes "$@"); do
                stop_node "$node"
            done
            ;;
        status)
            for node in $(get_nodes "$@"); do
                status_node "$node"
                echo "---"
            done
            ;;
        logs)
            for node in $(get_nodes "$@"); do
                logs_node "$node"
                echo "---"
            done
            ;;
        shell)
            if [ $# -ne 1 ]; then
                echo "Error: shell command requires exactly one node name"
                usage
                exit 1
            fi
            shell_node "$1"
            ;;
        *)
            echo "Error: Unknown command '$command'"
            usage
            exit 1
            ;;
    esac
}

main "$@"
EOF

    sudo chmod +x "$mgmt_script"
}

# Main execution
main() {
    log "Starting multi-volume Nix Kubernetes setup..."
    
    create_base_structure
    create_nix_users
    create_volumes
    install_k8s_tools
    create_cluster_init
    create_management_script
    
    log "Multi-volume Nix Kubernetes setup complete!"
    log ""
    log "Created encrypted volumes:"
    for node_info in "${K8S_NODES[@]}"; do
        IFS=':' read -r node_name provider <<< "$node_info"
        log "  - $node_name (provider: $provider) -> $BASE_DIR/$node_name"
        log "    Encrypted disk image: $BASE_DIR/${node_name}.dmg"
        log "    Volume management: $BASE_DIR/$node_name/manage-volume.sh"
    done
    log ""
    log "Management commands:"
    log "  $BASE_DIR/manage-cluster.sh status    - Show status of all nodes"
    log "  $BASE_DIR/manage-cluster.sh shell <node> - Open shell for specific node"
    log "  $BASE_DIR/init-cluster.sh            - Initialize the cluster"
    log ""
    log "Volume management commands:"
    for node_info in "${K8S_NODES[@]}"; do
        IFS=':' read -r node_name provider <<< "$node_info"
        log "  $BASE_DIR/$node_name/manage-volume.sh {mount|unmount|status|compact}"
    done
    log ""
    log "Next steps:"
    log "1. Mount all volumes: for node in \${K8S_NODES[@]}; do \$BASE_DIR/\${node%%:*}/manage-volume.sh mount; done"
    log "2. Configure cloud provider credentials for each volume"
    log "3. Run: $BASE_DIR/init-cluster.sh"
    log "4. Start services: $BASE_DIR/manage-cluster.sh start"
}

main "$@"
