#!/bin/bash

# Terraform Language Server Initialization Script
# This script properly initializes the Terraform language server for the workspace

set -e

echo "🚀 Initializing Terraform Language Server"
echo "========================================"

# Check if we're in the Nix environment
if ! command -v terraform-ls &> /dev/null; then
    echo "❌ terraform-ls not found. Activating Nix environment..."
    nix develop --impure
fi

echo "✅ terraform-ls found: $(which terraform-ls)"
echo "✅ terraform found: $(which terraform)"

# Navigate to terraform directory
cd "$(dirname "$0")/../infrastructure/terraform"

echo "📁 Working in: $(pwd)"

# Initialize Terraform (this helps the language server)
echo "🔧 Initializing Terraform..."
terraform init -backend=false

# Check if modules exist
echo "📦 Checking modules..."
if [ -d "modules" ]; then
    echo "✅ Modules directory found"
    echo "   Modules: $(find modules -name "*.tf" -type f | wc -l | tr -d ' ') files"
else
    echo "❌ Modules directory not found"
fi

# Check if environments exist
echo "🌍 Checking environments..."
if [ -d "environments" ]; then
    echo "✅ Environments directory found"
    echo "   Environments: $(ls environments | wc -l | tr -d ' ') directories"
else
    echo "❌ Environments directory not found"
fi

# Validate Terraform configuration
echo "🧪 Validating Terraform configuration..."
if terraform validate; then
    echo "✅ Terraform validation passed"
else
    echo "❌ Terraform validation failed"
    echo "   Run 'terraform validate' for details"
fi

# Check Terraform language server status
echo "🔍 Checking Terraform language server..."
if pgrep -f "terraform-ls" > /dev/null; then
    echo "✅ Terraform language server is running"
    echo "   Process IDs: $(pgrep -f "terraform-ls")"
else
    echo "❌ Terraform language server is not running"
    echo "   It should start automatically when you open .tf files"
fi

echo ""
echo "🎯 Next Steps:"
echo "1. Open a .tf file in VSCode/Cursor"
echo "2. Check Command Palette (Cmd+Shift+P) → 'Terraform: Restart Language Server'"
echo "3. Check Output panel → 'Terraform' for any errors"
echo "4. Try command-click on module references"

echo ""
echo "🔧 Troubleshooting:"
echo "- If command-click doesn't work, try restarting VSCode/Cursor"
echo "- Check that HashiCorp Terraform extension is installed"
echo "- Verify workspace settings in .vscode/settings.json"
echo "- Run 'terraform init' in each environment directory"

echo ""
echo "📋 Workspace Structure:"
echo "├── modules/          # Reusable Terraform modules"
echo "├── environments/     # Environment-specific configurations"
echo "├── templates/        # Cloud-init templates"
echo "└── .vscode/         # Workspace settings"



