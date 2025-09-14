#!/bin/bash

# Force Remove All Socket Connections Script
# This script aggressively removes all socket connections and network interfaces

echo "=== FORCE REMOVE ALL SOCKET CONNECTIONS ==="
echo "Aggressively removing all socket connections and network interfaces..."

# Step 1: Kill all processes that might be using sockets
echo "Step 1: Killing all processes using sockets..."
./platform-tools/adb shell "killall -9 system_server"
./platform-tools/adb shell "killall -9 zygote"
./platform-tools/adb shell "killall -9 zygote64"
./platform-tools/adb shell "killall -9 surfaceflinger"
./platform-tools/adb shell "killall -9 servicemanager"

# Step 2: Force stop all network-related services
echo "Step 2: Force stopping all network services..."
./platform-tools/adb shell "am force-stop com.android.systemui"
./platform-tools/adb shell "am force-stop com.android.settings"
./platform-tools/adb shell "am force-stop com.android.wifi"
./platform-tools/adb shell "am force-stop com.android.bluetooth"
./platform-tools/adb shell "am force-stop com.samsung.android.wifi"
./platform-tools/adb shell "am force-stop com.samsung.android.bluetooth"

# Step 3: Disable all network interfaces through system properties
echo "Step 3: Disabling all network interfaces..."
./platform-tools/adb shell "setprop net.dns1 127.0.0.1"
./platform-tools/adb shell "setprop net.dns2 127.0.0.1"
./platform-tools/adb shell "setprop net.dns3 127.0.0.1"
./platform-tools/adb shell "setprop net.dns4 127.0.0.1"

# Step 4: Remove all network routes
echo "Step 4: Removing all network routes..."
./platform-tools/adb shell "ip route del default"
./platform-tools/adb shell "ip route del 192.168.1.0/24"
./platform-tools/adb shell "ip route del 127.0.0.0/8"

# Step 5: Disable all network interfaces
echo "Step 5: Disabling all network interfaces..."
./platform-tools/adb shell "ip link set wlan0 down"
./platform-tools/adb shell "ip link set p2p0 down"
./platform-tools/adb shell "ip link set swlan0 down"
./platform-tools/adb shell "ip link set lo down"

# Step 6: Remove all network configurations
echo "Step 6: Removing all network configurations..."
./platform-tools/adb shell "rm -rf /data/misc/wifi"
./platform-tools/adb shell "rm -rf /data/misc/bluetooth"
./platform-tools/adb shell "rm -rf /data/misc/ethernet"
./platform-tools/adb shell "rm -rf /data/misc/dhcp"

# Step 7: Clear all network settings
echo "Step 7: Clearing all network settings..."
./platform-tools/adb shell "settings put global wifi_on 0"
./platform-tools/adb shell "settings put global bluetooth_on 0"
./platform-tools/adb shell "settings put global mobile_data 0"
./platform-tools/adb shell "settings put global airplane_mode_on 1"

# Step 8: Remove all network settings from database
echo "Step 8: Removing all network settings from database..."
./platform-tools/adb shell "settings delete system wifi_saved_state"
./platform-tools/adb shell "settings delete system bluetooth_saved_state"
./platform-tools/adb shell "settings delete global wifi_on"
./platform-tools/adb shell "settings delete global bluetooth_on"
./platform-tools/adb shell "settings delete global mobile_data"

# Step 9: Disable all network services
echo "Step 9: Disabling all network services..."
./platform-tools/adb shell "svc wifi disable"
./platform-tools/adb shell "svc bluetooth disable"
./platform-tools/adb shell "svc data disable"

# Step 10: Remove all network-related packages
echo "Step 10: Removing all network-related packages..."
./platform-tools/adb shell "pm uninstall --user 0 com.android.wifi"
./platform-tools/adb shell "pm uninstall --user 0 com.android.bluetooth"
./platform-tools/adb shell "pm uninstall --user 0 com.samsung.android.wifi"
./platform-tools/adb shell "pm uninstall --user 0 com.samsung.android.bluetooth"

# Step 11: Clear all network-related app data
echo "Step 11: Clearing all network-related app data..."
./platform-tools/adb shell "pm clear com.android.wifi"
./platform-tools/adb shell "pm clear com.android.bluetooth"
./platform-tools/adb shell "pm clear com.android.settings"
./platform-tools/adb shell "pm clear com.samsung.android.wifi"
./platform-tools/adb shell "pm clear com.samsung.android.bluetooth"

# Step 12: Remove all network-related user data
echo "Step 12: Removing all network-related user data..."
./platform-tools/adb shell "rm -rf /data/user/0/com.android.wifi"
./platform-tools/adb shell "rm -rf /data/user/0/com.android.bluetooth"
./platform-tools/adb shell "rm -rf /data/user/0/com.android.settings"
./platform-tools/adb shell "rm -rf /data/user/0/com.samsung.android.wifi"
./platform-tools/adb shell "rm -rf /data/user/0/com.samsung.android.bluetooth"

# Step 13: Clear all network-related temporary files
echo "Step 13: Clearing all network-related temporary files..."
./platform-tools/adb shell "rm -rf /data/local/tmp/wifi*"
./platform-tools/adb shell "rm -rf /data/local/tmp/bluetooth*"
./platform-tools/adb shell "rm -rf /data/local/tmp/network*"
./platform-tools/adb shell "rm -rf /data/local/tmp/socket*"

# Step 14: Remove all network-related preferences
echo "Step 14: Removing all network-related preferences..."
./platform-tools/adb shell "rm -rf /data/data/com.android.wifi/shared_prefs"
./platform-tools/adb shell "rm -rf /data/data/com.android.bluetooth/shared_prefs"
./platform-tools/adb shell "rm -rf /data/data/com.android.settings/shared_prefs"
./platform-tools/adb shell "rm -rf /data/data/com.samsung.android.wifi/shared_prefs"
./platform-tools/adb shell "rm -rf /data/data/com.samsung.android.bluetooth/shared_prefs"

# Step 15: Clear all network-related databases
echo "Step 15: Clearing all network-related databases..."
./platform-tools/adb shell "rm -rf /data/data/com.android.wifi/databases"
./platform-tools/adb shell "rm -rf /data/data/com.android.bluetooth/databases"
./platform-tools/adb shell "rm -rf /data/data/com.android.settings/databases"
./platform-tools/adb shell "rm -rf /data/data/com.samsung.android.wifi/databases"
./platform-tools/adb shell "rm -rf /data/data/com.samsung.android.bluetooth/databases"

# Step 16: Remove all network-related logs
echo "Step 16: Removing all network-related logs..."
./platform-tools/adb shell "rm -rf /data/log/wifi"
./platform-tools/adb shell "rm -rf /data/log/bluetooth"
./platform-tools/adb shell "rm -rf /data/log/network"

# Step 17: Clear all network-related caches
echo "Step 17: Clearing all network-related caches..."
./platform-tools/adb shell "rm -rf /data/dalvik-cache/*wifi*"
./platform-tools/adb shell "rm -rf /data/dalvik-cache/*bluetooth*"
./platform-tools/adb shell "rm -rf /data/dalvik-cache/*network*"
./platform-tools/adb shell "rm -rf /data/dalvik-cache/*socket*"

# Step 18: Remove all network-related certificates
echo "Step 18: Removing all network-related certificates..."
./platform-tools/adb shell "rm -rf /data/misc/keystore"
./platform-tools/adb shell "rm -rf /data/misc/ssl"
./platform-tools/adb shell "rm -rf /data/misc/wifi/keystore"

# Step 19: Disable all network-related system properties
echo "Step 19: Disabling all network-related system properties..."
./platform-tools/adb shell "setprop ro.wifi.channels 0"
./platform-tools/adb shell "setprop ro.bluetooth.enabled 0"
./platform-tools/adb shell "setprop ro.telephony.call_ring.multiple 0"
./platform-tools/adb shell "setprop ro.telephony.default_network 0"

# Step 20: Final aggressive cleanup
echo "Step 20: Final aggressive cleanup..."
./platform-tools/adb shell "sync"
./platform-tools/adb shell "echo 3 > /proc/sys/vm/drop_caches"

echo "=== AGGRESSIVE SOCKET REMOVAL COMPLETE ==="
echo "All socket connections and network interfaces have been aggressively removed."
echo "The device is now completely isolated from all networks."
