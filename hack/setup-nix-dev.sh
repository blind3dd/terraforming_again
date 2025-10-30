#!/bin/bash
# Setup Nix Development Environment for Terraforming Again
# This script initializes the Nix flake and installs all development tools

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "🚀 Setting up Nix development environment for Terraforming Again"
echo ""

# Check if Nix is installed
if ! command -v nix >/dev/null 2>&1; then
    echo "❌ Nix is not installed!"
    echo "Install with: sh <(curl -L https://nixos.org/nix/install)"
    exit 1
fi

echo "✅ Nix is installed: $(nix --version)"

# Check if flakes are enabled
if ! nix flake --help >/dev/null 2>&1; then
    echo "❌ Nix flakes not enabled!"
    echo "Enable with:"
    echo "  mkdir -p ~/.config/nix"
    echo "  echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf"
    exit 1
fi

echo "✅ Nix flakes are enabled"

# Install direnv if not present
if ! command -v direnv >/dev/null 2>&1; then
    echo "📦 Installing direnv..."
    nix-env -iA nixpkgs.direnv
    echo "✅ direnv installed"
else
    echo "✅ direnv is installed: $(direnv --version)"
fi

# Setup direnv hook in shell
if ! grep -q 'eval "$(direnv hook' ~/.zshrc 2>/dev/null; then
    echo "📝 Adding direnv hook to ~/.zshrc..."
    echo '' >> ~/.zshrc
    echo '# Direnv hook for automatic environment loading' >> ~/.zshrc
    echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
    echo "✅ direnv hook added to ~/.zshrc"
else
    echo "✅ direnv hook already configured"
fi

# Create flake.lock if it doesn't exist
if [ ! -f "flake.lock" ]; then
    echo "📝 Initializing flake.lock..."
    nix flake lock --accept-flake-config
    echo "✅ flake.lock created"
else
    echo "✅ flake.lock exists"
fi

# Update flake inputs
echo "📦 Updating flake inputs..."
nix flake update --accept-flake-config
echo "✅ Flake inputs updated"

# Build the development shell (this downloads all packages)
echo "🔨 Building development shell (this may take a few minutes)..."
nix develop --accept-flake-config --command echo "Development shell built successfully"
echo "✅ Development shell ready"

# Allow direnv for this project
if [ -f ".envrc" ]; then
    echo "📝 Allowing direnv for this project..."
    direnv allow
    echo "✅ direnv allowed"
fi

# Setup VSCode/Cursor configuration
echo "📝 Setting up VSCode/Cursor configuration..."
mkdir -p .vscode
if [ -f ".nix/dotfiles/ide/settings.json" ]; then
    cp .nix/dotfiles/ide/settings.json .vscode/settings.json
    echo "✅ VSCode settings installed"
fi
if [ -f ".nix/dotfiles/ide/extensions.json" ]; then
    cp .nix/dotfiles/ide/extensions.json .vscode/extensions.json
    echo "✅ VSCode extensions.json installed"
fi

# Fix Go navigation
if [ -f "hack/fix-go-navigation.sh" ]; then
    echo "🔧 Running Go navigation fix..."
    chmod +x hack/fix-go-navigation.sh
    bash hack/fix-go-navigation.sh
fi

echo ""
echo "✅ Nix development environment setup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Restart your terminal (or run: source ~/.zshrc)"
echo "   2. cd into this directory - direnv will auto-load the environment"
echo "   3. Run: nix develop --accept-flake-config"
echo "   4. Open in VSCode/Cursor and install recommended extensions"
echo ""
echo "💡 Useful commands:"
echo "   nix develop           - Enter development environment"
echo "   nix flake update      - Update all dependencies"
echo "   direnv reload         - Reload environment"
echo "   ./hack/fix-go-navigation.sh - Fix gopls if needed"
echo ""

