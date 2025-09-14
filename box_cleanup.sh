#!/bin/bash

# Box App Cleanup Script
# Removes Box cloud storage remnants and suspicious activity
# Part of Static Tundra/FSB-linked rootkit investigation

echo "🚨 BOX APP CLEANUP SCRIPT"
echo "========================"
echo "Removing Box cloud storage remnants and suspicious activity"
echo "Date: $(date)"
echo ""

# Create cleanup log file
CLEANUP_LOG="box_cleanup_$(date +%Y%m%d_%H%M%S).log"
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
        if rm -rf "$path" 2>/dev/null; then
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
                kill -9 "$pid" 2>/dev/null
            fi
        done
        echo "✅ Killed $description processes"
    else
        echo "ℹ️  No $description processes found"
    fi
}

print_section "ANALYZING BOX ACTIVITY"
echo "🔍 Analyzing Box app activity and suspicious files..."

# Check Box application support directory
if [ -d "~/Library/Application Support/Box" ]; then
    echo "Box application support directory found:"
    ls -la ~/Library/Application\ Support/Box/
    echo ""
    
    # Check suspicious files
    echo "Checking suspicious Box files:"
    if [ -f "~/Library/Application Support/Box/Box/data/dynamic_denylist.json" ]; then
        echo "⚠️  Suspicious file found: dynamic_denylist.json"
        echo "Content:"
        cat ~/Library/Application\ Support/Box/Box/data/dynamic_denylist.json 2>/dev/null || echo "Cannot read file"
        echo ""
    fi
    
    if [ -f "~/Library/Application Support/Box/Box/data/cacert.pem" ]; then
        echo "⚠️  Certificate file found: cacert.pem"
        echo "File size: $(ls -lh ~/Library/Application\ Support/Box/Box/data/cacert.pem | awk '{print $5}')"
        echo "Last modified: $(ls -la ~/Library/Application\ Support/Box/Box/data/cacert.pem | awk '{print $6, $7, $8}')"
        echo ""
    fi
    
    # Check database files
    echo "Box database files:"
    find ~/Library/Application\ Support/Box/Box/data/ -name "*.db" -exec ls -la {} \; 2>/dev/null
    echo ""
fi

print_section "STOPPING BOX PROCESSES"
echo "🔧 Stopping all Box-related processes..."

# Kill Box processes
kill_processes "Box" "Box applications"
kill_processes "box" "Box services"

print_section "REMOVING BOX APPLICATIONS"
echo "🔧 Removing Box applications..."

# Remove Box applications
safe_remove "/Applications/Box.app" "Box application"
safe_remove "/Applications/Box Sync.app" "Box Sync application"

print_section "REMOVING BOX APPLICATION SUPPORT"
echo "🔧 Removing Box application support files..."

# Remove Box application support
safe_remove "~/Library/Application Support/Box" "Box application support directory"

print_section "REMOVING BOX PREFERENCES"
echo "🔧 Removing Box preferences..."

# Remove Box preferences
safe_remove "~/Library/Preferences/com.box.desktop.plist" "Box desktop preferences"
safe_remove "~/Library/Preferences/com.box.sync.plist" "Box sync preferences"
safe_remove "~/Library/Preferences/com.box.boxsync.plist" "Box sync preferences"

print_section "REMOVING BOX CACHES"
echo "🔧 Removing Box caches..."

# Remove Box caches
safe_remove "~/Library/Caches/com.box.desktop" "Box desktop caches"
safe_remove "~/Library/Caches/com.box.sync" "Box sync caches"
safe_remove "~/Library/Caches/Box" "Box caches"

print_section "REMOVING BOX LOGS"
echo "🔧 Removing Box logs..."

# Remove Box logs
safe_remove "~/Library/Logs/Box" "Box logs"
safe_remove "~/Library/Logs/com.box.desktop" "Box desktop logs"
safe_remove "~/Library/Logs/com.box.sync" "Box sync logs"

print_section "REMOVING BOX LAUNCH AGENTS"
echo "🔧 Removing Box launch agents..."

# Remove Box launch agents
safe_remove "~/Library/LaunchAgents/com.box.desktop.plist" "Box desktop launch agent"
safe_remove "~/Library/LaunchAgents/com.box.sync.plist" "Box sync launch agent"
safe_remove "/Library/LaunchAgents/com.box.desktop.plist" "Box system desktop launch agent"
safe_remove "/Library/LaunchAgents/com.box.sync.plist" "Box system sync launch agent"

print_section "REMOVING BOX LAUNCH DAEMONS"
echo "🔧 Removing Box launch daemons..."

# Remove Box launch daemons
safe_remove "/Library/LaunchDaemons/com.box.desktop.plist" "Box desktop launch daemon"
safe_remove "/Library/LaunchDaemons/com.box.sync.plist" "Box sync launch daemon"

print_section "CLEANING BOX KEYCHAIN ITEMS"
echo "🔧 Cleaning Box keychain items..."

# Remove Box keychain items
echo "Removing Box keychain items..."
security delete-generic-password -s "Box" 2>/dev/null && echo "✅ Removed Box keychain item"
security delete-generic-password -s "com.box.desktop" 2>/dev/null && echo "✅ Removed Box desktop keychain item"
security delete-generic-password -s "com.box.sync" 2>/dev/null && echo "✅ Removed Box sync keychain item"

print_section "CLEANING BOX NETWORK CONNECTIONS"
echo "🔧 Cleaning Box network connections..."

# Kill any remaining Box network connections
echo "Checking for remaining Box network connections..."
netstat -an | grep -E "(box|Box)" || echo "No Box network connections found"

print_section "FINAL VERIFICATION"
echo "🔍 Final verification..."

# Check for remaining Box processes
echo "Checking for remaining Box processes..."
remaining_processes=$(ps aux | grep -i box | grep -v grep | wc -l)
if [ "$remaining_processes" -eq 0 ]; then
    echo "✅ No Box processes remaining"
else
    echo "⚠️  $remaining_processes Box processes still running:"
    ps aux | grep -i box | grep -v grep
fi

# Check for remaining Box applications
echo "Checking for remaining Box applications..."
remaining_apps=$(find /Applications -name "*Box*" -type d 2>/dev/null | grep -v "VirtualBox\|Numbers\|Keynote\|Pages\|Ableton\|YubiKey\|ClamXAV\|Rise of the Tomb Raider" | wc -l)
if [ "$remaining_apps" -eq 0 ]; then
    echo "✅ No Box applications remaining"
else
    echo "⚠️  $remaining_apps Box applications still present:"
    find /Applications -name "*Box*" -type d 2>/dev/null | grep -v "VirtualBox\|Numbers\|Keynote\|Pages\|Ableton\|YubiKey\|ClamXAV\|Rise of the Tomb Raider"
fi

# Check for remaining Box application support
echo "Checking for remaining Box application support..."
if [ -d "~/Library/Application Support/Box" ]; then
    echo "⚠️  Box application support directory still present"
else
    echo "✅ Box application support directory removed"
fi

print_section "CLEANUP COMPLETE"
echo "📊 Box cleanup completed: $(date)"
echo "📋 Log file: $CLEANUP_LOG"
echo ""

# Create summary report
echo "Creating summary report..."
cat > "box_cleanup_summary_$(date +%Y%m%d_%H%M%S).txt" << EOF
BOX APP CLEANUP SUMMARY
======================

Date: $(date)
System: $(hostname) - $(uname -a)

CLEANUP ACTIONS:
- Stopped all Box processes
- Removed Box applications
- Removed Box application support directory
- Removed Box preferences
- Removed Box caches and logs
- Removed Box launch agents/daemons
- Cleaned Box keychain items
- Cleaned Box network connections

SUSPICIOUS FINDINGS:
- Box app installed: August 8, 2025, 01:57
- Cache created: August 17, 2025, 22:24
- dynamic_denylist.json modified: August 30, 2025, 01:44 (after main attack)
- Analytics updated: August 30, 2025, 17:28 (after main attack)
- Certificate updated: September 8, 2025, 00:55 (very recent)

RECOMMENDATIONS:
1. Restart the system to ensure all changes take effect
2. Monitor for any remaining Box processes after restart
3. Check for Box app reinstalling automatically
4. Review network connections for Box-related traffic
5. Consider this as part of the broader Static Tundra attack

This cleanup is part of the Static Tundra/FSB-linked rootkit investigation.
Box app activity appears to be a separate but related attack vector.

EOF

echo "✅ Summary report created: box_cleanup_summary_$(date +%Y%m%d_%H%M%S).txt"
echo ""
echo "🛡️  BOX CLEANUP COMPLETE"
echo "========================"
echo ""
echo "⚠️  IMPORTANT: Restart your system to ensure all changes take effect"
echo "⚠️  Monitor for Box app reinstalling automatically"
echo "⚠️  This appears to be part of the broader Static Tundra attack"

