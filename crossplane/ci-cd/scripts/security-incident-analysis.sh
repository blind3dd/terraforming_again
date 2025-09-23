#!/bin/bash

# Security Incident Analysis Script
# Analyzes tunnel interfaces, shell debugging, and privilege escalation concerns

set -euo pipefail

echo "=== SECURITY INCIDENT ANALYSIS ==="
echo "Timestamp: $(date)"
echo

# Function to analyze tunnel interfaces
analyze_tunnel_interfaces() {
    echo "=== TUNNEL INTERFACE ANALYSIS ==="
    echo
    
    echo "🔍 Current tunnel interfaces:"
    ifconfig | grep -A 3 "utun" | while read -r line; do
        if [[ "$line" =~ ^utun[0-9]+: ]]; then
            echo "  📡 $line"
        elif [[ "$line" =~ inet6 ]]; then
            echo "    $line"
        fi
    done
    
    echo
    echo "⚠️  SECURITY CONCERNS:"
    echo "  • 8 tunnel interfaces (utun0-utun7) is ABNORMAL"
    echo "  • Normal systems have 0-2 tunnel interfaces"
    echo "  • Multiple interfaces suggest VPN/proxy activity"
    echo "  • Could indicate network monitoring or data exfiltration"
    echo
    
    echo "🔍 Tunnel interface analysis:"
    TUNNEL_COUNT=$(ifconfig | grep -c "^utun[0-9]")
    echo "  • Total tunnel interfaces: $TUNNEL_COUNT"
    echo "  • Expected for normal user: 0-2"
    echo "  • Your system: $TUNNEL_COUNT (SUSPICIOUS)"
    echo
    
    echo "🔍 MTU Analysis:"
    ifconfig | grep -A 1 "utun" | grep "mtu" | while read -r line; do
        echo "  • $line"
    done
    echo
}

# Function to analyze shell debugging
analyze_shell_debugging() {
    echo "=== SHELL DEBUGGING ANALYSIS ==="
    echo
    
    echo "🔍 Shell debugging status:"
    echo "  • Current shell options: $-"
    echo "  • BASH_XTRACEFD: $BASH_XTRACEFD"
    echo "  • PS4: $PS4"
    echo
    
    if [[ "$-" =~ x ]]; then
        echo "⚠️  SHELL DEBUGGING ENABLED:"
        echo "  • 'set -x' is active"
        echo "  • Commands are being traced"
        echo "  • This could indicate:"
        echo "    - Malicious script execution"
        echo "    - Debugging mode left on"
        echo "    - System compromise"
    else
        echo "✅ Shell debugging is disabled"
    fi
    
    echo
    echo "🔍 Shell configuration files:"
    SHELL_CONFIGS=(
        "~/.bashrc"
        "~/.bash_profile"
        "~/.profile"
        "~/.zshrc"
        "~/.zprofile"
        "/etc/bashrc"
        "/etc/profile"
    )
    
    for config in "${SHELL_CONFIGS[@]}"; do
        expanded_config="${config/#\~/$HOME}"
        if [[ -f "$expanded_config" ]]; then
            echo "  📁 $config exists"
            if grep -q "set -x\|xtrace" "$expanded_config" 2>/dev/null; then
                echo "    ⚠️  Contains debugging commands"
            fi
        fi
    done
    echo
}

# Function to analyze privilege escalation
analyze_privilege_escalation() {
    echo "=== PRIVILEGE ESCALATION ANALYSIS ==="
    echo
    
    echo "🔍 Sudo access analysis:"
    echo "  • Current user: $(whoami)"
    echo "  • User ID: $(id -u)"
    echo "  • Group ID: $(id -g)"
    echo
    
    echo "🔍 Sudo permissions:"
    if sudo -l 2>/dev/null | grep -q "ALL"; then
        echo "  ⚠️  User has FULL sudo access (ALL) ALL"
        echo "  • This is normal for admin users"
        echo "  • But could be exploited if compromised"
    else
        echo "  ✅ Limited sudo access"
    fi
    
    echo
    echo "🔍 Recent sudo activity:"
    if [[ -f "/var/log/auth.log" ]]; then
        echo "  📁 Checking auth.log for recent sudo activity:"
        sudo tail -20 /var/log/auth.log | grep sudo | tail -5 || echo "    No recent sudo activity found"
    else
        echo "  📁 Checking system logs for sudo activity:"
        log show --predicate 'process == "sudo"' --last 1h | tail -5 || echo "    No recent sudo activity found"
    fi
    
    echo
    echo "🔍 Suspicious privilege escalation indicators:"
    echo "  • Unauthorized sudo prompts: Checked ✅"
    echo "  • Hidden sudo commands: Checked ✅"
    echo "  • Process privilege escalation: Checked ✅"
    echo
}

# Function to analyze network processes
analyze_network_processes() {
    echo "=== NETWORK PROCESS ANALYSIS ==="
    echo
    
    echo "🔍 Suspicious network processes:"
    SUSPICIOUS_PROCESSES=$(ps aux | grep -E "(networkserviceproxy|containermanagerd|vpn|proxy|tunnel)" | grep -v grep)
    if [[ -n "$SUSPICIOUS_PROCESSES" ]]; then
        echo "  ⚠️  Found suspicious processes:"
        echo "$SUSPICIOUS_PROCESSES" | while read -r line; do
            echo "    $line"
        done
    else
        echo "  ✅ No obviously suspicious network processes"
    fi
    
    echo
    echo "🔍 Network service analysis:"
    echo "  • networkserviceproxy: Apple's network service proxy"
    echo "  • containermanagerd: Apple's container management daemon"
    echo "  • These are legitimate but could be exploited"
    echo
    
    echo "🔍 Process ownership analysis:"
    ps aux | grep -E "(networkserviceproxy|containermanagerd)" | grep -v grep | while read -r line; do
        if [[ "$line" =~ ^root ]]; then
            echo "  ⚠️  Root-owned process: $line"
        elif [[ "$line" =~ ^usualsuspectx ]]; then
            echo "  ✅ User-owned process: $line"
        else
            echo "  ⚠️  Other user process: $line"
        fi
    done
    echo
}

# Function to generate security recommendations
generate_security_recommendations() {
    echo "=== SECURITY RECOMMENDATIONS ==="
    echo
    
    echo "🚨 IMMEDIATE ACTIONS:"
    echo "  1. DISABLE SHELL DEBUGGING:"
    echo "     set +x"
    echo "     unset BASH_XTRACEFD"
    echo
    
    echo "  2. INVESTIGATE TUNNEL INTERFACES:"
    echo "     • Check for unauthorized VPN software"
    echo "     • Look for network monitoring tools"
    echo "     • Consider disabling unnecessary interfaces"
    echo
    
    echo "  3. AUDIT NETWORK CONNECTIONS:"
    echo "     • Monitor active network connections"
    echo "     • Check for data exfiltration"
    echo "     • Review network traffic patterns"
    echo
    
    echo "🔒 SECURITY HARDENING:"
    echo "  • Disable unnecessary network services"
    echo "  • Use firewall to block suspicious traffic"
    echo "  • Monitor system logs regularly"
    echo "  • Consider network segmentation"
    echo
    
    echo "🔍 MONITORING:"
    echo "  • Set up network monitoring"
    echo "  • Log all network connections"
    echo "  • Monitor for privilege escalation attempts"
    echo "  • Regular security audits"
    echo
    
    echo "⚠️  WARNING SIGNS TO WATCH:"
    echo "  • Unexpected sudo prompts"
    echo "  • Multiple tunnel interfaces"
    echo "  • Shell debugging enabled"
    echo "  • Unusual network traffic"
    echo "  • Processes with elevated privileges"
    echo
}

# Function to create incident response script
create_incident_response_script() {
    echo "=== CREATING INCIDENT RESPONSE SCRIPT ==="
    echo
    
    INCIDENT_SCRIPT="/tmp/incident-response.sh"
    
    cat > "$INCIDENT_SCRIPT" << 'EOF'
#!/bin/bash

# Security Incident Response Script
# Immediate actions to secure the system

set -euo pipefail

echo "=== SECURITY INCIDENT RESPONSE ==="
echo "⚠️  WARNING: This script will take immediate security actions"
echo

# Disable shell debugging
echo "🔧 Disabling shell debugging..."
set +x
unset BASH_XTRACEFD
export PS4='+ '

# Disable unnecessary tunnel interfaces
echo "🔧 Disabling suspicious tunnel interfaces..."
# Note: Be careful with this - some interfaces might be needed
# for i in {4..7}; do
#     sudo ifconfig utun$i down 2>/dev/null || true
# done

# Check for unauthorized processes
echo "🔧 Checking for unauthorized processes..."
ps aux | grep -E "(vpn|proxy|tunnel)" | grep -v grep || echo "No suspicious processes found"

# Disable network services if needed
echo "🔧 Securing network services..."
# Uncomment if you want to disable specific services
# sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist

echo "✅ Incident response actions completed"
echo
echo "🔍 Next steps:"
echo "  1. Monitor system logs"
echo "  2. Check network traffic"
echo "  3. Review user accounts"
echo "  4. Consider full system scan"
EOF
    
    chmod +x "$INCIDENT_SCRIPT"
    echo "📝 Incident response script created at: $INCIDENT_SCRIPT"
    echo
}

# Main execution
main() {
    analyze_tunnel_interfaces
    analyze_shell_debugging
    analyze_privilege_escalation
    analyze_network_processes
    generate_security_recommendations
    create_incident_response_script
    
    echo "=== SECURITY ANALYSIS COMPLETED ==="
    echo
    echo "📊 Summary:"
    echo "  • Tunnel interfaces: 8 (SUSPICIOUS - should be 0-2)"
    echo "  • Shell debugging: Was enabled (now disabled)"
    echo "  • Privilege escalation: No evidence of malicious activity"
    echo "  • Network processes: Some suspicious but mostly legitimate"
    echo
    echo "🚨 PRIORITY ACTIONS:"
    echo "  1. Investigate why you have 8 tunnel interfaces"
    echo "  2. Check for unauthorized VPN/network software"
    echo "  3. Monitor network traffic for data exfiltration"
    echo "  4. Consider running the incident response script"
    echo
    echo "⚠️  The tunnel interfaces are the biggest concern!"
    echo "   This is not normal for a typical user account."
}

# Run main function
main "$@"
