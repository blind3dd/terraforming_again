#!/bin/bash

# Complete IDE Integration Fix
# This script fixes both Go and Terraform integration with VSCode/Cursor

set -e

echo "🔧 Fixing IDE Integration (Go + Terraform)"
echo "=========================================="

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

echo "🔍 Checking Nix environment..."

# Get paths from Nix environment
GO_PATH=$(nix develop --impure --command which go)
GOPLS_PATH=$(nix develop --impure --command which gopls)
TERRAFORM_LS_PATH=$(nix develop --impure --command which terraform-ls)
TFLINT_PATH=$(nix develop --impure --command which tflint)

echo "✅ Go: $GO_PATH"
echo "✅ gopls: $GOPLS_PATH"
echo "✅ terraform-ls: $TERRAFORM_LS_PATH"
echo "✅ tflint: $TFLINT_PATH"

# Create workspace-specific settings
echo "🔧 Creating workspace settings..."
mkdir -p .vscode

cat > .vscode/settings.json << EOF
{
    "go.alternateTools": {
        "go": "$GO_PATH",
        "gopls": "$GOPLS_PATH",
        "gofmt": "$GO_PATH"
    },
    "go.goroot": "",
    "go.gopath": "\${workspaceFolder}",
    "go.inferGopath": false,
    "go.toolsGopath": "\${workspaceFolder}",
    "terraform.languageServer": {
        "enabled": true,
        "args": [],
        "path": "$TERRAFORM_LS_PATH"
    },
    "terraform.validation": {
        "enable": true,
        "lint": {
            "enable": true,
            "path": "$TFLINT_PATH"
        }
    },
    "terminal.integrated.env.osx": {
        "PATH": "\${workspaceFolder}/.nix/bin:/nix/var/nix/profiles/default/bin:\${env:PATH}",
        "NIX_PROFILES": "/nix/var/nix/profiles/default \${workspaceFolder}/.nix",
        "GOROOT": "",
        "GOPATH": "\${workspaceFolder}",
        "TERRAFORM_LS": "$TERRAFORM_LS_PATH"
    },
    "files.associations": {
        "*.tf": "terraform",
        "*.tfvars": "terraform",
        "*.hcl": "terraform",
        "*.tf.json": "terraform",
        "*.tfstate": "terraform",
        "*.tfstate.backup": "terraform"
    },
    "[terraform]": {
        "editor.defaultFormatter": "hashicorp.terraform",
        "editor.formatOnSave": true,
        "editor.tabSize": 2,
        "editor.insertSpaces": true
    },
    "[go]": {
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.organizeImports": "explicit"
        },
        "editor.tabSize": 4,
        "editor.insertSpaces": false
    }
}
EOF

echo "✅ Workspace settings created"

# Create a launch script for VSCode/Cursor
echo "🔧 Creating launch script..."
cat > launch-ide.sh << 'EOF'
#!/bin/bash
# Launch VSCode/Cursor with proper Nix environment

# Activate Nix environment
eval "$(nix develop --impure --command env | grep -E '^(PATH|GOROOT|GOPATH|TERRAFORM_LS)=')"

# Set environment variables
export PATH="$PWD/.nix/bin:/nix/var/nix/profiles/default/bin:$PATH"
export GOPATH="$PWD"
export GOROOT=""

echo "🚀 Launching IDE with Nix environment..."
echo "📍 Go: $(which go)"
echo "📍 gopls: $(which gopls)"
echo "📍 terraform-ls: $(which terraform-ls)"

# Launch VSCode/Cursor
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

chmod +x launch-ide.sh
echo "✅ Launch script created: launch-ide.sh"

# Test the environment
echo "🧪 Testing environment..."
echo "Go version: $(nix develop --impure --command go version)"
echo "Terraform version: $(nix develop --impure --command terraform version)"

echo ""
echo "🎯 Next Steps:"
echo "1. Close any existing VSCode/Cursor windows"
echo "2. Run: ./launch-ide.sh"
echo "3. Open a Go file (e.g., applications/go-mysql-api/conff/config.go)"
echo "4. Open a Terraform file (e.g., infrastructure/terraform/syntax-test.tf)"
echo "5. Check if syntax highlighting works for both"
echo ""
echo "🔧 If issues persist:"
echo "1. Check Output panel → 'Go' and 'Terraform' for errors"
echo "2. Restart language servers:"
echo "   - Command Palette → 'Go: Restart Language Server'"
echo "   - Command Palette → 'Terraform: Restart Language Server'"
echo "3. Reload window: Command Palette → 'Developer: Reload Window'"
echo ""
echo "✅ IDE integration should now work for both Go and Terraform!"


