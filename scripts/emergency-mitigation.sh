#!/bin/bash

# EMERGENCY SECURITY MITIGATION SCRIPT
# Immediate actions to secure system with 8 tunnel interfaces

set -euo pipefail

echo "🚨 EMERGENCY SECURITY MITIGATION 🚨"
echo "Timestamp: $(date)"
echo
echo "⚠️  CRITICAL: You have 8 tunnel interfaces with default routes!"
echo "This indicates potential network compromise or data exfiltration."
echo

# Function to check current tunnel status
check_tunnel_status() {
    echo "=== CURRENT TUNNEL STATUS ==="
    echo
    echo "🔍 Active tunnel interfaces:"
    ifconfig | grep -A 1 "^utun" | while read -r line; do
        if [[ "$line" =~ ^utun[0-9]+: ]]; then
            echo "  📡 $line"
        elif [[ "$line" =~ inet6 ]]; then
            echo "    $line"
        fi
    done
    
    echo
    echo "🔍 Default routes through tunnels:"
    netstat -rn | grep "utun" | grep "default" | while read -r line; do
        echo "  ⚠️  $line"
    done
    echo
}

# Function to identify processes using tunnels
identify_tunnel_processes() {
    echo "=== IDENTIFYING TUNNEL PROCESSES ==="
    echo
    
    echo "🔍 Processes using tunnel interfaces:"
    # Check for processes that might be creating tunnels
    SUSPICIOUS_PROCESSES=(
        "vpn"
        "proxy"
        "tunnel"
        "openvpn"
        "wireguard"
        "nordvpn"
        "expressvpn"
        "surfshark"
        "protonvpn"
        "tunnelblick"
        "viscosity"
        "shimo"
        "clash"
        "v2ray"
        "shadowsocks"
    )
    
    for process in "${SUSPICIOUS_PROCESSES[@]}"; do
        if ps aux | grep -i "$process" | grep -v grep; then
            echo "  ⚠️  Found suspicious process: $process"
        fi
    done
    
    echo
    echo "🔍 Network-related processes:"
    ps aux | grep -E "(networkserviceproxy|containermanagerd|networkd)" | grep -v grep | while read -r line; do
        echo "  📡 $line"
    done
    echo
}

# Function to disable tunnel interfaces
disable_tunnel_interfaces() {
    echo "=== DISABLING TUNNEL INTERFACES ==="
    echo
    
    echo "⚠️  WARNING: This will disable tunnel interfaces 4-7"
    echo "These are the suspicious ones beyond normal system usage."
    echo
    
    read -p "Disable tunnel interfaces 4-7? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔧 Disabling tunnel interfaces 4-7..."
        
        for i in {4..7}; do
            echo "  Disabling utun$i..."
            sudo ifconfig utun$i down 2>/dev/null || echo "    utun$i already down or doesn't exist"
        done
        
        echo "✅ Tunnel interfaces 4-7 disabled"
    else
        echo "❌ Skipping tunnel interface disabling"
    fi
    echo
}

# Function to check for VPN software
check_vpn_software() {
    echo "=== CHECKING FOR VPN SOFTWARE ==="
    echo
    
    echo "🔍 Common VPN applications:"
    VPN_APPS=(
        "/Applications/NordVPN.app"
        "/Applications/ExpressVPN.app"
        "/Applications/Surfshark.app"
        "/Applications/ProtonVPN.app"
        "/Applications/Tunnelblick.app"
        "/Applications/Viscosity.app"
        "/Applications/Shimo.app"
        "/Applications/ClashX.app"
        "/Applications/V2rayU.app"
        "/Applications/ShadowsocksX-NG.app"
    )
    
    for app in "${VPN_APPS[@]}"; do
        if [[ -d "$app" ]]; then
            echo "  ⚠️  Found VPN app: $app"
        fi
    done
    
    echo
    echo "🔍 VPN configuration files:"
    find ~/Library -name "*vpn*" -o -name "*tunnel*" 2>/dev/null | head -10 | while read -r file; do
        echo "  📁 $file"
    done
    
    echo
    echo "🔍 VPN launch agents:"
    find ~/Library/LaunchAgents -name "*vpn*" -o -name "*tunnel*" 2>/dev/null | while read -r file; do
        echo "  📁 $file"
    done
    echo
}

# Function to secure network configuration
secure_network_config() {
    echo "=== SECURING NETWORK CONFIGURATION ==="
    echo
    
    echo "🔧 Disabling file sharing services..."
    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true
    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist 2>/dev/null || true
    
    echo "🔧 Enabling firewall..."
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
    
    echo "🔧 Disabling remote login..."
    sudo systemsetup -setremotelogin off
    
    echo "✅ Network services secured"
    echo
}

# Function to monitor network traffic
monitor_network_traffic() {
    echo "=== NETWORK TRAFFIC MONITORING ==="
    echo
    
    echo "🔍 Current network connections:"
    netstat -an | grep ESTABLISHED | head -10 | while read -r line; do
        echo "  📡 $line"
    done
    
    echo
    echo "🔍 Suspicious network connections:"
    netstat -an | grep ESTABLISHED | grep -E "(443|80|8080|8443)" | head -5 | while read -r line; do
        echo "  ⚠️  $line"
    done
    echo
}

# Function to create monitoring script
create_monitoring_script() {
    echo "=== CREATING MONITORING SCRIPT ==="
    echo
    
    MONITOR_SCRIPT="/tmp/network-monitor.sh"
    
    cat > "$MONITOR_SCRIPT" << 'EOF'
#!/bin/bash

# Network Security Monitoring Script
# Run this regularly to monitor for suspicious activity

echo "=== NETWORK SECURITY MONITOR ==="
echo "Timestamp: $(date)"
echo

echo "🔍 Tunnel interfaces:"
ifconfig | grep -c "^utun" | while read -r count; do
    if [[ $count -gt 2 ]]; then
        echo "  ⚠️  WARNING: $count tunnel interfaces detected (normal: 0-2)"
    else
        echo "  ✅ Normal tunnel interface count: $count"
    fi
done

echo
echo "🔍 Default routes through tunnels:"
netstat -rn | grep "utun" | grep "default" | while read -r line; do
    echo "  ⚠️  Suspicious route: $line"
done

echo
echo "🔍 Active network connections:"
netstat -an | grep ESTABLISHED | wc -l | while read -r count; do
    echo "  📡 Active connections: $count"
done

echo
echo "🔍 VPN-related processes:"
ps aux | grep -E "(vpn|proxy|tunnel)" | grep -v grep | wc -l | while read -r count; do
    if [[ $count -gt 0 ]]; then
        echo "  ⚠️  VPN-related processes: $count"
    else
        echo "  ✅ No VPN-related processes"
    fi
done
EOF
    
    chmod +x "$MONITOR_SCRIPT"
    echo "📝 Monitoring script created at: $MONITOR_SCRIPT"
    echo "🔧 Run with: $MONITOR_SCRIPT"
    echo
}

# Function to generate emergency recommendations
generate_emergency_recommendations() {
    echo "=== EMERGENCY RECOMMENDATIONS ==="
    echo
    
    echo "🚨 IMMEDIATE ACTIONS:"
    echo "  1. Disconnect from internet temporarily"
    echo "  2. Run full malware scan"
    echo "  3. Check for unauthorized software"
    echo "  4. Monitor network traffic"
    echo "  5. Consider system restore from backup"
    echo
    
    echo "🔒 SECURITY HARDENING:"
    echo "  • Disable all unnecessary network services"
    echo "  • Enable firewall with strict rules"
    echo "  • Use VPN only when necessary"
    echo "  • Monitor system logs regularly"
    echo "  • Keep system updated"
    echo
    
    echo "🔍 INVESTIGATION:"
    echo "  • Check system logs for suspicious activity"
    echo "  • Review installed applications"
    echo "  • Monitor network traffic patterns"
    echo "  • Check for data exfiltration"
    echo "  • Consider professional security audit"
    echo
    
    echo "⚠️  WARNING:"
    echo "  • 8 tunnel interfaces is EXTREMELY ABNORMAL"
    echo "  • This could indicate active compromise"
    echo "  • Consider isolating this system from network"
    echo "  • Document all findings for security analysis"
    echo
}

# Main execution
main() {
    check_tunnel_status
    identify_tunnel_processes
    disable_tunnel_interfaces
    check_vpn_software
    secure_network_config
    monitor_network_traffic
    create_monitoring_script
    generate_emergency_recommendations
    
    echo "=== EMERGENCY MITIGATION COMPLETED ==="
    echo
    echo "📊 Summary:"
    echo "  • Tunnel interface status checked"
    echo "  • Suspicious processes identified"
    echo "  • Network services secured"
    echo "  • Monitoring script created"
    echo
    echo "🚨 CRITICAL NEXT STEPS:"
    echo "  1. Run the monitoring script regularly"
    echo "  2. Check for unauthorized VPN software"
    echo "  3. Monitor network traffic for data exfiltration"
    echo "  4. Consider professional security assessment"
    echo
    echo "⚠️  The 8 tunnel interfaces are a MAJOR security concern!"
    echo "   This is not normal and requires immediate investigation."
}

# Run main function
main "$@"
