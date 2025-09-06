# Kubernetes IAM Authentication Setup

This guide explains how to set up secure Kubernetes authentication tied to AWS IAM using OIDC integration and aws-iam-authenticator.

## Overview

This solution provides:
- **OIDC Integration** - Secure identity provider for Kubernetes
- **IAM Role-based Access** - Different permission levels (admin, developer, readonly)
- **Service Account Integration** - For application-level AWS access
- **RBAC Integration** - Kubernetes role-based access control
- **Multi-factor Authentication** - Combined with VPN access

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   AWS IAM       │    │   OIDC Provider  │    │   Kubernetes    │
│   Users/Roles   │───▶│   (aws-iam-auth) │───▶│   Cluster       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   IAM Policies  │    │   Token Exchange │    │   RBAC Rules    │
│   & Permissions │    │   & Validation   │    │   & Access      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Prerequisites

- AWS CLI configured with appropriate permissions
- Kubernetes cluster running
- kubectl installed and configured
- Terraform (for infrastructure setup)

## Installation

### 1. Deploy Infrastructure

```bash
# Deploy the Kubernetes IAM authentication module
terraform init
terraform plan -target=module.kubernetes_iam_auth
terraform apply -target=module.kubernetes_iam_auth
```

### 2. Install aws-iam-authenticator

```bash
# Run the installation script on your Kubernetes control plane
./scripts/install-aws-iam-authenticator.sh
```

### 3. Configure Kubernetes

```bash
# Apply the aws-auth ConfigMap
kubectl apply -f /etc/kubernetes/manifests/aws-auth-configmap.yaml

# Apply RBAC rules
kubectl apply -f /etc/kubernetes/manifests/aws-iam-rbac.yaml
```

## Configuration

### IAM Roles

The setup creates four IAM roles:

1. **Cluster Admin** (`{cluster-name}-cluster-admin`)
   - Full cluster access
   - Can manage all resources
   - Maps to `system:masters` group

2. **Developer** (`{cluster-name}-developer`)
   - Application deployment access
   - Can manage pods, services, deployments
   - Limited to specific namespaces

3. **Read-Only** (`{cluster-name}-readonly`)
   - View-only access
   - Can list and describe resources
   - No modification permissions

4. **Service Account** (`{cluster-name}-service-account`)
   - For application-level AWS access
   - Can access S3, Secrets Manager, SSM
   - Used by pods for AWS API calls

### OIDC Provider

The OIDC provider is configured with:
- **URL**: `https://kubernetes.{cluster-domain}`
- **Client IDs**: `sts.amazonaws.com`, service account
- **Thumbprint**: Kubernetes OIDC certificate thumbprint

### RBAC Configuration

```yaml
# Cluster Admin - Full access
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: aws-iam-cluster-admin
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]

# Developer - Application management
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: aws-iam-developer
rules:
- apiGroups: ["", "apps", "extensions"]
  resources: ["pods", "services", "deployments", "replicasets", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

# Read-Only - View access only
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: aws-iam-readonly
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
```

## Usage

### For Cluster Administrators

```bash
# Assume the cluster admin role
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-cluster-admin \
  --role-session-name k8s-admin

# Set environment variables
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."

# Use kubectl with IAM authentication
kubectl get nodes
kubectl get pods --all-namespaces
kubectl create namespace production
```

### For Developers

```bash
# Assume the developer role
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-developer \
  --role-session-name k8s-dev

# Set environment variables
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."

# Deploy applications
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl create configmap app-config --from-literal=key=value
```

### For Read-Only Users

```bash
# Assume the read-only role
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-readonly \
  --role-session-name k8s-readonly

# Set environment variables
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."

# View resources (read-only)
kubectl get pods
kubectl describe pod POD_NAME
kubectl logs POD_NAME
```

### For Service Accounts

```yaml
# Create a service account with IAM role
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-service-account
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
    spec:
      serviceAccountName: app-service-account
      containers:
      - name: app
        image: your-app:latest
        env:
        - name: AWS_REGION
          value: us-north-1
```

## Security Features

### 1. Multi-Factor Authentication
- **VPN Access Required** - Must connect via WireGuard VPN
- **IAM Authentication** - Must have valid AWS credentials
- **Role-based Access** - Different permission levels

### 2. Token Management
- **Short-lived Tokens** - IAM session tokens expire
- **Automatic Refresh** - aws-iam-authenticator handles token refresh
- **Secure Storage** - Tokens stored in memory only

### 3. Network Security
- **Private Cluster** - Kubernetes API not accessible from internet
- **VPN-only Access** - All access through secure VPN tunnel
- **IMDSv2 Enforcement** - Instance metadata requires tokens

### 4. Audit Logging
- **All API Calls Logged** - Kubernetes audit logs
- **IAM Access Logged** - CloudTrail logs IAM usage
- **VPN Access Logged** - WireGuard connection logs

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   ```bash
   # Check IAM permissions
   aws sts get-caller-identity
   
   # Verify role assumption
   aws sts assume-role --role-arn ROLE_ARN --role-session-name test
   ```

2. **Service Not Running**
   ```bash
   # Check service status
   systemctl status aws-iam-authenticator
   
   # View logs
   journalctl -u aws-iam-authenticator -f
   
   # Restart service
   systemctl restart aws-iam-authenticator
   ```

3. **RBAC Denied**
   ```bash
   # Check user permissions
   kubectl auth can-i get pods --as=aws-iam-developer
   
   # Check role bindings
   kubectl get clusterrolebindings
   kubectl describe clusterrolebinding aws-iam-developer-binding
   ```

4. **OIDC Issues**
   ```bash
   # Validate OIDC provider
   aws iam get-open-id-connect-provider --open-id-connect-provider-arn OIDC_ARN
   
   # Check thumbprint
   openssl s_client -servername kubernetes.CLUSTER_DOMAIN -connect kubernetes.CLUSTER_DOMAIN:443
   ```

### Validation Commands

```bash
# Validate aws-iam-authenticator
/usr/local/bin/validate-aws-iam-auth.sh

# Test token generation
aws-iam-authenticator token -i CLUSTER_NAME --region REGION

# Test kubectl access
kubectl get nodes
kubectl get pods --all-namespaces

# Check RBAC
kubectl auth can-i get pods
kubectl auth can-i create deployments
```

## Best Practices

### 1. Principle of Least Privilege
- Grant minimum required permissions
- Use specific IAM policies
- Regular permission audits

### 2. Token Management
- Use short-lived tokens
- Rotate credentials regularly
- Monitor token usage

### 3. Monitoring
- Enable CloudTrail logging
- Monitor Kubernetes audit logs
- Set up alerts for failed authentications

### 4. Backup and Recovery
- Backup aws-auth ConfigMap
- Document IAM role configurations
- Test disaster recovery procedures

## Integration with Existing Security

This IAM authentication integrates with:
- **WireGuard VPN** - Network-level security
- **SELinux Policies** - Host-level security
- **Audit Logging** - Comprehensive monitoring
- **IMDSv2** - Instance metadata security

## Next Steps

1. **Deploy Infrastructure** - Use Terraform to create IAM roles and OIDC provider
2. **Install Components** - Run the installation script
3. **Configure Users** - Set up IAM users and role mappings
4. **Test Access** - Validate authentication for different user types
5. **Monitor Usage** - Set up logging and monitoring

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review logs: `journalctl -u aws-iam-authenticator -f`
3. Validate configuration: `/usr/local/bin/validate-aws-iam-auth.sh`
4. Test IAM permissions: `aws sts get-caller-identity`
