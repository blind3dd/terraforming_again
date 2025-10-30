#!/bin/bash

# Install CRDs for all operators
# This script installs Custom Resource Definitions for Terraform, Vault, Ansible, and Karpenter operators

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    print_success "kubectl is available and cluster is accessible"
}

# Function to install CRDs
install_crds() {
    local operator_name="$1"
    local crd_file="$2"
    
    print_status "Installing CRDs for $operator_name..."
    
    if [[ ! -f "$crd_file" ]]; then
        print_error "CRD file not found: $crd_file"
        return 1
    fi
    
    # Apply the CRD
    if kubectl apply -f "$crd_file"; then
        print_success "CRDs for $operator_name installed successfully"
    else
        print_error "Failed to install CRDs for $operator_name"
        return 1
    fi
}

# Function to wait for CRDs to be established
wait_for_crds() {
    local crd_name="$1"
    local timeout="${2:-60}"
    
    print_status "Waiting for CRD $crd_name to be established..."
    
    if kubectl wait --for=condition=Established --timeout="${timeout}s" crd/"$crd_name" 2>/dev/null; then
        print_success "CRD $crd_name is established"
    else
        print_warning "CRD $crd_name may not be fully established yet"
    fi
}

# Function to verify CRD installation
verify_crds() {
    local crd_name="$1"
    
    print_status "Verifying CRD $crd_name..."
    
    if kubectl get crd "$crd_name" &> /dev/null; then
        print_success "CRD $crd_name is installed and available"
    else
        print_error "CRD $crd_name is not available"
        return 1
    fi
}

# Main installation function
main() {
    print_status "Starting CRD installation for Database CI operators..."
    
    # Check prerequisites
    check_kubectl
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Install Terraform Operator CRDs
    install_crds "Terraform Operator" "$SCRIPT_DIR/terraform-operator/crds/terraformconfigs.yaml"
    wait_for_crds "terraformconfigs.terraform.io"
    verify_crds "terraformconfigs.terraform.io"
    
    # Install Vault Operator CRDs
    install_crds "Vault Operator" "$SCRIPT_DIR/vault-operator/crds/vaultsecrets.yaml"
    wait_for_crds "vaultsecrets.vault.io"
    verify_crds "vaultsecrets.vault.io"
    
    # Install Ansible Operator CRDs
    install_crds "Ansible Operator" "$SCRIPT_DIR/ansible-operator/crds/ansiblejobs.yaml"
    wait_for_crds "ansiblejobs.ansible.io"
    verify_crds "ansiblejobs.ansible.io"
    
    # Install Karpenter CRDs
    install_crds "Karpenter" "$SCRIPT_DIR/karpenter/crds/nodeclaims.yaml"
    wait_for_crds "nodeclaims.karpenter.sh"
    verify_crds "nodeclaims.karpenter.sh"
    
    install_crds "Karpenter" "$SCRIPT_DIR/karpenter/crds/nodepools.yaml"
    wait_for_crds "nodepools.karpenter.sh"
    verify_crds "nodepools.karpenter.sh"
    
    print_success "All CRDs have been installed successfully!"
    
    # List all installed CRDs
    print_status "Installed CRDs:"
    kubectl get crd | grep -E "(terraform|vault|ansible|karpenter)"
}

# Handle script arguments
case "${1:-install}" in
    install)
        main
        ;;
    uninstall)
        print_status "Uninstalling CRDs..."
        kubectl delete crd terraformconfigs.terraform.io || true
        kubectl delete crd vaultsecrets.vault.io || true
        kubectl delete crd ansiblejobs.ansible.io || true
        kubectl delete crd nodeclaims.karpenter.sh || true
        kubectl delete crd nodepools.karpenter.sh || true
        print_success "CRDs uninstalled"
        ;;
    verify)
        print_status "Verifying CRD installation..."
        verify_crds "terraformconfigs.terraform.io"
        verify_crds "vaultsecrets.vault.io"
        verify_crds "ansiblejobs.ansible.io"
        verify_crds "nodeclaims.karpenter.sh"
        verify_crds "nodepools.karpenter.sh"
        print_success "All CRDs are properly installed"
        ;;
    *)
        echo "Usage: $0 {install|uninstall|verify}"
        echo "  install   - Install all CRDs (default)"
        echo "  uninstall - Remove all CRDs"
        echo "  verify    - Verify CRD installation"
        exit 1
        ;;
esac
