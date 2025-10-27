# Nix Development Environment

This directory contains the Nix-based development environment setup for the Terraforming Again project.

## Quick Start

```bash
# 1. Install Nix (if not already installed)
sh <(curl -L https://nixos.org/nix/install)

# 2. Run the setup script
./hack/setup-nix-dev.sh

# 3. Restart your terminal or run:
source ~/.zshrc

# 4. Enter the project directory (direnv will auto-load)
cd /path/to/terraforming_again

# 5. Or manually enter the dev environment:
nix develop --accept-flake-config
```

## What's Included

### Languages & Runtimes
- **Go 1.23**: Main language for go-mysql-api
- **Python 3.11**: For Ansible and automation scripts
- **Node.js 20**: For any frontend/webhook services

### Infrastructure Tools
- **OpenTofu**: Open-source Terraform alternative
- **Terraform Language Server**: For IDE support
- **Ansible**: Infrastructure automation
- **Ansible Lint**: Playbook validation

### Kubernetes & ClusterAPI
- **kubectl**: Kubernetes CLI
- **helm**: Package manager for Kubernetes
- **kustomize**: Template-free Kubernetes configuration
- **k9s**: Terminal UI for Kubernetes
- **kind**: Local Kubernetes clusters
- **clusterctl**: ClusterAPI management CLI
- **talosctl**: Talos OS management CLI

### Cloud Provider CLIs
- **AWS CLI v2**: Amazon Web Services
- **Azure CLI**: Microsoft Azure
- **gcloud**: Google Cloud Platform

### Security Tools
- **Trivy**: Vulnerability scanner
- **Checkov**: Infrastructure as Code security
- **Semgrep**: SAST code analysis
- **GnuPG**: GPG signing and encryption
- **YubiKey Manager**: Hardware security key management
- **Kerberos**: Authentication

### Development Tools
- **git** + **gh**: Version control and GitHub CLI
- **jq** + **yq**: JSON/YAML processing
- **ripgrep**, **fd**, **fzf**: Fast search tools
- **direnv**: Automatic environment loading
- **pre-commit**: Git hooks framework

## VSCode/Cursor Integration

The Nix environment automatically configures:

### Settings (`dotfiles/ide/settings.json`)
- Go language server (gopls) configuration
- Command+click navigation for Go code
- Terraform/OpenTofu formatting
- Ansible syntax highlighting
- YAML schema validation for GitHub Actions
- Git commit signing

### Extensions (`dotfiles/ide/extensions.json`)
Recommended extensions include:
- `golang.go` - Go language support
- `hashicorp.terraform` - Terraform/HCL support
- `redhat.ansible` - Ansible support
- `jnoortheen.nix-ide` - Nix language support
- `ms-kubernetes-tools.vscode-kubernetes-tools` - Kubernetes
- And many more...

## Directory Structure

```
.nix/
├── README.md                 # This file
├── dotfiles/
│   └── ide/
│       ├── settings.json     # VSCode settings template
│       └── extensions.json   # VSCode extensions
└── bin/                      # Symlinks to Nix tools (auto-generated)
    ├── go
    ├── gopls
    ├── terraform -> tofu
    ├── kubectl
    └── ...
```

## Usage

### Entering the Development Environment

**Option 1: Automatic (with direnv)**
```bash
cd /path/to/terraforming_again
# Environment loads automatically
```

**Option 2: Manual**
```bash
nix develop --accept-flake-config
```

### Common Tasks

```bash
# Update Nix dependencies
nix flake update

# Check what's available
nix flake show

# Run a command in the dev shell without entering it
nix develop --command go version
nix develop --command terraform version

# Garbage collect old packages
nix-collect-garbage -d
```

### Go Development

With the Nix environment active:
- Command+click works in VSCode/Cursor for Go imports
- `gopls` is properly configured
- All Go tools are in PATH

```bash
# Navigate to the Go application
cd crossplane/applications/go-mysql-api

# Download dependencies
go mod download

# Build
go build -v ./...

# Run tests
go test ./...

# Run the app
go run ./cmd
```

### Terraform/OpenTofu

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply infrastructure
terraform apply

# Validate configuration
terraform validate
tflint
```

### Ansible

```bash
# Navigate to Ansible directory
cd crossplane/compositions/infrastructure/ansible

# List hosts
ansible all --list-hosts

# Run playbook
ansible-playbook playbooks/site.yml --check --diff

# Lint playbooks
ansible-lint playbooks/
```

### Kubernetes & ClusterAPI

```bash
# Check kubectl context
kubectl config get-contexts

# Initialize ClusterAPI
clusterctl init --infrastructure aws:v2.6.0

# Create a cluster
kubectl apply -f capi/hybrid-cluster.yaml

# Get cluster kubeconfig
clusterctl get kubeconfig hybrid-cluster > ~/.kube/hybrid-kubeconfig
```

## Troubleshooting

### Go Navigation Not Working

If Command+click doesn't work in Go files:

```bash
# 1. Run the fix script
./hack/fix-go-navigation.sh

# 2. Restart gopls
pkill gopls

# 3. Restart VSCode/Cursor
```

### Direnv Not Loading

```bash
# Allow direnv for this project
direnv allow

# Check status
direnv status

# Reload manually
direnv reload
```

### Nix Store Issues

```bash
# Clean up old generations
nix-collect-garbage -d

# Optimize Nix store
nix-store --optimise

# Verify store integrity
nix-store --verify --check-contents
```

### Tool Not Found

If a tool isn't available after entering the dev shell:

```bash
# Check if it's in the flake
cat flake.nix | grep <tool-name>

# Verify it's in the shell
nix develop --command which <tool-name>

# If missing, add to flake.nix and rebuild
nix flake update
nix develop
```

## Updating the Environment

### Add a New Tool

Edit `flake.nix`:
```nix
devTools = with pkgs; [
  git
  jq
  my-new-tool  # Add here
];
```

Then rebuild:
```bash
nix flake update
nix develop
```

### Update Tool Versions

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Enter new shell
nix develop
```

## Security

All tools are pinned to specific versions via `flake.lock`. This ensures:
- Reproducible builds across machines
- Security auditing of dependencies
- Controlled updates

To audit security:
```bash
# Check for vulnerabilities
nix flake check

# View flake metadata
nix flake metadata
```

## Performance

### Cache Configuration

The flake uses:
- `cache.nixos.org` - Official Nix binary cache
- `nix-community.cachix.org` - Community binary cache

This speeds up package installation by downloading pre-built binaries instead of compiling from source.

### Garbage Collection

```bash
# Remove old generations (keep last 3)
nix-env --delete-generations +3

# Garbage collect
nix-collect-garbage -d

# Optimize store
nix-store --optimise
```

## Support

If you encounter issues:
1. Check the Nix logs: `journalctl -xe` (Linux) or `Console.app` (macOS)
2. Verify Nix version: `nix --version` (should be 2.18+)
3. Check flake: `nix flake check`
4. Ask in #nix on your team chat

## Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [direnv Documentation](https://direnv.net/)
- [Development with Nix](https://nixos.org/guides/dev-environment.html)

