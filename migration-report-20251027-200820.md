# Migration Report: Terraforming Again Refactor

**Date**: $(date)
**Mode**: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "EXECUTED")

## Migration Summary

### Structure Changes

#### New Directory Layout
```
terraforming_again/
├── applications/       # Application code
├── infrastructure/     # IaC (Terraform, Ansible, Crossplane)
├── platform/          # Platform services (CAPI, operators)
├── environments/      # Environment configs
├── .github/           # CI/CD
├── hack/              # Developer scripts
├── docs/              # Documentation
└── scripts/archived/  # Old scripts
```

### File Movements

#### Applications
- crossplane/applications/go-mysql-api → applications/go-mysql-api

#### Terraform Infrastructure

- dhcp-private-fqdn.tf → infrastructure/terraform/dhcp-private-fqdn.tf

- ecr.tf → infrastructure/terraform/ecr.tf

- kubernetes-cluster.tf → infrastructure/terraform/kubernetes-cluster.tf

- kubernetes-control-plane.tf → infrastructure/terraform/kubernetes-control-plane.tf

- load-balancer-route53.tf → infrastructure/terraform/load-balancer-route53.tf

- main-ec2-only.tf → infrastructure/terraform/main-ec2-only.tf

- main.tf → infrastructure/terraform/main.tf

- outputs.tf → infrastructure/terraform/outputs.tf

- provider-aws.tf → infrastructure/terraform/providers/provider-aws.tf

- provider-azure.tf → infrastructure/terraform/providers/provider-azure.tf

- provider-gcp.tf → infrastructure/terraform/providers/provider-gcp.tf

- provider-ibm.tf → infrastructure/terraform/providers/provider-ibm.tf

- provider-local.tf → infrastructure/terraform/providers/provider-local.tf

- provider-utility.tf → infrastructure/terraform/providers/provider-utility.tf

- providers.tf → infrastructure/terraform/providers/providers.tf

- rds.tf → infrastructure/terraform/rds.tf

- variables.tf → infrastructure/terraform/variables.tf

