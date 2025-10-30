# Clean Environment Structure for Terraform

## Current Issues
- `environments.old` contains conflicting Terraform configurations
- Terraform reads ALL `.tf` files in the directory tree
- Duplicate resource definitions causing validation errors
- Mixed environment configurations

## Solution: Clean Environment Structure

### 1. Remove Conflicting Files
- Rename `environments.old` to `environments-backup-YYYYMMDD`
- Keep only the current `environments/` directory
- Ensure no `.tf` files in backup directories

### 2. Environment Structure
```
environments/
├── dev/
│   ├── main.tf           # Environment-specific resources
│   ├── terraform.tfvars  # Environment variables
│   └── outputs.tf        # Environment outputs
├── test/
├── prod/
└── shared/               # Shared resources across environments
```

### 3. Root Level Files
```
infrastructure/terraform/
├── main.tf              # Core infrastructure (VPC, subnets, etc.)
├── variables.tf         # All variable definitions
├── outputs.tf           # All output definitions
├── modules/             # Reusable modules
├── environments/        # Environment-specific configs
└── templates/           # Cloud-init templates
```

## Migration Steps

1. **Backup**: Create backup of `environments.old`
2. **Extract**: Pull useful configs from old structure
3. **Clean**: Remove conflicting files
4. **Consolidate**: Merge duplicate resources
5. **Validate**: Test Terraform validation

## Files to Preserve from environments.old

### Useful Configurations:
- `dev/terraform.tfvars` - Environment variables
- `endpoints-config.yaml` - Internal domain configuration
- `generate-dns-records.sh` - DNS automation script

### Files to Remove:
- All `main.tf` files (conflict with root)
- All `outputs.tf` files (conflict with root)
- All `variables.tf` files (conflict with root)
