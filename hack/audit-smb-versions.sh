#!/bin/bash

# SMB Version Security Audit Script
# Explains SMB 1/2/3 security risks and checks system configuration

set -euo pipefail

echo "=== SMB VERSION SECURITY AUDIT ==="
echo "Timestamp: $(date)"
echo

# Function to explain SMB versions and risks
explain_smb_risks() {
    echo "=== SMB VERSION SECURITY EXPLANATION ==="
    echo
    echo "🔍 WHAT IS SMB?"
    echo "  SMB (Server Message Block) is a network protocol for file sharing"
    echo "  Originally developed by Microsoft, now used across platforms"
    echo "  macOS includes SMB client and server capabilities"
    echo
    
    echo "⚠️  SMB VERSION SECURITY RISKS:"
    echo
    echo "🔴 SMB 1.0 (SMB/CIFS):"
    echo "  • EXTREMELY VULNERABLE - should never be used"
    echo "  • No encryption - all data transmitted in plaintext"
    echo "  • Vulnerable to: EternalBlue, WannaCry, NotPetya attacks"
    echo "  • Used in major ransomware attacks (2017-2020)"
    echo "  • Microsoft disabled SMB1 by default in Windows 10"
    echo
    
    echo "🟡 SMB 2.0/2.1:"
    echo "  • Better than SMB1 but still has vulnerabilities"
    echo "  • Limited encryption support"
    echo "  • Vulnerable to: SMBGhost (CVE-2020-0796)"
    echo "  • Should be avoided when possible"
    echo
    
    echo "🟢 SMB 3.0/3.1.1:"
    echo "  • Most secure version currently available"
    echo "  • Strong encryption (AES-128-CCM)"
    echo "  • Pre-authentication integrity"
    echo "  • Still has some vulnerabilities but much safer"
    echo
    
    echo "🎯 WHY SMB IS DANGEROUS AND Y0U SHOULD CONSIDER NFS INSTEAD:"
    echo "  • Network file sharing = attack surface"
    echo "  • Often enabled by default on many systems"
    echo "  • Can be used for lateral movement in networks"
    echo "  • Data exfiltration vector"
    echo "  • Ransomware propagation method"
    echo
}

# Function to audit SMB configuration
audit_smb_config() {
    echo "=== SMB CONFIGURATION AUDIT ==="
    echo
    
    echo "🔍 SMB Server Status:"
    if launchctl list | grep -i smb; then
        echo "  ⚠️  SMB server services are running"
        launchctl list | grep -i smb | sed 's/^/    /'
    else
        echo "  ✅ No SMB server services running"
    fi
    
    echo
    echo "🔍 SMB Network Ports:"
    SMB_PORTS=$(netstat -an | grep LISTEN | grep -E ":(445|139)")
    if [[ -n "$SMB_PORTS" ]]; then
        echo "  ⚠️  SMB ports are listening:"
        echo "$SMB_PORTS" | sed 's/^/    /'
    else
        echo "  ✅ No SMB ports listening"
    fi
    
    echo
    echo "🔍 SMB Configuration Files:"
    SMB_CONFIGS=(
        "/Library/Preferences/SystemConfiguration/com.apple.smb.server.plist"
        "/etc/smb.conf"
        "/usr/local/etc/smb.conf"
    )
    
    for config in "${SMB_CONFIGS[@]}"; do
        if [[ -f "$config" ]]; then
            echo "  📁 Found: $config"
            if [[ "$config" == *.plist ]]; then
                echo "    Content:"
                defaults read "$config" 2>/dev/null | sed 's/^/      /' || echo "      Cannot read plist"
            else
                echo "    Content:"
                head -20 "$config" | sed 's/^/      /'
            fi
        fi
    done
    
    echo
    echo "🔍 SMB Processes:"
    SMB_PROCESSES=$(ps aux | grep -E "(smbd|nmbd|winbindd)" | grep -v grep)
    if [[ -n "$SMB_PROCESSES" ]]; then
        echo "  ⚠️  SMB processes running:"
        echo "$SMB_PROCESSES" | sed 's/^/    /'
    else
        echo "  ✅ No SMB processes running"
    fi
    
    echo
    echo "🔍 SMB Client Configuration:"
    if command -v smbutil &> /dev/null; then
        echo "  📁 SMB utilities available:"
        which smbutil | sed 's/^/    /'
        smbutil status 2>/dev/null || echo "    SMB client not active"
    else
        echo "  ✅ SMB utilities not found"
    fi
    
    echo
}

# Function to check SMB version support
check_smb_versions() {
    echo "=== SMB VERSION SUPPORT CHECK ==="
    echo
    
    echo "🔍 SMB Version Detection:"
    if command -v smbutil &> /dev/null; then
        echo "  📁 Checking SMB version support..."
        
        # Try to get SMB version info
        smbutil status 2>/dev/null || echo "    SMB not active"
        
        # Check for SMB version configuration
        if [[ -f "/Library/Preferences/SystemConfiguration/com.apple.smb.server.plist" ]]; then
            echo "  📁 SMB server configuration found"
            SMB_CONFIG=$(defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server 2>/dev/null)
            if [[ -n "$SMB_CONFIG" ]]; then
                echo "    Configuration:"
                echo "$SMB_CONFIG" | sed 's/^/      /'
            fi
        fi
    else
        echo "  ✅ SMB utilities not available"
    fi
    
    echo
    echo "🔍 Network SMB Connections:"
    SMB_CONNECTIONS=$(netstat -an | grep -E ":(445|139)" | grep ESTABLISHED)
    if [[ -n "$SMB_CONNECTIONS" ]]; then
        echo "  ⚠️  Active SMB connections:"
        echo "$SMB_CONNECTIONS" | sed 's/^/    /'
    else
        echo "  ✅ No active SMB connections"
    fi
    
    echo
}

# Function to check for SMB vulnerabilities
check_smb_vulnerabilities() {
    echo "=== SMB VULNERABILITY CHECK ==="
    echo
    
    echo "🔍 Known SMB Vulnerabilities:"
    echo "  • EternalBlue (MS17-010) - SMB1 vulnerability"
    echo "  • SMBGhost (CVE-2020-0796) - SMB3 vulnerability"
    echo "  • SMBleed (CVE-2020-1206) - SMB3 vulnerability"
    echo "  • WannaCry, NotPetya, BadRabbit - Ransomware using SMB"
    echo
    
    echo "🔍 SMB Security Best Practices:"
    echo "  ✅ Disable SMB1 completely"
    echo "  ✅ Use SMB3.1.1 with encryption"
    echo "  ✅ Disable SMB if not needed"
    echo "  ✅ Use strong authentication"
    echo "  ✅ Network segmentation"
    echo "  ✅ Regular security updates"
    echo
    
    echo "🔍 macOS SMB Security Status:"
    if [[ -f "/Library/Preferences/SystemConfiguration/com.apple.smb.server.plist" ]]; then
        echo "  ⚠️  SMB server configuration exists"
        echo "  📁 Check if SMB1 is disabled"
    else
        echo "  ✅ No SMB server configuration found"
    fi
    
    echo
}

# Function to generate SMB hardening recommendations
generate_smb_recommendations() {
    echo "=== SMB SECURITY RECOMMENDATIONS ==="
    echo
    
    echo "🔒 IMMEDIATE ACTIONS:"
    echo "  1. DISABLE SMB COMPLETELY (if not needed):"
    echo "     sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist"
    echo "     sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.netbiosd.plist"
    echo
    
    echo "  2. DISABLE SMB1 (if SMB is needed):"
    echo "     sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server"
    echo "     'SMB1Enabled' -bool false"
    echo
    
    echo "  3. ENABLE SMB3 ENCRYPTION:"
    echo "     sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server"
    echo "     'SMB3EncryptionRequired' -bool true"
    echo
    
    echo "  4. DISABLE NETBIOS:"
    echo "     sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.netbiosd.plist"
    echo
    
    echo "🔒 NETWORK SECURITY:"
    echo "  • Block SMB ports (445, 139) at firewall"
    echo "  • Use VPN for remote file access"
    echo "  • Implement network segmentation"
    echo "  • Monitor SMB traffic"
    echo
    
    echo "🔒 ALTERNATIVES TO SMB:"
    echo "  • Use SFTP/SCP for secure file transfer"
    echo "  • Use rsync over SSH"
    echo "  • Use cloud storage with encryption"
    echo "  • Use encrypted file sharing solutions"
    echo
    
    echo "⚠️  WARNING:"
    echo "  • SMB is a major attack vector"
    echo "  • Many ransomware attacks use SMB"
    echo "  • Disable SMB unless absolutely necessary"
    echo "  • Always use the latest SMB version with encryption"
    echo
}

# Function to create SMB hardening script
create_smb_hardening_script() {
    echo "=== CREATING SMB HARDENING SCRIPT ==="
    echo
    
    HARDENING_SCRIPT="/tmp/smb-hardening.sh"
    
    cat > "$HARDENING_SCRIPT" << 'EOF'
#!/bin/bash

# SMB Security Hardening Script
# Disables SMB services and configures secure settings

set -euo pipefail

echo "=== SMB SECURITY HARDENING ==="
echo "⚠️  WARNING: This will disable SMB file sharing"
echo

# Disable SMB services
echo "🚫 Disabling SMB services..."

# Disable SMB daemon
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true

# Disable NetBIOS
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.netbiosd.plist 2>/dev/null || true

# Disable SMB server
sudo systemsetup -setfilesharing off 2>/dev/null || true

echo "✅ SMB services disabled"
echo

# Configure SMB security (if re-enabled later)
echo "🔒 Configuring SMB security settings..."

# Disable SMB1
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server 'SMB1Enabled' -bool false 2>/dev/null || true

# Require SMB3 encryption
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server 'SMB3EncryptionRequired' -bool true 2>/dev/null || true

# Disable guest access
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server 'AllowGuestAccess' -bool false 2>/dev/null || true

echo "✅ SMB security settings configured"
echo

echo "🔧 To re-enable SMB later (NOT RECOMMENDED):"
echo "  sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist"
echo "  sudo systemsetup -setfilesharing on"
echo
echo "⚠️  Remember: SMB is a major security risk!"
EOF
    
    chmod +x "$HARDENING_SCRIPT"
    echo "📝 SMB hardening script created at: $HARDENING_SCRIPT"
    echo
}

# Main execution
main() {
    explain_smb_risks
    audit_smb_config
    check_smb_versions
    check_smb_vulnerabilities
    generate_smb_recommendations
    create_smb_hardening_script
    
    echo "=== SMB AUDIT COMPLETED ==="
    echo
    echo "📊 Summary:"
    echo "  • SMB version risks explained"
    echo "  • Current SMB configuration audited"
    echo "  • Vulnerability status checked"
    echo "  • Security recommendations provided"
    echo "  • Hardening script generated"
    echo
    echo "🔍 Next steps:"
    echo "  1. Review SMB security risks above"
    echo "  2. Disable SMB if not needed"
    echo "  3. Configure SMB3 encryption if SMB is required"
    echo "  4. Run the SMB hardening script"
    echo "  5. Consider SMB alternatives for file sharing"
    echo
    echo "⚠️  Remember: SMB is a major attack vector - disable if possible!"
}

# Run main function
main "$@"
