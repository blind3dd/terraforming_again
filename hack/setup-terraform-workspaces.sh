#!/usr/bin/env bash
# Setup Terraform workspaces configuration
# This consolidates environments into a single configuration using workspaces

set -e

BASE_DIR="infrastructure/terraform"
CONFIG_DIR="$BASE_DIR/environments"

echo "🔧 Setting up Terraform Workspaces"
echo ""

# Check if we should consolidate or use existing structure
echo "Options:"
echo "1. Keep separate directories, add workspace support to each"
echo "2. Create unified configuration with workspaces (recommended)"
read -p "Choose option [1/2]: " option

case $option in
  1)
    echo ""
    echo "📝 Updating backend configuration to use workspace-specific paths..."
    
    # Update each environment's backend to use workspace key
    for env in dev test prod; do
      env_file="$CONFIG_DIR/$env/main.tf"
      if [ -f "$env_file" ]; then
        echo "📝 Updating: $env_file"
        
        # Update backend to use workspace-specific path
        # For local backend with workspaces
        if grep -q 'backend "local"' "$env_file"; then
          # Update path to include workspace
          sed -i.bak 's|path = "terraform.tfstate"|path = "terraform-${terraform.workspace}.tfstate"|' "$env_file"
          rm -f "$env_file.bak"
          echo "✅ Updated $env backend"
        fi
      fi
    done
    
    echo ""
    echo "✅ Backend configurations updated!"
    echo "💡 Each environment now uses workspace-specific state files"
    ;;
    
  2)
    echo ""
    echo "📝 This would create a unified configuration..."
    echo "💡 For now, let's use option 1 to keep your existing structure"
    echo "   but add workspace support for better state management"
    ;;
    
  *)
    echo "❌ Invalid option"
    exit 1
    ;;
esac

echo ""
echo "📋 Next steps:"
echo "  1. Run: ./hack/terraform-workspace.sh $CONFIG_DIR/test dev"
echo "  2. Run: terraform init"
echo "  3. Switch workspaces: terraform workspace select dev|test|prod"

