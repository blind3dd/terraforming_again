#!/usr/bin/env bash
# Initialize all Terraform/OpenTofu directories

set -e

echo "🔧 Initializing all Terraform/OpenTofu directories..."
echo ""

# Directories that need initialization (environments and standalone projects)
TERRAFORM_DIRS=(
  "./azure-connector"
  "./infrastructure/terraform/environments/dev"
#   "./infrastructure/terraform/environments/prod"
  "./infrastructure/terraform/environments/test"
)

# Modules don't need separate initialization
MODULE_DIRS=(
  "./common"
  "./infrastructure/terraform/modules/compute"
  "./infrastructure/terraform/modules/database"
  "./infrastructure/terraform/modules/networking"
  "./infrastructure/terraform/modules/tailscale"
)

# Use terraform if available, otherwise tofu
TERRAFORM_CMD="terraform"
if ! command -v terraform >/dev/null 2>&1; then
  if command -v tofu >/dev/null 2>&1; then
    TERRAFORM_CMD="tofu"
  else
    echo "❌ Neither terraform nor tofu found!"
    exit 1
  fi
fi

echo "Using: $TERRAFORM_CMD"
echo ""

# Initialize each directory
for dir in "${TERRAFORM_DIRS[@]}"; do
  if [ -d "$dir" ] && [ -n "$(find "$dir" -maxdepth 1 -name '*.tf' 2>/dev/null)" ]; then
    echo "📁 Initializing: $dir"
    (cd "$dir" && $TERRAFORM_CMD init -upgrade)
    echo "✅ Done: $dir"
    echo ""
  else
    echo "⏭️  Skipping: $dir (no .tf files found)"
  fi
done

echo "✅ All Terraform directories initialized!"
echo ""
echo "💡 Note: Modules in ./common and ./infrastructure/terraform/modules/*"
echo "   don't need separate initialization - they're included by environments"

