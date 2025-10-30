#!/bin/bash

# Terraform Language Server Restart Script
# This script helps restart the Terraform language server if it's not working

set -e

echo "🔧 Terraform Language Server Troubleshooting"
echo "============================================="

# Check if we're in the Nix environment
if ! command -v terraform-ls &> /dev/null; then
    echo "❌ terraform-ls not found. Make sure you're in the Nix environment:"
    echo "   nix develop --impure"
    exit 1
fi

echo "✅ terraform-ls found: $(which terraform-ls)"

# Check if terraform is available
if ! command -v terraform &> /dev/null; then
    echo "❌ terraform not found. Make sure you're in the Nix environment:"
    echo "   nix develop --impure"
    exit 1
fi

echo "✅ terraform found: $(which terraform)"

# Check if tflint is available
if ! command -v tflint &> /dev/null; then
    echo "❌ tflint not found. Make sure you're in the Nix environment:"
    echo "   nix develop --impure"
    exit 1
fi

echo "✅ tflint found: $(which tflint)"

# Check Terraform version
echo "📋 Terraform version:"
terraform version

# Check if we're in a Terraform directory
if [ ! -f "main.tf" ] && [ ! -f "*.tf" ]; then
    echo "⚠️  No Terraform files found in current directory"
    echo "   Make sure you're in a directory with .tf files"
fi

# Check for Terraform language server process
echo "🔍 Checking for Terraform language server processes..."
if pgrep -f "terraform-ls" > /dev/null; then
    echo "✅ Terraform language server is running"
    echo "   Process IDs: $(pgrep -f "terraform-ls")"
else
    echo "❌ Terraform language server is not running"
fi

# Check VSCode/Cursor extensions
echo "🔍 Checking for Terraform extensions..."
if [ -d "$HOME/.vscode/extensions" ] || [ -d "$HOME/.cursor/extensions" ]; then
    echo "✅ VSCode/Cursor extensions directory found"
    
    # Check for HashiCorp Terraform extension
    if find "$HOME/.vscode/extensions" "$HOME/.cursor/extensions" -name "*hashicorp.terraform*" -type d 2>/dev/null | grep -q .; then
        echo "✅ HashiCorp Terraform extension found"
    else
        echo "❌ HashiCorp Terraform extension not found"
        echo "   Install: HashiCorp Terraform extension"
    fi
else
    echo "❌ VSCode/Cursor extensions directory not found"
fi

echo ""
echo "🛠️  Troubleshooting Steps:"
echo "1. Make sure you're in the Nix environment: nix develop --impure"
echo "2. Restart VSCode/Cursor"
echo "3. Open Command Palette (Cmd+Shift+P) and run:"
echo "   - 'Terraform: Restart Language Server'"
echo "   - 'Developer: Reload Window'"
echo "4. Check Output panel for 'Terraform' logs"
echo "5. Verify file associations in settings.json"

echo ""
echo "📁 Current directory: $(pwd)"
echo "📁 Terraform files: $(find . -name "*.tf" -type f 2>/dev/null | wc -l | tr -d ' ') files"

# Test Terraform validation
echo ""
echo "🧪 Testing Terraform validation..."
if terraform validate 2>/dev/null; then
    echo "✅ Terraform validation passed"
else
    echo "❌ Terraform validation failed"
    echo "   Run 'terraform validate' for details"
fi

echo ""
echo "🎯 If issues persist:"
echo "1. Check VSCode/Cursor Output panel → Terraform"
echo "2. Verify workspace settings in .vscode/settings.json"
echo "3. Ensure all required extensions are installed"
echo "4. Try opening a single .tf file to test syntax highlighting"



