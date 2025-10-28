#!/bin/bash

# Install Required Extensions for Cursor
# This script helps install the necessary extensions for Go and Terraform development

set -e

echo "🔧 Installing Required Extensions for Cursor"
echo "============================================="

# Check if we're in the project directory
if [ ! -f "flake.nix" ]; then
    echo "❌ Not in project root directory. Please run from project root."
    exit 1
fi

echo "📋 Required Extensions:"
echo "  - golang.go (Go language support)"
echo "  - hashicorp.terraform (Terraform language support)"
echo "  - hashicorp.hcl (HCL language support)"

echo ""
echo "🎯 Manual Installation Steps:"
echo "1. Open Cursor"
echo "2. Press Cmd+Shift+P to open Command Palette"
echo "3. Type 'Extensions: Install Extensions'"
echo "4. Search for and install these extensions:"
echo "   - Go (by Google)"
echo "   - HashiCorp Terraform"
echo "   - HCL"

echo ""
echo "🔧 Alternative: Use Command Line (if available)"
echo "If Cursor CLI is available, you can run:"
echo "  cursor --install-extension golang.go"
echo "  cursor --install-extension hashicorp.terraform"
echo "  cursor --install-extension hashicorp.hcl"

echo ""
echo "🧪 After Installing Extensions:"
echo "1. Restart Cursor"
echo "2. Open a Go file (e.g., applications/go-mysql-api/conff/config.go)"
echo "3. Check if Go syntax highlighting works"
echo "4. Open a Terraform file (e.g., infrastructure/terraform/syntax-test.tf)"
echo "5. Check if Terraform syntax highlighting works"

echo ""
echo "🔍 Troubleshooting:"
echo "If extensions are installed but not working:"
echo "1. Check Output panel → 'Go' and 'Terraform' for errors"
echo "2. Try Command Palette → 'Developer: Reload Window'"
echo "3. Verify workspace settings in .vscode/settings.json"

echo ""
echo "💡 Quick Test:"
echo "After installing extensions, try these commands in Command Palette:"
echo "  - 'Go: Restart Language Server'"
echo "  - 'Terraform: Restart Language Server'"
echo "  - 'Go: Install/Update Tools'"

echo ""
echo "✅ Once extensions are installed, both Go and Terraform should work properly!"


