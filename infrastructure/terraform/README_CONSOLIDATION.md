# Terraform Consolidation Plan

## Current Issues
1. **Duplicate Resources**: Multiple files define the same resources (VPC, subnets, load balancers, etc.)
2. **Inconsistent Structure**: Mix of root-level files and environment-specific configs
3. **Missing Modules**: No proper module structure for reusability
4. **Hardcoded Secrets**: Docker-compose.yml has hardcoded passwords

## Consolidation Strategy

### 1. Clean Root Structure
- `main.tf` - Main configuration (providers, locals, core resources)
- `variables.tf` - All variable definitions
- `outputs.tf` - All output definitions
- `modules/` - Reusable modules
- `environments/` - Environment-specific configurations

### 2. Module Structure
```
modules/
├── networking/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── compute/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── database/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── security/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── monitoring/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

### 3. Environment Structure
```
environments/
├── dev/
│   ├── main.tf
│   ├── terraform.tfvars
│   └── outputs.tf
├── test/
├── prod/
└── shared/
```

### 4. Crossplane Integration
- Use Terraform Provider for Crossplane
- Separate Crossplane resources from Terraform infrastructure
- Crossplane manages Kubernetes resources
- Terraform manages cloud infrastructure

## Files to Remove/Consolidate
- `main-ec2-only.tf` → Merge into modules
- `kubernetes-cluster.tf` → Move to Crossplane
- `kubernetes-control-plane.tf` → Move to Crossplane
- `load-balancer-route53.tf` → Move to networking module
- `dhcp-private-fqdn.tf` → Move to networking module
- `ecr.tf` → Move to compute module
- `rds.tf` → Move to database module

## Next Steps
1. Create module structure
2. Consolidate duplicate resources
3. Move environment-specific configs
4. Integrate with Crossplane
5. Fix hardcoded secrets with SSM
