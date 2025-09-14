#!/bin/bash

# USB-C Port Troubleshooting Script
# Identifies causes of USB-C port resets and connection issues

echo "=== USB-C PORT TROUBLESHOOTING ANALYSIS ==="
echo "Timestamp: $(date)"
echo

# 1. Check for Malwarebytes RTProtectionDaemon issues
echo "=== ISSUE IDENTIFIED: Malwarebytes RTProtectionDaemon ==="
echo "⚠️  PROBLEM: RTProtectionDaemon (PID 64091) is constantly disconnecting/reconnecting"
echo "This is likely causing USB port resets and connection instability."
echo

# Check if Malwarebytes is running
MALWAREBYTES_RUNNING=$(ps aux | grep -i "malwarebytes\|RTProtectionDaemon" | grep -v grep)
if [ -n "$MALWAREBYTES_RUNNING" ]; then
    echo "🔍 Malwarebytes processes found:"
    echo "$MALWAREBYTES_RUNNING"
    echo
    echo "💡 SOLUTION: Malwarebytes real-time protection may be interfering with USB devices"
    echo "   Try temporarily disabling real-time protection to test"
    echo
fi

# 2. Check usbmuxd processes
echo "=== USB MUX DAEMON ANALYSIS ==="
USBMUXD_PROCESSES=$(ps aux | grep usbmuxd | grep -v grep)
if [ -n "$USBMUXD_PROCESSES" ]; then
    echo "✅ usbmuxd processes running (normal):"
    echo "$USBMUXD_PROCESSES"
    echo
    echo "• Main usbmuxd: Handles iOS device connections"
    echo "• RemotePairingDataVaultHelper: Manages device pairing data"
    echo "These are legitimate Apple system processes."
    echo
else
    echo "❌ No usbmuxd processes found (unusual)"
    echo
fi

# 3. Check USB system information
echo "=== USB SYSTEM INFORMATION ==="
echo "USB Controllers detected:"
system_profiler SPUSBDataType | grep -A 2 "Host Controller Driver" | head -10
echo

# 4. Check for USB-related kernel messages
echo "=== RECENT USB ACTIVITY ==="
echo "Checking for USB-related kernel messages..."
USB_MESSAGES=$(sudo dmesg | grep -i "usb\|reset\|disconnect" | tail -5)
if [ -n "$USB_MESSAGES" ]; then
    echo "Recent USB activity:"
    echo "$USB_MESSAGES"
else
    echo "No recent USB-related kernel messages found"
fi
echo

# 5. Check for power management issues
echo "=== POWER MANAGEMENT CHECK ==="
echo "Checking USB power management settings..."
POWER_SETTINGS=$(pmset -g | grep -i "usb\|power")
if [ -n "$POWER_SETTINGS" ]; then
    echo "Power management settings:"
    echo "$POWER_SETTINGS"
else
    echo "No specific USB power settings found"
fi
echo

# 6. Check for conflicting processes
echo "=== POTENTIAL CONFLICTING PROCESSES ==="
echo "Processes that might interfere with USB:"
CONFLICTING=$(ps aux | grep -E "(usbmuxd|usbd|IOUSBHostFamily|RTProtectionDaemon)" | grep -v grep)
if [ -n "$CONFLICTING" ]; then
    echo "$CONFLICTING"
else
    echo "No obvious conflicting processes found"
fi
echo

# 7. Recommendations
echo "=== TROUBLESHOOTING RECOMMENDATIONS ==="
echo
echo "🔧 IMMEDIATE ACTIONS:"
echo "1. TEMPORARILY DISABLE MALWAREBYTES:"
echo "   • Open Malwarebytes"
echo "   • Go to Preferences > Real-time Protection"
echo "   • Disable 'Real-time Protection' temporarily"
echo "   • Test USB-C devices for 30 minutes"
echo
echo "2. RESET USB SYSTEM:"
echo "   • Unplug all USB devices"
echo "   • Run: sudo kextunload -b com.apple.iokit.IOUSBHostFamily"
echo "   • Run: sudo kextload -b com.apple.iokit.IOUSBHostFamily"
echo "   • Reconnect devices"
echo
echo "3. CHECK USB-C CABLE/ADAPTER:"
echo "   • Try different USB-C cables"
echo "   • Test with different devices"
echo "   • Check for physical damage"
echo
echo "4. RESET NVRAM/PRAM:"
echo "   • Shutdown Mac"
echo "   • Power on and immediately hold: Cmd+Option+P+R"
echo "   • Hold for 20 seconds, then release"
echo
echo "5. SAFE MODE TEST:"
echo "   • Restart and hold Shift during boot"
echo "   • Test USB-C devices in Safe Mode"
echo "   • If working in Safe Mode, it's a software conflict"
echo
echo "🔍 ADVANCED TROUBLESHOOTING:"
echo "6. CHECK SYSTEM LOGS:"
echo "   • Console.app > System Reports"
echo "   • Look for USB-related errors"
echo
echo "7. RESET SMC (System Management Controller):"
echo "   • Shutdown Mac"
echo "   • Hold Shift+Control+Option+Power for 10 seconds"
echo "   • Release and power on normally"
echo
echo "8. MALWAREBYTES CONFIGURATION:"
echo "   • Add USB devices to exclusions"
echo "   • Disable 'Scan network drives'"
echo "   • Reduce real-time protection sensitivity"
echo
echo "=== MOST LIKELY CAUSE ==="
echo "Based on the logs, Malwarebytes RTProtectionDaemon is the most likely"
echo "culprit causing USB port resets. The constant disconnections in the"
echo "kernel logs match the timing of your USB-C issues."
echo
echo "Try disabling Malwarebytes real-time protection first, as this is"
echo "the quickest way to test if it's the cause."

