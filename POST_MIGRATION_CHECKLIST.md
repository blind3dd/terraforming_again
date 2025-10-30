# Post-Migration Checklist

**Status**: ✅ Migration Complete  
**Date**: October 27, 2025  
**Branch**: working_branch (9 commits ahead of origin)

## ✅ Completed

- [x] Repository restructured (460 files moved)
- [x] Applications consolidated → `applications/`
- [x] Infrastructure organized → `infrastructure/`
- [x] Platform services → `platform/`
- [x] Documentation organized → `docs/`
- [x] Nix development environment added
- [x] YubiKey GPG signing configured
- [x] Migration summary documented

## 🔄 Pending Actions

### Immediate (Before Push)

```bash
# 1. Wait for Nix environment to finish building
# (Currently building in background)

# 2. Test the environment once ready
nix develop --accept-flake-config

# Inside Nix shell:
cd applications/go-mysql-api
go version  # Should show Go version
go mod download
go build -v ./cmd  # Test Go build

cd ../../infrastructure/terraform
terraform version  # Should show OpenTofu
```

### After Nix Build Completes

```bash
# 3. Push all commits to remote
git push origin working_branch

# 4. Create/update PR
gh pr create --title "refactor: clean structure migration + Nix environment" \
  --body "See docs/migration/MIGRATION_SUMMARY.md for details.

## Changes
- 460 files reorganized into clean structure
- Nix flake with all dev tools (Go, Terraform, K8s, Ansible)
- YubiKey GPG signing support
- VSCode integration with command+click navigation
- Comprehensive documentation

## Structure
\`\`\`
applications/      # App code
infrastructure/    # All IaC
platform/          # CAPI, operators
environments/      # Env configs
docs/              # Organized docs
\`\`\`"
```

### Next Development Tasks

#### 1. Set Up AWS STS (Non-Root Credentials)

```bash
# Use the consolidated script
./hack/assume-role.sh \
  --profile default \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/TerraformRole \
  --export

# Verify
aws sts get-caller-identity
```

#### 2. Configure Tailscale VPN

Create `hack/setup-tailscale.sh`:
```bash
#!/bin/bash
# Install Tailscale on Azure VM
ssh azure-vm 'curl -fsSL https://tailscale.com/install.sh | sh'
ssh azure-vm 'sudo tailscale up --advertise-routes=10.0.0.0/8'

# Install on AWS jump host
ssh aws-jumphost 'curl -fsSL https://tailscale.com/install.sh | sh'
ssh aws-jumphost 'sudo tailscale up --advertise-routes=172.16.0.0/16'

# Now access via Tailscale IPs instead of VPN
```

#### 3. Deploy ClusterAPI

```bash
# On your management cluster (Azure AKS or local kind)
./platform/cluster-api/deploy-capi-simple.sh init

# Create a workload cluster
kubectl apply -f platform/cluster-api/workload/hybrid-cluster.yaml

# Get kubeconfig
clusterctl get kubeconfig hybrid-cluster > ~/.kube/hybrid-kubeconfig
```

#### 4. Update Terraform Backend

In `infrastructure/terraform/main.tf`:
```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "terraforming-again/terraform.tfstate"
    region = "us-west-2"
  }
}
```

Then:
```bash
cd infrastructure/terraform
terraform init -migrate-state
```

#### 5. Create Environment-Specific Configs

Populate `environments/{dev,test,prod}/`:

```bash
# Dev environment
cat > environments/dev/terraform.tfvars << 'EOF'
environment = "dev"
instance_type = "t3.micro"
enable_monitoring = false
EOF

# Copy Kustomize overlays
cp -r applications/go-mysql-api/operator-kustomize/overlays/dev/* \
      environments/dev/

# Helm values
cat > environments/dev/values.yaml << 'EOF'
replicaCount: 1
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
EOF
```

## 🧪 Verification Tests

### Test Terraform

```bash
cd infrastructure/terraform

# Init
terraform init

# Validate
terraform validate

# Plan for dev
terraform plan -var-file=../../environments/dev/terraform.tfvars

# If errors, check provider paths:
grep -r "provider-" . | grep -v ".terraform"
```

### Test Ansible

```bash
cd infrastructure/ansible

# Syntax check
ansible-playbook --syntax-check playbooks/site.yml

# List tasks
ansible-playbook playbooks/site.yml --list-tasks

# Dry run
ansible-playbook playbooks/site.yml --check --diff
```

### Test Go Application

```bash
cd applications/go-mysql-api

# Download deps
go mod download

# Build
go build -v ./cmd

# Test
go test ./...

# Run locally with docker-compose
docker-compose up -d
curl http://localhost:8080/health
```

### Test Kubernetes Manifests

```bash
cd infrastructure/kubernetes/manifests

# Validate YAML
kubectl apply --dry-run=client -f .

# Check for issues
kubectl apply --dry-run=server -f .
```

## 📋 Known Issues to Fix

### 1. Double Nesting Fixed
- ✅ `applications/go-mysql-api/go-mysql-api/` → `applications/go-mysql-api/`
- ✅ `infrastructure/ansible/ansible/` → `infrastructure/ansible/`

### 2. Provider Paths in Terraform
Some Terraform files may reference old paths like `../provider-aws.tf`. Update to:
```hcl
# Old (broken):
# source = "../provider-aws.tf"

# New (correct):
# Providers are now in infrastructure/terraform/providers/
# No need for explicit references, they're in the same workspace
```

### 3. Workflow Script Paths
GitHub workflows updated, but verify:
```bash
# Check for old paths
grep -r "crossplane/ci-cd" .github/workflows/
grep -r "crossplane/applications" .github/workflows/

# Should now use:
# - applications/go-mysql-api/
# - hack/ (for scripts)
```

## 🔒 Security Checklist

- [x] YubiKey GPG signing configured
- [ ] AWS STS role assumption (not root)
- [ ] Secrets moved to environment vars
- [ ] TLS enabled on go-mysql-api
- [ ] Hardcoded passwords removed from docker-compose

## 📚 Documentation Updates Needed

- [ ] Update main README.md with new structure
- [ ] Update CONTRIBUTING.md paths
- [ ] Add ARCHITECTURE.md diagram
- [ ] Document environment setup in docs/guides/

## 🎯 Final Steps

1. **Push commits**:
   ```bash
   git push origin working_branch
   ```

2. **Merge PR #9** (or create new one with all changes)

3. **Archive device scripts** to separate repo:
   ```bash
   cd /Users/usualsuspectx/Development/go/src/github.com/blind3dd/sec_scripts
   git add -A
   git commit -m "feat: archive device management scripts from terraforming_again"
   git remote add origin git@github.com:blind3dd/sec_scripts.git
   git push -u origin main
   ```

4. **Test in clean clone**:
   ```bash
   git clone <repo> test-clean
   cd test-clean
   nix develop --accept-flake-config
   cd infrastructure/terraform && terraform init
   ```

---

**Questions or Issues?**
- See `docs/migration/MIGRATION_SUMMARY.md`
- Run `./hack/setup-yubikey-gpg.sh` if GPG isn't working
- Check `.nix/README.md` for Nix environment details

