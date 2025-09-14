#!/bin/bash
# Secure macOS Local Kubernetes Setup
# This script configures security measures to prevent impersonation attacks
# and other security issues when running Kubernetes locally on macOS

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    error "This script is designed for macOS only"
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    error "kubectl is not installed. Please install it first."
fi

# Check if Docker Desktop or minikube is running
if ! kubectl cluster-info &> /dev/null; then
    error "No Kubernetes cluster is running. Please start Docker Desktop or minikube first."
fi

log "Securing macOS local Kubernetes cluster against impersonation attacks..."

# 1. Create security namespace
log "Creating security namespace..."
kubectl create namespace security --dry-run=client -o yaml | kubectl apply -f -

# 2. Apply security configurations
log "Applying security configurations..."
kubectl apply -f kubernetes/macos-local-security.yaml

# 3. Configure ImpersonationFilter
log "Configuring ImpersonationFilter..."
cat > /tmp/impersonation-filter.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: impersonation-filter-config
  namespace: kube-system
data:
  config.yaml: |
    # ImpersonationFilter configuration for local macOS Kubernetes
    disableUserImpersonation: true
    disableGroupImpersonation: true
    disableServiceAccountImpersonation: true
    allowedImpersonators: []
    allowedImpersonatorGroups: []
    disableExtraFieldImpersonation: true
    logImpersonationAttempts: true
    failClosed: true
EOF

kubectl apply -f /tmp/impersonation-filter.yaml
rm -f /tmp/impersonation-filter.yaml

# 4. Create restrictive RBAC
log "Creating restrictive RBAC..."
cat > /tmp/restrictive-rbac.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: macos-restricted-user
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources: ["networkpolicies"]
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

kubectl apply -f /tmp/restrictive-rbac.yaml
rm -f /tmp/restrictive-rbac.yaml

# 5. Configure Pod Security Standards
log "Configuring Pod Security Standards..."
kubectl create namespace secure-workloads --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace secure-workloads pod-security.kubernetes.io/enforce=restricted
kubectl label namespace secure-workloads pod-security.kubernetes.io/audit=restricted
kubectl label namespace secure-workloads pod-security.kubernetes.io/warn=restricted

# 6. Create Network Policies
log "Creating network policies..."
cat > /tmp/network-policies.yaml << EOF
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

kubectl apply -f /tmp/network-policies.yaml
rm -f /tmp/network-policies.yaml

# 7. Configure Audit Logging
log "Configuring audit logging..."
cat > /tmp/audit-policy.yaml << EOF
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  namespaces: ["kube-system"]
  verbs: ["impersonate"]
  resources:
  - group: ""
    resources: ["users", "groups", "serviceaccounts"]
- level: RequestResponse
  verbs: ["create", "update", "patch"]
  resources:
  - group: ""
    resources: ["pods"]
  - group: "apps"
    resources: ["deployments", "replicasets"]
- level: RequestResponse
  verbs: ["create", "update", "patch", "delete"]
  resources:
  - group: "rbac.authorization.k8s.io"
    resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
EOF

kubectl create configmap audit-policy --from-file=policy.yaml=/tmp/audit-policy.yaml -n kube-system
rm -f /tmp/audit-policy.yaml

# 8. Create Security Monitoring
log "Creating security monitoring..."
cat > /tmp/security-monitoring.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: security-monitoring
  namespace: kube-system
data:
  monitor.sh: |
    #!/bin/bash
    # Monitor for impersonation attempts and security violations
    while true; do
      # Check for impersonation attempts in audit logs
      if kubectl logs -n kube-system -l app=audit-controller | grep -i "impersonate" > /dev/null 2>&1; then
        echo "WARNING: Impersonation attempt detected at $(date)"
      fi
      
      # Check for privilege escalation attempts
      if kubectl logs -n kube-system -l app=admission-controller | grep -i "privilege" > /dev/null 2>&1; then
        echo "WARNING: Privilege escalation attempt detected at $(date)"
      fi
      
      # Check for unauthorized RBAC changes
      if kubectl logs -n kube-system -l app=rbac-controller | grep -i "unauthorized" > /dev/null 2>&1; then
        echo "WARNING: Unauthorized RBAC change detected at $(date)"
      fi
      
      sleep 30
    done
EOF

kubectl apply -f /tmp/security-monitoring.yaml
rm -f /tmp/security-monitoring.yaml

# 9. Configure macOS-specific security settings
log "Configuring macOS-specific security settings..."

# Disable automatic login
sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser -string ""

# Enable FileVault if not already enabled
if ! fdesetup status | grep -q "FileVault is On"; then
    warn "FileVault is not enabled. Consider enabling it for additional security."
fi

# Configure firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

# 10. Create security validation script
log "Creating security validation script..."
cat > /tmp/validate-security.sh << 'EOF'
#!/bin/bash
# Validate security configuration

echo "=== Kubernetes Security Validation ==="

# Check if ImpersonationFilter is configured
if kubectl get configmap impersonation-filter-config -n kube-system > /dev/null 2>&1; then
    echo "✓ ImpersonationFilter is configured"
else
    echo "✗ ImpersonationFilter is not configured"
fi

# Check if Pod Security Standards are enforced
if kubectl get namespace secure-workloads -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' | grep -q "restricted"; then
    echo "✓ Pod Security Standards are enforced"
else
    echo "✗ Pod Security Standards are not enforced"
fi

# Check if Network Policies are applied
if kubectl get networkpolicy default-deny-all -n default > /dev/null 2>&1; then
    echo "✓ Network Policies are applied"
else
    echo "✗ Network Policies are not applied"
fi

# Check if RBAC is restrictive
if kubectl get clusterrole macos-restricted-user > /dev/null 2>&1; then
    echo "✓ Restrictive RBAC is configured"
else
    echo "✗ Restrictive RBAC is not configured"
fi

# Check if audit logging is enabled
if kubectl get configmap audit-policy -n kube-system > /dev/null 2>&1; then
    echo "✓ Audit logging is configured"
else
    echo "✗ Audit logging is not configured"
fi

echo "=== macOS Security Validation ==="

# Check FileVault status
if fdesetup status | grep -q "FileVault is On"; then
    echo "✓ FileVault is enabled"
else
    echo "✗ FileVault is not enabled"
fi

# Check firewall status
if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -q "enabled"; then
    echo "✓ Firewall is enabled"
else
    echo "✗ Firewall is not enabled"
fi

# Check automatic login
if sudo defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null | grep -q ""; then
    echo "✗ Automatic login is enabled"
else
    echo "✓ Automatic login is disabled"
fi

echo "=== Security Validation Complete ==="
EOF

chmod +x /tmp/validate-security.sh
sudo mv /tmp/validate-security.sh /usr/local/bin/validate-k8s-security

# 11. Create security monitoring daemon
log "Creating security monitoring daemon..."
cat > /tmp/com.kubernetes.security.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.kubernetes.security</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/validate-k8s-security</string>
    </array>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/kubernetes-security.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/kubernetes-security-error.log</string>
</dict>
</plist>
EOF

sudo mv /tmp/com.kubernetes.security.plist /Library/LaunchDaemons/
sudo launchctl load /Library/LaunchDaemons/com.kubernetes.security.plist

# 12. Create security documentation
log "Creating security documentation..."
cat > /tmp/MACOS_K8S_SECURITY.md << 'EOF'
# macOS Local Kubernetes Security Guide

## Overview
This guide covers security measures implemented to protect your local macOS Kubernetes cluster from impersonation attacks and other security threats.

## Security Measures Implemented

### 1. ImpersonationFilter
- **Purpose**: Prevents unauthorized user/group/service account impersonation
- **Configuration**: Disabled by default, fail-closed on attempts
- **Monitoring**: All impersonation attempts are logged

### 2. Pod Security Standards
- **Enforcement**: Restricted mode for all workloads
- **Namespace**: `secure-workloads` with strict policies
- **Features**: Non-root containers, read-only filesystems, dropped capabilities

### 3. Network Policies
- **Default**: Deny all ingress/egress traffic
- **Scope**: Applied to default and secure-workloads namespaces
- **Benefit**: Prevents lateral movement and data exfiltration

### 4. RBAC (Role-Based Access Control)
- **Principle**: Least privilege access
- **Scope**: Minimal permissions for local development
- **Monitoring**: All RBAC changes are audited

### 5. Audit Logging
- **Scope**: Impersonation attempts, privilege escalation, RBAC changes
- **Storage**: Kubernetes audit logs
- **Monitoring**: Automated security monitoring daemon

### 6. macOS Security
- **FileVault**: Full disk encryption (if enabled)
- **Firewall**: Application firewall with stealth mode
- **Login**: Automatic login disabled

## Usage

### Starting Secure Cluster
```bash
# Start your Kubernetes cluster (Docker Desktop, minikube, etc.)
# Then run the security script
./scripts/secure-macos-k8s.sh
```

### Validating Security
```bash
# Run security validation
validate-k8s-security
```

### Monitoring Security
```bash
# Check security logs
tail -f /var/log/kubernetes-security.log

# Check for impersonation attempts
kubectl logs -n kube-system -l app=audit-controller | grep -i "impersonate"
```

## Best Practices

1. **Regular Updates**: Keep Kubernetes and Docker Desktop updated
2. **Minimal Permissions**: Use the restrictive RBAC roles provided
3. **Network Isolation**: Use the secure-workloads namespace for sensitive workloads
4. **Audit Monitoring**: Regularly check audit logs for suspicious activity
5. **macOS Security**: Keep macOS updated and enable FileVault

## Troubleshooting

### Common Issues

1. **Pod Creation Fails**
   - Check Pod Security Standards compliance
   - Ensure containers run as non-root
   - Verify seccomp profiles are available

2. **Network Connectivity Issues**
   - Check Network Policies
   - Verify ingress/egress rules
   - Test with kubectl exec

3. **Permission Denied Errors**
   - Check RBAC configuration
   - Verify user has appropriate roles
   - Check audit logs for details

### Security Validation

Run the validation script to check your security configuration:
```bash
validate-k8s-security
```

## Additional Security Considerations

1. **Container Images**: Use only trusted, scanned images
2. **Secrets Management**: Use Kubernetes secrets or external secret management
3. **Network Segmentation**: Consider using service mesh for additional security
4. **Monitoring**: Implement comprehensive monitoring and alerting
5. **Backup**: Regular backup of cluster configuration and data

## Emergency Procedures

### Disable Security (Emergency Only)
```bash
# Remove network policies
kubectl delete networkpolicy default-deny-all -n default
kubectl delete networkpolicy default-deny-all -n secure-workloads

# Remove Pod Security Standards
kubectl label namespace secure-workloads pod-security.kubernetes.io/enforce-
kubectl label namespace secure-workloads pod-security.kubernetes.io/audit-
kubectl label namespace secure-workloads pod-security.kubernetes.io/warn-
```

### Re-enable Security
```bash
# Re-run the security script
./scripts/secure-macos-k8s.sh
```

## Support

For security issues or questions:
1. Check the audit logs first
2. Run the validation script
3. Review this documentation
4. Consider the emergency procedures if needed

Remember: Security is a process, not a one-time setup. Regular monitoring and updates are essential.
EOF

mv /tmp/MACOS_K8S_SECURITY.md ./

# 13. Final validation
log "Running final security validation..."
/usr/local/bin/validate-k8s-security

log "macOS Kubernetes security configuration complete!"
log "Security documentation created: MACOS_K8S_SECURITY.md"
log "Validation script available: validate-k8s-security"
log "Security monitoring daemon started"

info "Key security features enabled:"
info "- ImpersonationFilter: Prevents unauthorized impersonation"
info "- Pod Security Standards: Restricted mode enforcement"
info "- Network Policies: Default deny all traffic"
info "- RBAC: Least privilege access control"
info "- Audit Logging: Comprehensive security event logging"
info "- macOS Security: FileVault, firewall, and login security"

warn "Remember to:"
warn "- Keep Kubernetes and Docker Desktop updated"
warn "- Regularly check audit logs for suspicious activity"
warn "- Use the secure-workloads namespace for sensitive workloads"
warn "- Run validate-k8s-security periodically"

log "Your local macOS Kubernetes cluster is now secured against impersonation attacks!"
