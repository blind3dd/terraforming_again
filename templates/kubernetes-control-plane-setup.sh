#!/bin/bash
# Kubernetes Control Plane Setup Script
# This script initializes the Kubernetes cluster and installs Calico CNI

set -e

# Configuration variables
ENVIRONMENT="${environment}"
SERVICE_NAME="${service_name}"
CLUSTER_NAME="${cluster_name}"
POD_CIDR="${pod_cidr}"
SERVICE_CIDR="${service_cidr}"
CALICO_VERSION="${calico_version}"
KUBERNETES_VERSION="${kubernetes_version}"
AWS_REGION="${aws_region}"
AWS_ACCOUNT_ID="${aws_account_id}"
RDS_ENDPOINT="${rds_endpoint}"
RDS_PORT="${rds_port}"
RDS_DATABASE="${rds_database}"
RDS_USERNAME="${rds_username}"
RDS_PASSWORD_PARAMETER="${rds_password_parameter}"
AWS_ACCESS_KEY_ID="${aws_access_key_id}"
AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"
ROUTE53_ZONE_ID="${route53_zone_id}"

# Feature flags
ENABLE_MULTICLUSTER_HEADLESS="${enable_multicluster_headless}"
ENABLE_NATIVE_SIDECARS="${enable_native_sidecars}"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

warn() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1"
    exit 1
}

# Function to check if this is the first control plane node
is_first_control_plane() {
    # Check if etcd data directory is empty (first node)
    if [ ! -d "/var/lib/etcd/member" ] || [ -z "$(ls -A /var/lib/etcd/member 2>/dev/null)" ]; then
        log "This appears to be the first control plane node"
        return 0
    else
        log "This appears to be a subsequent control plane node"
        return 1
    fi
}

# Function to initialize the first control plane node
init_first_control_plane() {
    log "Initializing first control plane node..."
    
    # Create kubeadm config
    cat > /tmp/kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  criSocket: "unix:///run/containerd/containerd.sock"
  kubeletExtraArgs:
    cgroup-driver: "systemd"
    container-runtime-endpoint: "unix:///run/containerd/containerd.sock"
    node-ip: "$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
    cloud-provider: "aws"
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: "$KUBERNETES_VERSION"
clusterName: "$CLUSTER_NAME"
controlPlaneEndpoint: "$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):6443"
networking:
  podSubnet: "$POD_CIDR"
  serviceSubnet: "$SERVICE_CIDR"
  dnsDomain: "cluster.local"
apiServer:
  certSANs:
    - "$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
    - "kubernetes.default.svc"
    - "kubernetes.default.svc.cluster.local"
    - "127.0.0.1"
    - "localhost"
    - "$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
  extraArgs:
    cloud-provider: "aws"
    cloud-config: "/etc/kubernetes/cloud-config"
controllerManager:
  extraArgs:
    cloud-provider: "aws"
    cloud-config: "/etc/kubernetes/cloud-config"
    allocate-node-cidrs: "false"
scheduler:
  extraArgs: {}
etcd:
  local:
    dataDir: "/var/lib/etcd"
    extraArgs:
      listen-client-urls: "https://127.0.0.1:2379,https://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):2379"
      advertise-client-urls: "https://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):2379"
      listen-peer-urls: "https://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):2380"
      initial-advertise-peer-urls: "https://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):2380"
      initial-cluster: "k8s-control-plane-1=https://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):2380"
      initial-cluster-state: "new"
      initial-cluster-token: "etcd-cluster"
      client-cert-auth: "true"
      peer-cert-auth: "true"
      cert-file: "/etc/kubernetes/pki/etcd/server.crt"
      key-file: "/etc/kubernetes/pki/etcd/server.key"
      peer-cert-file: "/etc/kubernetes/pki/etcd/peer.crt"
      peer-key-file: "/etc/kubernetes/pki/etcd/peer.key"
      trusted-ca-file: "/etc/kubernetes/pki/etcd/ca.crt"
      peer-trusted-ca-file: "/etc/kubernetes/pki/etcd/ca.crt"
EOF

    # Initialize the cluster
    kubeadm init --config=/tmp/kubeadm-config.yaml --upload-certs

    # Set up kubectl
    mkdir -p /home/ec2-user/.kube
    cp -i /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
    chown ec2-user:ec2-user /home/ec2-user/.kube/config

    log "✅ First control plane node initialized successfully!"
}

# Function to install Calico CNI
install_calico() {
    log "Installing Calico CNI..."
    
    # Download Calico operator
    curl -O -L "https://github.com/projectcalico/calico/releases/download/v${calico_version}/tigera-operator.yaml"
    
    # Apply Calico operator
    kubectl apply -f tigera-operator.yaml
    
    # Download Calico custom resources
    curl -O -L "https://github.com/projectcalico/calico/releases/download/v${calico_version}/custom-resources.yaml"
    
    # Update custom resources with our CIDR
    sed -i "s|cidr: 192.168.0.0/16|cidr: ${pod_cidr}|g" custom-resources.yaml
    
    # Apply custom resources
    kubectl apply -f custom-resources.yaml
    
    # Wait for Calico to be ready
    log "Waiting for Calico to be ready..."
    kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=300s
    
    log "✅ Calico CNI installed successfully!"
}

# Function to install cert-manager
install_cert_manager() {
    log "Installing cert-manager..."
    
    # Apply cert-manager CRDs
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml
    
    # Add Jetstack Helm repository
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    
    # Install cert-manager
    helm install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --version v1.13.0 \
        --set installCRDs=true
    
    # Wait for cert-manager to be ready
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s
    
    log "✅ cert-manager installed successfully!"
}

# Function to configure CoreDNS
configure_coredns() {
    log "Configuring CoreDNS..."
    
    # Create CoreDNS ConfigMap
    cat > /tmp/coredns-configmap.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
        log
        hosts {
           127.0.0.1 localhost
           fallthrough
        }
    }
EOF

    kubectl apply -f /tmp/coredns-configmap.yaml
    
    # Update CoreDNS deployment
    kubectl patch deployment coredns -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/volumes/-", "value": {"name": "custom-config", "configMap": {"name": "coredns-custom"}}}, {"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts/-", "value": {"name": "custom-config", "mountPath": "/etc/coredns/custom"}}]'
    
    # Restart CoreDNS
    kubectl rollout restart deployment coredns -n kube-system
    
    log "✅ CoreDNS configured successfully!"
}

# Function to install Istio
install_istio() {
    log "Installing Istio..."
    
    # Download Istio
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.20.0 sh -
    cd istio-1.20.0
    
    # Install Istio with Ambient Mode
    bin/istioctl install --set profile=ambient --set values.global.proxy.resources.limits.cpu=500m --set values.global.proxy.resources.limits.memory=512Mi --set values.global.proxy.resources.requests.cpu=100m --set values.global.proxy.resources.requests.memory=128Mi --set values.global.proxy.includeIPRanges=10.244.0.0/16 --set values.global.proxy.nativeSidecar=${enable_native_sidecars} -y
    
    # Enable Istio injection for default namespace
    kubectl label namespace default istio-injection=enabled
    
    log "✅ Istio installed successfully!"
}

# Function to verify cluster health
verify_cluster_health() {
    log "Verifying cluster health..."
    
    # Check nodes
    kubectl get nodes -o wide
    
    # Check pods
    kubectl get pods --all-namespaces
    
    # Check services
    kubectl get services --all-namespaces
    
    log "✅ Cluster health verification completed!"
}

# Main execution
main() {
    log "🚀 Starting Kubernetes Control Plane Setup"
    log "Environment: $ENVIRONMENT"
    log "Service: $SERVICE_NAME"
    log "Cluster: $CLUSTER_NAME"
    log "Pod CIDR: $POD_CIDR"
    log "Service CIDR: $SERVICE_CIDR"

    # Check if this is the first control plane node
    if is_first_control_plane; then
        # Initialize the first control plane node
        init_first_control_plane
        
        # Install Calico CNI
        install_calico
        
        # Install cert-manager
        install_cert_manager
        
        # Configure CoreDNS
        configure_coredns
        
        # Install Istio
        install_istio
        
        # Verify cluster health
        verify_cluster_health
        
        log " First control plane node setup completed successfully!"
        log " Next steps:"
        log " 1. Join other control plane nodes"
        log " 2. Join worker nodes"
        log " 3. Deploy your applications"
    else
        log "This is a subsequent control plane node - joining cluster..."
        # TODO: Implement join logic for subsequent control plane nodes
        warn "Manual intervention required to join subsequent control plane nodes"
    fi

    # Fun completion message
    if command -v cowsay &> /dev/null && command -v fortune &> /dev/null; then
        echo ""
        fortune | cowsay
    fi
}

# Run main function
main "$@"
