#!/bin/bash

# Complete Email Unlinking Script for Samsung Android Device
# This script removes ALL email associations and accounts

echo "=== COMPLETE EMAIL UNLINKING SCRIPT ==="
echo "Removing ALL email associations and accounts..."
echo "Device will be completely unlinked from any email accounts..."

# Step 1: Remove all Google accounts
echo "Step 1: Removing all Google accounts..."
./platform-tools/adb shell "pm clear com.google.android.gms"
./platform-tools/adb shell "pm clear com.google.android.gsf"
./platform-tools/adb shell "pm clear com.google.android.gsf.login"

# Step 2: Remove all email providers
echo "Step 2: Removing all email providers..."
./platform-tools/adb shell "pm clear com.android.email"
./platform-tools/adb shell "pm clear com.google.android.gm"
./platform-tools/adb shell "pm clear com.microsoft.office.outlook"
./platform-tools/adb shell "pm clear com.yahoo.mobile.client.android.mail"

# Step 3: Clear all account databases
echo "Step 3: Clearing all account databases..."
./platform-tools/adb shell "rm -rf /data/system/accounts.db*"
./platform-tools/adb shell "rm -rf /data/system/sync/*"
./platform-tools/adb shell "rm -rf /data/data/com.android.providers.contacts/databases/*"

# Step 4: Remove all email settings
echo "Step 4: Removing all email settings..."
./platform-tools/adb shell "settings delete system email_accounts"
./platform-tools/adb shell "settings delete system email_providers"
./platform-tools/adb shell "settings delete global email_accounts"
./platform-tools/adb shell "settings delete secure email_accounts"

# Step 5: Clear all contact providers
echo "Step 5: Clearing all contact providers..."
./platform-tools/adb shell "pm clear com.android.providers.contacts"
./platform-tools/adb shell "rm -rf /data/data/com.android.providers.contacts/*"

# Step 6: Remove all calendar providers
echo "Step 6: Removing all calendar providers..."
./platform-tools/adb shell "pm clear com.android.providers.calendar"
./platform-tools/adb shell "rm -rf /data/data/com.android.providers.calendar/*"

# Step 7: Clear all sync settings
echo "Step 7: Clearing all sync settings..."
./platform-tools/adb shell "settings delete system sync_enabled"
./platform-tools/adb shell "settings delete global sync_enabled"
./platform-tools/adb shell "settings delete secure sync_enabled"

# Step 8: Remove all cloud storage accounts
echo "Step 8: Removing all cloud storage accounts..."
./platform-tools/adb shell "pm clear com.google.android.apps.drive"
./platform-tools/adb shell "pm clear com.microsoft.skydrive"
./platform-tools/adb shell "pm clear com.dropbox.android"

# Step 9: Clear all authentication tokens
echo "Step 9: Clearing all authentication tokens..."
./platform-tools/adb shell "rm -rf /data/data/com.google.android.gms/shared_prefs/*"
./platform-tools/adb shell "rm -rf /data/data/com.google.android.gsf/shared_prefs/*"
./platform-tools/adb shell "rm -rf /data/data/com.google.android.gm/shared_prefs/*"

# Step 10: Remove all email-related preferences
echo "Step 10: Removing all email-related preferences..."
./platform-tools/adb shell "rm -rf /data/data/com.android.email/shared_prefs/*"
./platform-tools/adb shell "rm -rf /data/data/com.google.android.gm/shared_prefs/*"
./platform-tools/adb shell "rm -rf /data/data/com.microsoft.office.outlook/shared_prefs/*"

# Step 11: Clear all account manager data
echo "Step 11: Clearing all account manager data..."
./platform-tools/adb shell "rm -rf /data/system/account_manager.xml"
./platform-tools/adb shell "rm -rf /data/system/account_manager.db*"

# Step 12: Remove all email certificates
echo "Step 12: Removing all email certificates..."
./platform-tools/adb shell "rm -rf /data/misc/keystore/user_0/*"
./platform-tools/adb shell "rm -rf /data/misc/ssl/certs/*"

# Step 13: Clear all email cache
echo "Step 13: Clearing all email cache..."
./platform-tools/adb shell "rm -rf /data/data/com.android.email/cache/*"
./platform-tools/adb shell "rm -rf /data/data/com.google.android.gm/cache/*"
./platform-tools/adb shell "rm -rf /data/data/com.microsoft.office.outlook/cache/*"

# Step 14: Remove all email databases
echo "Step 14: Removing all email databases..."
./platform-tools/adb shell "rm -rf /data/data/com.android.email/databases/*"
./platform-tools/adb shell "rm -rf /data/data/com.google.android.gm/databases/*"
./platform-tools/adb shell "rm -rf /data/data/com.microsoft.office.outlook/databases/*"

# Step 15: Clear all email logs
echo "Step 15: Clearing all email logs..."
./platform-tools/adb shell "rm -rf /data/data/com.android.email/logs/*"
./platform-tools/adb shell "rm -rf /data/data/com.google.android.gm/logs/*"
./platform-tools/adb shell "rm -rf /data/data/com.microsoft.office.outlook/logs/*"

# Step 16: Remove all email temporary files
echo "Step 16: Removing all email temporary files..."
./platform-tools/adb shell "rm -rf /data/data/com.android.email/temp/*"
./platform-tools/adb shell "rm -rf /data/data/com.google.android.gm/temp/*"
./platform-tools/adb shell "rm -rf /data/data/com.microsoft.office.outlook/temp/*"

# Step 17: Clear all email settings
echo "Step 17: Clearing all email settings..."
./platform-tools/adb shell "rm -rf /data/data/com.android.email/settings/*"
./platform-tools/adb shell "rm -rf /data/data/com.google.android.gm/settings/*"
./platform-tools/adb shell "rm -rf /data/data/com.microsoft.office.outlook/settings/*"

# Step 18: Remove all email user data
echo "Step 18: Removing all email user data..."
./platform-tools/adb shell "rm -rf /data/user/0/com.android.email/*"
./platform-tools/adb shell "rm -rf /data/user/0/com.google.android.gm/*"
./platform-tools/adb shell "rm -rf /data/user/0/com.microsoft.office.outlook/*"

# Step 19: Clear all email system data
echo "Step 19: Clearing all email system data..."
./platform-tools/adb shell "rm -rf /data/system/email*"
./platform-tools/adb shell "rm -rf /data/system/account*"
./platform-tools/adb shell "rm -rf /data/system/sync*"

# Step 20: Final verification
echo "Step 20: Final verification..."
echo "Checking for remaining email accounts..."
./platform-tools/adb shell "dumpsys account" | grep -i "email" || echo "No email accounts found"
./platform-tools/adb shell "dumpsys account" | grep -i "google" || echo "No Google accounts found"
./platform-tools/adb shell "dumpsys account" | grep -i "microsoft" || echo "No Microsoft accounts found"

echo "=== EMAIL UNLINKING COMPLETE ==="
echo "All email associations have been removed."
echo "The device is now completely unlinked from any email accounts."
echo "You can now set up the device with new email accounts."
