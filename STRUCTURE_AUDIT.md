# Project Structure Audit & Reorganization Plan

## Current Issues Identified

### 1. Duplicate Directories
- `applications/` (root) vs `crossplane/applications/`
- `operators/` (root) vs `crossplane/operators/`
- `infrastructure/` (root) vs `crossplane/infrastructure/`
- `ci-cd/` (root) vs `crossplane/ci-cd/`
- `docs/` (root) vs `crossplane/docs/`

### 2. Scattered Helm/Kustomize Configurations
- `ansible/helm-kustomize/` - Should be moved to proper locations
- `kustomize/` (root) - Should be under crossplane structure
- Individual operator directories have their own helm/kustomize

### 3. Multiple ArgoCD Locations
- `argocd/` (root)
- `ci-cd/argocd/`
- `infrastructure/argocd/`

### 4. Inconsistent Naming
- `go-mysql-api/` vs `applications/go-mysql-api/`
- `webhooks/` vs `applications/webhooks/`
- `terraform-environments/` vs `environments/`

## Target Structure (Crossplane-First)

```
crossplane/
├── applications/                    # All applications
│   ├── go-mysql-api/
│   │   ├── helm/                   # Helm charts
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
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
│   │   │       └── prod/
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
│   │   │   └── templates/
│   │   ├── kustomize/
│   │   │   ├── base/
│   │   │   └── overlays/
│   │   │       ├── dev/
│   │   │       ├── test/
│   │   │       └── prod/
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
│   │   ├── environments/
│   │   │   ├── dev/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   └── terraform.tfvars
│   │   │   ├── test/
│   │   │   ├── prod/
│   │   │   └── sandbox/
│   │   ├── modules/
│   │   │   ├── aws/
│   │   │   ├── azure/
│   │   │   ├── gcp/
│   │   │   └── shared/
│   │   └── shared/
│   ├── ansible/                    # Consolidated Ansible
│   │   ├── playbooks/
│   │   ├── roles/
│   │   └── inventory/
│   └── argocd/                     # GitOps configuration
│       ├── applications/
│       ├── projects/
│       └── app-of-apps/
├── ci-cd/                          # CI/CD configurations
│   ├── github-actions/
│   ├── prow/                       # ProwRobot configs
│   │   └── webhooks/
│   └── scripts/
└── docs/                           # Documentation
    ├── architecture/
    ├── deployment/
    └── operations/
```

## Reorganization Steps

### Step 1: Consolidate Applications
1. Move `go-mysql-api/` → `crossplane/applications/go-mysql-api/`
2. Move `applications/webhooks/` → `crossplane/applications/api-compatibility-webhook/`
3. Ensure each application has proper helm/kustomize structure

### Step 2: Consolidate Operators
1. Move all operator directories from root `operators/` → `crossplane/operators/`
2. Ensure each operator has proper helm/kustomize structure
3. Move `ansible/helm-kustomize/` content to appropriate operator directories

### Step 3: Consolidate Infrastructure
1. Move `terraform-environments/` → `crossplane/infrastructure/terraform/environments/`
2. Move `modules/` → `crossplane/infrastructure/terraform/modules/`
3. Consolidate all ArgoCD configurations → `crossplane/infrastructure/argocd/`

### Step 4: Consolidate CI/CD
1. Move `.github/workflows/` → `crossplane/ci-cd/github-actions/`
2. Move `.prow/` → `crossplane/ci-cd/prow/`
3. Move `scripts/` → `crossplane/ci-cd/scripts/`

### Step 5: Consolidate Documentation
1. Move `docs/` → `crossplane/docs/`
2. Ensure all documentation is properly organized

### Step 6: Clean Up
1. Remove duplicate directories at root level
2. Update all references and paths
3. Update CI/CD workflows to use new paths

## Helm & Kustomize Structure Standards

### Helm Structure
```
helm/
├── Chart.yaml
├── values.yaml
├── values-dev.yaml
├── values-test.yaml
├── values-prod.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── configmap.yaml
    └── _helpers.tpl
```

### Kustomize Structure
```
kustomize/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
└── overlays/
    ├── dev/
    │   ├── kustomization.yaml
    │   └── patches/
    │       ├── deployment-patch.yaml
    │       └── service-patch.yaml
    ├── test/
    │   ├── kustomization.yaml
    │   └── patches/
    └── prod/
        ├── kustomization.yaml
        └── patches/
```

## Benefits of This Structure

1. **Single Source of Truth**: Everything under `crossplane/`
2. **Consistent Patterns**: All applications and operators follow same structure
3. **Environment Separation**: Clear dev/test/prod separation
4. **Helm + Kustomize**: Helm generates base, Kustomize patches for environments
5. **GitOps Ready**: ArgoCD can easily manage the entire structure
6. **Crossplane Native**: All resources managed through Crossplane compositions

## Next Steps

1. **Backup Current State**: Create backup before reorganization
2. **Execute Reorganization**: Move files systematically
3. **Update References**: Update all paths in configurations
4. **Test Structure**: Validate all components work
5. **Update Documentation**: Update all documentation
6. **Commit Changes**: Commit the new structure
