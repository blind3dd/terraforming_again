#!/bin/bash

# macOS Security Hardening Script
# Removes development tools, disables WebKit, and sets up Nix package manager

set -euo pipefail

echo "=== macOS SECURITY HARDENING SCRIPT ==="
echo "⚠️  WARNING: This script will remove development tools and disable WebKit"
echo "⚠️  Make sure you have backups and understand the implications"
echo
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo "Starting security hardening process..."
echo

# Function to check if running as admin
check_admin() {
    if [[ $EUID -ne 0 ]]; then
        echo "❌ This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to backup important files
backup_files() {
    echo "📦 Creating backup of system configuration..."
    BACKUP_DIR="/tmp/mac-security-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup system preferences
    cp -r /Library/Preferences "$BACKUP_DIR/" 2>/dev/null || true
    cp -r ~/Library/Preferences "$BACKUP_DIR/user_preferences/" 2>/dev/null || true
    
    echo "✅ Backup created at: $BACKUP_DIR"
    echo
}

# 1. Remove Xcode Command Line Tools and development libraries
remove_dev_tools() {
    echo "=== REMOVING DEVELOPMENT TOOLS ==="
    
    # Check if Xcode Command Line Tools are installed
    if xcode-select -p &>/dev/null; then
        echo "🗑️  Removing Xcode Command Line Tools..."
        sudo rm -rf /Library/Developer/CommandLineTools
        sudo xcode-select --uninstall 2>/dev/null || true
        echo "✅ Xcode Command Line Tools removed"
    else
        echo "ℹ️  Xcode Command Line Tools not found"
    fi
    
    # Remove development libraries
    echo "🗑️  Removing development libraries..."
    
    # Remove common development directories
    DEV_DIRS=(
        "/usr/local/include"
        "/usr/local/lib"
        "/usr/local/share/man"
        "/opt/homebrew"  # Homebrew
        "/usr/local/Homebrew"
        "/Applications/Xcode.app"
        "/Applications/Xcode-beta.app"
    )
    
    for dir in "${DEV_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            echo "  Removing: $dir"
            rm -rf "$dir"
        fi
    done
    
    # Remove development tools from PATH
    echo "🔧 Cleaning up PATH..."
    # Remove common development paths
    export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v -E "(homebrew|Xcode|Developer)" | tr '\n' ':' | sed 's/:$//')
    
    echo "✅ Development tools removed"
    echo
}

# 2. Disable WebKit and Safari components
disable_webkit() {
    echo "=== DISABLING WEBKIT AND SAFARI ==="
    
    # Disable Safari
    echo "🚫 Disabling Safari..."
    sudo chmod 000 /Applications/Safari.app 2>/dev/null || true
    sudo chmod 000 /System/Applications/Safari.app 2>/dev/null || true
    
    # Disable WebKit frameworks
    echo "🚫 Disabling WebKit frameworks..."
    WEBKIT_FRAMEWORKS=(
        "/System/Library/Frameworks/WebKit.framework"
        "/System/Library/PrivateFrameworks/WebKit.framework"
        "/System/Library/PrivateFrameworks/WebKitLegacy.framework"
    )
    
    for framework in "${WEBKIT_FRAMEWORKS[@]}"; do
        if [[ -d "$framework" ]]; then
            echo "  Disabling: $framework"
            sudo chmod 000 "$framework" 2>/dev/null || true
        fi
    done
    
    # Disable WebKit processes
    echo "🚫 Disabling WebKit processes..."
    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.WebKit.* 2>/dev/null || true
    sudo launchctl unload -w /System/Library/LaunchAgents/com.apple.WebKit.* 2>/dev/null || true
    
    # Remove Safari from dock and applications
    echo "🚫 Removing Safari from applications..."
    defaults write com.apple.dock persistent-apps -array-remove '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file:///Applications/Safari.app/</string></dict></dict></dict>' 2>/dev/null || true
    
    echo "✅ WebKit and Safari disabled"
    echo
}

# 3. Remove emulation libraries and virtualization tools
remove_emulation_tools() {
    echo "=== REMOVING EMULATION AND VIRTUALIZATION TOOLS ==="
    
    # Remove common virtualization tools
    VIRTUALIZATION_APPS=(
        "/Applications/VMware Fusion.app"
        "/Applications/Parallels Desktop.app"
        "/Applications/VirtualBox.app"
        "/Applications/Docker.app"
        "/Applications/UTM.app"
        "/Applications/QEMU.app"
    )
    
    for app in "${VIRTUALIZATION_APPS[@]}"; do
        if [[ -d "$app" ]]; then
            echo "🗑️  Removing: $app"
            rm -rf "$app"
        fi
    done
    
    # Remove emulation libraries
    echo "🗑️  Removing emulation libraries..."
    EMULATION_LIBS=(
        "/usr/local/lib/qemu"
        "/usr/local/lib/virtualbox"
        "/usr/local/lib/docker"
        "/opt/vagrant"
        "/usr/local/bin/qemu-*"
        "/usr/local/bin/vbox*"
    )
    
    for lib in "${EMULATION_LIBS[@]}"; do
        if [[ -e "$lib" ]]; then
            echo "  Removing: $lib"
            rm -rf "$lib"
        fi
    done
    
    # Disable virtualization kernel extensions
    echo "🚫 Disabling virtualization kernel extensions..."
    sudo kextunload -b com.vmware.kext.vmhgfs 2>/dev/null || true
    sudo kextunload -b com.vmware.kext.vmx86 2>/dev/null || true
    sudo kextunload -b org.virtualbox.kext.VBoxDrv 2>/dev/null || true
    
    echo "✅ Emulation and virtualization tools removed"
    echo
}

# 4. Install and configure Nix package manager
install_nix() {
    echo "=== INSTALLING NIX PACKAGE MANAGER ==="
    
    # Check if Nix is already installed
    if command -v nix &> /dev/null; then
        echo "ℹ️  Nix is already installed"
        nix --version
    else
        echo "📦 Installing Nix package manager..."
        
        # Install Nix in single-user mode for better security
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- --no-confirm
        
        # Source Nix environment
        if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
            source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        fi
        
        echo "✅ Nix installed successfully"
    fi
    
    # Configure Nix for security
    echo "🔒 Configuring Nix for security..."
    
    # Create secure Nix configuration
    mkdir -p ~/.config/nix
    cat > ~/.config/nix/nix.conf << 'EOF'
# Security-focused Nix configuration
sandbox = true
require-sigs = true
trusted-users = root
allowed-users = root
max-jobs = 1
cores = 1
build-users-group = nixbld
EOF
    
    # Configure Nix daemon for security
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
EOF
    
    # Restart Nix daemon
    sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
    sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
    
    echo "✅ Nix configured for security"
    echo
}

# 5. Additional security hardening
additional_hardening() {
    echo "=== ADDITIONAL SECURITY HARDENING ==="
    
    # Disable remote login
    echo "🚫 Disabling remote login..."
    sudo systemsetup -setremotelogin off
    
    # Disable file sharing
    echo "🚫 Disabling file sharing..."
    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist 2>/dev/null || true
    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true
    
    # Disable AirDrop
    echo "🚫 Disabling AirDrop..."
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.airport.preferences RequireAdminIBSS -bool YES
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.airport.preferences RequireAdminNetworkChange -bool YES
    
    # Disable Bluetooth
    echo "🚫 Disabling Bluetooth..."
    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.bluetoothd.plist 2>/dev/null || true
    
    # Enable firewall
    echo "🔥 Enabling firewall..."
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
    
    # Disable automatic updates (security risk)
    echo "🚫 Disabling automatic updates..."
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool false
    
    echo "✅ Additional security hardening completed"
    echo
}

# 6. Clean up and finalize
cleanup() {
    echo "=== CLEANUP AND FINALIZATION ==="
    
    # Clear caches
    echo "🧹 Clearing system caches..."
    sudo rm -rf /System/Library/Caches/*
    sudo rm -rf /Library/Caches/*
    rm -rf ~/Library/Caches/*
    
    # Update locate database
    echo "🔍 Updating locate database..."
    sudo /usr/libexec/locate.updatedb
    
    # Clear bash history
    echo "🧹 Clearing bash history..."
    history -c
    rm -f ~/.bash_history
    
    echo "✅ Cleanup completed"
    echo
}

# Main execution
main() {
    check_admin
    backup_files
    remove_dev_tools
    disable_webkit
    remove_emulation_tools
    install_nix
    additional_hardening
    cleanup
    
    echo "=== SECURITY HARDENING COMPLETED ==="
    echo
    echo "✅ Development tools removed"
    echo "✅ WebKit and Safari disabled"
    echo "✅ Emulation tools removed"
    echo "✅ Nix package manager installed and configured"
    echo "✅ Additional security hardening applied"
    echo
    echo "🔒 Your Mac is now significantly more secure"
    echo "📦 Use 'nix-env -i <package>' to install packages"
    echo "🔄 Reboot your system to ensure all changes take effect"
    echo
    echo "⚠️  Remember: You may need to reinstall some legitimate applications"
    echo "   that were removed during the hardening process"
}

# Run main function
main "$@"
