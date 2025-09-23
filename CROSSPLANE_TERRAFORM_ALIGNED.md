# Crossplane-First Structure (Terraform Environment Aligned)

## Overview
Crossplane as the top-level control plane with environments that match the existing Terraform structure: `dev`, `test`, `sandbox`, `shared`.

## Project Structure

```
crossplane/                          # 🎯 TOP-LEVEL: Crossplane Control Plane
├── applications/                    # All applications
│   ├── go-mysql-api/
│   │   ├── helm/                   # Helm charts
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   ├── values-dev.yaml
│   │   │   ├── values-test.yaml
│   │   │   ├── values-sandbox.yaml
│   │   │   └── templates/
│   │   ├── kustomize/              # Kustomize overlays
│   │   │   ├── base/
│   │   │   │   ├── kustomization.yaml
│   │   │   │   ├── deployment.yaml
│   │   │   │   ├── service.yaml
│   │   │   │   └── ingress.yaml
│   │   │   └── overlays/
│   │   │       ├── dev/
│   │   │       │   ├── kustomization.yaml
│   │   │       │   └── patches/
│   │   │       ├── test/
│   │   │       │   ├── kustomization.yaml
│   │   │       │   └── patches/
│   │   │       ├── sandbox/
│   │   │       │   ├── kustomization.yaml
│   │   │       │   └── patches/
│   │   │       └── shared/
│   │   │           ├── kustomization.yaml
│   │   │           └── patches/
│   │   ├── manifests/              # Generated manifests
│   │   └── tests/                  # Application tests
│   └── api-compatibility-webhook/
│       ├── helm/
│       ├── kustomize/
│       └── manifests/
├── operators/                       # All operators
│   ├── terraform-operator/
│   │   ├── helm/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   ├── values-dev.yaml
│   │   │   ├── values-test.yaml
│   │   │   ├── values-sandbox.yaml
│   │   │   └── templates/
│   │   ├── kustomize/
│   │   │   ├── base/
│   │   │   └── overlays/
│   │   │       ├── dev/
│   │   │       ├── test/
│   │   │       ├── sandbox/
│   │   │       └── shared/
│   │   └── crds/
│   ├── ansible-operator/
│   │   ├── helm/
│   │   ├── kustomize/
│   │   └── crds/
│   ├── vault-operator/
│   ├── karpenter/
│   └── telemetry-operator/
├── infrastructure/                  # Infrastructure as Code
│   ├── terraform/                  # Consolidated Terraform
│   │   ├── environments/           # Matches existing Terraform structure
│   │   │   ├── dev/               # From terraform-environments/dev/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   ├── outputs.tf
│   │   │   │   └── terraform.tfvars
│   │   │   ├── test/              # From terraform-environments/test/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   ├── outputs.tf
│   │   │   │   └── terraform.tfvars
│   │   │   ├── sandbox/           # From terraform-environments/sandbox/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   ├── outputs.tf
│   │   │   │   └── terraform.tfvars
│   │   │   ├── shared/            # From terraform-environments/shared/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   ├── outputs.tf
│   │   │   │   └── terraform.tfvars
│   │   │   ├── endpoints-config.yaml
│   │   │   ├── generate-dns-records.sh
│   │   │   └── terraform-env.sh
│   │   ├── modules/               # From root modules/
│   │   │   ├── aws/
│   │   │   ├── azure/
│   │   │   ├── gcp/
│   │   │   └── shared/
│   │   └── shared/                # Shared Terraform configs
│   ├── ansible/                   # Consolidated Ansible
│   │   ├── playbooks/             # From ansible/playbooks/
│   │   ├── roles/                 # From ansible/roles/
│   │   └── inventory/             # From ansible/inventory/
│   └── argocd/                    # GitOps configuration
│       ├── applications/
│       ├── projects/
│       └── app-of-apps/
├── ci-cd/                          # CI/CD configurations
│   ├── github-actions/            # From .github/workflows/
│   ├── prow/                      # From .prow/
│   │   └── webhooks/              # From ci-cd/prow/webhooks/
│   └── scripts/                   # From scripts/
└── docs/                           # Documentation
    ├── architecture/
    ├── deployment/
    └── operations/
```

## Environment Alignment

### Terraform Environments → Crossplane Environments
- `terraform-environments/dev/` → `crossplane/infrastructure/terraform/environments/dev/`
- `terraform-environments/test/` → `crossplane/infrastructure/terraform/environments/test/`
- `terraform-environments/sandbox/` → `crossplane/infrastructure/terraform/environments/sandbox/`
- `terraform-environments/shared/` → `crossplane/infrastructure/terraform/environments/shared/`

### Helm Values Alignment
Each application and operator has environment-specific values:
- `values-dev.yaml` → Development environment
- `values-test.yaml` → Test environment  
- `values-sandbox.yaml` → Sandbox environment
- `values.yaml` → Base/default values

### Kustomize Overlays Alignment
Each application and operator has environment-specific overlays:
- `overlays/dev/` → Development environment patches
- `overlays/test/` → Test environment patches
- `overlays/sandbox/` → Sandbox environment patches
- `overlays/shared/` → Shared environment patches

## Crossplane Compositions by Environment

### Development Environment
```yaml
# crossplane/compositions/environments/dev/infrastructure.yaml
apiVersion: terraforming-again.io/v1alpha1
kind: XInfrastructure
metadata:
  name: dev-infrastructure
spec:
  parameters:
    environment: dev
    clusterName: dev-cluster
    nodeCount: 3
    instanceType: t3.medium
  compositionRef:
    name: aws-eks-cluster
```

### Test Environment
```yaml
# crossplane/compositions/environments/test/infrastructure.yaml
apiVersion: terraforming-again.io/v1alpha1
kind: XInfrastructure
metadata:
  name: test-infrastructure
spec:
  parameters:
    environment: test
    clusterName: test-cluster
    nodeCount: 5
    instanceType: t3.large
  compositionRef:
    name: aws-eks-cluster
```

### Sandbox Environment
```yaml
# crossplane/compositions/environments/sandbox/infrastructure.yaml
apiVersion: terraforming-again.io/v1alpha1
kind: XInfrastructure
metadata:
  name: sandbox-infrastructure
spec:
  parameters:
    environment: sandbox
    clusterName: sandbox-cluster
    nodeCount: 2
    instanceType: t3.small
  compositionRef:
    name: aws-eks-cluster
```

### Shared Environment
```yaml
# crossplane/compositions/environments/shared/infrastructure.yaml
apiVersion: terraforming-again.io/v1alpha1
kind: XInfrastructure
metadata:
  name: shared-infrastructure
spec:
  parameters:
    environment: shared
    clusterName: shared-cluster
    nodeCount: 1
    instanceType: t3.medium
  compositionRef:
    name: aws-eks-cluster
```

## Migration Strategy

### Phase 1: Move Terraform Environments
1. Move `terraform-environments/*` → `crossplane/infrastructure/terraform/environments/`
2. Move `modules/*` → `crossplane/infrastructure/terraform/modules/`
3. Update all Terraform references

### Phase 2: Move Applications
1. Move `go-mysql-api/` → `crossplane/applications/go-mysql-api/`
2. Move `applications/webhooks/` → `crossplane/applications/api-compatibility-webhook/`
3. Ensure proper helm/kustomize structure for each environment

### Phase 3: Move Operators
1. Move `operators/*` → `crossplane/operators/`
2. Ensure proper helm/kustomize structure for each environment
3. Move `ansible/helm-kustomize/*` to appropriate operator directories

### Phase 4: Move CI/CD
1. Move `.github/workflows/` → `crossplane/ci-cd/github-actions/`
2. Move `.prow/` → `crossplane/ci-cd/prow/`
3. Move `scripts/` → `crossplane/ci-cd/scripts/`

### Phase 5: Move Infrastructure
1. Move `ansible/*` → `crossplane/infrastructure/ansible/`
2. Consolidate all ArgoCD configurations → `crossplane/infrastructure/argocd/`

### Phase 6: Clean Up
1. Remove duplicate directories at root level
2. Update all references and paths
3. Update CI/CD workflows to use new paths

## Benefits

1. **Environment Consistency**: Same environment names across Terraform and Crossplane
2. **Single Control Plane**: Crossplane manages everything
3. **Terraform Compatibility**: Existing Terraform structure preserved
4. **Helm + Kustomize**: Environment-specific configurations
5. **GitOps Ready**: ArgoCD can manage the entire structure
6. **Clear Separation**: Applications, operators, and infrastructure clearly separated

## Next Steps

1. **Execute Migration**: Move files systematically
2. **Update References**: Update all paths in configurations
3. **Test Environments**: Validate all environments work
4. **Update CI/CD**: Update workflows for new structure
5. **Documentation**: Update all documentation
