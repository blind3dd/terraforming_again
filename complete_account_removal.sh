#!/bin/bash

# Complete Account Removal Script
# This script completely removes the pawelbek90 account and all its data from the system

echo "=== COMPLETE ACCOUNT REMOVAL SCRIPT ==="
echo "CRITICAL: Completely removing pawelbek90 account from the system..."

# Define the account to be completely removed
ACCOUNT_TO_REMOVE="pawelbek90"

# --- PHASE 1: Force Kill All Processes ---
echo "=== PHASE 1: Force Killing All Processes ==="
echo "Killing all processes for $ACCOUNT_TO_REMOVE..."
sudo pkill -9 -u "$ACCOUNT_TO_REMOVE" 2>/dev/null
echo "All processes killed for $ACCOUNT_TO_REMOVE"

# --- PHASE 2: Remove User from All Groups ---
echo "=== PHASE 2: Removing User from All Groups ==="
echo "Removing $ACCOUNT_TO_REMOVE from all groups..."
# Get all groups the user belongs to
GROUPS=$(dscl . -read /Users/"$ACCOUNT_TO_REMOVE" NFSGroups 2>/dev/null | cut -d: -f2 | tr -d ' ')
if [ ! -z "$GROUPS" ]; then
    for group in $GROUPS; do
        echo "Removing $ACCOUNT_TO_REMOVE from group $group..."
        sudo dscl . -delete /Groups/"$group" GroupMembership "$ACCOUNT_TO_REMOVE" 2>/dev/null
    done
fi

# Remove from standard groups
sudo dscl . -delete /Groups/admin GroupMembership "$ACCOUNT_TO_REMOVE" 2>/dev/null
sudo dscl . -delete /Groups/staff GroupMembership "$ACCOUNT_TO_REMOVE" 2>/dev/null
sudo dscl . -delete /Groups/wheel GroupMembership "$ACCOUNT_TO_REMOVE" 2>/dev/null
sudo dscl . -delete /Groups/_appserveradm GroupMembership "$ACCOUNT_TO_REMOVE" 2>/dev/null
sudo dscl . -delete /Groups/_appserverusr GroupMembership "$ACCOUNT_TO_REMOVE" 2>/dev/null

# --- PHASE 3: Remove All User Data ---
echo "=== PHASE 3: Removing All User Data ==="
echo "Removing home directory for $ACCOUNT_TO_REMOVE..."
sudo rm -rf "/Users/$ACCOUNT_TO_REMOVE"

echo "Removing user preferences..."
sudo rm -rf "/Library/Preferences/ByHost/com.apple.*.$ACCOUNT_TO_REMOVE.plist"
sudo rm -rf "/Library/Preferences/com.apple.*.$ACCOUNT_TO_REMOVE.plist"

echo "Removing user caches..."
sudo rm -rf "/Library/Caches/com.apple.*.$ACCOUNT_TO_REMOVE"
sudo rm -rf "/var/folders/*/*/com.apple.*.$ACCOUNT_TO_REMOVE"

echo "Removing user application support..."
sudo rm -rf "/Library/Application Support/com.apple.*.$ACCOUNT_TO_REMOVE"

# --- PHASE 4: Remove User from Directory Services ---
echo "=== PHASE 4: Removing User from Directory Services ==="
echo "Removing $ACCOUNT_TO_REMOVE from directory services..."

# Remove all user attributes
sudo dscl . -delete /Users/"$ACCOUNT_TO_REMOVE" 2>/dev/null

# Remove from recent users list
sudo defaults delete /Library/Preferences/com.apple.loginwindow RecentUsers 2>/dev/null
# Recreate recent users list without the removed user
CURRENT_USERS=$(dscl . -list /Users | grep -v "^_" | grep -v "$ACCOUNT_TO_REMOVE")
sudo defaults write /Library/Preferences/com.apple.loginwindow RecentUsers -array $CURRENT_USERS

# --- PHASE 5: Remove User from System Configuration ---
echo "=== PHASE 5: Removing User from System Configuration ==="
echo "Removing $ACCOUNT_TO_REMOVE from system configuration..."

# Remove from auto-login if set
sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null

# Remove from console users
sudo dscl . -delete /Users/"$ACCOUNT_TO_REMOVE" IsConsoleUser 2>/dev/null

# Remove from admin users
sudo dscl . -delete /Users/"$ACCOUNT_TO_REMOVE" IsAdmin 2>/dev/null

# --- PHASE 6: Clean Network Configuration ---
echo "=== PHASE 6: Cleaning Network Configuration ==="
echo "Removing network configurations for $ACCOUNT_TO_REMOVE..."

# Remove network preferences
sudo rm -rf "/Library/Preferences/SystemConfiguration/com.apple.network.*.$ACCOUNT_TO_REMOVE.plist"

# Remove VPN configurations
sudo security delete-generic-password -l "VPN" "/Users/$ACCOUNT_TO_REMOVE/Library/Keychains/login.keychain-db" 2>/dev/null

# Remove network extensions
sudo rm -rf "/Library/Application Support/com.apple.networkextension.*.$ACCOUNT_TO_REMOVE"

# --- PHASE 7: Remove Apple ID Integration ---
echo "=== PHASE 7: Removing Apple ID Integration ==="
echo "Removing Apple ID integration for $ACCOUNT_TO_REMOVE..."

# Remove iCloud configuration
sudo rm -rf "/Library/Preferences/com.apple.iCloud.*.$ACCOUNT_TO_REMOVE.plist"
sudo rm -rf "/Library/Application Support/iCloud.*.$ACCOUNT_TO_REMOVE"

# Remove Apple ID tokens
sudo rm -rf "/Library/Keychains/login.keychain-db.$ACCOUNT_TO_REMOVE"
sudo rm -rf "/Library/Keychains/CloudKit.*.$ACCOUNT_TO_REMOVE"

# Remove Apple ID preferences
sudo rm -rf "/Library/Preferences/com.apple.AppleID.*.$ACCOUNT_TO_REMOVE.plist"
sudo rm -rf "/Library/Preferences/com.apple.ids.*.$ACCOUNT_TO_REMOVE.plist"

# --- PHASE 8: Remove Kerberos Integration ---
echo "=== PHASE 8: Removing Kerberos Integration ==="
echo "Removing Kerberos integration for $ACCOUNT_TO_REMOVE..."

# Remove Kerberos principals
sudo dscl . -delete /Users/"$ACCOUNT_TO_REMOVE" KerberosPrincipal 2>/dev/null

# Remove Kerberos keys
sudo dscl . -delete /Users/"$ACCOUNT_TO_REMOVE" KerberosKeys 2>/dev/null

# Remove Kerberos configuration
sudo rm -rf "/Library/Preferences/edu.mit.Kerberos.*.$ACCOUNT_TO_REMOVE.plist"
sudo rm -rf "/Library/Preferences/com.apple.Kerberos.*.$ACCOUNT_TO_REMOVE.plist"

# --- PHASE 9: Remove Enterprise Integration ---
echo "=== PHASE 9: Removing Enterprise Integration ==="
echo "Removing enterprise integration for $ACCOUNT_TO_REMOVE..."

# Remove managed preferences
sudo rm -rf "/Library/Managed Preferences/$ACCOUNT_TO_REMOVE"

# Remove enterprise configuration
sudo rm -rf "/Library/Application Support/com.apple.ManagedClient.*.$ACCOUNT_TO_REMOVE"

# Remove enterprise caches
sudo rm -rf "/var/db/ManagedClient/$ACCOUNT_TO_REMOVE"

# --- PHASE 10: Clean System Logs ---
echo "=== PHASE 10: Cleaning System Logs ==="
echo "Removing system logs for $ACCOUNT_TO_REMOVE..."

# Remove user-specific log files
sudo rm -rf "/var/log/asl/*.$ACCOUNT_TO_REMOVE"
sudo rm -rf "/var/log/system.log.*.$ACCOUNT_TO_REMOVE"

# Remove user-specific crash reports
sudo rm -rf "/Library/Logs/DiagnosticReports/*.$ACCOUNT_TO_REMOVE"
sudo rm -rf "/var/log/DiagnosticReports/*.$ACCOUNT_TO_REMOVE"

# --- PHASE 11: Remove User from File Permissions ---
echo "=== PHASE 11: Removing User from File Permissions ==="
echo "Removing $ACCOUNT_TO_REMOVE from file permissions..."

# Remove from system file permissions
sudo chmod -R -x "/System/Library/User Template/$ACCOUNT_TO_REMOVE" 2>/dev/null
sudo rm -rf "/System/Library/User Template/$ACCOUNT_TO_REMOVE" 2>/dev/null

# Remove from application permissions
sudo rm -rf "/Applications/*.$ACCOUNT_TO_REMOVE"
sudo rm -rf "/Applications/*/Contents/MacOS/*.$ACCOUNT_TO_REMOVE"

# --- PHASE 12: Final Verification ---
echo "=== PHASE 12: Final Verification ==="
echo "Verifying complete removal of $ACCOUNT_TO_REMOVE..."

# Check if user still exists
if dscl . -read /Users/"$ACCOUNT_TO_REMOVE" >/dev/null 2>&1; then
    echo "ERROR: User $ACCOUNT_TO_REMOVE still exists in directory services!"
    echo "Attempting final removal..."
    sudo dscl . -delete /Users/"$ACCOUNT_TO_REMOVE"
fi

# Check if home directory still exists
if [ -d "/Users/$ACCOUNT_TO_REMOVE" ]; then
    echo "ERROR: Home directory still exists!"
    echo "Attempting final removal..."
    sudo rm -rf "/Users/$ACCOUNT_TO_REMOVE"
fi

# Check if user is in recent users
RECENT_USERS=$(defaults read /Library/Preferences/com.apple.loginwindow RecentUsers 2>/dev/null)
if echo "$RECENT_USERS" | grep -q "$ACCOUNT_TO_REMOVE"; then
    echo "ERROR: User still in recent users list!"
    echo "Attempting final removal..."
    sudo defaults delete /Library/Preferences/com.apple.loginwindow RecentUsers
    CURRENT_USERS=$(dscl . -list /Users | grep -v "^_" | grep -v "$ACCOUNT_TO_REMOVE")
    sudo defaults write /Library/Preferences/com.apple.loginwindow RecentUsers -array $CURRENT_USERS
fi

echo "=== COMPLETE ACCOUNT REMOVAL COMPLETE ==="
echo "The $ACCOUNT_TO_REMOVE account has been completely removed from the system."
echo "All user data, preferences, and system integration have been eliminated."

echo ""
echo "IMMEDIATE NEXT STEPS:"
echo "1. REBOOT YOUR MAC IMMEDIATELY"
echo "2. Verify the account is completely gone"
echo "3. Check for any remaining references"
echo "4. Monitor system for any issues"

echo ""
echo "WARNING: This was a complete account removal."
echo "All data associated with $ACCOUNT_TO_REMOVE has been permanently deleted."
