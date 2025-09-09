# Environment Structure

This directory contains environment-specific configurations using symlinks to avoid duplication.

## Structure

```
environments/
├── shared/          # Common/shared infrastructure configuration
│   ├── environment.tf → ../../common/main.tf
│   ├── variables.tf → ../../common/variables.tf
│   ├── output.tf → ../../common/output.tf
│   ├── terraform.tfvars → ../../common/terraform.tfvars
│   └── provider.tf → ../../provider.tf
├── test/            # Test environment specific configuration
│   ├── environment.tf → ../../test/env.tf
│   ├── variables.tf → ../../test/variables.tf
│   ├── output.tf → ../../test/output.tf
│   ├── terraform.tfvars → ../../test/terraform.tfvars
│   └── provider.tf → ../../provider.tf
└── sandbox/         # Sandbox environment specific configuration
    ├── environment.tf → ../../sanbox/env.tf
    ├── variables.tf → ../../sanbox/variables.tf
    ├── output.tf → ../../sanbox/output.tf
    ├── terraform.tfvars → ../../sanbox/terraform.tfvars
    └── provider.tf → ../../provider.tf
```

## Usage

### Switch Environments (from root directory)
```bash
# Switch to shared/common configuration
./switch-environment.sh shared

# Switch to test environment
./switch-environment.sh test

# Switch to sandbox environment
./switch-environment.sh sandbox
```

### Work in Specific Environment
```bash
# Work in test environment
cd environments/test
terraform init
terraform plan
terraform apply
```

## Environment Types

- **shared**: Common infrastructure configuration (default)
- **test**: Test environment with test-specific variables
- **sandbox**: Sandbox environment with sandbox-specific variables

## Benefits

- ✅ **No Duplication**: All files are symlinked, single source of truth
- ✅ **Easy Switching**: Use the script to switch between environments
- ✅ **Proper Module References**: All modules point to `modules/` directory
- ✅ **Clean Structure**: Organized in `environments/` folder
- ✅ **Scalable**: Easy to add production environment later
