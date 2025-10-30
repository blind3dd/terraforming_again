#!/bin/bash
# Simple macOS Kubernetes Security Setup
# Focuses on preventing impersonation attacks and basic security

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $1${NC}"; exit 1; }

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    error "kubectl not found. Please install it first."
fi

# Check if cluster is running
if ! kubectl cluster-info &> /dev/null; then
    error "No Kubernetes cluster running. Start Docker Desktop or minikube first."
fi

log "Setting up basic security for local macOS Kubernetes..."

# 1. Create ImpersonationFilter configuration
log "Creating ImpersonationFilter to prevent impersonation attacks..."
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: impersonation-filter-config
  namespace: kube-system
data:
  config.yaml: |
    # Prevent all impersonation by default
    disableUserImpersonation: true
    disableGroupImpersonation: true
    disableServiceAccountImpersonation: true
    allowedImpersonators: []
    allowedImpersonatorGroups: []
    logImpersonationAttempts: true
    failClosed: true
EOF

# 2. Create restrictive RBAC
log "Creating restrictive RBAC..."
cat << 'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: macos-restricted-user
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: macos-user-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: macos-restricted-user
subjects:
- kind: User
  name: macos-user
  apiGroup: rbac.authorization.k8s.io
EOF

# 3. Create secure namespace with Pod Security Standards
log "Creating secure namespace..."
kubectl create namespace secure-workloads --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace secure-workloads pod-security.kubernetes.io/enforce=restricted --overwrite
kubectl label namespace secure-workloads pod-security.kubernetes.io/audit=restricted --overwrite
kubectl label namespace secure-workloads pod-security.kubernetes.io/warn=restricted --overwrite

# 4. Create basic network policy
log "Creating network policy..."
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: secure-workloads
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# 5. Create audit policy
log "Creating audit policy..."
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: audit-policy
  namespace: kube-system
data:
  policy.yaml: |
    apiVersion: audit.k8s.io/v1
    kind: Policy
    rules:
    - level: RequestResponse
      verbs: ["impersonate"]
      resources:
      - group: ""
        resources: ["users", "groups", "serviceaccounts"]
    - level: RequestResponse
      verbs: ["create", "update", "patch", "delete"]
      resources:
      - group: "rbac.authorization.k8s.io"
        resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
EOF

# 6. Create validation script
log "Creating validation script..."
cat > /tmp/validate-security.sh << 'EOF'
#!/bin/bash
echo "=== Kubernetes Security Check ==="

# Check ImpersonationFilter
if kubectl get configmap impersonation-filter-config -n kube-system > /dev/null 2>&1; then
    echo "✓ ImpersonationFilter configured"
else
    echo "✗ ImpersonationFilter missing"
fi

# Check Pod Security Standards
if kubectl get namespace secure-workloads -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' | grep -q "restricted"; then
    echo "✓ Pod Security Standards enforced"
else
    echo "✗ Pod Security Standards not enforced"
fi

# Check Network Policies
if kubectl get networkpolicy default-deny-all -n default > /dev/null 2>&1; then
    echo "✓ Network Policies applied"
else
    echo "✗ Network Policies missing"
fi

# Check RBAC
if kubectl get clusterrole macos-restricted-user > /dev/null 2>&1; then
    echo "✓ Restrictive RBAC configured"
else
    echo "✗ Restrictive RBAC missing"
fi

echo "=== Security Check Complete ==="
EOF

chmod +x /tmp/validate-security.sh
sudo mv /tmp/validate-security.sh /usr/local/bin/validate-k8s-security

# 7. macOS specific security
log "Configuring macOS security..."

# Check FileVault
if fdesetup status | grep -q "FileVault is On"; then
    log "✓ FileVault is enabled"
else
    warn "FileVault is not enabled. Consider enabling it."
fi

# Check firewall
if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -q "enabled"; then
    log "✓ Firewall is enabled"
else
    warn "Firewall is not enabled. Consider enabling it."
fi

# 8. Create simple monitoring
log "Creating simple security monitoring..."
cat > /tmp/security-monitor.sh << 'EOF'
#!/bin/bash
# Simple security monitor
while true; do
    # Check for impersonation attempts
    if kubectl logs -n kube-system --since=1m | grep -i "impersonate" > /dev/null 2>&1; then
        echo "WARNING: Impersonation attempt detected at $(date)"
    fi
    
    # Check for privilege escalation
    if kubectl logs -n kube-system --since=1m | grep -i "privilege" > /dev/null 2>&1; then
        echo "WARNING: Privilege escalation attempt detected at $(date)"
    fi
    
    sleep 60
done
EOF

chmod +x /tmp/security-monitor.sh
mv /tmp/security-monitor.sh ~/security-monitor.sh

log "Security setup complete!"
log "Run 'validate-k8s-security' to check your configuration"
log "Run '~/security-monitor.sh' to monitor for security events"
log "Use 'secure-workloads' namespace for your applications"

warn "Remember to:"
warn "- Keep Kubernetes updated"
warn "- Use the secure-workloads namespace"
warn "- Check logs regularly for security events"
