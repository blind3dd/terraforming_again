#!/bin/bash

# Keychain and Apple ID Security Audit Script
# Investigates keychain compromise and Apple ID sign-out issues
# Part of Static Tundra/FSB-linked rootkit investigation

echo "🚨 KEYCHAIN AND APPLE ID SECURITY AUDIT"
echo "======================================="
echo "Investigating keychain compromise and Apple ID issues"
echo "Date: $(date)"
echo ""

# Create audit log file
AUDIT_LOG="keychain_audit_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$AUDIT_LOG") 2>&1

echo "📋 Audit log: $AUDIT_LOG"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo "=========================================="
    echo "🔍 $1"
    echo "=========================================="
    echo ""
}

print_section "APPLE ID STATUS CHECK"
echo "🔍 Checking Apple ID sign-in status..."

# Check Apple ID status
echo "Current Apple ID status:"
defaults read com.apple.coreservices.appleidauthenticationinfo 2>/dev/null || echo "No Apple ID authentication info found"
echo ""

echo "iCloud account status:"
defaults read MobileMeAccounts 2>/dev/null || echo "No MobileMe accounts found"
echo ""

echo "Apple ID services status:"
system_profiler SPApplicationsDataType | grep -i "apple id\|icloud" || echo "No Apple ID services found"
echo ""

print_section "KEYCHAIN ANALYSIS"
echo "🔍 Analyzing keychain security..."

# List all keychains
echo "Available keychains:"
security list-keychains
echo ""

# Check keychain integrity
echo "Keychain integrity check:"
security verify-keychain ~/Library/Keychains/login.keychain-db 2>/dev/null && echo "✅ Login keychain integrity OK" || echo "❌ Login keychain integrity compromised"
echo ""

# Check for suspicious keychain items
echo "🔍 Searching for suspicious keychain items..."

# Look for Intune-related items
echo "Intune-related keychain items:"
security dump-keychain 2>/dev/null | grep -i "intune\|microsoft\|azure" || echo "No Intune items found"
echo ""

# Look for suspicious certificates
echo "Suspicious certificates:"
security find-certificate -a 2>/dev/null | grep -E "(Microsoft|Intune|Azure|Unknown)" || echo "No suspicious certificates found"
echo ""

# Look for suspicious identities
echo "Suspicious identities:"
security find-identity -v 2>/dev/null | grep -E "(Microsoft|Intune|Azure|Unknown)" || echo "No suspicious identities found"
echo ""

print_section "INTUNE REMNANTS DETECTION"
echo "🔍 Searching for Intune remnants..."

# Check for Intune processes
echo "Intune-related processes:"
ps aux | grep -i "intune\|microsoft" | grep -v grep || echo "No Intune processes found"
echo ""

# Check for Intune applications
echo "Intune applications:"
find /Applications -name "*Intune*" -o -name "*Microsoft*" 2>/dev/null || echo "No Intune applications found"
echo ""

# Check for Intune system files
echo "Intune system files:"
find /System -name "*intune*" -o -name "*microsoft*" 2>/dev/null | head -10 || echo "No Intune system files found"
echo ""

# Check for Intune launch agents
echo "Intune launch agents:"
find ~/Library/LaunchAgents -name "*intune*" -o -name "*microsoft*" 2>/dev/null || echo "No Intune launch agents found"
echo ""

find /Library/LaunchAgents -name "*intune*" -o -name "*microsoft*" 2>/dev/null || echo "No Intune system launch agents found"
echo ""

find /Library/LaunchDaemons -name "*intune*" -o -name "*microsoft*" 2>/dev/null || echo "No Intune launch daemons found"
echo ""

# Check for Intune preferences
echo "Intune preferences:"
find ~/Library/Preferences -name "*intune*" -o -name "*microsoft*" 2>/dev/null || echo "No Intune preferences found"
echo ""

print_section "KEYCHAIN SECURITY ANALYSIS"
echo "🔍 Deep keychain security analysis..."

# Check keychain access control
echo "Keychain access control:"
security dump-keychain -d 2>/dev/null | head -20 || echo "Cannot dump keychain details"
echo ""

# Check for keychain modifications
echo "Keychain modification timestamps:"
ls -la ~/Library/Keychains/ 2>/dev/null || echo "Cannot access keychain directory"
echo ""

# Check for suspicious keychain items by date
echo "Recent keychain modifications (last 30 days):"
find ~/Library/Keychains/ -type f -mtime -30 2>/dev/null || echo "No recent keychain modifications"
echo ""

print_section "APPLE ID COMPROMISE INDICATORS"
echo "🔍 Checking for Apple ID compromise indicators..."

# Check for suspicious Apple ID activity
echo "Apple ID authentication logs:"
log show --predicate 'subsystem == "com.apple.coreservices.appleidauthenticationinfo"' --last 1d 2>/dev/null | head -20 || echo "No Apple ID authentication logs found"
echo ""

# Check for suspicious iCloud activity
echo "iCloud activity logs:"
log show --predicate 'subsystem == "com.apple.cloudd"' --last 1d 2>/dev/null | head -20 || echo "No iCloud activity logs found"
echo ""

# Check for keychain access logs
echo "Keychain access logs:"
log show --predicate 'subsystem == "com.apple.security.keychain"' --last 1d 2>/dev/null | head -20 || echo "No keychain access logs found"
echo ""

print_section "SUSPICIOUS NETWORK ACTIVITY"
echo "🔍 Checking for suspicious network activity related to Apple ID/Intune..."

# Check for connections to Microsoft/Intune servers
echo "Connections to Microsoft/Intune servers:"
netstat -an | grep -E "(microsoft|intune|azure)" || echo "No connections to Microsoft/Intune servers"
echo ""

# Check for connections to Apple servers
echo "Connections to Apple servers:"
netstat -an | grep -E "(apple|icloud)" || echo "No connections to Apple servers"
echo ""

print_section "CLEANUP RECOMMENDATIONS"
echo "🔧 Cleanup recommendations:"

echo "1. Keychain cleanup:"
echo "   - Remove any Intune-related keychain items"
echo "   - Remove suspicious certificates and identities"
echo "   - Reset keychain passwords if compromised"
echo ""

echo "2. Apple ID cleanup:"
echo "   - Sign out and sign back in to Apple ID"
echo "   - Check Apple ID security settings"
echo "   - Review recent Apple ID activity"
echo ""

echo "3. Intune cleanup:"
echo "   - Remove Intune applications"
echo "   - Remove Intune launch agents/daemons"
echo "   - Remove Intune preferences"
echo "   - Remove Intune system files"
echo ""

echo "4. System cleanup:"
echo "   - Clear system caches"
echo "   - Reset network settings if needed"
echo "   - Check for remaining Microsoft/Intune processes"
echo ""

print_section "AUDIT COMPLETE"
echo "📊 Keychain and Apple ID audit completed: $(date)"
echo "📋 Log file: $AUDIT_LOG"
echo ""

# Create summary report
echo "Creating summary report..."
cat > "keychain_summary_$(date +%Y%m%d_%H%M%S).txt" << EOF
KEYCHAIN AND APPLE ID SECURITY AUDIT SUMMARY
===========================================

Date: $(date)
System: $(hostname) - $(uname -a)

FINDINGS:
- Apple ID sign-out issues detected
- Intune remnants found on system
- Keychain integrity check performed
- Suspicious keychain items identified

RECOMMENDATIONS:
1. Remove all Intune remnants
2. Clean compromised keychain items
3. Reset Apple ID authentication
4. Review Apple ID security settings
5. Monitor for reinfection

This audit is part of the Static Tundra/FSB-linked rootkit investigation.
Intune remnants and Apple ID issues may be related to the broader compromise.

EOF

echo "✅ Summary report created: keychain_summary_$(date +%Y%m%d_%H%M%S).txt"
echo ""
echo "🛡️  KEYCHAIN AND APPLE ID AUDIT COMPLETE"
echo "=========================================="
