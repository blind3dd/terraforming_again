# Terraform Workspaces Usage Guide

## Overview

Terraform workspaces allow you to manage multiple environments (dev, test, prod) using a single Terraform configuration. Each workspace maintains its own state file.

## How It Works

When using local backend with workspaces:
- Terraform automatically stores state files in: `.terraform.tfstate.d/<workspace>/terraform.tfstate`
- Each workspace has isolated state
- Switch between environments without changing code

## Quick Start

### 1. Initialize Terraform
```bash
cd infrastructure/terraform/environments/test
terraform init
```

### 2. Create/Select Workspaces
```bash
# List available workspaces
terraform workspace list

# Create new workspace (if needed)
terraform workspace new dev
terraform workspace new test
terraform workspace new prod

# Switch to a workspace
terraform workspace select dev
```

### 3. Use Helper Script
```bash
# Switch to dev workspace
./hack/terraform-workspace.sh infrastructure/terraform/environments/test dev

# Initialize with workspace
./hack/terraform-workspace.sh infrastructure/terraform/environments/test init-dev
```

## State File Structure

With workspaces, state files are organized as:
```
.terraform/
  terraform.tfstate.d/
    default/
      terraform.tfstate
    dev/
      terraform.tfstate
    test/
      terraform.tfstate
    prod/
      terraform.tfstate
```

## Benefits

✅ **Single Codebase**: One configuration for all environments  
✅ **Isolated State**: Each workspace has its own state  
✅ **Easy Switching**: `terraform workspace select <env>`  
✅ **Safety**: Prevents accidental cross-environment changes  
✅ **Variables**: Use `terraform.tfvars` or workspace-specific vars  

## Example Workflow

```bash
# Work on dev environment
cd infrastructure/terraform/environments/test
terraform workspace select dev
terraform plan
terraform apply

# Switch to test environment
terraform workspace select test
terraform plan
terraform apply

# Check current workspace
terraform workspace show
```

## Workspace-Specific Variables

You can use workspace-specific variable files:
- `terraform.tfvars` - shared variables
- `terraform-dev.tfvars` - dev-specific (if needed)
- `terraform-test.tfvars` - test-specific (if needed)
- `terraform-prod.tfvars` - prod-specific (if needed)

Or use environment variables or conditional logic in your Terraform code.

## Migration from Separate Directories

If you want to consolidate environments:
1. Keep your current directory structure for now
2. Use workspaces within each environment directory
3. Eventually consolidate into a single directory with workspaces

## Backend Configuration

Current backend uses local filesystem with workspace support:
```hcl
backend "local" {
  path = "terraform.tfstate"
}
```

Terraform automatically handles workspace isolation in `.terraform.tfstate.d/` directory.

## Helper Scripts

- `hack/terraform-workspace.sh` - Manage workspaces
- `hack/terraform-init-all.sh` - Initialize all directories
- `hack/setup-terraform-backend.sh` - Setup backend (S3 or local)

