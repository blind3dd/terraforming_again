# Hybrid Cloud Setup Guide
## AWS + Azure + CAPI Integration

This guide covers setting up a true hybrid cloud architecture with AWS, Azure, and Cluster API (CAPI) for Kubernetes management.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Actions│    │     Ansible     │    │     ArgoCD      │
│   (CI/CD)       │    │  (Hardening)    │    │   (GitOps)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  AWS + Azure    │    │   Multi-Cloud   │    │   CAPI Clusters │
│  (Terraform)    │    │  (Linux/Windows)│    │  (Hybrid K8s)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### 1. Prerequisites

```bash
# Install required tools
make dev-setup

# Install Azure CLI
brew install azure-cli

# Install CAPI tools
brew install clusterctl
```

### 2. Azure Setup

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "Your Subscription ID"

# Create service principal
az ad sp create-for-rbac --name "hybrid-cloud-sp" --role contributor

# Deploy Azure infrastructure
make azure-connector-setup
cd azure-connector
terraform init
terraform plan
terraform apply
```

### 3. CAPI Setup

```bash
# Initialize CAPI
make capi-setup

# Install AWS provider
make capi-aws-provider

# Install Azure provider
make capi-azure-provider

# Create hybrid cluster
make capi-hybrid-cluster
```

## 🔧 Configuration

### Azure Connector Configuration

The Azure connector provides:
- **Azure Kubernetes Service (AKS)** - Managed Kubernetes
- **Azure Container Registry (ACR)** - Container registry
- **Azure Key Vault** - Secrets management
- **Azure Monitor** - Observability
- **Azure AD Integration** - Identity management

### CAPI Configuration

CAPI enables:
- **Multi-cloud cluster management** - Deploy across AWS and Azure
- **Consistent API** - Same interface for all clouds
- **GitOps integration** - Declarative cluster management
- **Automated scaling** - Cluster autoscaling

## 🔐 Security Features

### Encrypted Environment Variables
```bash
# Encrypt sensitive data
make encrypt-env KEY="AZURE_CLIENT_ID" VALUE="your-client-id"
make encrypt-env KEY="AZURE_CLIENT_SECRET" VALUE="your-client-secret"
```

### Cross-Cloud Networking
```bash
# Configure hybrid networking
make azure-hybrid-networking
```

### Identity Integration
- **Azure AD** - Centralized identity management
- **AWS IAM** - Cross-cloud access
- **FIDO2 Keys** - Hardware-based authentication

## 📊 Monitoring & Observability

### Request ID Logging
```go
// UUID + Date format: 20241201-a1b2c3d4
logInfo(ctx, "Processing request: %s", requestID)
```

### Cross-Cloud Monitoring
- **Azure Monitor** - Azure resources
- **AWS CloudWatch** - AWS resources
- **Prometheus** - Kubernetes metrics
- **Grafana** - Unified dashboards

## 🛠️ Development Workflow

### 1. Build and Test
```bash
# Build all services
make build

# Run tests
make test

# Security scan
make security-scan
```

### 2. Deploy
```bash
# Deploy to hybrid cloud
make deploy-prod
```

### 3. Monitor
```bash
# Check cluster status
make capi-status

# View logs
kubectl logs -f deployment/api-compatibility-webhook
```

## 🔄 GitOps Workflow

### 1. Code Changes
```bash
# Make changes to code
git add .
git commit -m "Add hybrid cloud support"
git push
```

### 2. Automated Deployment
- **GitHub Actions** - Builds and tests
- **ArgoCD** - Deploys to clusters
- **CAPI** - Manages cluster lifecycle

### 3. Monitoring
- **Request tracing** - UUID-based logging
- **Cross-cloud metrics** - Unified observability
- **Security scanning** - Continuous security validation

## 🚨 Security Considerations

### Confidential Containers
```bash
# Set up confidential containers
make confidential-containers
```

### Network Security
- **VPN/ExpressRoute** - Secure cross-cloud connectivity
- **Network policies** - Kubernetes network segmentation
- **Firewall rules** - Cloud-native security groups

### Identity Security
- **Multi-factor authentication** - FIDO2 keys
- **Role-based access control** - Least privilege
- **Audit logging** - Comprehensive audit trails

## 📈 Scaling

### Horizontal Scaling
```bash
# Scale CAPI clusters
kubectl scale machinedeployment hybrid-cluster-md-0 --replicas=5
```

### Vertical Scaling
```bash
# Update machine templates
kubectl edit awsmachinetemplate hybrid-cluster-md-0
```

## 🔍 Troubleshooting

### Common Issues

1. **Cross-cloud networking**
   ```bash
   # Check network connectivity
   kubectl exec -it pod-name -- ping azure-vm-ip
   ```

2. **Authentication issues**
   ```bash
   # Check Azure AD integration
   az aks get-credentials --resource-group hybrid-rg --name hybrid-aks
   ```

3. **CAPI cluster issues**
   ```bash
   # Check cluster status
   kubectl get clusters
   kubectl describe cluster hybrid-cluster
   ```

## 📚 Additional Resources

- [Azure Connector Documentation](azure-connector/README.md)
- [CAPI Documentation](capi/README.md)
- [Security Best Practices](SECURITY.md)
- [Monitoring Setup](MONITORING.md)

## 🎯 Next Steps

1. **Wireguard VPN** - Secure remote access
2. **Nix Package Manager** - Reproducible environments
3. **Confidential Containers** - Hardware-based security
4. **Multi-region deployment** - Global availability

---

**Happy Hybrid Cloud Computing!** 🚀☁️
