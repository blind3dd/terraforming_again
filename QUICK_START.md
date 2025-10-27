# Quick Start Guide - Terraforming Again

## Initial Setup (One-time)

```bash
# 1. Add Nix files to git and commit
git add flake.nix .envrc .nix/ NIX_SETUP.md .gitignore
git commit -m "feat: add Nix development environment"

# 2. Initialize flake.lock
nix flake lock --accept-flake-config

# 3. Run the setup script
./hack/setup-nix-dev.sh

# 4. Restart terminal
exec zsh  # or restart Terminal.app

# 5. Return to project directory (direnv will auto-load)
cd /path/to/terraforming_again
```

## Daily Development

### Enter Environment

```bash
cd /path/to/terraforming_again
# Direnv auto-loads the environment

# Or manually:
nix develop --accept-flake-config
```

### Common Commands

```bash
# Go development
cd crossplane/applications/go-mysql-api
go mod download
go build -v ./cmd
go run ./cmd

# Terraform/OpenTofu
terraform init
terraform plan
terraform apply

# Kubernetes
kubectl get nodes
kubectl apply -f kubernetes/

# ClusterAPI
clusterctl init --infrastructure aws:v2.6.0
kubectl apply -f capi/hybrid-cluster.yaml

# Ansible
cd crossplane/compositions/infrastructure/ansible
ansible-playbook playbooks/site.yml --check

# AWS with STS (avoid root credentials)
./hack/assume-role.sh --profile default --role-arn arn:aws:iam::ACCOUNT:role/TerraformRole --export
aws sts get-caller-identity
```

## VSCode/Cursor

1. Open this directory in VSCode/Cursor
2. Install recommended extensions (popup will appear)
3. Reload window
4. Command+click should now work in Go files

## Troubleshooting

```bash
# Go navigation not working?
./hack/fix-go-navigation.sh

# Direnv not loading?
direnv allow

# Update dependencies
nix flake update
direnv reload

# Clean up
nix-collect-garbage -d
```

## Architecture

This project uses:
- **Nix**: Reproducible development environment
- **Go**: Application backend (go-mysql-api)
- **Terraform/OpenTofu**: Infrastructure as Code
- **Ansible**: Configuration management
- **ClusterAPI**: Kubernetes cluster management
- **Talos/Bottlerocket**: Immutable Kubernetes OS
- **AWS + Azure**: Multi-cloud deployment

## Next Steps

- [ ] Fix PR conflicts: see `hack/merge-conflicts.md`
- [ ] Setup AWS STS: run `./hack/assume-role.sh`
- [ ] Deploy CAPI: run `./deploy-capi-simple.sh`
- [ ] Test Go navigation in VSCode

See `NIX_SETUP.md` for full documentation.

