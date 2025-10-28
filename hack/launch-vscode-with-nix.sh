#!/bin/bash

# Launch VSCode/Cursor with Nix Environment Integration
# This script ensures VSCode/Cursor runs with the proper Nix environment for Terraform

set -e

echo "🚀 Launching VSCode/Cursor with Nix Environment Integration"
echo "========================================================="

# Check if we're in the project directory
if [ ! -f "flake.nix" ]; then
    echo "❌ Not in project root directory. Please run from project root."
    exit 1
fi

# Check if Nix is available
if ! command -v nix &> /dev/null; then
    echo "❌ Nix not found. Please install Nix first."
    exit 1
fi

# Check if terraform-ls is available in Nix environment
echo "🔍 Checking Terraform language server..."
if ! nix develop --impure --command which terraform-ls &> /dev/null; then
    echo "❌ terraform-ls not found in Nix environment"
    echo "   Run: nix develop --impure"
    exit 1
fi

echo "✅ terraform-ls found in Nix environment"

# Get the path to terraform-ls
TERRAFORM_LS_PATH=$(nix develop --impure --command which terraform-ls)
echo "📍 terraform-ls path: $TERRAFORM_LS_PATH"

# Update VSCode settings with the correct path
echo "🔧 Updating VSCode settings..."
cat > infrastructure/terraform/.vscode/settings.json << EOF
{
    "terraform.languageServer": {
        "enabled": true,
        "args": [],
        "path": "$TERRAFORM_LS_PATH"
    },
    "terraform.experimentalFeatures": {
        "validateOnSave": true,
        "prefillRequiredFields": true
    },
    "terraform.format": {
        "enable": true,
        "ignoreExtensionsOnSave": [".terraform.lock.hcl"]
    },
    "terraform.validation": {
        "enable": true,
        "lint": {
            "enable": true,
            "path": "tflint"
        }
    },
    "files.associations": {
        "*.tf": "terraform",
        "*.tfvars": "terraform",
        "*.hcl": "terraform",
        "*.tf.json": "terraform",
        "*.tfstate": "terraform",
        "*.tfstate.backup": "terraform",
        "terraform.rc": "terraform",
        ".terraformrc": "terraform"
    },
    "[terraform]": {
        "editor.defaultFormatter": "hashicorp.terraform",
        "editor.formatOnSave": true,
        "editor.tabSize": 2,
        "editor.insertSpaces": true,
        "editor.detectIndentation": false,
        "editor.suggest.insertMode": "replace",
        "editor.wordWrap": "off",
        "editor.bracketPairColorization.enabled": true,
        "editor.guides.bracketPairs": true
    },
    "[hcl]": {
        "editor.defaultFormatter": "hashicorp.terraform",
        "editor.formatOnSave": true,
        "editor.tabSize": 2,
        "editor.insertSpaces": true
    },
    "terraform.telemetry": {
        "enable": true
    },
    "terraform.indexing": {
        "enabled": true,
        "liveIndexing": true
    }
}
EOF

echo "✅ VSCode settings updated"

# Create a wrapper script for launching VSCode with Nix environment
echo "🔧 Creating VSCode wrapper script..."
cat > launch-vscode.sh << 'EOF'
#!/bin/bash
# Launch VSCode with Nix environment

# Activate Nix environment
eval "$(nix develop --impure --command env | grep -E '^(PATH|TERRAFORM_LS|TF_LOG)=')"

# Launch VSCode with the environment
if command -v code &> /dev/null; then
    echo "🚀 Launching VSCode..."
    code .
elif command -v cursor &> /dev/null; then
    echo "🚀 Launching Cursor..."
    cursor .
else
    echo "❌ Neither 'code' nor 'cursor' command found"
    echo "   Please install VSCode or Cursor CLI tools"
    exit 1
fi
EOF

chmod +x launch-vscode.sh

echo "✅ Wrapper script created: launch-vscode.sh"

# Check if VSCode/Cursor CLI is available
if command -v code &> /dev/null; then
    echo "✅ VSCode CLI found"
    LAUNCHER="code"
elif command -v cursor &> /dev/null; then
    echo "✅ Cursor CLI found"
    LAUNCHER="cursor"
else
    echo "⚠️  VSCode/Cursor CLI not found"
    echo "   Please install CLI tools or use the wrapper script"
    echo "   Run: ./launch-vscode.sh"
    exit 0
fi

echo ""
echo "🎯 Next Steps:"
echo "1. Close any existing VSCode/Cursor windows"
echo "2. Run: ./launch-vscode.sh"
echo "   OR"
echo "3. Run: $LAUNCHER ."
echo ""
echo "4. Open a .tf file (e.g., environments/dev/main.tf)"
echo "5. Check if syntax highlighting works"
echo "6. Try command-click on module references"
echo ""
echo "🔧 If syntax highlighting still doesn't work:"
echo "1. Open Command Palette (Cmd+Shift+P)"
echo "2. Run: 'Terraform: Restart Language Server'"
echo "3. Check Output panel → 'Terraform' for errors"
echo ""
echo "📋 Troubleshooting:"
echo "- Make sure HashiCorp Terraform extension is installed"
echo "- Check that terraform-ls is running in Output panel"
echo "- Verify workspace settings in .vscode/settings.json"



