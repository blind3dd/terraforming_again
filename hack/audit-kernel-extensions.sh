#!/bin/bash

# Kernel Extensions and Private Frameworks Security Audit Script
# Identifies suspicious, unnecessary, or potentially dangerous components

set -euo pipefail

echo "=== KERNEL EXTENSIONS & PRIVATE FRAMEWORKS AUDIT ==="
echo "Timestamp: $(date)"
echo

# Function to check if running as root
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        echo "⚠️  Some operations require root privileges"
        echo "   Run with 'sudo' for complete analysis"
        echo
    fi
}

# Function to get file signatures and certificates
check_signature() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo "  📋 Signature: $(codesign -dv "$file" 2>&1 | grep -E "(Authority|TeamIdentifier)" || echo "No signature info")"
        echo "  🔒 Certificate: $(codesign -dv --verbose=4 "$file" 2>&1 | grep -E "Authority" | head -1 || echo "No certificate info")"
    fi
}

# 1. Audit Loaded Kernel Extensions
audit_loaded_kexts() {
    echo "=== LOADED KERNEL EXTENSIONS AUDIT ==="
    echo
    
    # Get loaded kernel extensions
    echo "🔍 Currently loaded kernel extensions:"
    kextstat | while read -r line; do
        if [[ "$line" =~ ^[0-9]+[[:space:]]+[0-9]+[[:space:]]+0x[0-9a-f]+[[:space:]]+0x[0-9a-f]+[[:space:]]+0x[0-9a-f]+[[:space:]]+([^[:space:]]+) ]]; then
            kext_name="${BASH_REMATCH[1]}"
            echo "  📦 $kext_name"
            
            # Check if it's a third-party extension
            if [[ ! "$kext_name" =~ ^(com\.apple|org\.openbsd) ]]; then
                echo "    ⚠️  THIRD-PARTY KEXT DETECTED"
                
                # Try to find the kext file
                kext_path=$(find /System/Library/Extensions /Library/Extensions -name "*.kext" -exec grep -l "$kext_name" {}/Contents/Info.plist \; 2>/dev/null | head -1)
                if [[ -n "$kext_path" ]]; then
                    echo "    📁 Location: $kext_path"
                    check_signature "$kext_path"
                fi
            fi
        fi
    done
    echo
}

# 2. Audit All Kernel Extensions (loaded and unloaded)
audit_all_kexts() {
    echo "=== ALL KERNEL EXTENSIONS AUDIT ==="
    echo
    
    echo "🔍 All kernel extensions in system directories:"
    
    # System extensions
    echo "📁 System Extensions (/System/Library/Extensions):"
    find /System/Library/Extensions -name "*.kext" -type d 2>/dev/null | while read -r kext; do
        kext_name=$(basename "$kext" .kext)
        echo "  📦 $kext_name"
        
        # Check if it's loaded
        if kextstat | grep -q "$kext_name"; then
            echo "    ✅ LOADED"
        else
            echo "    ⏸️  NOT LOADED"
        fi
        
        # Check signature
        check_signature "$kext"
    done
    
    echo
    echo "📁 Third-party Extensions (/Library/Extensions):"
    if [[ -d "/Library/Extensions" ]]; then
        find /Library/Extensions -name "*.kext" -type d 2>/dev/null | while read -r kext; do
            kext_name=$(basename "$kext" .kext)
            echo "  📦 $kext_name"
            echo "    ⚠️  THIRD-PARTY EXTENSION"
            
            # Check if it's loaded
            if kextstat | grep -q "$kext_name"; then
                echo "    ✅ LOADED"
            else
                echo "    ⏸️  NOT LOADED"
            fi
            
            # Check signature
            check_signature "$kext"
        done
    else
        echo "  ℹ️  No third-party extensions directory found"
    fi
    echo
}

# 3. Audit System Extensions (newer macOS)
audit_system_extensions() {
    echo "=== SYSTEM EXTENSIONS AUDIT ==="
    echo
    
    if command -v systemextensionsctl &> /dev/null; then
        echo "🔍 System Extensions (macOS 10.15+):"
        systemextensionsctl list 2>/dev/null | while read -r line; do
            if [[ "$line" =~ ^[0-9]+[[:space:]]+[0-9]+[[:space:]]+([^[:space:]]+) ]]; then
                ext_name="${BASH_REMATCH[1]}"
                echo "  📦 $ext_name"
                
                # Check if it's third-party
                if [[ ! "$ext_name" =~ ^(com\.apple|org\.openbsd) ]]; then
                    echo "    ⚠️  THIRD-PARTY SYSTEM EXTENSION"
                fi
            fi
        done
    else
        echo "ℹ️  systemextensionsctl not available (older macOS)"
    fi
    echo
}

# 4. Audit Private Frameworks
audit_private_frameworks() {
    echo "=== PRIVATE FRAMEWORKS AUDIT ==="
    echo
    
    echo "🔍 Suspicious or unnecessary private frameworks:"
    
    # List of potentially suspicious frameworks
    SUSPICIOUS_FRAMEWORKS=(
        "WebKit.framework"
        "WebKitLegacy.framework"
        "JavaScriptCore.framework"
        "CoreEmoji.framework"
        "GameCenter.framework"
        "GameKit.framework"
        "Social.framework"
        "Twitter.framework"
        "FacebookSDK.framework"
        "GoogleSignIn.framework"
        "FBSDKCoreKit.framework"
        "FBSDKLoginKit.framework"
        "FBSDKShareKit.framework"
    )
    
    for framework in "${SUSPICIOUS_FRAMEWORKS[@]}"; do
        # Check system frameworks
        if [[ -d "/System/Library/PrivateFrameworks/$framework" ]]; then
            echo "  📦 /System/Library/PrivateFrameworks/$framework"
            echo "    ⚠️  POTENTIALLY UNNECESSARY"
            check_signature "/System/Library/PrivateFrameworks/$framework"
        fi
        
        # Check regular frameworks
        if [[ -d "/System/Library/Frameworks/$framework" ]]; then
            echo "  📦 /System/Library/Frameworks/$framework"
            echo "    ⚠️  POTENTIALLY UNNECESSARY"
            check_signature "/System/Library/Frameworks/$framework"
        fi
    done
    
    echo
    echo "🔍 Third-party frameworks in /Library/Frameworks:"
    if [[ -d "/Library/Frameworks" ]]; then
        find /Library/Frameworks -name "*.framework" -type d 2>/dev/null | while read -r framework; do
            framework_name=$(basename "$framework")
            echo "  📦 $framework_name"
            echo "    ⚠️  THIRD-PARTY FRAMEWORK"
            check_signature "$framework"
        done
    else
        echo "  ℹ️  No third-party frameworks directory found"
    fi
    echo
}

# 5. Audit Launch Daemons and Agents
audit_launch_services() {
    echo "=== LAUNCH SERVICES AUDIT ==="
    echo
    
    echo "🔍 Third-party launch daemons:"
    find /Library/LaunchDaemons -name "*.plist" 2>/dev/null | while read -r plist; do
        plist_name=$(basename "$plist")
        echo "  📦 $plist_name"
        
        # Check if it's loaded
        if launchctl list | grep -q "$plist_name"; then
            echo "    ✅ LOADED"
        else
            echo "    ⏸️  NOT LOADED"
        fi
        
        # Check signature
        check_signature "$plist"
    done
    
    echo
    echo "🔍 Third-party launch agents:"
    find /Library/LaunchAgents -name "*.plist" 2>/dev/null | while read -r plist; do
        plist_name=$(basename "$plist")
        echo "  📦 $plist_name"
        
        # Check if it's loaded
        if launchctl list | grep -q "$plist_name"; then
            echo "    ✅ LOADED"
        else
            echo "    ⏸️  NOT LOADED"
        fi
        
        # Check signature
        check_signature "$plist"
    done
    echo
}

# 6. Audit System Integrity Protection (SIP) status
audit_sip_status() {
    echo "=== SYSTEM INTEGRITY PROTECTION AUDIT ==="
    echo
    
    if command -v csrutil &> /dev/null; then
        echo "🔍 SIP Status:"
        csrutil status
    else
        echo "ℹ️  csrutil not available"
    fi
    
    echo
    echo "🔍 Gatekeeper Status:"
    spctl --status
    
    echo
    echo "🔍 Quarantine Status:"
    defaults read com.apple.LaunchServices LSQuarantine 2>/dev/null || echo "Quarantine not configured"
    echo
}

# 7. Generate security recommendations
generate_recommendations() {
    echo "=== SECURITY RECOMMENDATIONS ==="
    echo
    
    echo "🔒 KERNEL EXTENSIONS:"
    echo "  • Remove any third-party kernel extensions you don't recognize"
    echo "  • Unload unnecessary extensions: sudo kextunload -b <bundle-id>"
    echo "  • Delete extension files: sudo rm -rf /Library/Extensions/<extension>.kext"
    echo
    
    echo "🔒 PRIVATE FRAMEWORKS:"
    echo "  • Remove WebKit frameworks if you don't need web browsing"
    echo "  • Remove social media frameworks (Twitter, Facebook, etc.)"
    echo "  • Remove gaming frameworks if you don't play games"
    echo
    
    echo "🔒 LAUNCH SERVICES:"
    echo "  • Review and remove unnecessary launch daemons/agents"
    echo "  • Disable services: sudo launchctl unload -w <plist-path>"
    echo "  • Remove plist files: sudo rm <plist-path>"
    echo
    
    echo "🔒 SYSTEM SECURITY:"
    echo "  • Ensure SIP is enabled: sudo csrutil enable"
    echo "  • Enable Gatekeeper: sudo spctl --master-enable"
    echo "  • Enable FileVault for disk encryption"
    echo
    
    echo "⚠️  WARNING:"
    echo "  • Always backup before removing system components"
    echo "  • Some components may be required by legitimate software"
    echo "  • Test thoroughly after making changes"
    echo
}

# 8. Create removal script for identified issues
create_removal_script() {
    echo "=== CREATING REMOVAL SCRIPT ==="
    echo
    
    REMOVAL_SCRIPT="/tmp/remove-suspicious-components.sh"
    
    cat > "$REMOVAL_SCRIPT" << 'EOF'
#!/bin/bash

# Auto-generated removal script for suspicious components
# Review carefully before running!

set -euo pipefail

echo "=== REMOVING SUSPICIOUS COMPONENTS ==="
echo "⚠️  WARNING: This script will remove identified suspicious components"
echo "⚠️  Review the list below before proceeding"
echo

# Add removal commands here based on audit results
# Example:
# echo "Removing suspicious kernel extension..."
# sudo kextunload -b com.suspicious.kext 2>/dev/null || true
# sudo rm -rf /Library/Extensions/SuspiciousExtension.kext

echo "✅ Removal script created at: $REMOVAL_SCRIPT"
echo "📝 Edit the script to add specific removal commands"
echo "🔧 Run with: sudo bash $REMOVAL_SCRIPT"
EOF
    
    chmod +x "$REMOVAL_SCRIPT"
    echo "📝 Removal script created at: $REMOVAL_SCRIPT"
    echo
}

# Main execution
main() {
    check_privileges
    audit_loaded_kexts
    audit_all_kexts
    audit_system_extensions
    audit_private_frameworks
    audit_launch_services
    audit_sip_status
    generate_recommendations
    create_removal_script
    
    echo "=== AUDIT COMPLETED ==="
    echo
    echo "📊 Summary:"
    echo "  • Kernel extensions audited"
    echo "  • Private frameworks audited"
    echo "  • Launch services audited"
    echo "  • System security status checked"
    echo "  • Removal script generated"
    echo
    echo "🔍 Next steps:"
    echo "  1. Review the audit results above"
    echo "  2. Edit the removal script with specific components to remove"
    echo "  3. Test in a safe environment first"
    echo "  4. Run the removal script if needed"
    echo
    echo "⚠️  Remember: Always backup before making system changes!"
}

# Run main function
main "$@"
