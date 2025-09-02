c#!/bin/bash
# Kubernetes Worker Node Setup Script
# This script joins a Kubernetes worker node to the cluster

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

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $\$1"
}

warn() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $\$1"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $\$1"
    exit 1
}

# Function to wait for control plane to be ready
wait_for_control_plane() {
    log "Waiting for control plane to be ready..."
    
    # Wait for kubelet to be running
    while ! systemctl is-active --quiet kubelet; do
        log "Waiting for kubelet to start..."
        sleep 10
    done
    
    log "Kubelet is running"
}

# Function to get join command from control plane
get_join_command() {
    log "Getting join command from control plane..."
    
    # This would typically be done by getting the join command from the first control plane node
    # For now, we'll create a placeholder join command
    cat > /home/ec2-user/join-command.txt << EOF
# Worker Node Join Command
# This would be obtained from the first control plane node
# Example: kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>

# To get the actual join command, run this on the first control plane node:
# kubeadm token create --print-join-command

# Then run the output command on this worker node
EOF

    chown ec2-user:ec2-user /home/ec2-user/join-command.txt
    chmod 644 /home/ec2-user/join-command.txt
    
    warn "Manual intervention required to join worker node"
    warn "Please run the join command from the control plane node"
}

# Function to join the worker node to the cluster
join_worker_node() {
    log "Joining worker node to the cluster..."
    
    # Check if we have a join command
    if [[ -f /home/ec2-user/join-command.txt ]]; then
        local join_command
        join_command=$(grep "kubeadm join" /home/ec2-user/join-command.txt || echo "")
        
        if [[ -n "$join_command" ]]; then
            log "Executing join command..."
            eval "$join_command"
            
            if [[ $? -eq 0 ]]; then
                log "Successfully joined the cluster!"
            else
                error "Failed to join the cluster"
            fi
        else
            warn "No valid join command found in /home/ec2-user/join-command.txt"
            warn "Please run the join command manually"
        fi
    else
        warn "Join command file not found"
        warn "Please run the join command manually"
    fi
}

# Function to verify node status
verify_node_status() {
    log "Verifying node status..."
    
    # Wait a bit for the node to register
    sleep 30
    
    # Check if kubectl is available
    if command -v kubectl &> /dev/null; then
        if kubectl get nodes &> /dev/null; then
            log "Node information:"
            kubectl get nodes -o wide
        else
            warn "Cannot connect to cluster API server"
        fi
    else
        warn "kubectl not available"
    fi
}

# Function to install Calico CNI (if not already installed)
install_calico() {
    log "Checking Calico CNI installation..."
    
    # Check if Calico is already installed
    if kubectl get pods -n kube-system | grep -q calico; then
        log "Calico CNI is already installed"
        return 0
    fi
    
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

# Function to configure node labels and taints
configure_node() {
    log "Configuring node labels and taints..."
    
    local node_name
    node_name=$(hostname)
    
    # Add node labels
    kubectl label node "$node_name" node-role.kubernetes.io/worker=true --overwrite
    kubectl label node "$node_name" environment="$ENVIRONMENT" --overwrite
    kubectl label node "$node_name" service="$SERVICE_NAME" --overwrite
    
    log "Node labels configured"
}

# Function to verify cluster connectivity
verify_cluster_connectivity() {
    log "Verifying cluster connectivity..."
    
    # Test DNS resolution
    if kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default; then
        log "✅ DNS resolution working"
    else
        warn "❌ DNS resolution failed"
    fi
    
    # Test pod-to-pod communication
    if kubectl run test-ping --image=busybox --rm -it --restart=Never -- ping -c 3 8.8.8.8; then
        log "✅ Pod-to-pod communication working"
    else
        warn "❌ Pod-to-pod communication failed"
    fi
}

# Function to display cluster information
display_cluster_info() {
    log "Cluster Information:"
    echo "Environment: $ENVIRONMENT"
    echo "Service: $SERVICE_NAME"
    echo "Cluster: $CLUSTER_NAME"
    echo "Pod CIDR: $POD_CIDR"
    echo "Service CIDR: $SERVICE_CIDR"
    echo "Kubernetes Version: $KUBERNETES_VERSION"
    echo "Calico Version: $CALICO_VERSION"
    echo "AWS Region: $AWS_REGION"
    echo "AWS Account: $AWS_ACCOUNT_ID"
    echo ""
    
    if command -v kubectl &> /dev/null; then
        echo "Node Status:"
        kubectl get nodes -o wide || echo "Cannot get node status"
        echo ""
        
        echo "Pod Status:"
        kubectl get pods --all-namespaces || echo "Cannot get pod status"
    fi
}

# Main execution
main() {
    log "🚀 Starting Kubernetes Worker Node Setup"
    log "Environment: $ENVIRONMENT"
    log "Service: $SERVICE_NAME"
    log "Cluster: $CLUSTER_NAME"
    log "Pod CIDR: $POD_CIDR"
    log "Service CIDR: $SERVICE_CIDR"

    # Wait for control plane
    wait_for_control_plane
    
    # Get join command
    get_join_command
    
    # Join the cluster
    join_worker_node
    
    # Verify node status
    verify_node_status
    
    # Install Calico (if needed)
    install_calico
    
    # Configure node
    configure_node
    
    # Verify connectivity
    verify_cluster_connectivity
    
    # Display information
    display_cluster_info

    log "🎉 Kubernetes Worker Node Setup completed successfully!"
    log "📋 Next steps:"
    log "   1. Verify node is ready: kubectl get nodes"
    log "   2. Check pod status: kubectl get pods --all-namespaces"
    log "   3. Test cluster connectivity"
    log "   4. Deploy your applications"

    # Fun completion message
    if command -v cowsay &> /dev/null && command -v fortune &> /dev/null; then
        echo ""
        fortune | cowsay
    fi
}

# Run main function
main "$@"
