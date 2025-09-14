#!/bin/bash
# Install and configure aws-iam-authenticator for Kubernetes
# This script sets up secure IAM-based authentication for Kubernetes

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Configuration
AWS_IAM_AUTHENTICATOR_VERSION="0.6.2"
KUBERNETES_VERSION="1.28"
CLUSTER_NAME="${CLUSTER_NAME:-go-mysql-api-cluster}"
CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-local}"
AWS_REGION="${AWS_REGION:-eu-north-1}"
OIDC_PROVIDER_ARN="${OIDC_PROVIDER_ARN:-}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root"
fi

log "Installing aws-iam-authenticator for Kubernetes IAM authentication..."

# Install required packages
log "Installing required packages..."
yum update -y
yum install -y curl wget unzip jq

# Download and install aws-iam-authenticator
log "Downloading aws-iam-authenticator v${AWS_IAM_AUTHENTICATOR_VERSION}..."
cd /tmp
wget "https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AWS_IAM_AUTHENTICATOR_VERSION}/aws-iam-authenticator_${AWS_IAM_AUTHENTICATOR_VERSION}_linux_amd64"
chmod +x "aws-iam-authenticator_${AWS_IAM_AUTHENTICATOR_VERSION}_linux_amd64"
mv "aws-iam-authenticator_${AWS_IAM_AUTHENTICATOR_VERSION}_linux_amd64" /usr/local/bin/aws-iam-authenticator

# Verify installation
if aws-iam-authenticator version >/dev/null 2>&1; then
    log "aws-iam-authenticator installed successfully"
    aws-iam-authenticator version
else
    error "Failed to install aws-iam-authenticator"
fi

# Create aws-iam-authenticator configuration directory
log "Creating configuration directory..."
mkdir -p /etc/aws-iam-authenticator
chmod 755 /etc/aws-iam-authenticator

# Create aws-iam-authenticator configuration
log "Creating aws-iam-authenticator configuration..."
cat > /etc/aws-iam-authenticator/config.yaml << EOF
# aws-iam-authenticator configuration
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://kubernetes.${CLUSTER_DOMAIN}
    certificate-authority-data: ""
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    user: aws-iam-authenticator
  name: ${CLUSTER_NAME}
current-context: ${CLUSTER_NAME}
users:
- name: aws-iam-authenticator
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${CLUSTER_NAME}"
        - "--region"
        - "${AWS_REGION}"
EOF

# Set proper permissions
chmod 600 /etc/aws-iam-authenticator/config.yaml
chown root:root /etc/aws-iam-authenticator/config.yaml

# Create systemd service for aws-iam-authenticator
log "Creating systemd service..."
cat > /etc/systemd/system/aws-iam-authenticator.service << EOF
[Unit]
Description=AWS IAM Authenticator for Kubernetes
Documentation=https://github.com/kubernetes-sigs/aws-iam-authenticator
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/aws-iam-authenticator server \\
    --config=/etc/aws-iam-authenticator/config.yaml \\
    --state-dir=/var/lib/aws-iam-authenticator \\
    --backend-mode=file \\
    --server-port=21362 \\
    --server-address=127.0.0.1
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=aws-iam-authenticator

[Install]
WantedBy=multi-user.target
EOF

# Create state directory
log "Creating state directory..."
mkdir -p /var/lib/aws-iam-authenticator
chmod 755 /var/lib/aws-iam-authenticator
chown root:root /var/lib/aws-iam-authenticator

# Reload systemd and enable service
log "Enabling aws-iam-authenticator service..."
systemctl daemon-reload
systemctl enable aws-iam-authenticator

# Create kubeconfig for aws-iam-authenticator
log "Creating kubeconfig for aws-iam-authenticator..."
mkdir -p /root/.kube
cat > /root/.kube/config << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://kubernetes.${CLUSTER_DOMAIN}
    certificate-authority-data: ""
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    user: aws-iam-authenticator
  name: ${CLUSTER_NAME}
current-context: ${CLUSTER_NAME}
users:
- name: aws-iam-authenticator
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${CLUSTER_NAME}"
        - "--region"
        - "${AWS_REGION}"
EOF

chmod 600 /root/.kube/config
chown root:root /root/.kube/config

# Create aws-auth ConfigMap template
log "Creating aws-auth ConfigMap template..."
mkdir -p /etc/kubernetes/manifests
cat > /etc/kubernetes/manifests/aws-auth-configmap.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::ACCOUNT_ID:role/${CLUSTER_NAME}-cluster-admin
      username: aws-iam-cluster-admin
      groups:
        - system:masters
    - rolearn: arn:aws:iam::ACCOUNT_ID:role/${CLUSTER_NAME}-developer
      username: aws-iam-developer
      groups:
        - aws-iam-developer
    - rolearn: arn:aws:iam::ACCOUNT_ID:role/${CLUSTER_NAME}-readonly
      username: aws-iam-readonly
      groups:
        - aws-iam-readonly
    - rolearn: arn:aws:iam::ACCOUNT_ID:role/${CLUSTER_NAME}-service-account
      username: aws-iam-service-account
      groups:
        - aws-iam-service-account
  mapUsers: |
    # Add IAM users here
    # - userarn: arn:aws:iam::ACCOUNT_ID:user/USERNAME
    #   username: USERNAME
    #   groups:
    #     - aws-iam-developer
EOF

# Create RBAC manifests
log "Creating RBAC manifests..."
cat > /etc/kubernetes/manifests/aws-iam-rbac.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: aws-iam-cluster-admin
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
- nonResourceURLs: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: aws-iam-developer
rules:
- apiGroups: ["", "apps", "extensions"]
  resources: ["pods", "services", "deployments", "replicasets", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses", "networkpolicies"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: aws-iam-readonly
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: aws-iam-cluster-admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: aws-iam-cluster-admin
subjects:
- kind: User
  name: aws-iam-cluster-admin
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: aws-iam-developer-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: aws-iam-developer
subjects:
- kind: User
  name: aws-iam-developer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: aws-iam-readonly-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: aws-iam-readonly
subjects:
- kind: User
  name: aws-iam-readonly
  apiGroup: rbac.authorization.k8s.io
EOF

# Create validation script
log "Creating validation script..."
cat > /usr/local/bin/validate-aws-iam-auth.sh << 'EOF'
#!/bin/bash
# Validate aws-iam-authenticator configuration

set -euo pipefail

log() {
    echo -e "\033[0;32m[$(date +'%Y-%m-%d %H:%M:%S')] $1\033[0m"
}

error() {
    echo -e "\033[0;31m[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1\033[0m"
    exit 1
}

log "Validating aws-iam-authenticator configuration..."

# Check if aws-iam-authenticator is installed
if ! command -v aws-iam-authenticator >/dev/null 2>&1; then
    error "aws-iam-authenticator is not installed"
fi

# Check if configuration file exists
if [[ ! -f /etc/aws-iam-authenticator/config.yaml ]]; then
    error "Configuration file not found"
fi

# Check if kubeconfig exists
if [[ ! -f /root/.kube/config ]]; then
    error "kubeconfig not found"
fi

# Check if service is running
if ! systemctl is-active --quiet aws-iam-authenticator; then
    error "aws-iam-authenticator service is not running"
fi

log "aws-iam-authenticator validation successful"
EOF

chmod +x /usr/local/bin/validate-aws-iam-auth.sh

# Create usage documentation
log "Creating usage documentation..."
cat > /usr/local/share/doc/aws-iam-authenticator-usage.md << EOF
# AWS IAM Authenticator for Kubernetes

## Overview
This setup provides secure IAM-based authentication for Kubernetes using aws-iam-authenticator.

## Configuration Files
- Configuration: /etc/aws-iam-authenticator/config.yaml
- Kubeconfig: /root/.kube/config
- Service: /etc/systemd/system/aws-iam-authenticator.service
- Manifests: /etc/kubernetes/manifests/

## Usage

### For Cluster Administrators
\`\`\`bash
# Assume the cluster admin role
aws sts assume-role --role-arn arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-cluster-admin --role-session-name k8s-admin

# Use kubectl with IAM authentication
kubectl get nodes
kubectl get pods --all-namespaces
\`\`\`

### For Developers
\`\`\`bash
# Assume the developer role
aws sts assume-role --role-arn arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-developer --role-session-name k8s-dev

# Use kubectl with IAM authentication
kubectl get pods
kubectl create deployment nginx --image=nginx
\`\`\`

### For Read-Only Users
\`\`\`bash
# Assume the read-only role
aws sts assume-role --role-arn arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-readonly --role-session-name k8s-readonly

# Use kubectl with IAM authentication (read-only)
kubectl get pods
kubectl describe pod POD_NAME
\`\`\`

## Service Management
\`\`\`bash
# Start service
systemctl start aws-iam-authenticator

# Stop service
systemctl stop aws-iam-authenticator

# Restart service
systemctl restart aws-iam-authenticator

# Check status
systemctl status aws-iam-authenticator

# View logs
journalctl -u aws-iam-authenticator -f
\`\`\`

## Validation
\`\`\`bash
# Validate configuration
/usr/local/bin/validate-aws-iam-auth.sh

# Test authentication
aws-iam-authenticator token -i CLUSTER_NAME --region REGION
\`\`\`

## Troubleshooting
1. Check service status: \`systemctl status aws-iam-authenticator\`
2. Check logs: \`journalctl -u aws-iam-authenticator -f\`
3. Validate configuration: \`/usr/local/bin/validate-aws-iam-auth.sh\`
4. Test IAM permissions: \`aws sts get-caller-identity\`
EOF

log "aws-iam-authenticator installation completed successfully!"
log "Configuration files created in /etc/aws-iam-authenticator/"
log "Service created: aws-iam-authenticator.service"
log "Validation script: /usr/local/bin/validate-aws-iam-auth.sh"
log "Documentation: /usr/local/share/doc/aws-iam-authenticator-usage.md"

# Start the service
log "Starting aws-iam-authenticator service..."
systemctl start aws-iam-authenticator

# Wait a moment for service to start
sleep 5

# Validate installation
log "Validating installation..."
/usr/local/bin/validate-aws-iam-auth.sh

log "aws-iam-authenticator is ready for use!"
log "Remember to:"
log "1. Update the aws-auth ConfigMap with your IAM roles"
log "2. Apply the RBAC manifests to your cluster"
log "3. Configure your IAM users/roles for authentication"
