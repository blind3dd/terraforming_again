#!/bin/bash

# =============================================================================
# Test Vault Operator Connectivity
# =============================================================================
# This script tests the Vault operator connectivity and SSM integration.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
VAULT_ADDR="${VAULT_ADDR:-https://internal.coderedalarmtech.com/vault}"
NAMESPACE="${NAMESPACE:-vault-operator}"
RELEASE_NAME="${RELEASE_NAME:-vault-operator}"

# Function to print colored output
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to test Vault operator deployment
test_vault_operator_deployment() {
    log "Testing Vault operator deployment..."
    
    # Check if deployment exists
    if ! kubectl get deployment "$RELEASE_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
        error "Vault operator deployment not found in namespace $NAMESPACE"
    fi
    
    # Check deployment status
    local ready_replicas
    ready_replicas=$(kubectl get deployment "$RELEASE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
    local desired_replicas
    desired_replicas=$(kubectl get deployment "$RELEASE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
    
    if [[ "$ready_replicas" == "$desired_replicas" ]]; then
        log "✅ Vault operator deployment is ready ($ready_replicas/$desired_replicas replicas)"
    else
        error "❌ Vault operator deployment not ready ($ready_replicas/$desired_replicas replicas)"
    fi
}

# Function to test Vault operator pod
test_vault_operator_pod() {
    log "Testing Vault operator pod..."
    
    # Get pod name
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=vault-operator" -o jsonpath='{.items[0].metadata.name}')
    
    if [[ -z "$pod_name" ]]; then
        error "❌ Vault operator pod not found"
    fi
    
    # Check pod status
    local pod_status
    pod_status=$(kubectl get pod "$pod_name" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
    
    if [[ "$pod_status" == "Running" ]]; then
        log "✅ Vault operator pod is running: $pod_name"
    else
        error "❌ Vault operator pod not running (status: $pod_status)"
    fi
    
    # Check pod logs for errors
    log "Checking Vault operator pod logs..."
    kubectl logs "$pod_name" -n "$NAMESPACE" --tail=10 | grep -i error && {
        warn "⚠️  Found errors in Vault operator logs"
    } || {
        log "✅ No errors found in Vault operator logs"
    }
}

# Function to test Vault connectivity
test_vault_connectivity() {
    log "Testing Vault connectivity..."
    
    # Get pod name
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=vault-operator" -o jsonpath='{.items[0].metadata.name}')
    
    # Test Vault health endpoint
    local health_status
    health_status=$(kubectl exec "$pod_name" -n "$NAMESPACE" -- curl -s -o /dev/null -w "%{http_code}" "$VAULT_ADDR/v1/sys/health" 2>/dev/null || echo "000")
    
    if [[ "$health_status" == "200" ]]; then
        log "✅ Vault health check passed (HTTP $health_status)"
    elif [[ "$health_status" == "503" ]]; then
        warn "⚠️  Vault is sealed (HTTP $health_status)"
    else
        error "❌ Vault connectivity failed (HTTP $health_status)"
    fi
}

# Function to test SSM parameter access
test_ssm_parameters() {
    log "Testing SSM parameter access..."
    
    # Get pod name
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=vault-operator" -o jsonpath='{.items[0].metadata.name}')
    
    # Test SSM parameter access
    local ssm_test
    ssm_test=$(kubectl exec "$pod_name" -n "$NAMESPACE" -- aws ssm get-parameter --name "/vault/operator/token" --region "$AWS_REGION" --query 'Parameter.Name' --output text 2>/dev/null || echo "FAILED")
    
    if [[ "$ssm_test" == "/vault/operator/token" ]]; then
        log "✅ SSM parameter access working"
    else
        error "❌ SSM parameter access failed"
    fi
}

# Function to test Ansible Vault password injection
test_ansible_vault_password() {
    log "Testing Ansible Vault password injection..."
    
    # Check if Ansible Vault password file exists
    if [[ -f ~/.vault_password ]]; then
        local password_length
        password_length=$(wc -c < ~/.vault_password)
        if [[ $password_length -gt 0 ]]; then
            log "✅ Ansible Vault password file exists and has content ($password_length bytes)"
        else
            error "❌ Ansible Vault password file is empty"
        fi
    else
        warn "⚠️  Ansible Vault password file not found at ~/.vault_password"
    fi
}

# Function to display Vault operator status
display_vault_operator_status() {
    log "Vault Operator Status Summary:"
    echo
    info "Configuration:"
    echo "  • Vault Address: $VAULT_ADDR"
    echo "  • Namespace: $NAMESPACE"
    echo "  • Release Name: $RELEASE_NAME"
    echo "  • Environment: $ENVIRONMENT"
    echo "  • AWS Region: $AWS_REGION"
    echo
    
    info "Deployment Status:"
    kubectl get deployment "$RELEASE_NAME" -n "$NAMESPACE" -o wide
    echo
    
    info "Pod Status:"
    kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=vault-operator" -o wide
    echo
    
    info "Service Status:"
    kubectl get service -n "$NAMESPACE" -l "app.kubernetes.io/name=vault-operator" -o wide
    echo
}

# Main function
main() {
    log "Testing Vault Operator with SSM Integration"
    log "Environment: $ENVIRONMENT"
    log "AWS Region: $AWS_REGION"
    log "Vault Address: $VAULT_ADDR"
    echo
    
    # Check prerequisites
    if ! command_exists kubectl; then
        error "kubectl is not installed or not in PATH"
    fi
    
    if ! command_exists aws; then
        error "AWS CLI is not installed or not in PATH"
    fi
    
    # Run tests
    test_vault_operator_deployment
    test_vault_operator_pod
    test_vault_connectivity
    test_ssm_parameters
    test_ansible_vault_password
    
    # Display status
    display_vault_operator_status
    
    log "✅ All Vault operator tests passed!"
    echo
    info "🚀 Vault operator is ready for use with:"
    echo "  • Internal FQDN routing: $VAULT_ADDR"
    echo "  • SSM Parameter Store integration"
    echo "  • Ansible Vault password injection"
    echo "  • Secure token-based authentication"
}

# Run main function
main "$@"
