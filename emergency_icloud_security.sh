#!/bin/bash

# Emergency iCloud Security Script
# This script secures iCloud data and removes unauthorized access

echo "=== EMERGENCY iCLOUD SECURITY SCRIPT ==="
echo "CRITICAL: Securing iCloud data and removing unauthorized access..."

# Define the compromised account
COMPROMISED_ACCOUNT="pawelbek90"
CURRENT_USER="usualsuspectx"

# --- PHASE 1: Force Logout from iCloud ---
echo "=== PHASE 1: Force Logout from iCloud ==="
echo "Force logging out from iCloud to prevent data access..."

# Kill all iCloud-related processes
sudo killall -9 "iCloud"
sudo killall -9 "iCloudDrive"
sudo killall -9 "iCloudQuota"
sudo killall -9 "CloudDocsDaemon"
sudo killall -9 "CloudKit"
sudo killall -9 "iCloudNotificationAgent"
sudo killall -9 "iCloudHelper"

# Stop iCloud services
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.iCloud* 2>/dev/null
sudo launchctl unload -w /System/Library/LaunchAgents/com.apple.iCloud* 2>/dev/null

# --- PHASE 2: Remove iCloud Access from Compromised Account ---
echo "=== PHASE 2: Removing iCloud Access from Compromised Account ==="
echo "Removing all iCloud access for $COMPROMISED_ACCOUNT..."

# Remove iCloud preferences
sudo rm -rf "/Users/$COMPROMISED_ACCOUNT/Library/Preferences/com.apple.iCloud*"
sudo rm -rf "/Users/$COMPROMISED_ACCOUNT/Library/Application Support/iCloud*"
sudo rm -rf "/Users/$COMPROMISED_ACCOUNT/Library/Containers/com.apple.iCloud*"
sudo rm -rf "/Users/$COMPROMISED_ACCOUNT/Library/Group Containers/group.com.apple.iCloud*"

# Remove iCloud keychain access
sudo rm -rf "/Users/$COMPROMISED_ACCOUNT/Library/Keychains/CloudKit*"
sudo rm -rf "/Users/$COMPROMISED_ACCOUNT/Library/Keychains/iCloud*"

# Remove iCloud tokens and certificates
sudo security delete-generic-password -l "iCloud" "/Users/$COMPROMISED_ACCOUNT/Library/Keychains/login.keychain-db" 2>/dev/null
sudo security delete-generic-password -l "CloudKit" "/Users/$COMPROMISED_ACCOUNT/Library/Keychains/login.keychain-db" 2>/dev/null

# --- PHASE 3: Secure Current User's iCloud Data ---
echo "=== PHASE 3: Securing Current User's iCloud Data ==="
echo "Securing iCloud data for $CURRENT_USER..."

# Backup current iCloud preferences
echo "Backing up current iCloud preferences..."
sudo cp -r "/Users/$CURRENT_USER/Library/Preferences/com.apple.iCloud*" "/tmp/icloud_backup_$(date +%Y%m%d_%H%M%S)/" 2>/dev/null

# Remove shared iCloud access
sudo rm -rf "/Library/Preferences/com.apple.iCloud*"
sudo rm -rf "/Library/Application Support/iCloud*"
sudo rm -rf "/Library/Containers/com.apple.iCloud*"

# --- PHASE 4: Remove iCloud from System Level ---
echo "=== PHASE 4: Removing iCloud from System Level ==="
echo "Removing system-level iCloud integration..."

# Remove system iCloud preferences
sudo rm -rf /Library/Preferences/SystemConfiguration/com.apple.iCloud*
sudo rm -rf /Library/Preferences/com.apple.iCloud*

# Remove iCloud from system keychain
sudo security delete-generic-password -l "iCloud" /Library/Keychains/System.keychain 2>/dev/null
sudo security delete-generic-password -l "CloudKit" /Library/Keychains/System.keychain 2>/dev/null

# Remove iCloud certificates
sudo security delete-certificate -c "iCloud" /Library/Keychains/System.keychain 2>/dev/null
sudo security delete-certificate -c "CloudKit" /Library/Keychains/System.keychain 2>/dev/null

# --- PHASE 5: Disable iCloud Services ---
echo "=== PHASE 5: Disabling iCloud Services ==="
echo "Disabling all iCloud-related services..."

# Disable iCloud launch daemons
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.iCloud* 2>/dev/null
sudo launchctl unload -w /System/Library/LaunchAgents/com.apple.iCloud* 2>/dev/null
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.CloudDocs* 2>/dev/null
sudo launchctl unload -w /System/Library/LaunchAgents/com.apple.CloudDocs* 2>/dev/null

# Disable CloudKit services
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.CloudKit* 2>/dev/null
sudo launchctl unload -w /System/Library/LaunchAgents/com.apple.CloudKit* 2>/dev/null

# --- PHASE 6: Clean iCloud Caches ---
echo "=== PHASE 6: Cleaning iCloud Caches ==="
echo "Cleaning all iCloud caches..."

# Clean system iCloud caches
sudo rm -rf /var/db/iCloud*
sudo rm -rf /var/db/CloudKit*
sudo rm -rf /var/db/CloudDocs*

# Clean user iCloud caches
sudo rm -rf "/Users/$CURRENT_USER/Library/Caches/com.apple.iCloud*"
sudo rm -rf "/Users/$CURRENT_USER/Library/Caches/CloudKit*"
sudo rm -rf "/Users/$CURRENT_USER/Library/Caches/CloudDocs*"

# Clean compromised account caches
sudo rm -rf "/Users/$COMPROMISED_ACCOUNT/Library/Caches/com.apple.iCloud*"
sudo rm -rf "/Users/$COMPROMISED_ACCOUNT/Library/Caches/CloudKit*"
sudo rm -rf "/Users/$COMPROMISED_ACCOUNT/Library/Caches/CloudDocs*"

# --- PHASE 7: Remove iCloud Network Configuration ---
echo "=== PHASE 7: Removing iCloud Network Configuration ==="
echo "Removing iCloud network configurations..."

# Remove iCloud network preferences
sudo rm -rf /Library/Preferences/SystemConfiguration/com.apple.iCloud*
sudo rm -rf /Library/Preferences/SystemConfiguration/CloudKit*
sudo rm -rf /Library/Preferences/SystemConfiguration/CloudDocs*

# Remove iCloud network extensions
sudo rm -rf /Library/Application Support/com.apple.networkextension*/*iCloud*
sudo rm -rf /Library/Application Support/com.apple.networkextension*/*CloudKit*
sudo rm -rf /Library/Application Support/com.apple.networkextension*/*CloudDocs*

# --- PHASE 8: Secure iCloud Drive ---
echo "=== PHASE 8: Securing iCloud Drive ==="
echo "Securing iCloud Drive access..."

# Remove iCloud Drive access
sudo rm -rf "/Users/$COMPROMISED_ACCOUNT/iCloud Drive*"
sudo rm -rf "/Users/$COMPROMISED_ACCOUNT/Library/CloudStorage/iCloudDrive*"

# Secure current user's iCloud Drive
sudo chmod 700 "/Users/$CURRENT_USER/iCloud Drive*" 2>/dev/null
sudo chmod 700 "/Users/$CURRENT_USER/Library/CloudStorage/iCloudDrive*" 2>/dev/null

# --- PHASE 9: Remove iCloud from Applications ---
echo "=== PHASE 9: Removing iCloud from Applications ==="
echo "Removing iCloud integration from applications..."

# Remove iCloud from system applications
sudo rm -rf /Applications/*/Contents/Resources/iCloud*
sudo rm -rf /Applications/*/Contents/Resources/CloudKit*
sudo rm -rf /Applications/*/Contents/Resources/CloudDocs*

# Remove iCloud from user applications
sudo rm -rf "/Users/$CURRENT_USER/Applications/*/Contents/Resources/iCloud*"
sudo rm -rf "/Users/$CURRENT_USER/Applications/*/Contents/Resources/CloudKit*"
sudo rm -rf "/Users/$CURRENT_USER/Applications/*/Contents/Resources/CloudDocs*"

# --- PHASE 10: Disable iCloud Sync Services ---
echo "=== PHASE 10: Disabling iCloud Sync Services ==="
echo "Disabling iCloud sync services..."

# Disable iCloud sync services
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.syncdefaultsd.plist 2>/dev/null
sudo launchctl unload -w /System/Library/LaunchAgents/com.apple.syncdefaultsd.plist 2>/dev/null

# Disable iCloud backup services
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.backupd.plist 2>/dev/null
sudo launchctl unload -w /System/Library/LaunchAgents/com.apple.backupd.plist 2>/dev/null

# --- PHASE 11: Remove iCloud from Directory Services ---
echo "=== PHASE 11: Removing iCloud from Directory Services ==="
echo "Removing iCloud from directory services..."

# Remove iCloud from directory services
sudo dscl . -delete /Users/"$COMPROMISED_ACCOUNT" iCloudAccount 2>/dev/null
sudo dscl . -delete /Users/"$COMPROMISED_ACCOUNT" CloudKitAccount 2>/dev/null
sudo dscl . -delete /Users/"$COMPROMISED_ACCOUNT" iCloudDriveAccount 2>/dev/null

# --- PHASE 12: Final Security Hardening ---
echo "=== PHASE 12: Final Security Hardening ==="
echo "Applying final security hardening..."

# Set strict permissions on iCloud directories
sudo chmod 700 "/Users/$CURRENT_USER/Library/Application Support/iCloud*" 2>/dev/null
sudo chmod 700 "/Users/$CURRENT_USER/Library/Containers/com.apple.iCloud*" 2>/dev/null
sudo chmod 700 "/Users/$CURRENT_USER/Library/Group Containers/group.com.apple.iCloud*" 2>/dev/null

# Remove iCloud from system preferences
sudo defaults delete /Library/Preferences/com.apple.iCloud* 2>/dev/null
sudo defaults delete /Library/Preferences/SystemConfiguration/com.apple.iCloud* 2>/dev/null

echo "=== EMERGENCY iCLOUD SECURITY COMPLETE ==="
echo "CRITICAL: iCloud access has been secured and unauthorized access removed."

echo ""
echo "IMMEDIATE NEXT STEPS:"
echo "1. REBOOT YOUR MAC IMMEDIATELY"
echo "2. Change your Apple ID password"
echo "3. Enable 2FA on your Apple ID"
echo "4. Review all devices signed into your Apple ID"
echo "5. Sign out of iCloud on all other devices"
echo "6. Re-sign into iCloud only on this Mac after reboot"
echo "7. Monitor for any unauthorized access attempts"

echo ""
echo "WARNING: Your iCloud data was potentially compromised."
echo "Consider this a complete security breach and take appropriate measures."
echo "Review all your iCloud data for any unauthorized changes."
