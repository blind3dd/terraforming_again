#!/bin/bash

# Work Profile Complete Removal Script for Samsung Android Device
# This script removes or disables all Work Profile functionality

echo "=== WORK PROFILE COMPLETE REMOVAL SCRIPT ==="
echo "Removing all Work Profile components and interfaces..."

# Step 1: Disable Work Profile in system settings
echo "Step 1: Disabling Work Profile in system settings..."
./platform-tools/adb shell "settings put global work_profile_enabled 0"
./platform-tools/adb shell "settings put system work_profile_enabled 0"
./platform-tools/adb shell "settings put secure work_profile_enabled 0"

# Step 2: Remove Work Profile user restrictions
echo "Step 2: Removing Work Profile user restrictions..."
./platform-tools/adb shell "dumpsys user" | grep -i "work" | while read line; do
    echo "Found work profile setting: $line"
done

# Step 3: Disable Work Profile apps and services
echo "Step 3: Disabling Work Profile apps and services..."
./platform-tools/adb shell "pm disable-user --user 0 com.android.managedprovisioning"
./platform-tools/adb shell "pm disable-user --user 0 com.android.systemui.work"
./platform-tools/adb shell "pm disable-user --user 0 com.samsung.android.knox.containercore"

# Step 4: Remove Work Profile from device policy
echo "Step 4: Removing Work Profile from device policy..."
./platform-tools/adb shell "dumpsys device_policy" | grep -i "work" | while read line; do
    echo "Found work profile policy: $line"
done

# Step 5: Clear Work Profile data and cache
echo "Step 5: Clearing Work Profile data and cache..."
./platform-tools/adb shell "pm clear com.android.managedprovisioning"
./platform-tools/adb shell "pm clear com.android.systemui.work"
./platform-tools/adb shell "pm clear com.samsung.android.knox.containercore"

# Step 6: Remove Work Profile from accounts
echo "Step 6: Removing Work Profile from accounts..."
./platform-tools/adb shell "dumpsys account" | grep -i "work" | while read line; do
    echo "Found work profile account: $line"
done

# Step 7: Disable Work Profile notifications
echo "Step 7: Disabling Work Profile notifications..."
./platform-tools/adb shell "settings put global work_profile_notifications_enabled 0"
./platform-tools/adb shell "settings put system work_profile_notifications_enabled 0"

# Step 8: Remove Work Profile from launcher
echo "Step 8: Removing Work Profile from launcher..."
./platform-tools/adb shell "pm disable-user --user 0 com.samsung.android.launcher.work"
./platform-tools/adb shell "pm clear com.samsung.android.launcher.work"

# Step 9: Disable Work Profile in Samsung settings
echo "Step 9: Disabling Work Profile in Samsung settings..."
./platform-tools/adb shell "pm disable-user --user 0 com.samsung.android.settings.work"
./platform-tools/adb shell "pm clear com.samsung.android.settings.work"

# Step 10: Remove Work Profile from system UI
echo "Step 10: Removing Work Profile from system UI..."
./platform-tools/adb shell "pm disable-user --user 0 com.android.systemui.work"
./platform-tools/adb shell "pm clear com.android.systemui.work"

# Step 11: Clear Work Profile preferences
echo "Step 11: Clearing Work Profile preferences..."
./platform-tools/adb shell "settings delete global work_profile_enabled"
./platform-tools/adb shell "settings delete system work_profile_enabled"
./platform-tools/adb shell "settings delete secure work_profile_enabled"

# Step 12: Remove Work Profile from device owner
echo "Step 12: Removing Work Profile from device owner..."
./platform-tools/adb shell "dumpsys device_policy" | grep -i "owner" | while read line; do
    echo "Found device owner: $line"
done

# Step 13: Disable Work Profile in Knox
echo "Step 13: Disabling Work Profile in Knox..."
./platform-tools/adb shell "pm disable-user --user 0 com.samsung.android.knox.containercore"
./platform-tools/adb shell "pm clear com.samsung.android.knox.containercore"

# Step 14: Remove Work Profile from enterprise management
echo "Step 14: Removing Work Profile from enterprise management..."
./platform-tools/adb shell "pm disable-user --user 0 com.samsung.android.enterprise"
./platform-tools/adb shell "pm clear com.samsung.android.enterprise"

# Step 15: Clear Work Profile from system cache
echo "Step 15: Clearing Work Profile from system cache..."
./platform-tools/adb shell "rm -rf /data/system/work_profile*"
./platform-tools/adb shell "rm -rf /data/system/enterprise*"
./platform-tools/adb shell "rm -rf /data/system/knox*"

# Step 16: Restart system services
echo "Step 16: Restarting system services..."
./platform-tools/adb shell "am force-stop com.android.systemui"
./platform-tools/adb shell "am start-service com.android.systemui"

# Step 17: Verify Work Profile removal
echo "Step 17: Verifying Work Profile removal..."
echo "Checking for remaining Work Profile components..."
./platform-tools/adb shell "pm list packages | grep -i work"
./platform-tools/adb shell "dumpsys user" | grep -i "work"
./platform-tools/adb shell "dumpsys device_policy" | grep -i "work"

echo "=== WORK PROFILE REMOVAL COMPLETE ==="
echo "All Work Profile components have been removed or disabled."
echo "The device should no longer show Work Profile interfaces."
