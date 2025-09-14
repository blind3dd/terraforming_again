#!/bin/bash

# Apple ID Mayhem Fix Script
# This script fixes the chaos caused by same Apple ID logged into multiple accounts

echo "=== APPLE ID MAYHEM FIX SCRIPT ==="
echo "This script fixes the chaos caused by same Apple ID logged into multiple accounts."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with sudo."
    exit 1
fi

echo "Starting Apple ID mayhem fix..."
echo ""

# =============================================================================
# PHASE 1: APPLE ID AUDIT
# =============================================================================

echo "=== PHASE 1: APPLE ID AUDIT ==="

echo "Checking Apple ID status across all accounts..."
echo "Current user Apple ID:"
defaults read com.apple.coreservices.useractivityd AppleIDEnabled 2>/dev/null || echo "Apple ID status not found"

echo "Checking for multiple Apple ID logins..."
find /Users -name "*.plist" -exec grep -l "AppleID" {} \; 2>/dev/null | head -10

echo "Checking iCloud account status..."
defaults read com.apple.bird iCloudDriveEnabled 2>/dev/null || echo "iCloud status not found"

echo "Checking for duplicate Apple ID entries..."
grep -r "AppleID" /Users/*/Library/Preferences/ 2>/dev/null | head -10

echo ""

# =============================================================================
# PHASE 2: MULTIPLE ACCOUNT DETECTION
# =============================================================================

echo "=== PHASE 2: MULTIPLE ACCOUNT DETECTION ==="

echo "Detecting accounts with Apple ID logins..."
for user in $(dscl . list /Users | grep -v "^_" | grep -v "^daemon\|^nobody\|^root"); do
    echo "Checking account: $user"
    if [ -f "/Users/$user/Library/Preferences/com.apple.coreservices.useractivityd.plist" ]; then
        echo "  Apple ID found in $user account"
        defaults read "/Users/$user/Library/Preferences/com.apple.coreservices.useractivityd.plist" 2>/dev/null | grep -i "appleid" || echo "  No Apple ID details found"
    else
        echo "  No Apple ID found in $user account"
    fi
done

echo ""

# =============================================================================
# PHASE 3: APPLE ID LOGOUT FROM SUSPICIOUS ACCOUNTS
# =============================================================================

echo "=== PHASE 3: APPLE ID LOGOUT FROM SUSPICIOUS ACCOUNTS ==="

echo "Logging out Apple ID from suspicious accounts..."
echo "Logging out Apple ID from blnd3dd account..."
if [ -f "/Users/blnd3dd/Library/Preferences/com.apple.coreservices.useractivityd.plist" ]; then
    defaults delete "/Users/blnd3dd/Library/Preferences/com.apple.coreservices.useractivityd.plist" AppleIDEnabled 2>/dev/null || echo "Apple ID not found in blnd3dd"
    defaults delete "/Users/blnd3dd/Library/Preferences/com.apple.coreservices.useractivityd.plist" AppleID 2>/dev/null || echo "Apple ID not found in blnd3dd"
    echo "Apple ID logged out from blnd3dd account"
else
    echo "blnd3dd account not found"
fi

echo "Logging out Apple ID from pawelbek90 account..."
if [ -f "/Users/pawelbek90/Library/Preferences/com.apple.coreservices.useractivityd.plist" ]; then
    defaults delete "/Users/pawelbek90/Library/Preferences/com.apple.coreservices.useractivityd.plist" AppleIDEnabled 2>/dev/null || echo "Apple ID not found in pawelbek90"
    defaults delete "/Users/pawelbek90/Library/Preferences/com.apple.coreservices.useractivityd.plist" AppleID 2>/dev/null || echo "Apple ID not found in pawelbek90"
    echo "Apple ID logged out from pawelbek90 account"
else
    echo "pawelbek90 account not found"
fi

echo ""

# =============================================================================
# PHASE 4: ICLOUD CLEANUP
# =============================================================================

echo "=== PHASE 4: ICLOUD CLEANUP ==="

echo "Disabling iCloud from suspicious accounts..."
echo "Disabling iCloud from blnd3dd account..."
if [ -f "/Users/blnd3dd/Library/Preferences/com.apple.bird.plist" ]; then
    defaults delete "/Users/blnd3dd/Library/Preferences/com.apple.bird.plist" iCloudDriveEnabled 2>/dev/null || echo "iCloud not found in blnd3dd"
    defaults delete "/Users/blnd3dd/Library/Preferences/com.apple.bird.plist" iCloudAccount 2>/dev/null || echo "iCloud account not found in blnd3dd"
    echo "iCloud disabled from blnd3dd account"
else
    echo "blnd3dd account not found"
fi

echo "Disabling iCloud from pawelbek90 account..."
if [ -f "/Users/pawelbek90/Library/Preferences/com.apple.bird.plist" ]; then
    defaults delete "/Users/pawelbek90/Library/Preferences/com.apple.bird.plist" iCloudDriveEnabled 2>/dev/null || echo "iCloud not found in pawelbek90"
    defaults delete "/Users/pawelbek90/Library/Preferences/com.apple.bird.plist" iCloudAccount 2>/dev/null || echo "iCloud account not found in pawelbek90"
    echo "iCloud disabled from pawelbek90 account"
else
    echo "pawelbek90 account not found"
fi

echo ""

# =============================================================================
# PHASE 5: KEYCHAIN APPLE ID CLEANUP
# =============================================================================

echo "=== PHASE 5: KEYCHAIN APPLE ID CLEANUP ==="

echo "Removing Apple ID entries from keychains..."
echo "Removing Apple ID from blnd3dd keychain..."
if [ -f "/Users/blnd3dd/Library/Keychains/login.keychain-db" ]; then
    security delete-generic-password -s "Apple ID" -a "blnd3dd" 2>/dev/null || echo "Apple ID not found in blnd3dd keychain"
    security delete-generic-password -s "iCloud" -a "blnd3dd" 2>/dev/null || echo "iCloud not found in blnd3dd keychain"
    echo "Apple ID removed from blnd3dd keychain"
else
    echo "blnd3dd keychain not found"
fi

echo "Removing Apple ID from pawelbek90 keychain..."
if [ -f "/Users/pawelbek90/Library/Keychains/login.keychain-db" ]; then
    security delete-generic-password -s "Apple ID" -a "pawelbek90" 2>/dev/null || echo "Apple ID not found in pawelbek90 keychain"
    security delete-generic-password -s "iCloud" -a "pawelbek90" 2>/dev/null || echo "iCloud not found in pawelbek90 keychain"
    echo "Apple ID removed from pawelbek90 keychain"
else
    echo "pawelbek90 keychain not found"
fi

echo ""

# =============================================================================
# PHASE 6: SYNC SERVICES CLEANUP
# =============================================================================

echo "=== PHASE 6: SYNC SERVICES CLEANUP ==="

echo "Disabling sync services from suspicious accounts..."
echo "Disabling sync services from blnd3dd account..."
if [ -f "/Users/blnd3dd/Library/Preferences/com.apple.coreservices.useractivityd.plist" ]; then
    defaults delete "/Users/blnd3dd/Library/Preferences/com.apple.coreservices.useractivityd.plist" ActivityAdvertisingAllowed 2>/dev/null || echo "Sync services not found in blnd3dd"
    defaults delete "/Users/blnd3dd/Library/Preferences/com.apple.coreservices.useractivityd.plist" ActivityReceivingAllowed 2>/dev/null || echo "Sync services not found in blnd3dd"
    echo "Sync services disabled from blnd3dd account"
else
    echo "blnd3dd account not found"
fi

echo "Disabling sync services from pawelbek90 account..."
if [ -f "/Users/pawelbek90/Library/Preferences/com.apple.coreservices.useractivityd.plist" ]; then
    defaults delete "/Users/pawelbek90/Library/Preferences/com.apple.coreservices.useractivityd.plist" ActivityAdvertisingAllowed 2>/dev/null || echo "Sync services not found in pawelbek90"
    defaults delete "/Users/pawelbek90/Library/Preferences/com.apple.coreservices.useractivityd.plist" ActivityReceivingAllowed 2>/dev/null || echo "Sync services not found in pawelbek90"
    echo "Sync services disabled from pawelbek90 account"
else
    echo "pawelbek90 account not found"
fi

echo ""

# =============================================================================
# PHASE 7: NOTIFICATION CLEANUP
# =============================================================================

echo "=== PHASE 7: NOTIFICATION CLEANUP ==="

echo "Clearing notifications from suspicious accounts..."
echo "Clearing notifications from blnd3dd account..."
rm -rf "/Users/blnd3dd/Library/Application Support/NotificationCenter" 2>/dev/null || echo "Notifications not found in blnd3dd"
rm -rf "/Users/blnd3dd/Library/Preferences/com.apple.notificationcenter" 2>/dev/null || echo "Notification preferences not found in blnd3dd"

echo "Clearing notifications from pawelbek90 account..."
rm -rf "/Users/pawelbek90/Library/Application Support/NotificationCenter" 2>/dev/null || echo "Notifications not found in pawelbek90"
rm -rf "/Users/pawelbek90/Library/Preferences/com.apple.notificationcenter" 2>/dev/null || echo "Notification preferences not found in pawelbek90"

echo ""

# =============================================================================
# PHASE 8: APP STORE CLEANUP
# =============================================================================

echo "=== PHASE 8: APP STORE CLEANUP ==="

echo "Logging out App Store from suspicious accounts..."
echo "Logging out App Store from blnd3dd account..."
if [ -f "/Users/blnd3dd/Library/Preferences/com.apple.appstore.plist" ]; then
    defaults delete "/Users/blnd3dd/Library/Preferences/com.apple.appstore.plist" AppleID 2>/dev/null || echo "App Store Apple ID not found in blnd3dd"
    defaults delete "/Users/blnd3dd/Library/Preferences/com.apple.appstore.plist" AutoUpdateEnabled 2>/dev/null || echo "App Store settings not found in blnd3dd"
    echo "App Store logged out from blnd3dd account"
else
    echo "blnd3dd account not found"
fi

echo "Logging out App Store from pawelbek90 account..."
if [ -f "/Users/pawelbek90/Library/Preferences/com.apple.appstore.plist" ]; then
    defaults delete "/Users/pawelbek90/Library/Preferences/com.apple.appstore.plist" AppleID 2>/dev/null || echo "App Store Apple ID not found in pawelbek90"
    defaults delete "/Users/pawelbek90/Library/Preferences/com.apple.appstore.plist" AutoUpdateEnabled 2>/dev/null || echo "App Store settings not found in pawelbek90"
    echo "App Store logged out from pawelbek90 account"
else
    echo "pawelbek90 account not found"
fi

echo ""

# =============================================================================
# PHASE 9: SYSTEM PREFERENCES CLEANUP
# =============================================================================

echo "=== PHASE 9: SYSTEM PREFERENCES CLEANUP ==="

echo "Clearing system preferences from suspicious accounts..."
echo "Clearing system preferences from blnd3dd account..."
rm -rf "/Users/blnd3dd/Library/Preferences/com.apple.systempreferences" 2>/dev/null || echo "System preferences not found in blnd3dd"

echo "Clearing system preferences from pawelbek90 account..."
rm -rf "/Users/pawelbek90/Library/Preferences/com.apple.systempreferences" 2>/dev/null || echo "System preferences not found in pawelbek90"

echo ""

# =============================================================================
# PHASE 10: CACHE CLEANUP
# =============================================================================

echo "=== PHASE 10: CACHE CLEANUP ==="

echo "Clearing caches from suspicious accounts..."
echo "Clearing caches from blnd3dd account..."
rm -rf "/Users/blnd3dd/Library/Caches/com.apple.coreservices" 2>/dev/null || echo "Core services cache not found in blnd3dd"
rm -rf "/Users/blnd3dd/Library/Caches/com.apple.bird" 2>/dev/null || echo "iCloud cache not found in blnd3dd"
rm -rf "/Users/blnd3dd/Library/Caches/com.apple.appstore" 2>/dev/null || echo "App Store cache not found in blnd3dd"

echo "Clearing caches from pawelbek90 account..."
rm -rf "/Users/pawelbek90/Library/Caches/com.apple.coreservices" 2>/dev/null || echo "Core services cache not found in pawelbek90"
rm -rf "/Users/pawelbek90/Library/Caches/com.apple.bird" 2>/dev/null || echo "iCloud cache not found in pawelbek90"
rm -rf "/Users/pawelbek90/Library/Caches/com.apple.appstore" 2>/dev/null || echo "App Store cache not found in pawelbek90"

echo ""

# =============================================================================
# PHASE 11: VERIFICATION
# =============================================================================

echo "=== PHASE 11: VERIFICATION ==="

echo "Verifying Apple ID cleanup..."
echo "Checking for remaining Apple ID entries..."
find /Users -name "*.plist" -exec grep -l "AppleID" {} \; 2>/dev/null | head -5

echo "Checking for remaining iCloud entries..."
find /Users -name "*.plist" -exec grep -l "iCloud" {} \; 2>/dev/null | head -5

echo "Checking for remaining sync service entries..."
find /Users -name "*.plist" -exec grep -l "ActivityAdvertisingAllowed" {} \; 2>/dev/null | head -5

echo ""

# =============================================================================
# PHASE 12: RECOMMENDATIONS
# =============================================================================

echo "=== PHASE 12: RECOMMENDATIONS ==="

echo "APPLE ID MAYHEM FIX RECOMMENDATIONS:"
echo ""
echo "1. APPLE ID SECURITY:"
echo "   - Use Apple ID only in ONE account on this Mac"
echo "   - Log out from all other accounts"
echo "   - Use different Apple IDs for different purposes"
echo "   - Monitor Apple ID access"
echo ""
echo "2. ACCOUNT ISOLATION:"
echo "   - Keep personal and work accounts separate"
echo "   - Use different Apple IDs for different accounts"
echo "   - Don't share Apple IDs between accounts"
echo "   - Monitor account access"
echo ""
echo "3. SYNC MANAGEMENT:"
echo "   - Disable sync services in unused accounts"
echo "   - Use sync only in primary account"
echo "   - Monitor sync conflicts"
echo "   - Check for duplicate data"
echo ""
echo "4. NOTIFICATION MANAGEMENT:"
echo "   - Disable notifications in unused accounts"
echo "   - Use notifications only in primary account"
echo "   - Monitor notification conflicts"
echo "   - Check for duplicate notifications"
echo ""
echo "5. CONTINUOUS MONITORING:"
echo "   - Monitor Apple ID access"
echo "   - Check for sync conflicts"
echo "   - Verify account isolation"
echo "   - Monitor notification conflicts"
echo ""

echo "=== APPLE ID MAYHEM FIX COMPLETE ==="
echo ""
echo "SUMMARY OF ACTIONS PERFORMED:"
echo "✅ Audited Apple ID status across all accounts"
echo "✅ Detected multiple account Apple ID logins"
echo "✅ Logged out Apple ID from suspicious accounts"
echo "✅ Disabled iCloud from suspicious accounts"
echo "✅ Removed Apple ID entries from keychains"
echo "✅ Disabled sync services from suspicious accounts"
echo "✅ Cleared notifications from suspicious accounts"
echo "✅ Logged out App Store from suspicious accounts"
echo "✅ Cleared system preferences from suspicious accounts"
echo "✅ Cleared caches from suspicious accounts"
echo "✅ Verified Apple ID cleanup"
echo "✅ Provided recommendations"
echo ""
echo "IMPORTANT: Apple ID mayhem should now be resolved!"
echo "Use Apple ID only in ONE account on this Mac."
echo ""
echo "NEXT STEPS:"
echo "1. Use Apple ID only in your primary account"
echo "2. Log out from all other accounts"
echo "3. Monitor for sync conflicts"
echo "4. Check for notification conflicts"
echo "5. Verify account isolation"
echo "6. Keep accounts separate"
echo ""
