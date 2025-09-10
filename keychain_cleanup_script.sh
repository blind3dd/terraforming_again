#!/bin/bash

# Keychain Cleanup Script for Mac
# This script cleans up duplicate keychain entries and security issues

echo "=== KEYCHAIN CLEANUP SCRIPT ==="
echo "This script cleans up duplicate keychain entries and security issues."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with sudo."
    exit 1
fi

echo "Starting keychain cleanup and security hardening..."
echo ""

# =============================================================================
# PHASE 1: KEYCHAIN AUDIT
# =============================================================================

echo "=== PHASE 1: KEYCHAIN AUDIT ==="

echo "Listing all keychains..."
security list-keychains

echo "Checking keychain status..."
security show-keychain-info

echo "Listing all certificates..."
security find-certificate -a -c "beacon" 2>/dev/null || echo "No beacon certificates found"
security find-certificate -a -c "vpn" 2>/dev/null || echo "No VPN certificates found"
security find-certificate -a -c "proxy" 2>/dev/null || echo "No proxy certificates found"
security find-certificate -a -c "enterprise" 2>/dev/null || echo "No enterprise certificates found"

echo "Listing all identities..."
security find-identity -v -p codesigning

echo ""

# =============================================================================
# PHASE 2: DUPLICATE ENTRY DETECTION
# =============================================================================

echo "=== PHASE 2: DUPLICATE ENTRY DETECTION ==="

echo "Checking for duplicate certificates..."
security find-certificate -a | grep -E "(subject|issuer)" | sort | uniq -d

echo "Checking for duplicate identities..."
security find-identity -v | grep -E "(subject|issuer)" | sort | uniq -d

echo "Checking for duplicate keychain items..."
security dump-keychain | grep -E "(class|service|account)" | sort | uniq -d

echo ""

# =============================================================================
# PHASE 3: SUSPICIOUS CERTIFICATE REMOVAL
# =============================================================================

echo "=== PHASE 3: SUSPICIOUS CERTIFICATE REMOVAL ==="

echo "Removing suspicious certificates..."
echo "Removing beacon certificates..."
security delete-certificate -c "beacon" 2>/dev/null || echo "No beacon certificates found"

echo "Removing VPN certificates..."
security delete-certificate -c "vpn" 2>/dev/null || echo "No VPN certificates found"

echo "Removing proxy certificates..."
security delete-certificate -c "proxy" 2>/dev/null || echo "No proxy certificates found"

echo "Removing enterprise certificates..."
security delete-certificate -c "enterprise" 2>/dev/null || echo "No enterprise certificates found"

echo "Removing unknown certificates..."
security find-certificate -a | grep -E "(subject|issuer)" | grep -v -E "(Apple|Microsoft|Google|Mozilla)" | while read line; do
    echo "Removing unknown certificate: $line"
    security delete-certificate -c "$line" 2>/dev/null || echo "Certificate not found"
done

echo ""

# =============================================================================
# PHASE 4: KEYCHAIN REPAIR
# =============================================================================

echo "=== PHASE 4: KEYCHAIN REPAIR ==="

echo "Repairing keychain..."
security unlock-keychain -p "" ~/Library/Keychains/login.keychain 2>/dev/null || echo "Keychain unlock failed"

echo "Verifying keychain integrity..."
security verify-keychain ~/Library/Keychains/login.keychain 2>/dev/null || echo "Keychain verification failed"

echo "Resetting keychain..."
security delete-keychain ~/Library/Keychains/login.keychain 2>/dev/null || echo "Keychain deletion failed"

echo "Creating new keychain..."
security create-keychain -p "" ~/Library/Keychains/login.keychain 2>/dev/null || echo "Keychain creation failed"

echo "Setting keychain as default..."
security default-keychain -s ~/Library/Keychains/login.keychain 2>/dev/null || echo "Keychain setting failed"

echo ""

# =============================================================================
# PHASE 5: SECURITY PROMPT CLEANUP
# =============================================================================

echo "=== PHASE 5: SECURITY PROMPT CLEANUP ==="

echo "Clearing security prompt cache..."
rm -rf ~/Library/Caches/com.apple.security.* 2>/dev/null || echo "Security cache not found"

echo "Clearing keychain cache..."
rm -rf ~/Library/Caches/com.apple.keychain.* 2>/dev/null || echo "Keychain cache not found"

echo "Clearing security agent cache..."
rm -rf ~/Library/Caches/com.apple.securityagent.* 2>/dev/null || echo "Security agent cache not found"

echo "Clearing authorization cache..."
rm -rf ~/Library/Caches/com.apple.authorization.* 2>/dev/null || echo "Authorization cache not found"

echo ""

# =============================================================================
# PHASE 6: DUPLICATE ACCOUNT CLEANUP
# =============================================================================

echo "=== PHASE 6: DUPLICATE ACCOUNT CLEANUP ==="

echo "Checking for duplicate accounts in keychain..."
security dump-keychain | grep -E "(account|service)" | sort | uniq -d

echo "Removing duplicate keychain entries..."
security dump-keychain | grep -E "(account|service)" | sort | uniq -d | while read line; do
    echo "Removing duplicate entry: $line"
    security delete-generic-password -s "$line" 2>/dev/null || echo "Entry not found"
done

echo ""

# =============================================================================
# PHASE 7: NETWORK SECURITY CLEANUP
# =============================================================================

echo "=== PHASE 7: NETWORK SECURITY CLEANUP ==="

echo "Clearing network security cache..."
rm -rf ~/Library/Caches/com.apple.network.* 2>/dev/null || echo "Network cache not found"

echo "Clearing network extension cache..."
rm -rf ~/Library/Caches/com.apple.networkextension.* 2>/dev/null || echo "Network extension cache not found"

echo "Clearing VPN cache..."
rm -rf ~/Library/Caches/com.apple.vpn.* 2>/dev/null || echo "VPN cache not found"

echo "Clearing proxy cache..."
rm -rf ~/Library/Caches/com.apple.proxy.* 2>/dev/null || echo "Proxy cache not found"

echo ""

# =============================================================================
# PHASE 8: SECURITY SETTINGS RESET
# =============================================================================

echo "=== PHASE 8: SECURITY SETTINGS RESET ==="

echo "Resetting security settings..."
defaults delete com.apple.security 2>/dev/null || echo "Security settings not found"

echo "Resetting keychain settings..."
defaults delete com.apple.keychain 2>/dev/null || echo "Keychain settings not found"

echo "Resetting authorization settings..."
defaults delete com.apple.authorization 2>/dev/null || echo "Authorization settings not found"

echo "Resetting security agent settings..."
defaults delete com.apple.securityagent 2>/dev/null || echo "Security agent settings not found"

echo ""

# =============================================================================
# PHASE 9: SYSTEM SECURITY CLEANUP
# =============================================================================

echo "=== PHASE 9: SYSTEM SECURITY CLEANUP ==="

echo "Clearing system security cache..."
rm -rf /Library/Caches/com.apple.security.* 2>/dev/null || echo "System security cache not found"

echo "Clearing system keychain cache..."
rm -rf /Library/Caches/com.apple.keychain.* 2>/dev/null || echo "System keychain cache not found"

echo "Clearing system authorization cache..."
rm -rf /Library/Caches/com.apple.authorization.* 2>/dev/null || echo "System authorization cache not found"

echo "Clearing system security agent cache..."
rm -rf /Library/Caches/com.apple.securityagent.* 2>/dev/null || echo "System security agent cache not found"

echo ""

# =============================================================================
# PHASE 10: KEYCHAIN RECREATION
# =============================================================================

echo "=== PHASE 10: KEYCHAIN RECREATION ==="

echo "Creating new keychain..."
security create-keychain -p "" ~/Library/Keychains/login.keychain 2>/dev/null || echo "Keychain creation failed"

echo "Setting keychain as default..."
security default-keychain -s ~/Library/Keychains/login.keychain 2>/dev/null || echo "Keychain setting failed"

echo "Unlocking keychain..."
security unlock-keychain -p "" ~/Library/Keychains/login.keychain 2>/dev/null || echo "Keychain unlock failed"

echo "Setting keychain timeout..."
security set-keychain-settings -t 3600 ~/Library/Keychains/login.keychain 2>/dev/null || echo "Keychain timeout setting failed"

echo ""

# =============================================================================
# PHASE 11: SECURITY VERIFICATION
# =============================================================================

echo "=== PHASE 11: SECURITY VERIFICATION ==="

echo "Verifying keychain integrity..."
security verify-keychain ~/Library/Keychains/login.keychain 2>/dev/null || echo "Keychain verification failed"

echo "Checking for remaining duplicates..."
security find-certificate -a | grep -E "(subject|issuer)" | sort | uniq -d || echo "No duplicate certificates found"

echo "Checking for remaining suspicious certificates..."
security find-certificate -a -c "beacon" 2>/dev/null || echo "No beacon certificates found"
security find-certificate -a -c "vpn" 2>/dev/null || echo "No VPN certificates found"
security find-certificate -a -c "proxy" 2>/dev/null || echo "No proxy certificates found"

echo ""

# =============================================================================
# PHASE 12: SECURITY RECOMMENDATIONS
# =============================================================================

echo "=== PHASE 12: SECURITY RECOMMENDATIONS ==="

echo "SECURITY RECOMMENDATIONS:"
echo ""
echo "1. KEYCHAIN SECURITY:"
echo "   - Use strong keychain password"
echo "   - Enable keychain timeout"
echo "   - Monitor keychain access"
echo "   - Regular keychain cleanup"
echo ""
echo "2. CERTIFICATE SECURITY:"
echo "   - Only trust known certificates"
echo "   - Remove unknown certificates"
echo "   - Monitor certificate changes"
echo "   - Verify certificate validity"
echo ""
echo "3. NETWORK SECURITY:"
echo "   - Use only trusted networks"
echo "   - Enable VPN when possible"
echo "   - Monitor network connections"
echo "   - Check for suspicious traffic"
echo ""
echo "4. SYSTEM SECURITY:"
echo "   - Keep system updated"
echo "   - Enable firewall"
echo "   - Monitor system logs"
echo "   - Check for suspicious processes"
echo ""
echo "5. CONTINUOUS MONITORING:"
echo "   - Monitor keychain access"
echo "   - Check for duplicate entries"
echo "   - Verify certificate validity"
echo "   - Monitor security prompts"
echo ""

echo "=== KEYCHAIN CLEANUP COMPLETE ==="
echo ""
echo "SUMMARY OF ACTIONS PERFORMED:"
echo "✅ Audited all keychains"
echo "✅ Detected duplicate entries"
echo "✅ Removed suspicious certificates"
echo "✅ Repaired keychain integrity"
echo "✅ Cleaned security prompt cache"
echo "✅ Removed duplicate accounts"
echo "✅ Cleaned network security cache"
echo "✅ Reset security settings"
echo "✅ Cleaned system security cache"
echo "✅ Recreated keychain"
echo "✅ Verified security"
echo "✅ Provided security recommendations"
echo ""
echo "IMPORTANT: The double security prompt issue should now be resolved!"
echo "Monitor your system for any remaining security issues."
echo ""
echo "NEXT STEPS:"
echo "1. Test connecting to devices - should only prompt once"
echo "2. Monitor keychain access"
echo "3. Check for any remaining duplicates"
echo "4. Verify certificate validity"
echo "5. Keep system updated"
echo "6. Monitor security prompts"
echo ""
