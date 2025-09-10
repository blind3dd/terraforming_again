#!/bin/bash

# Remove All Network and Device Connections Script
# This script removes all network connections, socket connections, and device associations

echo "=== REMOVE ALL NETWORK AND DEVICE CONNECTIONS ==="
echo "Removing all network connections, socket connections, and device associations..."

# Step 1: Disconnect all network interfaces
echo "Step 1: Disconnecting all network interfaces..."
./platform-tools/adb shell "ip link set wlan0 down"
./platform-tools/adb shell "ip link set p2p0 down"
./platform-tools/adb shell "ip link set swlan0 down"

# Step 2: Remove all network routes
echo "Step 2: Removing all network routes..."
./platform-tools/adb shell "ip route flush table main"
./platform-tools/adb shell "ip route flush cache"

# Step 3: Disable all network services
echo "Step 3: Disabling all network services..."
./platform-tools/adb shell "svc wifi disable"
./platform-tools/adb shell "svc bluetooth disable"
./platform-tools/adb shell "svc data disable"

# Step 4: Kill all network-related processes
echo "Step 4: Killing all network-related processes..."
./platform-tools/adb shell "killall wpa_supplicant"
./platform-tools/adb shell "killall dhcpcd"
./platform-tools/adb shell "killall dnsmasq"
./platform-tools/adb shell "killall hostapd"

# Step 5: Remove all socket connections
echo "Step 5: Removing all socket connections..."
./platform-tools/adb shell "rm -rf /dev/socket/*"
./platform-tools/adb shell "rm -rf /data/.socket_stream"
./platform-tools/adb shell "rm -rf /data/.diagsocket_stream"
./platform-tools/adb shell "rm -rf /data/.diag_stream"

# Step 6: Disable all network interfaces
echo "Step 6: Disabling all network interfaces..."
./platform-tools/adb shell "ifconfig wlan0 down"
./platform-tools/adb shell "ifconfig p2p0 down"
./platform-tools/adb shell "ifconfig swlan0 down"
./platform-tools/adb shell "ifconfig lo down"

# Step 7: Remove all network configurations
echo "Step 7: Removing all network configurations..."
./platform-tools/adb shell "rm -rf /data/misc/wifi/*"
./platform-tools/adb shell "rm -rf /data/misc/bluetooth/*"
./platform-tools/adb shell "rm -rf /data/misc/ethernet/*"
./platform-tools/adb shell "rm -rf /data/misc/dhcp/*"

# Step 8: Clear all network caches
echo "Step 8: Clearing all network caches..."
./platform-tools/adb shell "rm -rf /data/system/netstats/*"
./platform-tools/adb shell "rm -rf /data/system/network_policy.xml"
./platform-tools/adb shell "rm -rf /data/system/netpolicy.xml"

# Step 9: Disable all network permissions
echo "Step 9: Disabling all network permissions..."
./platform-tools/adb shell "settings put global wifi_on 0"
./platform-tools/adb shell "settings put global bluetooth_on 0"
./platform-tools/adb shell "settings put global mobile_data 0"
./platform-tools/adb shell "settings put global airplane_mode_on 1"

# Step 10: Remove all network settings
echo "Step 10: Removing all network settings..."
./platform-tools/adb shell "settings delete system wifi_saved_state"
./platform-tools/adb shell "settings delete system bluetooth_saved_state"
./platform-tools/adb shell "settings delete global wifi_on"
./platform-tools/adb shell "settings delete global bluetooth_on"
./platform-tools/adb shell "settings delete global mobile_data"

# Step 11: Clear all network databases
echo "Step 11: Clearing all network databases..."
./platform-tools/adb shell "rm -rf /data/data/com.android.settings/databases/*"
./platform-tools/adb shell "rm -rf /data/data/com.android.systemui/databases/*"
./platform-tools/adb shell "rm -rf /data/data/com.android.wifi/databases/*"

# Step 12: Remove all network logs
echo "Step 12: Removing all network logs..."
./platform-tools/adb shell "rm -rf /data/log/wifi/*"
./platform-tools/adb shell "rm -rf /data/log/bluetooth/*"
./platform-tools/adb shell "rm -rf /data/log/network/*"

# Step 13: Disable all network services
echo "Step 13: Disabling all network services..."
./platform-tools/adb shell "am force-stop com.android.wifi"
./platform-tools/adb shell "am force-stop com.android.bluetooth"
./platform-tools/adb shell "am force-stop com.android.settings"

# Step 14: Remove all network certificates
echo "Step 14: Removing all network certificates..."
./platform-tools/adb shell "rm -rf /data/misc/keystore/*"
./platform-tools/adb shell "rm -rf /data/misc/ssl/*"
./platform-tools/adb shell "rm -rf /data/misc/wifi/keystore/*"

# Step 15: Clear all network preferences
echo "Step 15: Clearing all network preferences..."
./platform-tools/adb shell "rm -rf /data/data/com.android.wifi/shared_prefs/*"
./platform-tools/adb shell "rm -rf /data/data/com.android.bluetooth/shared_prefs/*"
./platform-tools/adb shell "rm -rf /data/data/com.android.settings/shared_prefs/*"

# Step 16: Remove all network temporary files
echo "Step 16: Removing all network temporary files..."
./platform-tools/adb shell "rm -rf /data/local/tmp/wifi*"
./platform-tools/adb shell "rm -rf /data/local/tmp/bluetooth*"
./platform-tools/adb shell "rm -rf /data/local/tmp/network*"

# Step 17: Disable all network interfaces permanently
echo "Step 17: Disabling all network interfaces permanently..."
./platform-tools/adb shell "echo 0 > /sys/class/net/wlan0/operstate"
./platform-tools/adb shell "echo 0 > /sys/class/net/p2p0/operstate"
./platform-tools/adb shell "echo 0 > /sys/class/net/swlan0/operstate"

# Step 18: Remove all network system properties
echo "Step 18: Removing all network system properties..."
./platform-tools/adb shell "setprop wifi.interface wlan0"
./platform-tools/adb shell "setprop bluetooth.interface hci0"
./platform-tools/adb shell "setprop net.dns1 0.0.0.0"
./platform-tools/adb shell "setprop net.dns2 0.0.0.0"

# Step 19: Clear all network caches and temporary data
echo "Step 19: Clearing all network caches and temporary data..."
./platform-tools/adb shell "rm -rf /data/dalvik-cache/*wifi*"
./platform-tools/adb shell "rm -rf /data/dalvik-cache/*bluetooth*"
./platform-tools/adb shell "rm -rf /data/dalvik-cache/*network*"

# Step 20: Final network cleanup
echo "Step 20: Final network cleanup..."
./platform-tools/adb shell "sync"
./platform-tools/adb shell "echo 3 > /proc/sys/vm/drop_caches"

echo "=== NETWORK AND DEVICE DISCONNECTION COMPLETE ==="
echo "All network connections, socket connections, and device associations have been removed."
echo "The device is now completely disconnected from all networks and devices."
