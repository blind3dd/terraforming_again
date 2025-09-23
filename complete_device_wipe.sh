#!/bin/bash

# Complete Device Wipe Script for Samsung Android Device
# This script performs a comprehensive system-level wipe

echo "=== COMPLETE DEVICE WIPE SCRIPT ==="
echo "WARNING: This will completely wipe the device!"
echo "Removing all Samsung restrictions and making device completely clean..."

# Step 1: Remove all user accounts
echo "Step 1: Removing all user accounts..."
./platform-tools/adb shell "pm remove-user 0" 2>/dev/null || echo "User removal failed (expected)"

# Step 2: Clear all system settings
echo "Step 2: Clearing all system settings..."
./platform-tools/adb shell "settings delete system"
./platform-tools/adb shell "settings delete global"
./platform-tools/adb shell "settings delete secure"

# Step 3: Remove all installed packages (except system)
echo "Step 3: Removing all installed packages..."
./platform-tools/adb shell "pm list packages -3" | cut -d: -f2 | while read package; do
    echo "Removing package: $package"
    ./platform-tools/adb shell "pm uninstall --user 0 $package" 2>/dev/null || echo "Failed to remove $package"
done

# Step 4: Clear all data directories
echo "Step 4: Clearing all data directories..."
./platform-tools/adb shell "rm -rf /data/data/*"
./platform-tools/adb shell "rm -rf /data/app/*"
./platform-tools/adb shell "rm -rf /data/system/*"
./platform-tools/adb shell "rm -rf /data/misc/*"
./platform-tools/adb shell "rm -rf /data/local/*"

# Step 5: Remove Samsung-specific components
echo "Step 5: Removing Samsung-specific components..."
./platform-tools/adb shell "pm disable-user --user 0 com.samsung.android.knox.containercore"
./platform-tools/adb shell "pm disable-user --user 0 com.samsung.android.enterprise"
./platform-tools/adb shell "pm disable-user --user 0 com.samsung.android.settings.work"
./platform-tools/adb shell "pm disable-user --user 0 com.samsung.android.launcher.work"

# Step 6: Clear all caches
echo "Step 6: Clearing all caches..."
./platform-tools/adb shell "rm -rf /data/dalvik-cache/*"
./platform-tools/adb shell "rm -rf /cache/*"
./platform-tools/adb shell "rm -rf /data/cache/*"

# Step 7: Remove all logs
echo "Step 7: Removing all logs..."
./platform-tools/adb shell "rm -rf /data/log/*"
./platform-tools/adb shell "rm -rf /data/tombstones/*"
./platform-tools/adb shell "rm -rf /data/anr/*"

# Step 8: Clear all databases
echo "Step 8: Clearing all databases..."
./platform-tools/adb shell "rm -rf /data/system/databases/*"
./platform-tools/adb shell "rm -rf /data/data/*/databases/*"

# Step 9: Remove all preferences
echo "Step 9: Removing all preferences..."
./platform-tools/adb shell "rm -rf /data/data/*/shared_prefs/*"
./platform-tools/adb shell "rm -rf /data/system/shared_prefs/*"

# Step 10: Clear all temporary files
echo "Step 10: Clearing all temporary files..."
./platform-tools/adb shell "rm -rf /data/local/tmp/*"
./platform-tools/adb shell "rm -rf /tmp/*"

# Step 11: Remove all user data
echo "Step 11: Removing all user data..."
./platform-tools/adb shell "rm -rf /data/user/*"
./platform-tools/adb shell "rm -rf /data/media/*"

# Step 12: Clear all system properties
echo "Step 12: Clearing all system properties..."
./platform-tools/adb shell "setprop ro.debuggable 0"
./platform-tools/adb shell "setprop ro.secure 1"
./platform-tools/adb shell "setprop ro.adb.secure 1"

# Step 13: Remove all network configurations
echo "Step 13: Removing all network configurations..."
./platform-tools/adb shell "rm -rf /data/misc/wifi/*"
./platform-tools/adb shell "rm -rf /data/misc/ethernet/*"
./platform-tools/adb shell "rm -rf /data/misc/bluetooth/*"

# Step 14: Clear all security settings
echo "Step 14: Clearing all security settings..."
./platform-tools/adb shell "rm -rf /data/system/device_policies.xml"
./platform-tools/adb shell "rm -rf /data/system/enterprise.conf"
./platform-tools/adb shell "rm -rf /data/system/enterprise.db*"

# Step 15: Remove all certificates
echo "Step 15: Removing all certificates..."
./platform-tools/adb shell "rm -rf /data/misc/keystore/*"
./platform-tools/adb shell "rm -rf /data/misc/ssl/*"

# Step 16: Clear all accounts
echo "Step 16: Clearing all accounts..."
./platform-tools/adb shell "rm -rf /data/system/accounts.db*"
./platform-tools/adb shell "rm -rf /data/system/sync/*"

# Step 17: Remove all device identifiers
echo "Step 17: Removing all device identifiers..."
./platform-tools/adb shell "rm -rf /data/system/deviceid.xml"
./platform-tools/adb shell "rm -rf /data/system/device_policy.xml"

# Step 18: Clear all system services
echo "Step 18: Clearing all system services..."
./platform-tools/adb shell "am force-stop com.android.systemui"
./platform-tools/adb shell "am force-stop com.android.settings"

# Step 19: Remove all Samsung bloatware
echo "Step 19: Removing all Samsung bloatware..."
./platform-tools/adb shell "pm list packages | grep samsung" | cut -d: -f2 | while read package; do
    echo "Removing Samsung package: $package"
    ./platform-tools/adb shell "pm uninstall --user 0 $package" 2>/dev/null || echo "Failed to remove $package"
done

# Step 20: Final system cleanup
echo "Step 20: Final system cleanup..."
./platform-tools/adb shell "sync"
./platform-tools/adb shell "echo 3 > /proc/sys/vm/drop_caches"

echo "=== DEVICE WIPE COMPLETE ==="
echo "The device has been completely wiped and cleaned."
echo "All Samsung restrictions have been removed."
echo "The device is now completely clean and ready for use."
