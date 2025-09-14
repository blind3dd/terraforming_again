#!/bin/bash
# Setup Kubernetes Seccomp Profiles
# This script copies seccomp profiles to the correct location for Kubernetes

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $1${NC}"; exit 1; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root to copy files to system directories"
fi

log "Setting up Kubernetes seccomp profiles..."

# Create seccomp profiles directory
SECCOMP_DIR="/var/lib/kubelet/seccomp/profiles"
mkdir -p "$SECCOMP_DIR"

# Copy seccomp profiles
log "Copying seccomp profiles to $SECCOMP_DIR..."

# Copy general profiles
if [[ -f "selinux/seccomp-profiles.json" ]]; then
    cp selinux/seccomp-profiles.json "$SECCOMP_DIR/"
    log "✓ Copied seccomp-profiles.json"
else
    warn "seccomp-profiles.json not found"
fi

# Copy Kubernetes-specific profiles
if [[ -f "selinux/seccomp-kubelet-profile.json" ]]; then
    cp selinux/seccomp-kubelet-profile.json "$SECCOMP_DIR/"
    log "✓ Copied seccomp-kubelet-profile.json"
else
    warn "seccomp-kubelet-profile.json not found"
fi

if [[ -f "selinux/seccomp-kube-proxy-profile.json" ]]; then
    cp selinux/seccomp-kube-proxy-profile.json "$SECCOMP_DIR/"
    log "✓ Copied seccomp-kube-proxy-profile.json"
else
    warn "seccomp-kube-proxy-profile.json not found"
fi

if [[ -f "selinux/seccomp-k8s-webapp-profile.json" ]]; then
    cp selinux/seccomp-k8s-webapp-profile.json "$SECCOMP_DIR/"
    log "✓ Copied seccomp-k8s-webapp-profile.json"
else
    warn "seccomp-k8s-webapp-profile.json not found"
fi

if [[ -f "selinux/seccomp-k8s-database-profile.json" ]]; then
    cp selinux/seccomp-k8s-database-profile.json "$SECCOMP_DIR/"
    log "✓ Copied seccomp-k8s-database-profile.json"
else
    warn "seccomp-k8s-database-profile.json not found"
fi

if [[ -f "selinux/seccomp-k8s-system-profile.json" ]]; then
    cp selinux/seccomp-k8s-system-profile.json "$SECCOMP_DIR/"
    log "✓ Copied seccomp-k8s-system-profile.json"
else
    warn "seccomp-k8s-system-profile.json not found"
fi

# Copy role-specific profiles
if [[ -f "selinux/seccomp-bastion-profile.json" ]]; then
    cp selinux/seccomp-bastion-profile.json "$SECCOMP_DIR/"
    log "✓ Copied seccomp-bastion-profile.json"
else
    warn "seccomp-bastion-profile.json not found"
fi

if [[ -f "selinux/seccomp-root-profile.json" ]]; then
    cp selinux/seccomp-root-profile.json "$SECCOMP_DIR/"
    log "✓ Copied seccomp-root-profile.json"
else
    warn "seccomp-root-profile.json not found"
fi

if [[ -f "selinux/seccomp-container-profile.json" ]]; then
    cp selinux/seccomp-container-profile.json "$SECCOMP_DIR/"
    log "✓ Copied seccomp-container-profile.json"
else
    warn "seccomp-container-profile.json not found"
fi

# Set proper permissions
log "Setting proper permissions..."
chown -R root:root "$SECCOMP_DIR"
chmod -R 644 "$SECCOMP_DIR"

# Create symlinks for easier access
log "Creating symlinks for easier access..."
ln -sf "$SECCOMP_DIR/seccomp-k8s-database-profile.json" "$SECCOMP_DIR/database-profile.json"
ln -sf "$SECCOMP_DIR/seccomp-k8s-webapp-profile.json" "$SECCOMP_DIR/webapp-profile.json"
ln -sf "$SECCOMP_DIR/seccomp-k8s-system-profile.json" "$SECCOMP_DIR/system-profile.json"

# Verify installation
log "Verifying installation..."
ls -la "$SECCOMP_DIR"

# Create a ConfigMap with the profiles for reference
log "Creating ConfigMap with seccomp profiles..."
kubectl create configmap seccomp-profiles \
  --from-file="$SECCOMP_DIR" \
  --namespace=kube-system \
  --dry-run=client -o yaml > /tmp/seccomp-profiles-configmap.yaml

log "ConfigMap created at /tmp/seccomp-profiles-configmap.yaml"
log "Apply it with: kubectl apply -f /tmp/seccomp-profiles-configmap.yaml"

# Create a simple test pod to verify seccomp profiles work
log "Creating test pod to verify seccomp profiles..."
cat > /tmp/seccomp-test-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-test
  namespace: default
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
  containers:
  - name: test
    image: nginx:1.21-alpine
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 1000
      runAsGroup: 1000
      capabilities:
        drop:
        - ALL
      seccompProfile:
        type: Localhost
        localhostProfile: profiles/kubernetes/seccomp-k8s-database-profile.json
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
  restartPolicy: Never
EOF

log "Test pod created at /tmp/seccomp-test-pod.yaml"
log "Test it with: kubectl apply -f /tmp/seccomp-test-pod.yaml"

log "Seccomp profiles setup complete!"
log "Profiles are available at: $SECCOMP_DIR"
log "Use them in your pods with: localhostProfile: profiles/kubernetes/<profile-name>.json"

# Show available profiles
log "Available seccomp profiles:"
ls -1 "$SECCOMP_DIR"/*.json | sed 's|.*/||' | sed 's|\.json$||' | sort
