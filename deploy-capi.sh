#!/bin/bash

# Deploy CAPI (Cluster API) for Multi-Cloud Kubernetes Orchestration
# This script sets up CAPI as the foundation for managing our multi-cloud clusters

set -euo pipefail

# Configuration
BASE_DIR="/opt/nix-volumes"
CAPI_DIR="$BASE_DIR/capi-management"
NETWORK_DIR="$BASE_DIR/networking"

# CAPI providers to initialize
CAPI_PROVIDERS=(
    "aws"
    "azure" 
    "gcp"
    "ibm"
    "digitalocean"
    "vsphere"
    "openstack"
    "packet"
    "metal3"
    "equinix"
    "hetzner"
    "scaleway"
    "outscale"
    "nutanix"
    "oci"
    "alibaba"
    "tencent"
    "baidu"
    "ucloud"
    "qingcloud"
)

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        log "Installing kubectl..."
        nix-env -iA nixpkgs.kubectl
    fi
    
    # Check if clusterctl is available
    if ! command -v clusterctl &> /dev/null; then
        log "Installing clusterctl..."
        nix-env -iA nixpkgs.clusterctl
    fi
    
    # Check if helm is available
    if ! command -v helm &> /dev/null; then
        log "Installing helm..."
        nix-env -iA nixpkgs.kubernetes-helm-wrapped
    fi
    
    # Check if talosctl is available
    if ! command -v talosctl &> /dev/null; then
        log "Installing talosctl..."
        nix-env -iA nixpkgs.talosctl
    fi
    
    log "Prerequisites check completed"
}

# Create local Kubernetes cluster for CAPI management
create_management_cluster() {
    log "Creating local management cluster for CAPI..."
    
    # Check if we have a running cluster
    if kubectl cluster-info &> /dev/null; then
        log "Kubernetes cluster already running"
        kubectl cluster-info
        return 0
    fi
    
    # Try to start Docker Desktop Kubernetes
    if command -v docker &> /dev/null; then
        log "Starting Docker Desktop Kubernetes..."
        # This would typically be done through Docker Desktop UI
        log "Please ensure Docker Desktop Kubernetes is enabled and running"
        log "You can check status with: kubectl cluster-info"
    fi
    
    # Alternative: Use kind for local cluster
    if command -v kind &> /dev/null; then
        log "Creating kind cluster for CAPI management..."
        kind create cluster --name capi-management --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
    else
        log "Installing kind for local cluster..."
        nix-env -iA nixpkgs.kind
        kind create cluster --name capi-management
    fi
    
    log "Management cluster created"
}

# Initialize CAPI providers
init_capi_providers() {
    log "Initializing CAPI providers..."
    
    # Create CAPI configuration directory
    mkdir -p "$CAPI_DIR/config"
    
    # Initialize core providers
    log "Initializing core CAPI providers..."
    clusterctl init \
        --core cluster-api:v1.5.0 \
        --bootstrap kubeadm:v1.5.0 \
        --control-plane kubeadm:v1.5.0 \
        --infrastructure aws:v2.2.0,azure:v1.11.0,gcp:v1.4.0 \
        --config "$CAPI_DIR/config/clusterctl.yaml"
    
    # Wait for providers to be ready
    log "Waiting for CAPI providers to be ready..."
    kubectl wait --for=condition=Ready pods --all -n capi-system --timeout=300s
    kubectl wait --for=condition=Ready pods --all -n capi-kubeadm-bootstrap-system --timeout=300s
    kubectl wait --for=condition=Ready pods --all -n capi-kubeadm-control-plane-system --timeout=300s
    kubectl wait --for=condition=Ready pods --all -n capaws-system --timeout=300s
    kubectl wait --for=condition=condition=Ready pods --all -n capz-system --timeout=300s
    kubectl wait --for=condition=Ready pods --all -n capg-system --timeout=300s
    
    log "Core CAPI providers initialized"
}

# Create CAPI configuration
create_capi_config() {
    log "Creating CAPI configuration..."
    
    # Create clusterctl configuration
    tee "$CAPI_DIR/config/clusterctl.yaml" > /dev/null <<'EOF'
providers:
  - name: "cluster-api"
    url: "https://github.com/kubernetes-sigs/cluster-api/releases/latest/core-components.yaml"
    type: "CoreProvider"
  - name: "kubeadm"
    url: "https://github.com/kubernetes-sigs/cluster-api/releases/latest/bootstrap-components.yaml"
    type: "BootstrapProvider"
  - name: "kubeadm"
    url: "https://github.com/kubernetes-sigs/cluster-api/releases/latest/control-plane-components.yaml"
    type: "ControlPlaneProvider"
  - name: "aws"
    url: "https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/latest/infrastructure-components.yaml"
    type: "InfrastructureProvider"
  - name: "azure"
    url: "https://github.com/kubernetes-sigs/cluster-api-provider-azure/releases/latest/infrastructure-components.yaml"
    type: "InfrastructureProvider"
  - name: "gcp"
    url: "https://github.com/kubernetes-sigs/cluster-api-provider-gcp/releases/latest/infrastructure-components.yaml"
    type: "InfrastructureProvider"
  - name: "talos"
    url: "https://github.com/siderolabs/cluster-api-provider-talos/releases/latest/infrastructure-components.yaml"
    type: "InfrastructureProvider"
EOF

    # Create multi-cloud cluster template
    tee "$CAPI_DIR/config/multi-cloud-cluster.yaml" > /dev/null <<'EOF'
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: multi-cloud-cluster
  namespace: default
spec:
  clusterNetwork:
    pods:
      cidrBlocks: ["10.0.0.0/8"]
    services:
      cidrBlocks: ["10.96.0.0/12"]
  controlPlaneRef:
    apiVersion: controlplane.cluster.x-k8s.io/v1beta1
    kind: KubeadmControlPlane
    name: multi-cloud-cluster-control-plane
  infrastructureRef:
    apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
    kind: AWSCluster
    name: multi-cloud-cluster
---
apiVersion: controlplane.cluster.x-k8s.io/v1beta1
kind: KubeadmControlPlane
metadata:
  name: multi-cloud-cluster-control-plane
  namespace: default
spec:
  replicas: 3
  version: v1.28.0
  infrastructureTemplate:
    apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
    kind: AWSMachineTemplate
    name: multi-cloud-cluster-control-plane
  kubeadmConfigSpec:
    clusterConfiguration:
      apiServer:
        extraArgs:
          cloud-provider: aws
      controllerManager:
        extraArgs:
          cloud-provider: aws
    initConfiguration:
      nodeRegistration:
        kubeletExtraArgs:
          cloud-provider: aws
    joinConfiguration:
      nodeRegistration:
        kubeletExtraArgs:
          cloud-provider: aws
---
apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
kind: AWSCluster
metadata:
  name: multi-cloud-cluster
  namespace: default
spec:
  region: us-east-1
  sshKeyName: default
  version: v1.28.0
---
apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
kind: AWSMachineTemplate
metadata:
  name: multi-cloud-cluster-control-plane
  namespace: default
spec:
  template:
    spec:
      ami:
        id: ami-0c02fb55956c7d316  # Amazon Linux 2
      instanceType: t3.medium
      sshKeyName: default
      iamInstanceProfile: control-plane.cluster-api-provider-aws.sigs.k8s.io
EOF

    log "CAPI configuration created"
}

# Create Talos-specific CAPI configuration
create_talos_capi_config() {
    log "Creating Talos CAPI configuration..."
    
    # Initialize Talos provider
    clusterctl init --infrastructure talos:v0.5.0
    
    # Create Talos cluster template
    tee "$CAPI_DIR/config/talos-multi-cloud-cluster.yaml" > /dev/null <<'EOF'
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: talos-multi-cloud-cluster
  namespace: default
spec:
  clusterNetwork:
    pods:
      cidrBlocks: ["10.0.0.0/8"]
    services:
      cidrBlocks: ["10.96.0.0/12"]
  controlPlaneRef:
    apiVersion: controlplane.cluster.x-k8s.io/v1beta1
    kind: TalosControlPlane
    name: talos-multi-cloud-cluster-control-plane
  infrastructureRef:
    apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
    kind: TalosCluster
    name: talos-multi-cloud-cluster
---
apiVersion: controlplane.cluster.x-k8s.io/v1beta1
kind: TalosControlPlane
metadata:
  name: talos-multi-cloud-cluster-control-plane
  namespace: default
spec:
  replicas: 3
  version: v1.28.0
  infrastructureTemplate:
    apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
    kind: TalosMachineTemplate
    name: talos-multi-cloud-cluster-control-plane
  talosConfigSpec:
    generateType: controlplane
    talosVersion: v1.5.0
    configPatches:
    - op: add
      path: /machine/network
      value:
        interfaces:
        - interface: eth0
          addresses:
          - 10.0.1.5/24
---
apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
kind: TalosCluster
metadata:
  name: talos-multi-cloud-cluster
  namespace: default
spec:
  controlPlaneEndpoint:
    host: "10.0.1.5"
    port: 6443
---
apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
kind: TalosMachineTemplate
metadata:
  name: talos-multi-cloud-cluster-control-plane
  namespace: default
spec:
  template:
    spec:
      talosVersion: v1.5.0
      configPatches:
      - op: add
        path: /machine/install
        value:
          disk: /dev/sda
          image: ghcr.io/talos-systems/talos:v1.5.0
EOF

    log "Talos CAPI configuration created"
}

# Create CAPI management script
create_capi_management() {
    log "Creating CAPI management script..."
    
    tee "$CAPI_DIR/manage-capi.sh" > /dev/null <<'EOF'
#!/bin/bash

# CAPI Management Script
set -euo pipefail

CAPI_DIR="/opt/nix-volumes/capi-management"

usage() {
    echo "Usage: $0 {init|create-cluster|scale-cluster|delete-cluster|status|get-kubeconfig}"
    echo ""
    echo "Commands:"
    echo "  init            - Initialize CAPI providers"
    echo "  create-cluster  - Create multi-cloud cluster"
    echo "  scale-cluster   - Scale cluster nodes"
    echo "  delete-cluster  - Delete cluster"
    echo "  status          - Show cluster status"
    echo "  get-kubeconfig  - Get cluster kubeconfig"
}

init_capi() {
    echo "Initializing CAPI providers..."
    clusterctl init \
        --core cluster-api:v1.5.0 \
        --bootstrap kubeadm:v1.5.0 \
        --control-plane kubeadm:v1.5.0 \
        --infrastructure aws:v2.2.0,azure:v1.11.0,gcp:v1.4.0,talos:v0.5.0
}

create_cluster() {
    local cluster_name="${1:-multi-cloud-cluster}"
    local cluster_type="${2:-talos}"
    
    echo "Creating $cluster_type cluster: $cluster_name"
    
    if [[ "$cluster_type" == "talos" ]]; then
        kubectl apply -f "$CAPI_DIR/config/talos-multi-cloud-cluster.yaml"
    else
        kubectl apply -f "$CAPI_DIR/config/multi-cloud-cluster.yaml"
    fi
    
    echo "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready cluster/$cluster_name --timeout=600s
    
    echo "Cluster $cluster_name created successfully"
}

scale_cluster() {
    local cluster_name="${1:-multi-cloud-cluster}"
    local replicas="${2:-5}"
    
    echo "Scaling cluster $cluster_name to $replicas nodes..."
    
    if kubectl get taloscontrolplane $cluster_name-control-plane &> /dev/null; then
        kubectl patch taloscontrolplane $cluster_name-control-plane --type='merge' -p='{"spec":{"replicas":'$replicas'}}'
    else
        kubectl patch kubeadmcontrolplane $cluster_name-control-plane --type='merge' -p='{"spec":{"replicas":'$replicas'}}'
    fi
    
    echo "Cluster $cluster_name scaled to $replicas nodes"
}

delete_cluster() {
    local cluster_name="${1:-multi-cloud-cluster}"
    
    echo "Deleting cluster $cluster_name..."
    kubectl delete cluster $cluster_name
    echo "Cluster $cluster_name deleted"
}

status() {
    echo "CAPI Cluster Status:"
    echo "==================="
    
    echo -e "\n1. CAPI Providers:"
    clusterctl describe providers
    
    echo -e "\n2. Clusters:"
    kubectl get clusters
    
    echo -e "\n3. Control Planes:"
    kubectl get kubeadmcontrolplanes,taloscontrolplanes
    
    echo -e "\n4. Machines:"
    kubectl get machines
    
    echo -e "\n5. Infrastructure:"
    kubectl get awsclusters,azureclusters,gcpclusters,talosclusters
}

get_kubeconfig() {
    local cluster_name="${1:-multi-cloud-cluster}"
    
    echo "Getting kubeconfig for cluster: $cluster_name"
    clusterctl get kubeconfig $cluster_name > "$CAPI_DIR/$cluster_name-kubeconfig.yaml"
    echo "Kubeconfig saved to: $CAPI_DIR/$cluster_name-kubeconfig.yaml"
    echo "Use with: kubectl --kubeconfig $CAPI_DIR/$cluster_name-kubeconfig.yaml get nodes"
}

main() {
    case "${1:-}" in
        init)
            init_capi
            ;;
        create-cluster)
            create_cluster "$2" "$3"
            ;;
        scale-cluster)
            scale_cluster "$2" "$3"
            ;;
        delete-cluster)
            delete_cluster "$2"
            ;;
        status)
            status
            ;;
        get-kubeconfig)
            get_kubeconfig "$2"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
EOF

    chmod +x "$CAPI_DIR/manage-capi.sh"
    log "CAPI management script created"
}

# Deploy CAPI stack
deploy_capi() {
    log "Deploying CAPI stack..."
    
    check_prerequisites
    create_management_cluster
    init_capi_providers
    create_capi_config
    create_talos_capi_config
    create_capi_management
    
    log "CAPI deployment completed!"
}

# Main execution
main() {
    log "Starting CAPI deployment for multi-cloud Kubernetes orchestration..."
    
    deploy_capi
    
    log "CAPI deployment complete!"
    log ""
    log "Next steps:"
    log "1. Check CAPI status: $CAPI_DIR/manage-capi.sh status"
    log "2. Create Talos cluster: $CAPI_DIR/manage-capi.sh create-cluster talos-multi-cloud-cluster talos"
    log "3. Get kubeconfig: $CAPI_DIR/manage-capi.sh get-kubeconfig talos-multi-cloud-cluster"
    log "4. Deploy networking: $NETWORK_DIR/manage-networking.sh deploy"
}

main "$@"
