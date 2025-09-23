#!/bin/bash

# Factory Reset Script for New Device Setup
# This script performs a comprehensive factory reset

echo "=== FACTORY RESET FOR NEW SETUP ==="
echo "WARNING: This will completely reset the device!"
echo "The device will be ready for fresh configuration..."

# Step 1: Perform factory reset through recovery
echo "Step 1: Initiating factory reset through recovery..."
./platform-tools/adb reboot recovery

echo "Waiting for device to enter recovery mode..."
sleep 10

# Step 2: Alternative - Clear all user data through ADB
echo "Step 2: Clearing all user data through ADB..."
./platform-tools/adb shell "pm clear com.android.providers.settings"
./platform-tools/adb shell "pm clear com.android.providers.contacts"
./platform-tools/adb shell "pm clear com.android.providers.telephony"
./platform-tools/adb shell "pm clear com.android.providers.calendar"

# Step 3: Reset all system settings to default
echo "Step 3: Resetting all system settings to default..."
./platform-tools/adb shell "settings delete system"
./platform-tools/adb shell "settings delete global"
./platform-tools/adb shell "settings delete secure"

# Step 4: Clear all user accounts and data
echo "Step 4: Clearing all user accounts and data..."
./platform-tools/adb shell "rm -rf /data/data/com.android.providers.settings"
./platform-tools/adb shell "rm -rf /data/data/com.android.providers.contacts"
./platform-tools/adb shell "rm -rf /data/data/com.android.providers.telephony"
./platform-tools/adb shell "rm -rf /data/data/com.android.providers.calendar"

# Step 5: Remove all installed user apps
echo "Step 5: Removing all installed user apps..."
./platform-tools/adb shell "pm list packages -3" | cut -d: -f2 | while read package; do
    echo "Removing user app: $package"
    ./platform-tools/adb shell "pm uninstall --user 0 $package" 2>/dev/null || echo "Failed to remove $package"
done

# Step 6: Clear all caches and temporary data
echo "Step 6: Clearing all caches and temporary data..."
./platform-tools/adb shell "rm -rf /data/dalvik-cache/*"
./platform-tools/adb shell "rm -rf /data/local/tmp/*"
./platform-tools/adb shell "rm -rf /data/misc/*"

# Step 7: Reset network configurations
echo "Step 7: Resetting network configurations..."
./platform-tools/adb shell "rm -rf /data/misc/wifi/*"
./platform-tools/adb shell "rm -rf /data/misc/bluetooth/*"
./platform-tools/adb shell "rm -rf /data/misc/ethernet/*"

# Step 8: Clear all user preferences
echo "Step 8: Clearing all user preferences..."
./platform-tools/adb shell "rm -rf /data/data/*/shared_prefs/*"
./platform-tools/adb shell "rm -rf /data/system/shared_prefs/*"

# Step 9: Reset device identifiers
echo "Step 9: Resetting device identifiers..."
./platform-tools/adb shell "rm -rf /data/system/deviceid.xml"
./platform-tools/adb shell "rm -rf /data/system/device_policy.xml"

# Step 10: Clear all databases
echo "Step 10: Clearing all databases..."
./platform-tools/adb shell "rm -rf /data/data/*/databases/*"
./platform-tools/adb shell "rm -rf /data/system/databases/*"

# Step 11: Reset all system services
echo "Step 11: Resetting all system services..."
./platform-tools/adb shell "am force-stop com.android.systemui"
./platform-tools/adb shell "am force-stop com.android.settings"

# Step 12: Clear all logs
echo "Step 12: Clearing all logs..."
./platform-tools/adb shell "rm -rf /data/log/*"
./platform-tools/adb shell "rm -rf /data/tombstones/*"
./platform-tools/adb shell "rm -rf /data/anr/*"

# Step 13: Reset all accounts
echo "Step 13: Resetting all accounts..."
./platform-tools/adb shell "rm -rf /data/system/accounts.db*"
./platform-tools/adb shell "rm -rf /data/system/sync/*"

# Step 14: Clear all certificates
echo "Step 14: Clearing all certificates..."
./platform-tools/adb shell "rm -rf /data/misc/keystore/*"
./platform-tools/adb shell "rm -rf /data/misc/ssl/*"

# Step 15: Reset all security settings
echo "Step 15: Resetting all security settings..."
./platform-tools/adb shell "rm -rf /data/system/device_policies.xml"
./platform-tools/adb shell "rm -rf /data/system/enterprise.conf"
./platform-tools/adb shell "rm -rf /data/system/enterprise.db*"

# Step 16: Clear all user data
echo "Step 16: Clearing all user data..."
./platform-tools/adb shell "rm -rf /data/user/*"
./platform-tools/adb shell "rm -rf /data/media/*"

# Step 17: Reset all system properties
echo "Step 17: Resetting all system properties..."
./platform-tools/adb shell "setprop ro.debuggable 0"
./platform-tools/adb shell "setprop ro.secure 1"
./platform-tools/adb shell "setprop ro.adb.secure 1"

# Step 18: Final system cleanup
echo "Step 18: Final system cleanup..."
./platform-tools/adb shell "sync"
./platform-tools/adb shell "echo 3 > /proc/sys/vm/drop_caches"

# Step 19: Reboot device
echo "Step 19: Rebooting device for fresh setup..."
./platform-tools/adb reboot

echo "=== FACTORY RESET COMPLETE ==="
echo "The device has been completely reset and is ready for new setup."
echo "You can now configure the device as new."
echo "All previous data and settings have been removed."
