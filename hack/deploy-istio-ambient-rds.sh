#!/bin/bash
# Deploy Istio Ambient Mode RDS Application
# This script deploys a secure pod with Istio ambient mode connecting to RDS

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $1${NC}"; exit 1; }
info() { echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO: $1${NC}"; }

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    error "kubectl not found. Please install it first."
fi

# Check if cluster is running
if ! kubectl cluster-info &> /dev/null; then
    error "No Kubernetes cluster running. Start your cluster first."
fi

# Check if Istio is installed
if ! kubectl get namespace istio-system &> /dev/null; then
    error "Istio not found. Please install Istio first."
fi

log "Deploying Istio Ambient Mode RDS Application..."

# 1. Setup seccomp profiles
log "Setting up seccomp profiles..."
if [[ $EUID -eq 0 ]]; then
    ./scripts/setup-k8s-seccomp-profiles.sh
else
    warn "Not running as root. Seccomp profiles may not be available."
    warn "Run 'sudo ./scripts/setup-k8s-seccomp-profiles.sh' to install them."
fi

# 2. Create namespace and apply security policies
log "Creating namespace with security policies..."
kubectl apply -f kubernetes/istio-ambient-rds-pod.yaml

# 3. Wait for deployment to be ready
log "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/rds-app -n istio-ambient

# 4. Verify deployment
log "Verifying deployment..."
kubectl get pods -n istio-ambient
kubectl get services -n istio-ambient
kubectl get networkpolicies -n istio-ambient

# 5. Check seccomp profile is applied
log "Checking seccomp profile is applied..."
kubectl describe pod -l app=rds-app -n istio-ambient | grep -i seccomp || warn "Seccomp profile not found in pod description"

# 6. Test connectivity
log "Testing connectivity..."
kubectl exec -n istio-ambient deployment/rds-app -- curl -s http://localhost:8080/health || warn "Health check failed"

# 7. Show logs
log "Showing application logs..."
kubectl logs -n istio-ambient deployment/rds-app --tail=10

# 8. Show security context
log "Showing security context..."
kubectl get pod -l app=rds-app -n istio-ambient -o jsonpath='{.items[0].spec.securityContext}' | jq '.' 2>/dev/null || kubectl get pod -l app=rds-app -n istio-ambient -o jsonpath='{.items[0].spec.securityContext}'

# 9. Show container security context
log "Showing container security context..."
kubectl get pod -l app=rds-app -n istio-ambient -o jsonpath='{.items[0].spec.containers[0].securityContext}' | jq '.' 2>/dev/null || kubectl get pod -l app=rds-app -n istio-ambient -o jsonpath='{.items[0].spec.containers[0].securityContext}'

# 10. Show Istio ambient mode status
log "Checking Istio ambient mode status..."
kubectl get pods -n istio-ambient -o jsonpath='{.items[0].metadata.labels.sidecar\.istio\.io/inject}' || warn "Istio injection label not found"

# 11. Show network policies
log "Showing network policies..."
kubectl describe networkpolicy rds-app-netpol -n istio-ambient

# 12. Show service endpoints
log "Showing service endpoints..."
kubectl get endpoints rds-app-service -n istio-ambient

# 13. Show Istio resources
log "Showing Istio resources..."
kubectl get gateway,virtualservice,destinationrule -n istio-ambient

# 14. Show resource usage
log "Showing resource usage..."
kubectl top pods -n istio-ambient 2>/dev/null || warn "Metrics server not available"

# 15. Show security validation
log "Running security validation..."
kubectl get pod -l app=rds-app -n istio-ambient -o jsonpath='{.items[0].spec.containers[0].securityContext.seccompProfile}' | jq '.' 2>/dev/null || kubectl get pod -l app=rds-app -n istio-ambient -o jsonpath='{.items[0].spec.containers[0].securityContext.seccompProfile}'

log "Deployment complete!"
info "Key features deployed:"
info "- Istio ambient mode (no sidecar proxy)"
info "- Seccomp profile: seccomp-k8s-database-profile.json"
info "- Non-root user execution (UID 1000)"
info "- Read-only root filesystem"
info "- Dropped capabilities"
info "- Network policies for security"
info "- RDS connectivity ready"
info "- High availability with PDB and HPA"

warn "Next steps:"
warn "1. Update RDS credentials in the secret"
warn "2. Configure your application to connect to RDS"
warn "3. Test the application functionality"
warn "4. Monitor logs and metrics"

log "Access your application:"
log "kubectl port-forward -n istio-ambient service/rds-app-service 8080:8080"
log "Then visit: http://localhost:8080"
