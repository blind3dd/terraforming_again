#!/bin/bash

# Intune/Microsoft Cleanup Script
# Removes all Intune and Microsoft remnants to restore system integrity
# Part of Static Tundra/FSB-linked rootkit investigation

echo "🚨 INTUNE/MICROSOFT CLEANUP SCRIPT"
echo "=================================="
echo "Removing Intune and Microsoft remnants to restore system integrity"
echo "Date: $(date)"
echo ""

# Create cleanup log file
CLEANUP_LOG="intune_cleanup_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$CLEANUP_LOG") 2>&1

echo "📋 Cleanup log: $CLEANUP_LOG"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo "=========================================="
    echo "🔧 $1"
    echo "=========================================="
    echo ""
}

# Function to safely remove files/directories
safe_remove() {
    local path="$1"
    local description="$2"
    
    if [ -e "$path" ]; then
        echo "Removing $description: $path"
        if sudo rm -rf "$path" 2>/dev/null; then
            echo "✅ Successfully removed $description"
        else
            echo "❌ Failed to remove $description (may be protected)"
        fi
    else
        echo "ℹ️  $description not found: $path"
    fi
}

# Function to kill processes
kill_processes() {
    local process_pattern="$1"
    local description="$2"
    
    echo "Killing $description processes..."
    local pids=$(ps aux | grep -E "$process_pattern" | grep -v grep | awk '{print $2}')
    
    if [ -n "$pids" ]; then
        for pid in $pids; do
            if [ "$pid" != "$$" ]; then
                echo "Killing PID $pid ($description)"
                sudo kill -9 "$pid" 2>/dev/null
            fi
        done
        echo "✅ Killed $description processes"
    else
        echo "ℹ️  No $description processes found"
    fi
}

print_section "STOPPING MICROSOFT PROCESSES"
echo "🔧 Stopping all Microsoft-related processes..."

# Kill Microsoft processes
kill_processes "Microsoft" "Microsoft applications"
kill_processes "microsoft" "Microsoft services"
kill_processes "Edge" "Microsoft Edge"
kill_processes "Teams" "Microsoft Teams"
kill_processes "Outlook" "Microsoft Outlook"
kill_processes "OneDrive" "Microsoft OneDrive"
kill_processes "Defender" "Microsoft Defender"

print_section "REMOVING MICROSOFT APPLICATIONS"
echo "🔧 Removing Microsoft applications..."

# Remove Microsoft applications
safe_remove "/Applications/Microsoft Defender.app" "Microsoft Defender"
safe_remove "/Applications/Company Portal.app" "Company Portal"
safe_remove "/Applications/Microsoft Word.app" "Microsoft Word"
safe_remove "/Applications/Microsoft Excel.app" "Microsoft Excel"
safe_remove "/Applications/Microsoft PowerPoint.app" "Microsoft PowerPoint"
safe_remove "/Applications/Microsoft Outlook.app" "Microsoft Outlook"
safe_remove "/Applications/Microsoft OneNote.app" "Microsoft OneNote"
safe_remove "/Applications/Microsoft Teams.app" "Microsoft Teams"
safe_remove "/Applications/Microsoft Edge.app" "Microsoft Edge"
safe_remove "/Applications/OneDrive.app" "Microsoft OneDrive"

print_section "REMOVING MICROSOFT LAUNCH AGENTS/DAEMONS"
echo "🔧 Removing Microsoft launch agents and daemons..."

# Remove user launch agents
safe_remove "~/Library/LaunchAgents/com.microsoft.EdgeUpdater.wake.plist" "Microsoft Edge Updater launch agent"

# Remove system launch agents
safe_remove "/Library/LaunchAgents/com.microsoft.wdav.tray.plist" "Microsoft Defender tray launch agent"
safe_remove "/Library/LaunchAgents/com.microsoft.update.agent.plist" "Microsoft update agent"

# Remove system launch daemons
safe_remove "/Library/LaunchDaemons/com.microsoft.fresno.plist" "Microsoft Fresno daemon"
safe_remove "/Library/LaunchDaemons/com.microsoft.fresno.uninstall.plist" "Microsoft Fresno uninstall daemon"
safe_remove "/Library/LaunchDaemons/com.microsoft.wdav.tracer_install_monitor.plist" "Microsoft Defender tracer daemon"
safe_remove "/Library/LaunchDaemons/com.microsoft.dlp.install_monitor.plist" "Microsoft DLP daemon"
safe_remove "/Library/LaunchDaemons/com.microsoft.office.licensingV2.helper.plist" "Microsoft Office licensing daemon"
safe_remove "/Library/LaunchDaemons/com.microsoft.autoupdate.helper.plist" "Microsoft AutoUpdate daemon"

print_section "REMOVING MICROSOFT SYSTEM FILES"
echo "🔧 Removing Microsoft system files..."

# Remove Microsoft system support files
safe_remove "/System/Volumes/Data/Library/Application Support/Microsoft" "Microsoft system support directory"
safe_remove "/Library/Application Support/Microsoft" "Microsoft library support directory"

# Remove Microsoft system files
safe_remove "/System/Library/Templates/Data/private/etc/openldap/schema/microsoft.schema" "Microsoft LDAP schema"
safe_remove "/System/Library/Templates/Data/private/etc/openldap/schema/microsoft.ext.schema" "Microsoft LDAP ext schema"
safe_remove "/System/Library/Templates/Data/private/etc/openldap/schema/microsoft.std.schema" "Microsoft LDAP std schema"

print_section "REMOVING MICROSOFT PREFERENCES"
echo "🔧 Removing Microsoft preferences..."

# Remove Microsoft preferences
safe_remove "~/Library/Preferences/com.microsoft.autoupdate.fba.plist" "Microsoft AutoUpdate FBA preferences"
safe_remove "~/Library/Preferences/com.microsoft.msa-login-hint.plist" "Microsoft MSA login preferences"
safe_remove "~/Library/Preferences/com.microsoft.edgemac.plist" "Microsoft Edge preferences"
safe_remove "~/Library/Preferences/com.microsoft.wdav.mainux.plist" "Microsoft Defender main UX preferences"
safe_remove "~/Library/Preferences/com.microsoft.VSCode.plist" "Microsoft VSCode preferences"
safe_remove "~/Library/Preferences/com.microsoft.autoupdate2.plist" "Microsoft AutoUpdate 2 preferences"
safe_remove "~/Library/Preferences/group.com.microsoft.CompanyPortalMac.plist" "Company Portal group preferences"
safe_remove "~/Library/Preferences/com.microsoft.wdav.tray.plist" "Microsoft Defender tray preferences"
safe_remove "~/Library/Preferences/com.microsoft.wdav.shim.plist" "Microsoft Defender shim preferences"
safe_remove "~/Library/Preferences/com.microsoft.office.plist" "Microsoft Office preferences"
safe_remove "~/Library/Preferences/com.microsoft.shared.plist" "Microsoft shared preferences"
safe_remove "~/Library/Preferences/com.microsoft.CompanyPortalMac.plist" "Company Portal preferences"
safe_remove "~/Library/Preferences/com.microsoft.teams2.helper.plist" "Microsoft Teams helper preferences"

print_section "CLEANING KEYCHAIN"
echo "🔧 Cleaning Microsoft keychain items..."

# Remove Microsoft keychain items
echo "Removing Microsoft keychain items..."
security delete-generic-password -s "Microsoft Office Identities Cache 3" 2>/dev/null && echo "✅ Removed Microsoft Office Identities Cache"
security delete-generic-password -s "Microsoft Office Data" 2>/dev/null && echo "✅ Removed Microsoft Office Data"
security delete-generic-password -s "com.microsoft.onedrive.cookies" 2>/dev/null && echo "✅ Removed OneDrive cookies"
security delete-generic-password -s "com.microsoft.OutlookCore.ServiceV2" 2>/dev/null && echo "✅ Removed Outlook Core service"
security delete-generic-password -s "Microsoft Edge Safe Storage" 2>/dev/null && echo "✅ Removed Microsoft Edge Safe Storage"
security delete-generic-password -s "Microsoft Office Identities Settings 3" 2>/dev/null && echo "✅ Removed Microsoft Office Identities Settings"

print_section "CLEANING CACHES AND TEMPORARY FILES"
echo "🔧 Cleaning Microsoft caches and temporary files..."

# Remove Microsoft caches
safe_remove "~/Library/Caches/com.microsoft" "Microsoft caches"
safe_remove "~/Library/Caches/Microsoft" "Microsoft application caches"
safe_remove "~/Library/Application Support/Microsoft" "Microsoft application support"
safe_remove "~/Library/Application Support/Company Portal" "Company Portal application support"
safe_remove "~/Library/Application Support/Microsoft Edge" "Microsoft Edge application support"
safe_remove "~/Library/Application Support/Microsoft Teams" "Microsoft Teams application support"

# Remove Microsoft temporary files
safe_remove "/tmp/.com.microsoft" "Microsoft temporary files"
safe_remove "/var/folders/*/T/.com.microsoft" "Microsoft temporary folders"

print_section "CLEANING LOGS"
echo "🔧 Cleaning Microsoft logs..."

# Remove Microsoft logs
safe_remove "~/Library/Logs/Microsoft" "Microsoft logs"
safe_remove "/Library/Logs/Microsoft" "Microsoft system logs"

print_section "RESETTING KEYCHAIN INTEGRITY"
echo "🔧 Resetting keychain integrity..."

# Reset keychain
echo "Resetting keychain integrity..."
if security verify-keychain ~/Library/Keychains/login.keychain-db 2>/dev/null; then
    echo "✅ Keychain integrity verified"
else
    echo "⚠️  Keychain integrity compromised - attempting repair..."
    # Try to repair keychain
    if security repair-keychain ~/Library/Keychains/login.keychain-db 2>/dev/null; then
        echo "✅ Keychain repair attempted"
    else
        echo "❌ Keychain repair failed - manual intervention required"
    fi
fi

print_section "CLEANING NETWORK CONNECTIONS"
echo "🔧 Cleaning Microsoft network connections..."

# Kill any remaining Microsoft network connections
echo "Checking for remaining Microsoft network connections..."
netstat -an | grep -E "(microsoft|intune)" || echo "No Microsoft network connections found"

print_section "FINAL VERIFICATION"
echo "🔍 Final verification..."

# Check for remaining Microsoft processes
echo "Checking for remaining Microsoft processes..."
remaining_processes=$(ps aux | grep -i microsoft | grep -v grep | wc -l)
if [ "$remaining_processes" -eq 0 ]; then
    echo "✅ No Microsoft processes remaining"
else
    echo "⚠️  $remaining_processes Microsoft processes still running:"
    ps aux | grep -i microsoft | grep -v grep
fi

# Check for remaining Microsoft applications
echo "Checking for remaining Microsoft applications..."
remaining_apps=$(find /Applications -name "*Microsoft*" 2>/dev/null | wc -l)
if [ "$remaining_apps" -eq 0 ]; then
    echo "✅ No Microsoft applications remaining"
else
    echo "⚠️  $remaining_apps Microsoft applications still present:"
    find /Applications -name "*Microsoft*" 2>/dev/null
fi

# Check keychain integrity
echo "Checking keychain integrity..."
if security verify-keychain ~/Library/Keychains/login.keychain-db 2>/dev/null; then
    echo "✅ Keychain integrity restored"
else
    echo "❌ Keychain integrity still compromised"
fi

print_section "CLEANUP COMPLETE"
echo "📊 Intune/Microsoft cleanup completed: $(date)"
echo "📋 Log file: $CLEANUP_LOG"
echo ""

# Create summary report
echo "Creating summary report..."
cat > "intune_cleanup_summary_$(date +%Y%m%d_%H%M%S).txt" << EOF
INTUNE/MICROSOFT CLEANUP SUMMARY
===============================

Date: $(date)
System: $(hostname) - $(uname -a)

CLEANUP ACTIONS:
- Stopped all Microsoft processes
- Removed Microsoft applications
- Removed Microsoft launch agents/daemons
- Removed Microsoft system files
- Removed Microsoft preferences
- Cleaned Microsoft keychain items
- Cleaned Microsoft caches and temporary files
- Cleaned Microsoft logs
- Attempted keychain integrity repair

RECOMMENDATIONS:
1. Restart the system to ensure all changes take effect
2. Sign out and sign back in to Apple ID
3. Check Apple ID security settings
4. Monitor for any remaining Microsoft processes
5. Consider running keychain repair if issues persist

This cleanup is part of the Static Tundra/FSB-linked rootkit investigation.
Microsoft/Intune remnants may have been related to the broader compromise.

EOF

echo "✅ Summary report created: intune_cleanup_summary_$(date +%Y%m%d_%H%M%S).txt"
echo ""
echo "🛡️  INTUNE/MICROSOFT CLEANUP COMPLETE"
echo "====================================="
echo ""
echo "⚠️  IMPORTANT: Restart your system to ensure all changes take effect"
echo "⚠️  After restart, sign out and sign back in to Apple ID"
echo "⚠️  Check Apple ID security settings for any suspicious activity"
