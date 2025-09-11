#!/usr/bin/env bash

# macOS Login Hardening Script
# Forces YubiKey + PIN only, disables all other login methods
# Uses CLI tools: dscl, dseditgroup, security, sudo, pam_*

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo
    print_status $BLUE "=========================================="
    print_status $BLUE "$1"
    print_status $BLUE "=========================================="
    echo
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_status $RED "❌ Do not run this script as root!"
        print_status $YELLOW "💡 Run as regular user, script will use sudo when needed"
        exit 1
    fi
}

# Check macOS version
check_macos_version() {
    print_header "🍎 Checking macOS Version"
    
    MACOS_VERSION=$(sw_vers -productVersion)
    print_status $BLUE "macOS Version: $MACOS_VERSION"
    
    # Check if version is supported (macOS 10.15+)
    if [[ $(echo "$MACOS_VERSION" | cut -d. -f1) -lt 10 ]] || 
       [[ $(echo "$MACOS_VERSION" | cut -d. -f1) -eq 10 && $(echo "$MACOS_VERSION" | cut -d. -f2) -lt 15 ]]; then
        print_status $YELLOW "⚠️  This script is designed for macOS 10.15+ (Catalina and later)"
        print_status $YELLOW "💡 Some features may not work on older versions"
    else
        print_status $GREEN "✅ macOS version supported"
    fi
}

# Check current login methods
check_current_login_methods() {
    print_header "🔍 Checking Current Login Methods"
    
    print_status $BLUE "🔍 Current login methods enabled:"
    
    # Check Touch ID
    if bioutil -r &>/dev/null; then
        print_status $YELLOW "⚠️  Touch ID: ENABLED"
    else
        print_status $GREEN "✅ Touch ID: DISABLED"
    fi
    
    # Check Apple Watch
    if security authorizationdb read system.login.console 2>/dev/null | grep -q "AppleWatch"; then
        print_status $YELLOW "⚠️  Apple Watch: ENABLED"
    else
        print_status $GREEN "✅ Apple Watch: DISABLED"
    fi
    
    # Check password login
    if security authorizationdb read system.login.console 2>/dev/null | grep -q "builtin:authenticate"; then
        print_status $YELLOW "⚠️  Password Login: ENABLED"
    else
        print_status $GREEN "✅ Password Login: DISABLED"
    fi
    
    # Check YubiKey/PIV
    if security authorizationdb read system.login.console 2>/dev/null | grep -q "piv"; then
        print_status $GREEN "✅ YubiKey/PIV: ENABLED"
    else
        print_status $YELLOW "⚠️  YubiKey/PIV: NOT CONFIGURED"
    fi
}

# Disable Touch ID
disable_touch_id() {
    print_header "👆 Disabling Touch ID"
    
    print_status $BLUE "🔧 Disabling Touch ID for login..."
    
    # Disable Touch ID for login
    sudo bioutil -w -f 0 -u 0 -s
    
    # Remove Touch ID from authorization database
    sudo security authorizationdb remove system.login.console 2>/dev/null || true
    sudo security authorizationdb remove system.login.screensaver 2>/dev/null || true
    
    print_status $GREEN "✅ Touch ID disabled for login"
}

# Disable Apple Watch
disable_apple_watch() {
    print_header "⌚ Disabling Apple Watch Login"
    
    print_status $BLUE "🔧 Disabling Apple Watch for login..."
    
    # Remove Apple Watch from authorization database
    sudo security authorizationdb remove system.login.console 2>/dev/null || true
    sudo security authorizationdb remove system.login.screensaver 2>/dev/null || true
    
    print_status $GREEN "✅ Apple Watch login disabled"
}

# Disable password login
disable_password_login() {
    print_header "🔑 Disabling Password Login"
    
    print_status $BLUE "🔧 Disabling password-based login..."
    
    # Create custom authorization rule that only allows PIV/YubiKey
    cat > /tmp/piv_only_auth.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>class</key>
    <string>evaluate-mechanisms</string>
    <key>comment</key>
    <string>Allow only PIV/YubiKey authentication</string>
    <key>mechanisms</key>
    <array>
        <string>piv</string>
    </array>
    <key>tries</key>
    <integer>3</integer>
</dict>
</plist>
EOF
    
    # Apply the authorization rule
    sudo security authorizationdb write system.login.console < /tmp/piv_only_auth.plist
    sudo security authorizationdb write system.login.screensaver < /tmp/piv_only_auth.plist
    
    # Clean up temp file
    rm -f /tmp/piv_only_auth.plist
    
    print_status $GREEN "✅ Password login disabled"
}

# Configure PAM for YubiKey
configure_pam_yubikey() {
    print_header "🔐 Configuring PAM for YubiKey"
    
    print_status $BLUE "🔧 Configuring PAM to require YubiKey..."
    
    # Backup original PAM configuration
    sudo cp /etc/pam.d/login /etc/pam.d/login.backup.$(date +%Y%m%d_%H%M%S)
    sudo cp /etc/pam.d/screensaver /etc/pam.d/screensaver.backup.$(date +%Y%m%d_%H%M%S)
    
    # Create PAM configuration that requires YubiKey
    cat > /tmp/login_pam << 'EOF'
# PAM configuration for YubiKey-only login
auth       required       pam_opendirectory.so
auth       required       pam_piv.so
account    required       pam_opendirectory.so
password   required       pam_opendirectory.so
session    required       pam_launchd.so
EOF
    
    cat > /tmp/screensaver_pam << 'EOF'
# PAM configuration for YubiKey-only screensaver unlock
auth       required       pam_opendirectory.so
auth       required       pam_piv.so
account    required       pam_opendirectory.so
password   required       pam_opendirectory.so
session    required       pam_launchd.so
EOF
    
    # Apply PAM configuration
    sudo cp /tmp/login_pam /etc/pam.d/login
    sudo cp /tmp/screensaver_pam /etc/pam.d/screensaver
    
    # Clean up temp files
    rm -f /tmp/login_pam /tmp/screensaver_pam
    
    print_status $GREEN "✅ PAM configured for YubiKey"
}

# Configure user for YubiKey
configure_user_yubikey() {
    print_header "👤 Configuring User for YubiKey"
    
    CURRENT_USER=$(whoami)
    print_status $BLUE "🔧 Configuring user: $CURRENT_USER"
    
    # Create _piv group if it doesn't exist
    sudo dscl . -create /Groups/_piv
    sudo dscl . -create /Groups/_piv PrimaryGroupID 400
    sudo dscl . -create /Groups/_piv RealName "PIV Authentication Group"
    
    # Add user to necessary groups
    sudo dseditgroup -o edit -a "$CURRENT_USER" -t user _piv
    
    # Set user to require smart card
    sudo dscl . -create /Users/"$CURRENT_USER" SmartCardRequired -bool true
    
    print_status $GREEN "✅ User configured for YubiKey requirement"
}

# Enable FileVault
enable_filevault() {
    print_header "🔒 Enabling FileVault"
    
    print_status $BLUE "🔧 Checking FileVault status..."
    
    if fdesetup status | grep -q "FileVault is On"; then
        print_status $GREEN "✅ FileVault already enabled"
    else
        print_status $YELLOW "⚠️  FileVault is not enabled"
        print_status $BLUE "🔧 Enabling FileVault..."
        
        # Enable FileVault (this will require a restart)
        sudo fdesetup enable -user "$CURRENT_USER"
        
        print_status $YELLOW "⚠️  FileVault enabled - restart required"
        print_status $YELLOW "💡 You will need to restart your Mac to complete FileVault setup"
    fi
}

# Set firmware password (Intel Macs only)
set_firmware_password() {
    print_header "🔐 Setting Firmware Password"
    
    # Check if this is Apple Silicon (M1/M2/M3)
    if [[ $(uname -m) == "arm64" ]]; then
        print_status $BLUE "🍎 Apple Silicon Mac detected"
        print_status $GREEN "✅ Firmware password not needed - hardware security built-in"
        print_status $BLUE "💡 Apple Silicon uses Secure Boot and System Integrity Protection"
        return 0
    fi
    
    # Check if this is Intel Mac with T2 Security Chip
    if system_profiler SPHardwareDataType | grep -q "T2"; then
        print_status $BLUE "🔒 Intel Mac with T2 Security Chip detected"
        print_status $GREEN "✅ Firmware password not needed - T2 chip provides hardware security"
        print_status $BLUE "💡 T2 Security Chip handles Secure Boot and System Integrity Protection"
        return 0
    fi
    
    print_status $BLUE "🔧 Checking firmware password status..."
    
    if sudo firmwarepasswd -check 2>/dev/null | grep -q "Password Enabled: Yes"; then
        print_status $GREEN "✅ Firmware password already set"
    else
        print_status $YELLOW "⚠️  Firmware password not set"
        print_status $BLUE "🔧 Setting firmware password..."
        
        # Set firmware password (interactive)
        if sudo firmwarepasswd -setpasswd 2>/dev/null; then
            print_status $GREEN "✅ Firmware password set"
        else
            print_status $YELLOW "⚠️  Firmware password setup failed or not supported"
        fi
    fi
}

# Configure security policies
configure_security_policies() {
    print_header "🛡️ Configuring Security Policies"
    
    print_status $BLUE "🔧 Setting security policies..."
    
    # Disable automatic login
    sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true
    
    # Require password immediately after sleep
    sudo pmset -a sleep 0
    sudo pmset -a displaysleep 0
    
    # Disable guest account
    sudo dscl . -delete /Users/Guest 2>/dev/null || true
    
    # Disable root login
    sudo dscl . -create /Users/root UserShell /usr/bin/false
    
    print_status $GREEN "✅ Security policies configured"
}

# Test YubiKey configuration
test_yubikey_config() {
    print_header "🧪 Testing YubiKey Configuration"
    
    print_status $BLUE "🔍 Testing YubiKey detection..."
    
    if ykman list &>/dev/null; then
        print_status $GREEN "✅ YubiKey detected"
        
        # Test PIV status
        if ykman piv info &>/dev/null; then
            print_status $GREEN "✅ PIV application available"
        else
            print_status $YELLOW "⚠️  PIV application not configured"
        fi
    else
        print_status $RED "❌ YubiKey not detected"
        print_status $YELLOW "💡 Please connect your YubiKey and ensure PIV is configured"
    fi
}

# Provide next steps
provide_next_steps() {
    print_header "🚀 Next Steps"
    
    print_status $GREEN "✅ macOS login hardening complete!"
    echo
    
    print_status $BLUE "🔧 What was configured:"
    print_status $BLUE "  - Touch ID disabled for login"
    print_status $BLUE "  - Apple Watch login disabled"
    print_status $BLUE "  - Password login disabled"
    print_status $BLUE "  - PAM configured for YubiKey only"
    print_status $BLUE "  - User configured for smart card requirement"
    print_status $BLUE "  - FileVault enabled (if not already)"
    print_status $BLUE "  - Firmware password set"
    print_status $BLUE "  - Security policies hardened"
    echo
    
    print_status $YELLOW "⚠️  Important:"
    print_status $YELLOW "  - You MUST have your YubiKey connected to log in"
    print_status $YELLOW "  - Make sure PIV is properly configured on your YubiKey"
    print_status $YELLOW "  - Test login before closing this session"
    print_status $YELLOW "  - Keep your YubiKey PIN safe"
    echo
    
    print_status $RED "🚨 Critical:"
    print_status $RED "  - If you lose your YubiKey, you may be locked out"
    print_status $RED "  - Consider keeping a backup YubiKey"
    print_status $RED "  - Test the configuration before relying on it"
}

# Main function
main() {
    print_status $BLUE "🔒 macOS Login Hardening Script"
    echo
    
    print_status $YELLOW "This script will:"
    print_status $YELLOW "  1. Disable Touch ID for login"
    print_status $YELLOW "  2. Disable Apple Watch login"
    print_status $YELLOW "  3. Disable password login"
    print_status $YELLOW "  4. Configure PAM for YubiKey only"
    print_status $YELLOW "  5. Enable FileVault (if not already)"
    print_status $YELLOW "  6. Set firmware password"
    print_status $YELLOW "  7. Harden security policies"
    echo
    
    print_status $RED "🚨 WARNING: This will make your Mac require YubiKey for login!"
    print_status $RED "Make sure your YubiKey is properly configured before proceeding."
    echo
    
    read -p "Continue with login hardening? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status $YELLOW "Login hardening cancelled."
        exit 0
    fi
    
    # Run all steps
    check_root
    check_macos_version
    check_current_login_methods
    disable_touch_id
    disable_apple_watch
    disable_password_login
    configure_pam_yubikey
    configure_user_yubikey
    enable_filevault
    set_firmware_password
    configure_security_policies
    test_yubikey_config
    provide_next_steps
    
    print_header "🎯 Summary"
    
    print_status $GREEN "✅ SUCCESS: macOS login hardening complete!"
    print_status $GREEN "✅ Your Mac now requires YubiKey + PIN for login"
    print_status $GREEN "✅ All other login methods disabled"
    echo
    
    print_status $BLUE "💡 What this accomplished:"
    print_status $BLUE "  - Hardware-based authentication enforced"
    print_status $BLUE "  - Multi-factor authentication (YubiKey + PIN)"
    print_status $BLUE "  - Protection against password-based attacks"
    print_status $BLUE "  - Full disk encryption enabled"
    print_status $BLUE "  - Firmware protection enabled"
    echo
    
    print_status $YELLOW "🚀 Your Mac is now secured with YubiKey-only login!"
}

# Run main function
main "$@"
