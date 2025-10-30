# Nix Development Environment Setup

This project uses Nix flakes for a reproducible development environment with all tools needed for multi-cloud Kubernetes infrastructure management.

## Prerequisites

- macOS (Apple Silicon recommended)
- Nix with flakes enabled
- direnv (optional but recommended)

## Installation

### 1. Install Nix

```bash
sh <(curl -L https://nixos.org/nix/install)
```

### 2. Enable Flakes

```bash
mkdir -p ~/.config/nix
cat >> ~/.config/nix/nix.conf << 'EOF'
experimental-features = nix-command flakes
EOF
```

### 3. Run Setup Script

```bash
./hack/setup-nix-dev.sh
```

This will:
- ✅ Verify Nix installation
- ✅ Enable direnv
- ✅ Create flake.lock
- ✅ Download all development tools
- ✅ Setup VSCode/Cursor configuration
- ✅ Configure Git settings

### 4. Restart Terminal

```bash
# Reload shell configuration
source ~/.zshrc

# Or restart your terminal app
```

## Usage

### Automatic (Recommended)

With direnv installed:

```bash
cd /path/to/terraforming_again
# Environment loads automatically with all tools available
go version
terraform version
kubectl version --client
```

### Manual

```bash
# Enter development shell
nix develop --accept-flake-config

# Now all tools are available
go version
terraform version
```

## What You Get

### 🔧 Tools Available

| Category | Tools |
|----------|-------|
| **Go** | go, gopls, golangci-lint, delve |
| **Terraform** | opentofu, terraform-ls, tflint, terragrunt |
| **Kubernetes** | kubectl, helm, kustomize, k9s, kind |
| **ClusterAPI** | clusterctl, talosctl |
| **Ansible** | ansible, ansible-lint |
| **Cloud** | aws, az, gcloud |
| **Security** | trivy, checkov, semgrep, gnupg, ykman |
| **Utilities** | git, gh, jq, yq, ripgrep, fzf |

### 📝 VSCode Integration

The environment automatically configures VSCode/Cursor with:

- **Go**: Command+click navigation, gopls language server
- **Terraform**: Syntax highlighting, auto-formatting
- **Ansible**: YAML validation, playbook linting
- **Kubernetes**: Resource IntelliSense
- **Git**: Commit signing with GPG

Settings are stored in `.nix/dotfiles/ide/` and auto-copied to `.vscode/` on first run.

## Development Workflows

### Working with Go

```bash
cd crossplane/applications/go-mysql-api

# Install dependencies
go mod download

# Build
go build -v ./cmd

# Run
go run ./cmd

# Test
go test -v ./...

# Lint
golangci-lint run
```

**Command+click navigation** should work automatically in VSCode/Cursor. If not, run:
```bash
./hack/fix-go-navigation.sh
```

### Working with Terraform

```bash
# Initialize
terraform init

# Plan with specific environment
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply
terraform apply -auto-approve

# Validate all .tf files
terraform validate
tflint
```

### Working with Ansible

```bash
cd crossplane/compositions/infrastructure/ansible

# Check syntax
ansible-lint playbooks/

# Dry run
ansible-playbook playbooks/site.yml --check --diff

# Run playbook
ansible-playbook playbooks/site.yml
```

### Working with ClusterAPI

```bash
# Initialize CAPI providers
clusterctl init --infrastructure aws:v2.6.0,azure:v1.11.0

# Create a cluster
kubectl apply -f capi/hybrid-cluster.yaml

# Check cluster status
clusterctl describe cluster hybrid-cluster

# Get kubeconfig
clusterctl get kubeconfig hybrid-cluster > ~/.kube/hybrid-kubeconfig
```

### Security Scanning

```bash
# Scan for vulnerabilities
trivy fs .

# Scan Terraform
checkov -d .

# Scan code
semgrep scan --config auto
```

## Updating

### Update All Dependencies

```bash
# Update flake inputs (nixpkgs, etc.)
nix flake update

# Rebuild the environment
nix develop

# Or, if using direnv:
direnv reload
```

### Update Specific Tool

Edit `flake.nix` and change the version or package, then:

```bash
nix flake update
nix develop
```

## Troubleshooting

### Issue: "Path not tracked by Git"

```bash
# Add new files to Git before Nix can see them
git add flake.nix .envrc
git commit -m "feat: add Nix development environment"
```

### Issue: gopls not working

```bash
# Reinstall gopls
go install golang.org/x/tools/gopls@latest

# Kill existing gopls processes
pkill gopls

# Restart VSCode/Cursor
```

### Issue: direnv not loading

```bash
# Allow direnv for this project
direnv allow

# Check what's being loaded
direnv status
```

### Issue: Slow shell startup

```bash
# Optimize Nix store
nix-store --optimise

# Use cached builds
nix develop --offline  # Uses only cached packages
```

## Advanced

### Using Different Shells

```bash
# Bash
nix develop --command bash

# Zsh (default)
nix develop --command zsh

# Fish
nix develop --command fish
```

### Running Commands Without Entering Shell

```bash
# Run a single command
nix develop --command go version

# Run script
nix develop --command ./hack/deploy-capi.sh
```

### Building for CI/CD

The same environment can be used in GitHub Actions:

```yaml
- uses: cachix/install-nix-action@v25
  with:
    extra_nix_config: |
      experimental-features = nix-command flakes

- run: nix develop --command terraform init
- run: nix develop --command terraform plan
```

## Project-Specific Setup

### AWS STS Configuration

```bash
# Assume role using the helper script
./hack/assume-role.sh \
  --profile default \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/TerraformRole \
  --export

# Verify
aws sts get-caller-identity
```

### Azure Authentication

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription SUBSCRIPTION_ID

# Verify
az account show
```

### Tailscale VPN

```bash
# Install Tailscale on instances using Ansible
ansible-playbook crossplane/compositions/infrastructure/ansible/playbooks/setup-tailscale.yml

# Connect locally
tailscale up
```

## Next Steps

1. ✅ Run `./hack/setup-nix-dev.sh`
2. ✅ Restart terminal
3. ✅ Open VSCode/Cursor in this directory
4. ✅ Install recommended extensions
5. ✅ Test Go navigation with Command+click
6. ✅ Start developing!

## Questions?

Check `.nix/README.md` for more details or run `nix develop --help`.

