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

# Try different ways to launch Cursor/VSCode
if command -v cursor &> /dev/null; then
    echo "🚀 Launching Cursor (CLI)..."
    cursor .
elif command -v code &> /dev/null; then
    echo "🚀 Launching VSCode (CLI)..."
    code .
elif [ -d "/Applications/Cursor.app" ]; then
    echo "🚀 Launching Cursor (Applications)..."
    open -a Cursor .
elif [ -d "/Applications/Visual Studio Code.app" ]; then
    echo "🚀 Launching VSCode (Applications)..."
    open -a "Visual Studio Code" .
else
    echo "❌ Neither Cursor nor VSCode found"
    echo "   Please install Cursor or VSCode"
    echo "   Or add CLI tools to PATH"
    exit 1
fi
