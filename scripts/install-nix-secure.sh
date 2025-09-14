#!/bin/bash

# Secure Nix Package Manager Installation Script
# Installs Nix with security-focused configuration

set -euo pipefail

echo "=== SECURE NIX INSTALLATION ==="
echo

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "❌ Do not run this script as root"
    echo "   Nix should be installed as a regular user"
    exit 1
fi

# Check if Nix is already installed
if command -v nix &> /dev/null; then
    echo "ℹ️  Nix is already installed:"
    nix --version
    echo
    read -p "Reinstall/Reconfigure Nix? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo "📦 Installing Nix package manager with security configuration..."
echo

# Install Nix using the official installer
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- --no-confirm

# Source Nix environment
echo "🔧 Sourcing Nix environment..."
if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
elif [[ -f ~/.nix-profile/etc/profile.d/nix.sh ]]; then
    source ~/.nix-profile/etc/profile.d/nix.sh
fi

# Verify installation
if command -v nix &> /dev/null; then
    echo "✅ Nix installed successfully:"
    nix --version
else
    echo "❌ Nix installation failed"
    exit 1
fi

echo
echo "🔒 Configuring Nix for security..."

# Create user Nix configuration directory
mkdir -p ~/.config/nix

# Create secure user configuration
cat > ~/.config/nix/nix.conf << 'EOF'
# Security-focused Nix user configuration
sandbox = true
require-sigs = true
max-jobs = 1
cores = 1
substituters = https://cache.nixos.org/
trusted-substituters = https://cache.nixos.org/
experimental-features = nix-command flakes
EOF

# Create system-wide configuration (requires sudo)
echo "🔒 Configuring system-wide Nix security settings..."
sudo mkdir -p /etc/nix

sudo tee /etc/nix/nix.conf > /dev/null << 'EOF'
# System-wide Nix security configuration
sandbox = true
require-sigs = true
trusted-users = root
allowed-users = root
max-jobs = 1
cores = 1
build-users-group = nixbld
substituters = https://cache.nixos.org/
trusted-substituters = https://cache.nixos.org/
experimental-features = nix-command flakes
EOF

# Restart Nix daemon to apply configuration
echo "🔄 Restarting Nix daemon..."
sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true

# Wait for daemon to start
sleep 3

# Test Nix installation
echo "🧪 Testing Nix installation..."
if nix-env --version &> /dev/null; then
    echo "✅ Nix is working correctly"
else
    echo "❌ Nix test failed"
    exit 1
fi

echo
echo "=== NIX INSTALLATION COMPLETED ==="
echo
echo "✅ Nix package manager installed and configured securely"
echo "🔒 Security features enabled:"
echo "   • Sandboxing enabled"
echo "   • Signature verification required"
echo "   • Limited build resources"
echo "   • Trusted users only"
echo
echo "📦 Basic Nix commands:"
echo "   • nix-env -i <package>     # Install a package"
echo "   • nix-env -e <package>     # Remove a package"
echo "   • nix-env -q               # List installed packages"
echo "   • nix search <term>        # Search for packages"
echo
echo "🔧 Advanced usage:"
echo "   • nix-shell -p <package>   # Temporary environment"
echo "   • nix flake init           # Initialize a flake"
echo
echo "⚠️  Important:"
echo "   • Restart your terminal or run: source ~/.nix-profile/etc/profile.d/nix.sh"
echo "   • Nix packages are isolated and don't affect system packages"
echo "   • Use 'nix-env -i' for user packages, system packages require different approach"
echo
echo "🎯 Recommended next steps:"
echo "   1. Restart your terminal"
echo "   2. Try: nix search hello"
echo "   3. Install a test package: nix-env -i hello"
echo "   4. Run: hello"
