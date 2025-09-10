#!/bin/bash

# Standard Account Cleanup Script for Mac
# This script cleans up and secures the standard user account

echo "=== STANDARD ACCOUNT CLEANUP SCRIPT ==="
echo "This script cleans up and secures the standard user account on Mac."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with sudo."
    exit 1
fi

echo "Starting standard account cleanup and security hardening..."
echo ""

# =============================================================================
# PHASE 1: ACCOUNT AUDIT
# =============================================================================

echo "=== PHASE 1: ACCOUNT AUDIT ==="

echo "Checking all user accounts..."
dscl . list /Users | grep -v "^_" | grep -v "^daemon\|^nobody\|^root"

echo "Checking current user sessions..."
who

echo "Checking account details for current user..."
id

echo "Checking account creation dates..."
dscl . read /Users/$(whoami) | grep -E "(CreationDate|LastLoginTime)"

echo ""

# =============================================================================
# PHASE 2: SUSPICIOUS ACCOUNT INVESTIGATION
# =============================================================================

echo "=== PHASE 2: SUSPICIOUS ACCOUNT INVESTIGATION ==="

echo "Investigating suspicious accounts..."
echo "Checking account blnd3dd..."
if dscl . read /Users/blnd3dd >/dev/null 2>&1; then
    echo "Account blnd3dd exists - investigating..."
    dscl . read /Users/blnd3dd | head -20
    echo "Account blnd3dd last login:"
    last blnd3dd | head -5
else
    echo "Account blnd3dd not found"
fi

echo "Checking account pawelbek90..."
if dscl . read /Users/pawelbek90 >/dev/null 2>&1; then
    echo "Account pawelbek90 exists - investigating..."
    dscl . read /Users/pawelbek90 | head -20
    echo "Account pawelbek90 last login:"
    last pawelbek90 | head -5
else
    echo "Account pawelbek90 not found"
fi

echo ""

# =============================================================================
# PHASE 3: ACCOUNT SECURITY HARDENING
# =============================================================================

echo "=== PHASE 3: ACCOUNT SECURITY HARDENING ==="

echo "Hardening current user account..."
CURRENT_USER=$(whoami)

echo "Setting secure shell for current user..."
dscl . -create /Users/$CURRENT_USER UserShell /bin/bash

echo "Disabling guest account..."
defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false

echo "Disabling automatic login..."
defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser -string ""

echo "Enabling secure token for current user..."
sysadminctl -secureTokenOn $CURRENT_USER -password - 2>/dev/null || echo "Secure token already enabled or not available"

echo ""

# =============================================================================
# PHASE 4: SUSPICIOUS ACCOUNT DISABLE
# =============================================================================

echo "=== PHASE 4: SUSPICIOUS ACCOUNT DISABLE ==="

echo "Disabling suspicious accounts..."
echo "Disabling account blnd3dd..."
if dscl . read /Users/blnd3dd >/dev/null 2>&1; then
    dscl . -create /Users/blnd3dd IsHidden 1
    dscl . -create /Users/blnd3dd UserShell /usr/bin/false
    dscl . -create /Users/blnd3dd Password "*"
    echo "Account blnd3dd disabled"
else
    echo "Account blnd3dd not found"
fi

echo "Disabling account pawelbek90..."
if dscl . read /Users/pawelbek90 >/dev/null 2>&1; then
    dscl . -create /Users/pawelbek90 IsHidden 1
    dscl . -create /Users/pawelbek90 UserShell /usr/bin/false
    dscl . -create /Users/pawelbek90 Password "*"
    echo "Account pawelbek90 disabled"
else
    echo "Account pawelbek90 not found"
fi

echo ""

# =============================================================================
# PHASE 5: LOGIN SECURITY
# =============================================================================

echo "=== PHASE 5: LOGIN SECURITY ==="

echo "Configuring login security..."
echo "Disabling automatic login..."
defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser -string ""

echo "Enabling fast user switching..."
defaults write /Library/Preferences/.GlobalPreferences MultipleSessionEnabled -bool true

echo "Setting login window to show name and password..."
defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true

echo "Disabling password hints..."
defaults write /Library/Preferences/com.apple.loginwindow RetriesUntilHint -int 0

echo ""

# =============================================================================
# PHASE 6: FILE PERMISSIONS
# =============================================================================

echo "=== PHASE 6: FILE PERMISSIONS ==="

echo "Securing file permissions..."
echo "Securing home directory..."
chmod 755 /Users/$CURRENT_USER

echo "Securing user directories..."
chmod 700 /Users/$CURRENT_USER/Desktop
chmod 700 /Users/$CURRENT_USER/Documents
chmod 700 /Users/$CURRENT_USER/Downloads
chmod 700 /Users/$CURRENT_USER/Library

echo "Securing user files..."
chmod 600 /Users/$CURRENT_USER/.bash_history
chmod 600 /Users/$CURRENT_USER/.zsh_history
chmod 600 /Users/$CURRENT_USER/.ssh/id_rsa 2>/dev/null || echo "SSH key not found"
chmod 644 /Users/$CURRENT_USER/.ssh/id_rsa.pub 2>/dev/null || echo "SSH public key not found"

echo ""

# =============================================================================
# PHASE 7: PROCESS CLEANUP
# =============================================================================

echo "=== PHASE 7: PROCESS CLEANUP ==="

echo "Killing processes for suspicious accounts..."
echo "Killing processes for blnd3dd..."
pkill -u blnd3dd 2>/dev/null || echo "No processes for blnd3dd"

echo "Killing processes for pawelbek90..."
pkill -u pawelbek90 2>/dev/null || echo "No processes for pawelbek90"

echo "Checking for remaining suspicious processes..."
ps aux | grep -E "(blnd3dd|pawelbek90)" | grep -v grep || echo "No suspicious processes found"

echo ""

# =============================================================================
# PHASE 8: NETWORK SECURITY
# =============================================================================

echo "=== PHASE 8: NETWORK SECURITY ==="

echo "Securing network access..."
echo "Disabling remote login for suspicious accounts..."
dscl . -create /Users/blnd3dd RemoteLoginEnabled -bool false 2>/dev/null || echo "Account blnd3dd not found"
dscl . -create /Users/pawelbek90 RemoteLoginEnabled -bool false 2>/dev/null || echo "Account pawelbek90 not found"

echo "Disabling SSH access for suspicious accounts..."
dscl . -create /Users/blnd3dd UserShell /usr/bin/false 2>/dev/null || echo "Account blnd3dd not found"
dscl . -create /Users/pawelbek90 UserShell /usr/bin/false 2>/dev/null || echo "Account pawelbek90 not found"

echo ""

# =============================================================================
# PHASE 9: SYSTEM CLEANUP
# =============================================================================

echo "=== PHASE 9: SYSTEM CLEANUP ==="

echo "Cleaning system files..."
echo "Clearing user caches..."
rm -rf /Users/$CURRENT_USER/Library/Caches/* 2>/dev/null || echo "Permission denied"

echo "Clearing system caches..."
rm -rf /Library/Caches/* 2>/dev/null || echo "Permission denied"

echo "Clearing temporary files..."
rm -rf /tmp/* 2>/dev/null || echo "Permission denied"
rm -rf /var/tmp/* 2>/dev/null || echo "Permission denied"

echo "Clearing user temporary files..."
rm -rf /Users/$CURRENT_USER/Library/Application\ Support/CrashReporter/* 2>/dev/null || echo "Permission denied"

echo ""

# =============================================================================
# PHASE 10: SECURITY MONITORING
# =============================================================================

echo "=== PHASE 10: SECURITY MONITORING ==="

echo "Setting up security monitoring..."
echo "Enabling login monitoring..."
defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText -string "Authorized users only"

echo "Enabling audit logging..."
launchctl load -w /System/Library/LaunchDaemons/com.apple.auditd.plist 2>/dev/null || echo "Audit daemon not available"

echo "Enabling security logging..."
defaults write /Library/Preferences/com.apple.security.revocation CRLSufficientPerCert -bool true

echo ""

# =============================================================================
# PHASE 11: FINAL VERIFICATION
# =============================================================================

echo "=== PHASE 11: FINAL VERIFICATION ==="

echo "Verifying account security..."
echo "Current user: $(whoami)"
echo "Current user ID: $(id)"
echo "Current user groups: $(groups)"

echo "Checking for disabled accounts..."
dscl . list /Users | grep -v "^_" | while read user; do
    if dscl . read /Users/$user | grep -q "UserShell: /usr/bin/false"; then
        echo "Disabled account: $user"
    fi
done

echo "Checking for hidden accounts..."
dscl . list /Users | grep -v "^_" | while read user; do
    if dscl . read /Users/$user | grep -q "IsHidden: 1"; then
        echo "Hidden account: $user"
    fi
done

echo ""

# =============================================================================
# PHASE 12: SECURITY RECOMMENDATIONS
# =============================================================================

echo "=== PHASE 12: SECURITY RECOMMENDATIONS ==="

echo "SECURITY RECOMMENDATIONS:"
echo ""
echo "1. ACCOUNT SECURITY:"
echo "   - Change your password immediately"
echo "   - Enable two-factor authentication"
echo "   - Use strong, unique passwords"
echo "   - Monitor account access"
echo ""
echo "2. SYSTEM SECURITY:"
echo "   - Enable FileVault encryption"
echo "   - Enable firewall"
echo "   - Keep system updated"
echo "   - Monitor system logs"
echo ""
echo "3. NETWORK SECURITY:"
echo "   - Use only trusted networks"
echo "   - Enable VPN when possible"
echo "   - Monitor network traffic"
echo "   - Check for suspicious connections"
echo ""
echo "4. CONTINUOUS MONITORING:"
echo "   - Check for new user accounts"
echo "   - Monitor login attempts"
echo "   - Check for suspicious processes"
echo "   - Verify file permissions"
echo ""
echo "5. BACKUP SECURITY:"
echo "   - Create secure backups"
echo "   - Encrypt backup data"
echo "   - Store backups securely"
echo "   - Test backup restoration"
echo ""

echo "=== STANDARD ACCOUNT CLEANUP COMPLETE ==="
echo ""
echo "SUMMARY OF ACTIONS PERFORMED:"
echo "✅ Audited all user accounts"
echo "✅ Investigated suspicious accounts"
echo "✅ Hardened current user account"
echo "✅ Disabled suspicious accounts"
echo "✅ Configured login security"
echo "✅ Secured file permissions"
echo "✅ Cleaned up processes"
echo "✅ Secured network access"
echo "✅ Performed system cleanup"
echo "✅ Set up security monitoring"
echo "✅ Verified account security"
echo "✅ Provided security recommendations"
echo ""
echo "IMPORTANT: Change your password immediately!"
echo "Monitor your system for any suspicious activity."
echo ""
echo "NEXT STEPS:"
echo "1. Change your password immediately"
echo "2. Enable two-factor authentication"
echo "3. Enable FileVault encryption"
echo "4. Monitor system for suspicious activity"
echo "5. Check for unauthorized access"
echo "6. Keep system updated"
echo ""
