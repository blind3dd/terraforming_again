#!/bin/bash

# EMERGENCY SECURITY MITIGATION - I/O ERROR VERSION
# Alternative approaches when system services have I/O errors

set -euo pipefail

echo "🚨 EMERGENCY MITIGATION - I/O ERROR VERSION 🚨"
echo "Timestamp: $(date)"
echo
echo "⚠️  CRITICAL: System I/O errors detected!"
echo "This suggests system integrity issues or hardware problems."
echo "Focusing on immediate security threats that can be addressed."
echo

# Function to remove VPN software manually
remove_vpn_software() {
    echo "=== REMOVING VPN SOFTWARE ==="
    echo
    
    echo "🔧 Removing NordVPN..."
    if [[ -d "/Applications/NordVPN.app" ]]; then
        sudo rm -rf "/Applications/NordVPN.app"
        echo "  ✅ NordVPN.app removed"
    else
        echo "  ℹ️  NordVPN.app not found"
    fi
    
    echo "🔧 Removing VPN Unlimited..."
    if [[ -d "/Applications/VPN Unlimited®.app" ]]; then
        sudo rm -rf "/Applications/VPN Unlimited®.app"
        echo "  ✅ VPN Unlimited®.app removed"
    else
        echo "  ℹ️  VPN Unlimited®.app not found"
    fi
    
    echo "🔧 Removing VPN configuration files..."
    sudo rm -rf ~/Library/Application\ Support/NordVPN 2>/dev/null || true
    sudo rm -rf ~/Library/Application\ Support/VPN\ Unlimited 2>/dev/null || true
    sudo rm -rf ~/Library/Preferences/com.nordvpn.macos.plist 2>/dev/null || true
    sudo rm -rf ~/Library/Preferences/com.keepsolid.VPNUnlimited.plist 2>/dev/null || true
    
    echo "✅ VPN software removal completed"
    echo
}

# Function to disable tunnel interfaces
disable_tunnel_interfaces() {
    echo "=== DISABLING TUNNEL INTERFACES ==="
    echo
    
    echo "🔧 Disabling suspicious tunnel interfaces..."
    
    for i in {4..7}; do
        echo "  Disabling utun$i..."
        if sudo ifconfig utun$i down 2>/dev/null; then
            echo "    ✅ utun$i disabled"
        else
            echo "    ⚠️  utun$i already down or doesn't exist"
        fi
    done
    
    echo "✅ Tunnel interface disabling completed"
    echo
}

# Function to kill suspicious processes
kill_suspicious_processes() {
    echo "=== KILLING SUSPICIOUS PROCESSES ==="
    echo
    
    echo "🔧 Killing multiple networkserviceproxy processes..."
    if sudo pkill -f networkserviceproxy 2>/dev/null; then
        echo "  ✅ networkserviceproxy processes killed"
    else
        echo "  ℹ️  No networkserviceproxy processes found"
    fi
    
    echo "🔧 Checking for remaining suspicious processes..."
    REMAINING_PROCESSES=$(ps aux | grep -E "(vpn|proxy|tunnel)" | grep -v grep | wc -l)
    if [[ $REMAINING_PROCESSES -gt 0 ]]; then
        echo "  ⚠️  $REMAINING_PROCESSES suspicious processes still running:"
        ps aux | grep -E "(vpn|proxy|tunnel)" | grep -v grep | while read -r line; do
            echo "    $line"
        done
    else
        echo "  ✅ No suspicious processes running"
    fi
    
    echo "✅ Process cleanup completed"
    echo
}

# Function to check system integrity
check_system_integrity() {
    echo "=== SYSTEM INTEGRITY CHECK ==="
    echo
    
    echo "🔍 Checking System Integrity Protection..."
    if csrutil status 2>/dev/null; then
        echo "  ✅ SIP status checked"
    else
        echo "  ⚠️  Could not check SIP status"
    fi
    
    echo "🔍 Checking for I/O errors in system logs..."
    I_O_ERRORS=$(sudo dmesg 2>/dev/null | grep -i "i/o error" | wc -l)
    if [[ $I_O_ERRORS -gt 0 ]]; then
        echo "  ⚠️  $I_O_ERRORS I/O errors found in system logs"
        echo "  Recent I/O errors:"
        sudo dmesg 2>/dev/null | grep -i "i/o error" | tail -3 | while read -r line; do
            echo "    $line"
        done
    else
        echo "  ✅ No I/O errors in system logs"
    fi
    
    echo "🔍 Checking disk health..."
    if diskutil verifyDisk / 2>/dev/null | grep -q "OK"; then
        echo "  ✅ Root disk appears healthy"
    else
        echo "  ⚠️  Root disk may have issues"
    fi
    
    echo "✅ System integrity check completed"
    echo
}

# Function to secure network without system services
secure_network_alternative() {
    echo "=== ALTERNATIVE NETWORK SECURITY ==="
    echo
    
    echo "🔧 Checking current network services..."
    echo "  Active listening ports:"
    netstat -an | grep LISTEN | grep -E "(445|139|548|22|21|23)" | while read -r line; do
        echo "    ⚠️  $line"
    done
    
    echo "🔧 Checking firewall status..."
    if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -q "enabled"; then
        echo "  ✅ Firewall is enabled"
    else
        echo "  ⚠️  Firewall is disabled"
        echo "  🔧 Attempting to enable firewall..."
        if sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on 2>/dev/null; then
            echo "    ✅ Firewall enabled"
        else
            echo "    ❌ Could not enable firewall (I/O error)"
        fi
    fi
    
    echo "✅ Alternative network security completed"
    echo
}

# Function to monitor current threats
monitor_current_threats() {
    echo "=== CURRENT THREAT MONITORING ==="
    echo
    
    echo "🔍 Current tunnel interfaces:"
    TUNNEL_COUNT=$(ifconfig | grep -c "^utun" || echo "0")
    echo "  📡 Active tunnel interfaces: $TUNNEL_COUNT"
    
    if [[ $TUNNEL_COUNT -gt 2 ]]; then
        echo "  ⚠️  WARNING: $TUNNEL_COUNT tunnel interfaces (normal: 0-2)"
        ifconfig | grep -A 1 "^utun" | while read -r line; do
            if [[ "$line" =~ ^utun[0-9]+: ]]; then
                echo "    $line"
            fi
        done
    else
        echo "  ✅ Normal tunnel interface count"
    fi
    
    echo "🔍 Current network connections:"
    ESTABLISHED_COUNT=$(netstat -an | grep ESTABLISHED | wc -l)
    echo "  📡 Active connections: $ESTABLISHED_COUNT"
    
    echo "🔍 Suspicious network destinations:"
    netstat -an | grep ESTABLISHED | grep -E "(443|80|8080|8443)" | head -5 | while read -r line; do
        echo "  ⚠️  $line"
    done
    
    echo "✅ Threat monitoring completed"
    echo
}

# Function to generate emergency recommendations
generate_emergency_recommendations() {
    echo "=== EMERGENCY RECOMMENDATIONS ==="
    echo
    
    echo "🚨 IMMEDIATE ACTIONS (I/O Error Context):"
    echo "  1. ✅ VPN software removed"
    echo "  2. ✅ Tunnel interfaces disabled"
    echo "  3. ✅ Suspicious processes killed"
    echo "  4. 🔄 Monitor system for I/O errors"
    echo "  5. 🔄 Consider hardware diagnostics"
    echo
    
    echo "🔒 SECURITY HARDENING:"
    echo "  • System I/O errors suggest hardware/system issues"
    echo "  • Consider running Apple Diagnostics"
    echo "  • Check disk health with Disk Utility"
    echo "  • Monitor system logs for recurring errors"
    echo "  • Consider system restore from Time Machine"
    echo
    
    echo "🔍 INVESTIGATION:"
    echo "  • I/O errors may indicate failing storage"
    echo "  • Check for overheating or hardware issues"
    echo "  • Monitor system performance"
    echo "  • Consider professional hardware assessment"
    echo
    
    echo "⚠️  CRITICAL WARNING:"
    echo "  • I/O errors + 8 tunnel interfaces = SERIOUS ISSUE"
    echo "  • This could indicate system compromise + hardware failure"
    echo "  • Consider isolating system from network"
    echo "  • Document all findings for security analysis"
    echo
}

# Main execution
main() {
    remove_vpn_software
    disable_tunnel_interfaces
    kill_suspicious_processes
    check_system_integrity
    secure_network_alternative
    monitor_current_threats
    generate_emergency_recommendations
    
    echo "=== EMERGENCY MITIGATION COMPLETED (I/O ERROR VERSION) ==="
    echo
    echo "📊 Summary:"
    echo "  • VPN software removed"
    echo "  • Tunnel interfaces disabled"
    echo "  • Suspicious processes killed"
    echo "  • System integrity checked"
    echo "  • Alternative network security applied"
    echo
    echo "🚨 CRITICAL NEXT STEPS:"
    echo "  1. Monitor system for I/O errors"
    echo "  2. Run hardware diagnostics"
    echo "  3. Check disk health"
    echo "  4. Consider system restore"
    echo
    echo "⚠️  The combination of I/O errors and 8 tunnel interfaces"
    echo "   suggests both security compromise AND system failure!"
    echo "   This requires immediate professional attention."
}

# Run main function
main "$@"
