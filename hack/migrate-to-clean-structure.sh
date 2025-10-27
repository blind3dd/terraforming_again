#!/bin/bash
# Migration Script: Refactor to Clean Structure
# Moves files from current messy structure to organized, clean structure
# 
# Usage:
#   ./hack/migrate-to-clean-structure.sh --dry-run    # Preview changes
#   ./hack/migrate-to-clean-structure.sh              # Execute migration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
DRY_RUN=false
BACKUP_DIR="backups/pre-migration-$(date +%Y%m%d-%H%M%S)"
SEC_SCRIPTS_REPO="/Users/usualsuspectx/Development/go/src/github.com/blind3dd/sec_scripts"
MIGRATION_LOG="migration-report-$(date +%Y%m%d-%H%M%S).md"

# Parse arguments
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            echo -e "${YELLOW}🔍 DRY RUN MODE - No changes will be made${NC}"
            ;;
    esac
done

# Helper functions
log() {
    echo -e "${GREEN}✅${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠️${NC}  $1"
}

error() {
    echo -e "${RED}❌${NC} $1"
}

info() {
    echo -e "${CYAN}ℹ️${NC}  $1"
}

step() {
    echo -e "${BLUE}▶${NC}  $1"
}

# Execute or preview command
execute() {
    local cmd="$1"
    local description="$2"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${MAGENTA}[DRY-RUN]${NC} $description"
        echo "  Command: $cmd"
    else
        echo -e "${GREEN}[EXECUTING]${NC} $description"
        eval "$cmd"
    fi
}

# Create directory if it doesn't exist
create_dir() {
    local dir="$1"
    if [ "$DRY_RUN" = true ]; then
        echo -e "${MAGENTA}[DRY-RUN]${NC} Create directory: $dir"
    else
        mkdir -p "$dir"
    fi
}

# Move file or directory
move_item() {
    local src="$1"
    local dest="$2"
    local description="${3:-Moving $src to $dest}"
    
    if [ ! -e "$src" ]; then
        warn "Source not found: $src (skipping)"
        return 0
    fi
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${MAGENTA}[DRY-RUN]${NC} $description"
        echo "  From: $src"
        echo "  To:   $dest"
    else
        create_dir "$(dirname "$dest")"
        git mv "$src" "$dest" 2>/dev/null || mv "$src" "$dest"
        log "$description"
    fi
}

# Start migration report
start_report() {
    cat > "$MIGRATION_LOG" << 'EOF'
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

EOF
}

# Append to report
append_report() {
    echo "$1" >> "$MIGRATION_LOG"
}

# Create new directory structure
create_new_structure() {
    step "Creating new directory structure..."
    
    # Applications
    create_dir "applications/go-mysql-api"
    create_dir "applications/webhooks"
    
    # Infrastructure
    create_dir "infrastructure/terraform/modules"
    create_dir "infrastructure/terraform/providers"
    create_dir "infrastructure/terraform/environments/dev"
    create_dir "infrastructure/terraform/environments/test"
    create_dir "infrastructure/terraform/environments/prod"
    create_dir "infrastructure/terraform/environments/shared"
    create_dir "infrastructure/ansible/playbooks"
    create_dir "infrastructure/ansible/roles"
    create_dir "infrastructure/ansible/inventory"
    create_dir "infrastructure/crossplane/compositions/aws"
    create_dir "infrastructure/crossplane/compositions/azure"
    create_dir "infrastructure/crossplane/compositions/gcp"
    create_dir "infrastructure/crossplane/providers"
    create_dir "infrastructure/helm/values"
    
    # Platform
    create_dir "platform/cluster-api/management"
    create_dir "platform/cluster-api/workload/aws"
    create_dir "platform/cluster-api/workload/azure"
    create_dir "platform/cluster-api/bootstrap"
    create_dir "platform/operators/ansible-operator"
    create_dir "platform/operators/terraform-operator"
    create_dir "platform/operators/vault-operator"
    create_dir "platform/operators/karpenter"
    create_dir "platform/argocd/applications"
    create_dir "platform/argocd/projects"
    
    # Environments
    create_dir "environments/dev"
    create_dir "environments/test"
    create_dir "environments/prod"
    create_dir "environments/shared"
    
    # Documentation
    create_dir "docs/architecture"
    create_dir "docs/guides"
    create_dir "docs/security"
    create_dir "docs/development"
    
    # Scripts
    create_dir "scripts/archived/device-management"
    create_dir "scripts/deploy"
    create_dir "scripts/security"
    
    log "Directory structure created"
}

# Move applications
migrate_applications() {
    step "Migrating applications..."
    
    # Move go-mysql-api from crossplane/applications/
    if [ -d "crossplane/applications/go-mysql-api" ]; then
        move_item "crossplane/applications/go-mysql-api" \
                  "applications/go-mysql-api" \
                  "Moving Go MySQL API application"
    fi
    
    append_report "#### Applications
- crossplane/applications/go-mysql-api → applications/go-mysql-api
"
}

# Move and consolidate infrastructure
migrate_infrastructure() {
    step "Migrating infrastructure..."
    
    # === TERRAFORM ===
    append_report "#### Terraform Infrastructure
"
    
    # Move root .tf files to infrastructure/terraform/
    for tf_file in *.tf; do
        if [ -f "$tf_file" ] && [ "$tf_file" != "cloudinit.tf" ]; then
            # Determine if it's a provider or main infrastructure
            if [[ "$tf_file" == provider-* ]] || [[ "$tf_file" == providers.tf ]]; then
                move_item "$tf_file" "infrastructure/terraform/providers/$tf_file" \
                          "Moving provider config: $tf_file"
                append_report "- $tf_file → infrastructure/terraform/providers/$tf_file
"
            else
                # Main infrastructure files
                move_item "$tf_file" "infrastructure/terraform/$tf_file" \
                          "Moving Terraform config: $tf_file"
                append_report "- $tf_file → infrastructure/terraform/$tf_file
"
            fi
        fi
    done
    
    # Move terraform.tfvars and variables
    [ -f "terraform.tfvars" ] && move_item "terraform.tfvars" \
        "infrastructure/terraform/environments/dev/terraform.tfvars" \
        "Moving tfvars to dev environment"
    
    [ -f "variables.tf" ] && move_item "variables.tf" \
        "infrastructure/terraform/variables.tf" \
        "Moving variables definition"
    
    [ -f "outputs.tf" ] && move_item "outputs.tf" \
        "infrastructure/terraform/outputs.tf" \
        "Moving outputs definition"
    
    # Move existing terraform environments if they exist
    if [ -d "crossplane/infrastructure/terraform/environments" ]; then
        move_item "crossplane/infrastructure/terraform/environments" \
                  "infrastructure/terraform/environments-old" \
                  "Moving existing Terraform environments"
    fi
    
    # === ANSIBLE ===
    append_report "
#### Ansible Configuration
"
    
    # Move Ansible from crossplane/compositions/infrastructure/ansible/
    if [ -d "crossplane/compositions/infrastructure/ansible" ]; then
        # Move the entire ansible directory
        move_item "crossplane/compositions/infrastructure/ansible" \
                  "infrastructure/ansible" \
                  "Moving Ansible infrastructure"
        append_report "- crossplane/compositions/infrastructure/ansible → infrastructure/ansible
"
    fi
    
    # Also check for root-level ansible symlink
    if [ -L "ansible" ] || [ -d "ansible" ]; then
        if [ "$DRY_RUN" = false ]; then
            rm -rf ansible
            log "Removed root ansible symlink/directory"
        else
            info "Would remove: ansible (symlink/directory)"
        fi
    fi
    
    # === CROSSPLANE ===
    append_report "
#### Crossplane Compositions
"
    
    # Move Crossplane compositions
    if [ -d "crossplane/compositions/go-mysql-api-operator" ]; then
        # This is actually application-specific, should go to applications
        move_item "crossplane/compositions/go-mysql-api-operator/helm" \
                  "applications/go-mysql-api/operator-helm" \
                  "Moving operator Helm chart to application"
        
        move_item "crossplane/compositions/go-mysql-api-operator/kustomize" \
                  "applications/go-mysql-api/operator-kustomize" \
                  "Moving operator Kustomize to application"
    fi
    
    # Move security policies
    if [ -d "crossplane/security" ]; then
        move_item "crossplane/security" \
                  "infrastructure/crossplane/security" \
                  "Moving security policies"
    fi
    
    # Move selinux configs
    if [ -d "crossplane/selinux" ]; then
        move_item "crossplane/selinux" \
                  "infrastructure/ansible/files/selinux" \
                  "Moving SELinux policies to Ansible"
    fi
    
    # === HELM ===
    if [ -d "helmfile" ]; then
        move_item "helmfile" \
                  "infrastructure/helm" \
                  "Moving Helmfile configs"
    fi
}

# Move platform services (CAPI, operators)
migrate_platform() {
    step "Migrating platform services..."
    
    append_report "
#### Platform Services (CAPI & Operators)
"
    
    # Move CAPI configs
    if [ -d "capi" ]; then
        move_item "capi/hybrid-cluster.yaml" \
                  "platform/cluster-api/workload/hybrid-cluster.yaml" \
                  "Moving CAPI hybrid cluster config"
    fi
    
    # Move CAPI deployment scripts
    [ -f "deploy-capi.sh" ] && move_item "deploy-capi.sh" \
        "platform/cluster-api/deploy-capi.sh" \
        "Moving CAPI deployment script"
    
    [ -f "deploy-capi-simple.sh" ] && move_item "deploy-capi-simple.sh" \
        "platform/cluster-api/deploy-capi-simple.sh" \
        "Moving CAPI simple deployment script"
    
    # Move Kubernetes control plane deployment
    [ -f "deploy-kubernetes-control-plane.sh" ] && move_item "deploy-kubernetes-control-plane.sh" \
        "platform/cluster-api/deploy-control-plane.sh" \
        "Moving K8s control plane deployment"
    
    # Move cloud_init_and_k8s configs
    if [ -d "cloud_init_and_k8s" ]; then
        move_item "cloud_init_and_k8s" \
                  "platform/cluster-api/bootstrap" \
                  "Moving cloud-init and K8s bootstrap configs"
    fi
    
    append_report "- capi/ → platform/cluster-api/
- deploy-capi*.sh → platform/cluster-api/
- cloud_init_and_k8s/ → platform/cluster-api/bootstrap/
"
}

# Move environment configurations
migrate_environments() {
    step "Migrating environment configurations..."
    
    append_report "
#### Environment Configurations
"
    
    # Create environment-specific files
    # These will be created from existing configs
    
    info "Environment configs will be extracted from existing files"
    append_report "- Environment configs will be created in environments/{dev,test,prod}/
"
}

# Move documentation
migrate_documentation() {
    step "Migrating documentation..."
    
    append_report "
#### Documentation
"
    
    # Architecture docs
    local arch_docs=(
        "HYBRID_ARCHITECTURE.md"
        "HYBRID_CLOUD_SETUP.md"
        "CROSSPLANE_STRUCTURE.md"
        "CROSSPLANE_TERRAFORM_ALIGNED.md"
        "FINAL_CROSSPLANE_STRUCTURE.md"
    )
    
    for doc in "${arch_docs[@]}"; do
        [ -f "$doc" ] && move_item "$doc" "docs/architecture/$doc" \
            "Moving architecture doc: $doc"
    done
    
    # Security docs
    local sec_docs=(
        "AUDIT_LOGGING_CONFIGURATION.md"
        "COMPLETE_SECURITY_INVESTIGATION_SUMMARY.md"
        "KUBERNETES_SECCOMP_PROFILES.md"
        "ISTIO_RDS_SECURITY_GUIDE.md"
        "POLKIT_SECURITY_CONFIGURATION.md"
        "SECCOMP_PROFILES.md"
    )
    
    for doc in "${sec_docs[@]}"; do
        [ -f "$doc" ] && move_item "$doc" "docs/security/$doc" \
            "Moving security doc: $doc"
    done
    
    # Setup/guide docs
    local guide_docs=(
        "IAMV2_AUTH_SETUP.md"
        "DUAL_AUTHENTICATION_SETUP.md"
        "DHCP_PRIVATE_FQDN_GUIDE.md"
        "VPN_ACCESS_GUIDE.md"
        "KUBERNETES_IAM_AUTHENTICATION.md"
        "DATABASE_SCHEMA_SETUP.md"
        "PIPENV_SETUP.md"
        "RDS_VPC_ASSOCIATION.md"
        "SERVICE_CATALOG_RDS_SECURITY_ANALYSIS.md"
        "WEBHOOK_API_COMPATIBILITY_SOLUTION.md"
    )
    
    for doc in "${guide_docs[@]}"; do
        [ -f "$doc" ] && move_item "$doc" "docs/guides/$doc" \
            "Moving guide: $doc"
    done
    
    # Development docs
    [ -f "NIX_SETUP.md" ] && move_item "NIX_SETUP.md" "docs/development/NIX_SETUP.md"
    [ -f "QUICK_START.md" ] && move_item "QUICK_START.md" "docs/development/QUICK_START.md"
    [ -f "CONTRIBUTING.md" ] && move_item "CONTRIBUTING.md" "docs/development/CONTRIBUTING.md"
    
    append_report "- Architecture docs → docs/architecture/
- Security docs → docs/security/
- Setup guides → docs/guides/
- Development docs → docs/development/
"
}

# Archive unrelated device management scripts
archive_unrelated_scripts() {
    step "Archiving unrelated device management scripts..."
    
    append_report "
#### Unrelated Scripts (Moving to sec_scripts repo)
"
    
    # Create sec_scripts repo if it doesn't exist
    if [ ! -d "$SEC_SCRIPTS_REPO" ]; then
        execute "mkdir -p '$SEC_SCRIPTS_REPO'" \
                "Creating sec_scripts repository"
        
        if [ "$DRY_RUN" = false ]; then
            cd "$SEC_SCRIPTS_REPO"
            git init
            cat > README.md << 'SECEOF'
# Security Scripts Collection

Device management and security audit scripts.

## Contents

- **android/**: Android device cleanup and audit scripts
- **ios/**: iOS device management and security scripts
- **macos/**: macOS security and cleanup scripts
- **general/**: Cross-platform security tools

Moved from terraforming_again repository for better organization.
SECEOF
            git add README.md
            git commit -m "init: create sec_scripts repository"
            cd - > /dev/null
        fi
    fi
    
    # Device cleanup scripts (Android)
    local android_scripts=(
        "aggressive_android_cleanup.sh"
        "android_device_audit.sh"
        "android_manual_audit_checklist.md"
        "comprehensive_android_security_audit.sh"
        "remove_work_profile.sh"
    )
    
    create_dir "$SEC_SCRIPTS_REPO/android"
    for script in "${android_scripts[@]}"; do
        [ -f "$script" ] && move_item "$script" "$SEC_SCRIPTS_REPO/android/$script" \
            "Moving Android script: $script"
    done
    
    # iOS scripts
    local ios_scripts=(
        "apple_device_audit.sh"
        "apple_id_mayhem_fix.sh"
        "apple_id_sync_script.sh"
        "emergency_ios_cleanup.sh"
        "enhanced_emergency_ios_cleanup.sh"
        "enhanced_ios_device_audit.sh"
        "enhanced_selective_ios_cleanup.sh"
        "ios_apple_configurator_cleanup.sh"
        "IOS_AUDIT_AND_CLEANUP_GUIDE.md"
        "ios_automation_tools.sh"
        "ios_check.sh"
        "ios_device_verification.sh"
        "ios_ipad_audit_script.sh"
        "selective_ios_cleanup.sh"
        "unmount_simulators.sh"
    )
    
    create_dir "$SEC_SCRIPTS_REPO/ios"
    for script in "${ios_scripts[@]}"; do
        [ -f "$script" ] && move_item "$script" "$SEC_SCRIPTS_REPO/ios/$script" \
            "Moving iOS script: $script"
    done
    
    # macOS scripts
    local macos_scripts=(
        "emergency_mac_cleanup.sh"
        "mac_battery_fix.sh"
        "mac_cleanup_script.sh"
        "MACOS_K8S_SECURITY_QUICK_REFERENCE.md"
        "post_nvram_reset.sh"
        "factory_reset_new_setup.sh"
    )
    
    create_dir "$SEC_SCRIPTS_REPO/macos"
    for script in "${macos_scripts[@]}"; do
        [ -f "$script" ] && move_item "$script" "$SEC_SCRIPTS_REPO/macos/$script" \
            "Moving macOS script: $script"
    done
    
    # General security/audit scripts
    local general_scripts=(
        "browser_profile_security_audit.sh"
        "comprehensive_security_audit.sh"
        "rootkit_detection_removal_toolkit.sh"
        "complete_investigation_commands.sh"
        "crash_investigation.sh"
        "device_cleanup_script.sh"
        "keychain_cleanup_script.sh"
        "keychain_apple_id_audit.sh"
        "complete_account_logout.sh"
        "complete_account_removal.sh"
        "complete_device_wipe.sh"
        "multi_user_cleanup.sh"
        "standard_account_cleanup.sh"
        "intune_microsoft_cleanup.sh"
        "emergency_kerberos_cleanup.sh"
        "emergency_icloud_security.sh"
        "box_cleanup.sh"
        "unlink_all_emails.sh"
        "remove_all_connections.sh"
        "remove_connections_safe.sh"
        "force_remove_sockets.sh"
        "kill_all_terminals.sh"
        "consolidate_terminal_history.sh"
        "remove-xcode-completely.sh"
        "README_ROOTKIT_TOOLKIT.md"
    )
    
    create_dir "$SEC_SCRIPTS_REPO/general"
    for script in "${general_scripts[@]}"; do
        [ -f "$script" ] && move_item "$script" "$SEC_SCRIPTS_REPO/general/$script" \
            "Moving general security script: $script"
    done
    
    # Move audit logs and reports
    local audit_files=(
        "rootkit_audit_20250922_135212.log"
        "security_report_20250922_135521.txt"
        "intune_cleanup_summary_20250909_161944.txt"
        "keychain_summary_20250909_161708.txt"
    )
    
    create_dir "$SEC_SCRIPTS_REPO/reports"
    for file in "${audit_files[@]}"; do
        [ -f "$file" ] && move_item "$file" "$SEC_SCRIPTS_REPO/reports/$file" \
            "Moving audit report: $file"
    done
    
    # === ANSIBLE ===
    # Already moved in migrate_infrastructure
    
    # === CROSSPLANE ===
    append_report "
#### Crossplane
"
    
    # Move Crossplane compositions (infrastructure-related)
    if [ -d "crossplane/compositions/infrastructure" ] && [ -d "crossplane/compositions/infrastructure" ]; then
        # Infrastructure compositions go to infrastructure/crossplane/
        if [ -d "crossplane/compositions/infrastructure" ]; then
            # Exclude ansible which we already moved
            for item in crossplane/compositions/infrastructure/*; do
                if [ -d "$item" ] && [ "$(basename "$item")" != "ansible" ]; then
                    target_name=$(basename "$item")
                    move_item "$item" \
                              "infrastructure/crossplane/compositions/$target_name" \
                              "Moving Crossplane composition: $target_name"
                fi
            done
        fi
    fi
    
    append_report "- crossplane/compositions → infrastructure/crossplane/compositions/
- Device scripts → $SEC_SCRIPTS_REPO/
"
}

# Consolidate GitHub workflows
migrate_ci_cd() {
    step "Migrating CI/CD configurations..."
    
    append_report "
#### CI/CD Workflows
"
    
    # Remove duplicate workflows from crossplane/ci-cd/github-actions/
    if [ -d "crossplane/ci-cd/github-actions" ]; then
        if [ "$DRY_RUN" = false ]; then
            # Keep only .github/workflows/, archive the crossplane one
            move_item "crossplane/ci-cd/github-actions" \
                      "scripts/archived/old-workflows" \
                      "Archiving duplicate workflows from crossplane/ci-cd/"
        else
            info "Would archive: crossplane/ci-cd/github-actions → scripts/archived/old-workflows"
        fi
    fi
    
    # Move Prow configs to platform (if using Prow)
    if [ -d "crossplane/ci-cd/prow" ]; then
        move_item "crossplane/ci-cd/prow" \
                  "platform/prow" \
                  "Moving Prow configuration to platform"
    fi
    
    # Move CI/CD scripts to hack/
    if [ -d "crossplane/ci-cd/scripts" ]; then
        # These are utility scripts, move to hack/
        for script in crossplane/ci-cd/scripts/*; do
            if [ -f "$script" ]; then
                script_name=$(basename "$script")
                move_item "$script" "hack/$script_name" \
                          "Moving CI/CD script: $script_name"
            fi
        done
    fi
    
    append_report "- crossplane/ci-cd/github-actions/ → scripts/archived/ (duplicates removed)
- crossplane/ci-cd/prow/ → platform/prow/
- crossplane/ci-cd/scripts/ → hack/
"
}

# Move deployment and utility scripts
migrate_scripts() {
    step "Migrating deployment and utility scripts..."
    
    append_report "
#### Deployment Scripts
"
    
    # Setup scripts → hack/
    local setup_scripts=(
        "setup-actual-networking.sh"
        "setup-aws-cost-check.sh"
        "setup-aws-fido2-terminal.sh"
        "setup-aws-fido2.sh"
        "setup-aws-nix-fido2.sh"
        "setup-backend.sh"
        "setup-cilium-veth-networking.sh"
        "setup-container-runtime.sh"
        "setup-cross-cloud-networking.sh"
        "setup-dynamic-inventory.sh"
        "setup-iacrunner-security-admin.sh"
        "setup-macos-networking.sh"
        "setup-multi-account.sh"
        "setup-pipenv.sh"
        "setup-provider-networking.sh"
        "setup-proxy-networking.sh"
        "setup-simple-networking.sh"
        "setup-simple-proxy.sh"
        "setup-ssh-keys.sh"
        "setup-volume-networking.sh"
        "setup-workspaces.sh"
        "configure-eks.sh"
        "workspace-setup.sh"
        "switch-environment.sh"
    )
    
    for script in "${setup_scripts[@]}"; do
        [ -f "$script" ] && move_item "$script" "hack/$script" \
            "Moving setup script: $script"
    done
    
    # Nix setup scripts (if not already in hack/)
    [ -f "nix-complete-setup.sh" ] && move_item "nix-complete-setup.sh" \
        "hack/nix-complete-setup.sh"
    [ -f "nix-multi-volume-setup.sh" ] && move_item "nix-multi-volume-setup.sh" \
        "hack/nix-multi-volume-setup.sh"
    
    # User data and CloudInit
    [ -f "user_data.sh" ] && move_item "user_data.sh" \
        "infrastructure/terraform/templates/user_data.sh"
    [ -f "cloudinit_script.sh" ] && move_item "cloudinit_script.sh" \
        "infrastructure/terraform/templates/cloudinit_script.sh"
    [ -f "cloudinit.yml" ] && move_item "cloudinit.yml" \
        "infrastructure/terraform/templates/cloudinit.yml"
    
    # YubiKey scripts
    [ -f "generate-yubikey-certs-simple.sh" ] && move_item "generate-yubikey-certs-simple.sh" \
        "hack/generate-yubikey-certs-simple.sh"
    [ -f "generate-yubikey-piv-certs.sh" ] && move_item "generate-yubikey-piv-certs.sh" \
        "hack/generate-yubikey-piv-certs.sh"
    
    # Utility scripts
    [ -f "manage-aws-users.sh" ] && move_item "manage-aws-users.sh" \
        "hack/manage-aws-users.sh"
    [ -f "status.sh" ] && move_item "status.sh" \
        "hack/status.sh"
    
    append_report "- setup-*.sh → hack/
- CloudInit templates → infrastructure/terraform/templates/
- Utility scripts → hack/
"
}

# Move Kubernetes manifests
migrate_kubernetes() {
    step "Migrating Kubernetes manifests..."
    
    append_report "
#### Kubernetes Manifests
"
    
    if [ -d "kubernetes" ]; then
        # These are raw Kubernetes manifests
        # Organize by type or keep for reference
        move_item "kubernetes" \
                  "infrastructure/kubernetes/manifests" \
                  "Moving Kubernetes manifests"
        append_report "- kubernetes/ → infrastructure/kubernetes/manifests/
"
    fi
}

# Clean up empty directories
cleanup_empty_dirs() {
    step "Cleaning up empty directories..."
    
    if [ "$DRY_RUN" = false ]; then
        # Remove crossplane if empty
        if [ -d "crossplane" ] && [ -z "$(ls -A crossplane 2>/dev/null)" ]; then
            rmdir crossplane
            log "Removed empty crossplane directory"
        fi
        
        # Remove capi if empty
        if [ -d "capi" ] && [ -z "$(ls -A capi 2>/dev/null)" ]; then
            rmdir capi
            log "Removed empty capi directory"
        fi
    else
        info "Would clean up empty directories"
    fi
}

# Update references in files
update_references() {
    step "Updating file references..."
    
    append_report "
#### Reference Updates Needed
"
    
    if [ "$DRY_RUN" = false ]; then
        # Update terraform module references
        find infrastructure/terraform -name "*.tf" -type f | while read tf_file; do
            # Update provider references
            sed -i.bak 's|../provider-|./providers/provider-|g' "$tf_file" 2>/dev/null || true
            rm -f "${tf_file}.bak"
        done
        
        # Update workflow paths
        find .github/workflows -name "*.yml" -type f | while read workflow; do
            # Update script paths
            sed -i.bak 's|crossplane/ci-cd/scripts/|hack/|g' "$workflow" 2>/dev/null || true
            sed -i.bak 's|crossplane/applications/|applications/|g' "$workflow" 2>/dev/null || true
            rm -f "${workflow}.bak"
        done
        
        log "Updated file references"
        append_report "- Updated Terraform module paths
- Updated GitHub workflow script paths
- Updated application paths in workflows
"
    else
        info "Would update references in:"
        info "  - Terraform files (provider paths)"
        info "  - GitHub workflows (script paths)"
        info "  - Documentation (cross-references)"
    fi
}

# Generate migration summary
generate_summary() {
    append_report "
## Post-Migration Tasks

### Required Manual Updates

1. **Terraform Backend**: Update backend configuration in infrastructure/terraform/
2. **GitHub Secrets**: Verify all secrets are still accessible
3. **CI/CD Paths**: Test all workflow paths
4. **Documentation**: Update any hardcoded paths in docs

### Testing Checklist

- [ ] Terraform init/plan works in infrastructure/terraform/
- [ ] Ansible playbooks run from infrastructure/ansible/
- [ ] Go app builds from applications/go-mysql-api/
- [ ] GitHub workflows execute successfully
- [ ] CAPI configs apply from platform/cluster-api/
- [ ] All documentation links work

### Verification Commands

\`\`\`bash
# Test Terraform
cd infrastructure/terraform
terraform init
terraform validate

# Test Ansible
cd infrastructure/ansible
ansible-playbook --syntax-check playbooks/site.yml

# Test Go application
cd applications/go-mysql-api
go build -v ./cmd

# Test Nix environment
nix develop --command go version
\`\`\`

## File Statistics

**Moved**: $([ "$DRY_RUN" = true ] && echo "N/A (dry run)" || echo "See above")
**Archived**: Device management scripts → $SEC_SCRIPTS_REPO
**Consolidated**: Multiple Terraform and workflow locations

---
Generated: $(date)
"
    
    if [ "$DRY_RUN" = true ]; then
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}                  DRY RUN COMPLETE                         ${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}No changes were made. Review the migration plan above.${NC}"
        echo -e "${YELLOW}Run without --dry-run to execute the migration.${NC}"
        echo ""
    else
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}               MIGRATION COMPLETE                         ${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
        echo ""
        log "Migration report saved to: $MIGRATION_LOG"
        echo ""
    fi
}

# Main migration workflow
main() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Terraforming Again - Structure Migration Script        ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ "$DRY_RUN" = false ]; then
        warn "This will restructure the entire repository!"
        warn "Make sure you have committed all changes and have backups."
        echo ""
        read -p "Continue with migration? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            error "Migration cancelled"
            exit 1
        fi
    fi
    
    start_report
    
    # Execute migration steps
    create_new_structure
    migrate_applications
    migrate_infrastructure
    migrate_platform
    migrate_environments
    migrate_documentation
    migrate_kubernetes
    archive_unrelated_scripts
    migrate_scripts
    migrate_ci_cd
    cleanup_empty_dirs
    update_references
    generate_summary
    
    # Save migration log
    if [ "$DRY_RUN" = false ]; then
        create_dir "docs/migration"
        cp "$MIGRATION_LOG" "docs/migration/$MIGRATION_LOG"
        
        echo ""
        echo -e "${GREEN}Next steps:${NC}"
        echo "  1. Review migration report: cat $MIGRATION_LOG"
        echo "  2. Test Terraform: cd infrastructure/terraform && terraform init"
        echo "  3. Test Ansible: cd infrastructure/ansible && ansible-playbook --syntax-check playbooks/site.yml"
        echo "  4. Test Go app: cd applications/go-mysql-api && go build ./cmd"
        echo "  5. Commit changes: git add -A && git commit -m 'refactor: clean structure migration'"
        echo ""
    else
        cat "$MIGRATION_LOG"
    fi
}

# Run main function
main

