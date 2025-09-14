# Project Restructure Plan - Operator-First GitOps Architecture

## Architecture Principles
- **Everything is an Operator**: No manual terraform plans, everything managed by operators
- **Helm + Kustomize**: Helm charts with Kustomize patches for in-flight updates
- **Built-in Testing**: All applications have tests included in Helm charts
- **Dependency Management**: Helmfiles and helm.lock for controlled dependency changes
- **Infrastructure**: CAPI (Cluster API) for infrastructure provisioning
- **Deployment**: ArgoCD for continuous deployment

## Unified Structure

```
terraforming_again/
├── operators/                       # All operators (infrastructure + applications)
│   ├── go-mysql-api-operator/      # Application operator
│   │   ├── helm/                   # Helm chart with tests
│   │   │   ├── Chart.yaml          # With dependencies
│   │   │   ├── values.yaml
│   │   │   ├── templates/
│   │   │   │   ├── tests/          # Built-in application tests
│   │   │   │   └── ...
│   │   │   └── requirements.yaml   # Dependencies
│   │   ├── kustomize/              # Kustomize overlays for in-flight updates
│   │   │   ├── base/
│   │   │   └── overlays/
│   │   │       ├── dev/
│   │   │       ├── test/
│   │   │       └── sandbox/
│   │   ├── manifests/              # Generated manifests
│   │   ├── crds/                   # Custom Resource Definitions
│   │   ├── helmfile.yaml           # Helmfile for dependency management
│   │   └── helm.lock               # Locked dependencies
│   ├── webhook-operator/           # Unified webhook operator (app + infra webhooks)
│   │   ├── helm/
│   │   ├── kustomize/
│   │   ├── manifests/
│   │   ├── crds/
│   │   ├── helmfile.yaml
│   │   └── helm.lock
│   ├── terraform-operator/         # Terraform infrastructure operator
│   │   ├── helm/
│   │   ├── kustomize/
│   │   ├── crds/
│   │   ├── helmfile.yaml
│   │   └── helm.lock
│   ├── ansible-operator/           # Ansible automation operator
│   ├── vault-operator/             # Vault secrets operator
│   ├── karpenter/                  # Node provisioning operator
│   └── capi/                       # Cluster API operator
│       ├── helm/                   # CAPI operator Helm chart
│       ├── kustomize/
│       ├── crds/
│       ├── helmfile.yaml
│       ├── helm.lock
│       └── clusters/               # CAPI cluster definitions
│           ├── dev/
│           ├── test/
│           └── sandbox/
├── infrastructure/                  # Infrastructure definitions (modules/templates)
│   ├── bootstrap/                  # Bootstrap infrastructure (one-time manual apply)
│   │   ├── management-cluster/     # Management cluster terraform
│   │   └── bootstrap-scripts/      # Bootstrap automation scripts
│   └── terraform/                  # Terraform modules (reusable components)
│       ├── modules/                # Reusable Terraform modules
│       │   ├── vpc/
│       │   ├── rds/
│       │   ├── eks/
│       │   └── s3/
│       └── shared/                 # Shared configurations
├── ci-cd/                          # CI/CD configurations
│   ├── github-actions/
│   ├── prow/                       # ProwRobot configs
│   ├── argocd/                     # GitOps configuration
│   │   ├── applications/           # ArgoCD applications
│   │   ├── projects/               # ArgoCD projects
│   │   └── app-of-apps/            # Application of applications
│   └── scripts/
└── docs/                           # Documentation
    ├── architecture/
    ├── deployment/
    └── operations/
```

## Key Components

### 0. Operator-Infrastructure Relationship
- **Operators ARE the infrastructure management layer**
- **CAPI Operator**: Creates and manages Kubernetes clusters
- **Terraform Operator**: Creates and manages cloud resources using Terraform modules
- **Webhook-Based Infrastructure**: Operators use webhooks to trigger infrastructure changes
  - **Mutating Webhooks**: Modify resource requests before creation
  - **Validating Webhooks**: Validate resource requests
  - **Authorization Webhooks**: Control access to infrastructure resources
  - **Terraform Apply Webhooks**: Trigger terraform apply on infrastructure changes
- **Application Operators**: Deploy and manage applications on the infrastructure
- **Infrastructure/terraform/modules/**: Contains reusable Terraform modules that operators use
- **No manual terraform plan/apply**: Everything is managed by operators via webhooks

### 1. Operator Structure
Each operator follows the same pattern:
- **Helm Chart**: With built-in tests and dependencies
- **Kustomize Overlays**: For environment-specific patches
- **CRDs**: Custom resources for operator management
- **Helmfile**: Dependency management and version control
- **Helm.lock**: Locked dependency versions

### 2. Testing Strategy
- **Helm Tests**: Built into every chart (`templates/tests/`)
- **Integration Tests**: Operator-level testing
- **E2E Tests**: Full workflow testing

### 3. Dependency Management
- **Helmfile**: Manages chart dependencies and versions
- **Helm.lock**: Ensures reproducible builds
- **Requirements.yaml**: Declares dependencies

### 4. Infrastructure Provisioning
- **Bootstrap Strategy**: 
  - **Initial Infrastructure**: Manual terraform apply for bootstrap cluster (management cluster)
  - **Management Cluster**: Runs all operators and webhooks
  - **Workload Clusters**: Created by CAPI operator running on management cluster
- **CAPI Operator**: Cluster API operator manages infrastructure
- **Terraform Operator**: Manages infrastructure resources
- **Infrastructure Change Recording**:
  - **Custom Resources**: TerraformOperator creates CRDs for infrastructure resources
  - **State Management**: Terraform state stored in Kubernetes secrets/configmaps
  - **Change Tracking**: All infrastructure changes recorded as Kubernetes events
  - **Audit Trail**: Complete history of infrastructure changes in etcd
  - **Reconciliation**: Operator continuously reconciles desired vs actual state
- **Webhook-Based Infrastructure**: 
  - **Mutating Webhooks**: Automatically modify resource requests (e.g., add security groups, tags)
  - **Validating Webhooks**: Ensure resource requests meet policies
  - **Authorization Webhooks**: Control who can create/modify infrastructure
  - **Terraform Apply Webhooks**: Trigger terraform apply when infrastructure changes are needed
- **No Manual Plans**: Everything through operators and webhooks (after bootstrap)

### 5. Deployment Pipeline
- **ArgoCD**: Continuous deployment
- **GitOps**: Declarative configuration
- **In-flight Updates**: Kustomize patches for live updates

## Bootstrap Strategy (Solving the Chicken-and-Egg Problem)

### 1. Initial Bootstrap
- **Manual Terraform Apply**: Create the initial management cluster
  - VPC, subnets, security groups
  - EKS cluster (management cluster)
  - Basic IAM roles and policies
- **One-time manual operation**: This is the only manual terraform apply

### 2. Management Cluster Setup
- **Deploy Operators**: Install CAPI, Terraform, and other operators on management cluster
- **Deploy Webhooks**: Install mutating/validating/authorization webhooks
- **Deploy ArgoCD**: Install ArgoCD for GitOps

### 3. Workload Cluster Creation
- **CAPI Operator**: Creates workload clusters (dev, test, sandbox)
- **Terraform Operator**: Manages additional infrastructure resources
- **Webhook-Driven**: All subsequent infrastructure changes via webhooks

### 4. Self-Managing Infrastructure
- **Management Cluster**: Manages itself and all workload clusters
- **No More Manual Operations**: Everything automated after bootstrap

## Terraform Operator Change Recording

### 1. Custom Resource Definitions (CRDs)
```yaml
# Example: VPC resource
apiVersion: terraform.operator.io/v1alpha1
kind: VPC
metadata:
  name: dev-vpc
  namespace: infrastructure
spec:
  cidr: "10.0.0.0/16"
  enableDnsHostnames: true
  enableDnsSupport: true
status:
  state: "Ready"
  vpcId: "vpc-12345678"
  lastApplied: "2024-01-15T10:30:00Z"
```

### 2. State Management
- **Terraform State**: Stored in Kubernetes secrets
- **State Locking**: Using etcd for state locking
- **State Backup**: Regular backups to S3/GCS
- **State Encryption**: Encrypted at rest

### 3. Change Tracking
- **Kubernetes Events**: All infrastructure changes recorded as events
- **Audit Logs**: Complete audit trail in etcd
- **Change History**: Track all modifications with timestamps
- **Rollback Capability**: Ability to rollback to previous states

### 4. Reconciliation Loop
- **Continuous Monitoring**: Operator watches for changes
- **Desired vs Actual**: Compares desired state with actual infrastructure
- **Automatic Drift Detection**: Detects and corrects configuration drift
- **Self-Healing**: Automatically fixes infrastructure issues

## Cloud-Native Stack (Crossplane-First)

### 1. Crossplane for Everything
- **Infrastructure**: Crossplane providers (AWS, Azure, GCP)
- **Applications**: Crossplane compositions for app deployment
- **Webhooks**: Crossplane webhooks for validation/mutation
- **Ansible**: Crossplane Ansible provider
- **Terraform**: Crossplane Terraform provider

### 2. Unified Development Stack
- **Crossplane**: Single tool for all operators and infrastructure
- **Helm**: For packaging and deployment
- **Kustomize**: For environment-specific patches
- **ArgoCD**: For GitOps deployment

### 3. Removed Redundancies
- ❌ **Terraform Operator**: Replaced with Crossplane Terraform provider
- ❌ **Ansible Operator**: Replaced with Crossplane Ansible provider
- ❌ **Kubebuilder**: Replaced with Crossplane compositions
- ❌ **Manual Terraform**: Everything through Crossplane
- ❌ **Duplicate Environments**: Single Crossplane composition per environment

## Migration Strategy

### Phase 1: Create Operator Structure
1. Create unified operator directories
2. Move existing applications to operator format
3. Add Helm tests to all charts

### Phase 2: Implement Dependency Management
1. Add helmfile.yaml to all operators
2. Create requirements.yaml files
3. Generate helm.lock files

### Phase 3: Infrastructure Migration
1. Move to CAPI-based infrastructure
2. Consolidate Terraform into operators
3. Set up ArgoCD applications

### Phase 4: CI/CD Integration
1. Update ProwRobot for operator testing
2. Add GitHub CLI support
3. Implement GitOps workflows

## Benefits
- **Operator-First**: Everything managed by operators
- **Built-in Testing**: Tests included in every chart
- **Dependency Control**: Managed through helmfile/helm.lock
- **GitOps Ready**: ArgoCD integration
- **In-flight Updates**: Kustomize patches
- **Infrastructure as Code**: CAPI + Terraform operators
- **No Manual Operations**: Everything automated