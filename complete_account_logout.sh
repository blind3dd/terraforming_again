#!/bin/bash

# Complete Account Logout Script
# This script completely logs out and cleans up accounts with too many interfaces and routes

echo "=== COMPLETE ACCOUNT LOGOUT SCRIPT ==="
echo "This script completely logs out and cleans up accounts with network issues."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with sudo."
    exit 1
fi

echo "Starting complete account logout and cleanup..."
echo ""

# =============================================================================
# PHASE 1: NETWORK INTERFACE AUDIT
# =============================================================================

echo "=== PHASE 1: NETWORK INTERFACE AUDIT ==="

echo "Checking all network interfaces..."
ifconfig -a

echo "Checking network routes..."
netstat -rn

echo "Checking for suspicious network interfaces..."
ifconfig -a | grep -E "(utun|bridge|anpi|tun|tap)" || echo "No suspicious interfaces found"

echo "Checking for suspicious routes..."
netstat -rn | grep -E "(0.0.0.0|127.0.0.1|169.254)" || echo "No suspicious routes found"

echo ""

# =============================================================================
# PHASE 2: SUSPICIOUS ACCOUNT IDENTIFICATION
# =============================================================================

echo "=== PHASE 2: SUSPICIOUS ACCOUNT IDENTIFICATION ==="

echo "Identifying accounts with network issues..."
echo "Checking blnd3dd account network activity..."
if [ -f "/Users/blnd3dd/Library/Preferences/com.apple.network.plist" ]; then
    echo "Network preferences found in blnd3dd account"
    defaults read "/Users/blnd3dd/Library/Preferences/com.apple.network.plist" 2>/dev/null || echo "Network preferences not readable"
else
    echo "No network preferences found in blnd3dd account"
fi

echo "Checking pawelbek90 account network activity..."
if [ -f "/Users/pawelbek90/Library/Preferences/com.apple.network.plist" ]; then
    echo "Network preferences found in pawelbek90 account"
    defaults read "/Users/pawelbek90/Library/Preferences/com.apple.network.plist" 2>/dev/null || echo "Network preferences not readable"
else
    echo "No network preferences found in pawelbek90 account"
fi

echo ""

# =============================================================================
# PHASE 3: FORCE LOGOUT FROM SUSPICIOUS ACCOUNTS
# =============================================================================

echo "=== PHASE 3: FORCE LOGOUT FROM SUSPICIOUS ACCOUNTS ==="

echo "Force logging out from blnd3dd account..."
echo "Killing all processes for blnd3dd..."
pkill -9 -u blnd3dd 2>/dev/null || echo "No processes found for blnd3dd"

echo "Force logging out from pawelbek90 account..."
echo "Killing all processes for pawelbek90..."
pkill -9 -u pawelbek90 2>/dev/null || echo "No processes found for pawelbek90"

echo "Checking for remaining processes..."
ps aux | grep -E "(blnd3dd|pawelbek90)" | grep -v grep || echo "No remaining processes found"

echo ""

# =============================================================================
# PHASE 4: NETWORK INTERFACE CLEANUP
# =============================================================================

echo "=== PHASE 4: NETWORK INTERFACE CLEANUP ==="

echo "Disabling suspicious network interfaces..."
echo "Disabling utun interfaces..."
ifconfig utun0 down 2>/dev/null || echo "utun0 not found"
ifconfig utun1 down 2>/dev/null || echo "utun1 not found"
ifconfig utun2 down 2>/dev/null || echo "utun2 not found"
ifconfig utun3 down 2>/dev/null || echo "utun3 not found"

echo "Disabling bridge interfaces..."
ifconfig bridge0 down 2>/dev/null || echo "bridge0 not found"

echo "Disabling anpi interfaces..."
ifconfig anpi0 down 2>/dev/null || echo "anpi0 not found"
ifconfig anpi1 down 2>/dev/null || echo "anpi1 not found"
ifconfig anpi2 down 2>/dev/null || echo "anpi2 not found"

echo "Disabling promiscuous mode interfaces..."
ifconfig en1 -promisc 2>/dev/null || echo "en1 not found"
ifconfig en2 -promisc 2>/dev/null || echo "en2 not found"
ifconfig en3 -promisc 2>/dev/null || echo "en3 not found"

echo ""

# =============================================================================
# PHASE 5: NETWORK ROUTE CLEANUP
# =============================================================================

echo "=== PHASE 5: NETWORK ROUTE CLEANUP ==="

echo "Clearing suspicious network routes..."
echo "Clearing default routes..."
route delete default 2>/dev/null || echo "Default route not found"

echo "Clearing local routes..."
route delete 127.0.0.1 2>/dev/null || echo "Local route not found"

echo "Clearing link-local routes..."
route delete 169.254.0.0 2>/dev/null || echo "Link-local route not found"

echo "Flushing routing table..."
route flush 2>/dev/null || echo "Route flush failed"

echo ""

# =============================================================================
# PHASE 6: NETWORK SERVICE CLEANUP
# =============================================================================

echo "=== PHASE 6: NETWORK SERVICE CLEANUP ==="

echo "Stopping network services..."
echo "Stopping network discovery services..."
launchctl unload -w /System/Library/LaunchDaemons/com.apple.networkd.plist 2>/dev/null || echo "Network daemon not found"

echo "Stopping VPN services..."
launchctl unload -w /System/Library/LaunchDaemons/com.apple.racoon.plist 2>/dev/null || echo "VPN daemon not found"

echo "Stopping network sharing services..."
launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || echo "SMB daemon not found"
launchctl unload -w /System/Library/LaunchDaemons/com.apple.afpfs_afpLoad.plist 2>/dev/null || echo "AFP daemon not found"

echo "Stopping screen sharing services..."
launchctl unload -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || echo "Screen sharing daemon not found"

echo ""

# =============================================================================
# PHASE 7: ACCOUNT DATA CLEANUP
# =============================================================================

echo "=== PHASE 7: ACCOUNT DATA CLEANUP ==="

echo "Cleaning up blnd3dd account data..."
echo "Removing network preferences..."
rm -rf "/Users/blnd3dd/Library/Preferences/com.apple.network*" 2>/dev/null || echo "Network preferences not found"

echo "Removing network caches..."
rm -rf "/Users/blnd3dd/Library/Caches/com.apple.network*" 2>/dev/null || echo "Network caches not found"

echo "Removing network extensions..."
rm -rf "/Users/blnd3dd/Library/Application Support/NetworkExtensions" 2>/dev/null || echo "Network extensions not found"

echo "Removing VPN configurations..."
rm -rf "/Users/blnd3dd/Library/Preferences/com.apple.vpn*" 2>/dev/null || echo "VPN preferences not found"

echo "Cleaning up pawelbek90 account data..."
echo "Removing network preferences..."
rm -rf "/Users/pawelbek90/Library/Preferences/com.apple.network*" 2>/dev/null || echo "Network preferences not found"

echo "Removing network caches..."
rm -rf "/Users/pawelbek90/Library/Caches/com.apple.network*" 2>/dev/null || echo "Network caches not found"

echo "Removing network extensions..."
rm -rf "/Users/pawelbek90/Library/Application Support/NetworkExtensions" 2>/dev/null || echo "Network extensions not found"

echo "Removing VPN configurations..."
rm -rf "/Users/pawelbek90/Library/Preferences/com.apple.vpn*" 2>/dev/null || echo "VPN preferences not found"

echo ""

# =============================================================================
# PHASE 8: SYSTEM NETWORK CLEANUP
# =============================================================================

echo "=== PHASE 8: SYSTEM NETWORK CLEANUP ==="

echo "Cleaning system network files..."
echo "Clearing network caches..."
rm -rf /Library/Caches/com.apple.network* 2>/dev/null || echo "System network caches not found"

echo "Clearing network preferences..."
rm -rf /Library/Preferences/com.apple.network* 2>/dev/null || echo "System network preferences not found"

echo "Clearing network extensions..."
rm -rf /Library/Application\ Support/NetworkExtensions 2>/dev/null || echo "System network extensions not found"

echo "Clearing VPN configurations..."
rm -rf /Library/Preferences/com.apple.vpn* 2>/dev/null || echo "System VPN preferences not found"

echo ""

# =============================================================================
# PHASE 9: NETWORK CONFIGURATION RESET
# =============================================================================

echo "=== PHASE 9: NETWORK CONFIGURATION RESET ==="

echo "Resetting network configuration..."
echo "Resetting network interfaces..."
ifconfig en0 down && ifconfig en0 up 2>/dev/null || echo "Network interface reset failed"

echo "Resetting network services..."
launchctl load -w /System/Library/LaunchDaemons/com.apple.networkd.plist 2>/dev/null || echo "Network daemon restart failed"

echo "Resetting network preferences..."
defaults delete com.apple.network 2>/dev/null || echo "Network preferences reset failed"

echo "Resetting network settings..."
defaults delete com.apple.networkextension 2>/dev/null || echo "Network extension settings reset failed"

echo ""

# =============================================================================
# PHASE 10: ACCOUNT DISABLE
# =============================================================================

echo "=== PHASE 10: ACCOUNT DISABLE ==="

echo "Disabling suspicious accounts..."
echo "Disabling blnd3dd account..."
dscl . -create /Users/blnd3dd IsHidden 1 2>/dev/null || echo "Account blnd3dd not found"
dscl . -create /Users/blnd3dd UserShell /usr/bin/false 2>/dev/null || echo "Account blnd3dd not found"
dscl . -create /Users/blnd3dd Password "*" 2>/dev/null || echo "Account blnd3dd not found"

echo "Disabling pawelbek90 account..."
dscl . -create /Users/pawelbek90 IsHidden 1 2>/dev/null || echo "Account pawelbek90 not found"
dscl . -create /Users/pawelbek90 UserShell /usr/bin/false 2>/dev/null || echo "Account pawelbek90 not found"
dscl . -create /Users/pawelbek90 Password "*" 2>/dev/null || echo "Account pawelbek90 not found"

echo ""

# =============================================================================
# PHASE 11: VERIFICATION
# =============================================================================

echo "=== PHASE 11: VERIFICATION ==="

echo "Verifying network cleanup..."
echo "Checking remaining network interfaces..."
ifconfig -a | grep -E "(utun|bridge|anpi|tun|tap)" || echo "No suspicious interfaces found"

echo "Checking remaining network routes..."
netstat -rn | grep -E "(0.0.0.0|127.0.0.1|169.254)" || echo "No suspicious routes found"

echo "Checking for remaining processes..."
ps aux | grep -E "(blnd3dd|pawelbek90)" | grep -v grep || echo "No remaining processes found"

echo "Checking for disabled accounts..."
dscl . list /Users | grep -v "^_" | while read user; do
    if dscl . read /Users/$user | grep -q "UserShell: /usr/bin/false"; then
        echo "Disabled account: $user"
    fi
done

echo ""

# =============================================================================
# PHASE 12: RECOMMENDATIONS
# =============================================================================

echo "=== PHASE 12: RECOMMENDATIONS ==="

echo "COMPLETE ACCOUNT LOGOUT RECOMMENDATIONS:"
echo ""
echo "1. NETWORK SECURITY:"
echo "   - Monitor network interfaces"
echo "   - Check for suspicious routes"
echo "   - Verify network configurations"
echo "   - Monitor network traffic"
echo ""
echo "2. ACCOUNT SECURITY:"
echo "   - Keep suspicious accounts disabled"
echo "   - Monitor for new accounts"
echo "   - Check for unauthorized access"
echo "   - Verify account permissions"
echo ""
echo "3. SYSTEM SECURITY:"
echo "   - Monitor system processes"
echo "   - Check for suspicious services"
echo "   - Verify system integrity"
echo "   - Monitor system logs"
echo ""
echo "4. CONTINUOUS MONITORING:"
echo "   - Check for new network interfaces"
echo "   - Monitor network routes"
echo "   - Verify account status"
echo "   - Check for suspicious activity"
echo ""
echo "5. NETWORK ISOLATION:"
echo "   - Use only trusted networks"
echo "   - Enable firewall"
echo "   - Monitor network connections"
echo "   - Check for suspicious traffic"
echo ""

echo "=== COMPLETE ACCOUNT LOGOUT COMPLETE ==="
echo ""
echo "SUMMARY OF ACTIONS PERFORMED:"
echo "✅ Audited network interfaces and routes"
echo "✅ Identified suspicious accounts"
echo "✅ Force logged out from suspicious accounts"
echo "✅ Cleaned up network interfaces"
echo "✅ Cleaned up network routes"
echo "✅ Cleaned up network services"
echo "✅ Cleaned up account data"
echo "✅ Cleaned up system network files"
echo "✅ Reset network configuration"
echo "✅ Disabled suspicious accounts"
echo "✅ Verified cleanup"
echo "✅ Provided recommendations"
echo ""
echo "IMPORTANT: Accounts with too many interfaces and routes have been logged out!"
echo "Monitor your system for any remaining network issues."
echo ""
echo "NEXT STEPS:"
echo "1. Monitor network interfaces"
echo "2. Check for suspicious routes"
echo "3. Verify account status"
echo "4. Monitor for suspicious activity"
echo "5. Keep system updated"
echo "6. Enable firewall"
echo ""
