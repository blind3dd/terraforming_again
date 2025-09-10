#!/bin/bash

# 🚨 MULTI-USER SECURITY CLEANUP SCRIPT
# =====================================
# Comprehensive cleanup for all compromised user accounts
# Addresses Static Tundra rootkit across multiple users

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEANUP_LOG="$SCRIPT_DIR/multi_user_cleanup_$(date +%Y%m%d_%H%M%S).log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# User accounts to clean
USERS=("usualsuspectx" "blnd3dd" "pawelbek90")

# Logging function
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$CLEANUP_LOG"
}

# Print section header
print_section() {
    echo "" | tee -a "$CLEANUP_LOG"
    echo "==========================================" | tee -a "$CLEANUP_LOG"
    echo "$1" | tee -a "$CLEANUP_LOG"
    echo "==========================================" | tee -a "$CLEANUP_LOG"
    echo "" | tee -a "$CLEANUP_LOG"
}

# Function to check if user exists
user_exists() {
    local user=$1
    id "$user" >/dev/null 2>&1
}

# Function to clean Microsoft/Intune components for a user
clean_microsoft_components() {
    local user=$1
    local user_home="/Users/$user"
    
    log "🔧 Cleaning Microsoft/Intune components for user: $user"
    
    # Stop Microsoft processes
    sudo -u "$user" pkill -f "Microsoft" 2>/dev/null || true
    sudo -u "$user" pkill -f "Edge" 2>/dev/null || true
    sudo -u "$user" pkill -f "OneDrive" 2>/dev/null || true
    sudo -u "$user" pkill -f "Office" 2>/dev/null || true
    
    # Remove Microsoft applications
    sudo rm -rf "$user_home/Applications/Microsoft Edge.app" 2>/dev/null || true
    sudo rm -rf "$user_home/Applications/OneDrive.app" 2>/dev/null || true
    sudo rm -rf "$user_home/Applications/Microsoft Word.app" 2>/dev/null || true
    sudo rm -rf "$user_home/Applications/Microsoft Excel.app" 2>/dev/null || true
    sudo rm -rf "$user_home/Applications/Microsoft PowerPoint.app" 2>/dev/null || true
    sudo rm -rf "$user_home/Applications/Microsoft Outlook.app" 2>/dev/null || true
    sudo rm -rf "$user_home/Applications/Company Portal.app" 2>/dev/null || true
    
    # Remove Microsoft launch agents
    sudo rm -f "$user_home/Library/LaunchAgents/com.microsoft.EdgeUpdater.wake.plist" 2>/dev/null || true
    sudo rm -f "$user_home/Library/LaunchAgents/com.microsoft.autoupdate.agent.plist" 2>/dev/null || true
    sudo rm -f "$user_home/Library/LaunchAgents/com.microsoft.wdav.tray.plist" 2>/dev/null || true
    
    # Remove Microsoft preferences
    sudo rm -f "$user_home/Library/Preferences/com.microsoft.*" 2>/dev/null || true
    sudo rm -f "$user_home/Library/Preferences/group.com.microsoft.*" 2>/dev/null || true
    
    # Remove Microsoft application support
    sudo rm -rf "$user_home/Library/Application Support/Microsoft" 2>/dev/null || true
    sudo rm -rf "$user_home/Library/Application Support/Company Portal" 2>/dev/null || true
    sudo rm -rf "$user_home/Library/Application Support/Microsoft Edge" 2>/dev/null || true
    sudo rm -rf "$user_home/Library/Application Support/OneDrive" 2>/dev/null || true
    
    # Remove Microsoft caches
    sudo rm -rf "$user_home/Library/Caches/com.microsoft" 2>/dev/null || true
    sudo rm -rf "$user_home/Library/Caches/Microsoft" 2>/dev/null || true
    
    # Remove Microsoft logs
    sudo rm -rf "$user_home/Library/Logs/Microsoft" 2>/dev/null || true
    
    # Remove Microsoft application scripts
    sudo rm -rf "$user_home/Library/Application Scripts/com.microsoft.*" 2>/dev/null || true
    sudo rm -rf "$user_home/Library/Application Scripts/UBF8T346G9.com.microsoft.*" 2>/dev/null || true
    
    log "✅ Microsoft/Intune components cleaned for user: $user"
}

# Function to clean keychain for a user
clean_keychain() {
    local user=$1
    local user_home="/Users/$user"
    
    log "🔧 Cleaning keychain for user: $user"
    
    # Check keychain integrity
    if sudo -u "$user" security list-keychains >/dev/null 2>&1; then
        log "✅ Keychain accessible for user: $user"
        
        # Remove Microsoft keychain items
        sudo -u "$user" security delete-generic-password -s "Microsoft Office Identities Cache 3" 2>/dev/null || true
        sudo -u "$user" security delete-generic-password -s "Microsoft Office Data" 2>/dev/null || true
        sudo -u "$user" security delete-generic-password -s "Microsoft Office Identities Settings 3" 2>/dev/null || true
        
        # Remove suspicious certificates
        sudo -u "$user" security delete-certificate -c "Microsoft" 2>/dev/null || true
        
        log "✅ Keychain cleaned for user: $user"
    else
        log "❌ Keychain not accessible for user: $user"
    fi
}

# Function to clean browser profiles for a user
clean_browser_profiles() {
    local user=$1
    local user_home="/Users/$user"
    
    log "🔧 Cleaning browser profiles for user: $user"
    
    # Firefox profiles
    if [ -d "$user_home/Library/Application Support/Firefox" ]; then
        # Remove suspicious JSON files
        sudo find "$user_home/Library/Application Support/Firefox" -name "*.jsonlz4" -mtime -7 -delete 2>/dev/null || true
        sudo find "$user_home/Library/Application Support/Firefox" -name "upgrade.jsonlz4*" -delete 2>/dev/null || true
        
        log "✅ Firefox profiles cleaned for user: $user"
    fi
    
    # Chrome profiles
    if [ -d "$user_home/Library/Application Support/Google/Chrome" ]; then
        # Remove suspicious extensions
        sudo find "$user_home/Library/Application Support/Google/Chrome" -name "*microsoft*" -delete 2>/dev/null || true
        
        log "✅ Chrome profiles cleaned for user: $user"
    fi
}

# Function to clean downloads for a user
clean_downloads() {
    local user=$1
    local user_home="/Users/$user"
    
    log "🔧 Cleaning downloads for user: $user"
    
    # Remove suspicious executables
    sudo find "$user_home/Downloads" -name "setup.exe" -delete 2>/dev/null || true
    sudo find "$user_home/Downloads" -name "*.exe" -mtime -7 -delete 2>/dev/null || true
    sudo find "$user_home/Downloads" -name "*.msi" -mtime -7 -delete 2>/dev/null || true
    
    log "✅ Downloads cleaned for user: $user"
}

# Function to audit user account
audit_user() {
    local user=$1
    local user_home="/Users/$user"
    
    log "🔍 Auditing user account: $user"
    
    # Check user existence
    if ! user_exists "$user"; then
        log "❌ User $user does not exist"
        return 1
    fi
    
    # Check last login
    local last_login=$(last -1 "$user" 2>/dev/null | head -1 || echo "No login history")
    log "📅 Last login for $user: $last_login"
    
    # Check keychain status
    if [ -d "$user_home/Library/Keychains" ]; then
        local keychain_count=$(sudo ls -1 "$user_home/Library/Keychains"/*.keychain-db 2>/dev/null | wc -l)
        log "🔑 Keychain count for $user: $keychain_count"
        
        # List keychains
        sudo ls -la "$user_home/Library/Keychains/" 2>/dev/null | tee -a "$CLEANUP_LOG"
    fi
    
    # Check Microsoft components
    local microsoft_count=$(sudo find "$user_home" -name "*microsoft*" -o -name "*intune*" 2>/dev/null | wc -l)
    log "🔍 Microsoft components found for $user: $microsoft_count"
    
    # Check launch agents
    if [ -d "$user_home/Library/LaunchAgents" ]; then
        local launch_agents=$(sudo ls -1 "$user_home/Library/LaunchAgents" 2>/dev/null | wc -l)
        log "🚀 Launch agents for $user: $launch_agents"
        
        # List suspicious launch agents
        sudo ls -la "$user_home/Library/LaunchAgents" 2>/dev/null | tee -a "$CLEANUP_LOG"
    fi
    
    log "✅ Audit completed for user: $user"
}

# Main execution
main() {
    print_section "🚨 MULTI-USER SECURITY CLEANUP SCRIPT"
    log "Starting multi-user cleanup at $TIMESTAMP"
    log "Target users: ${USERS[*]}"
    
    # Audit all users first
    print_section "🔍 INITIAL USER AUDIT"
    for user in "${USERS[@]}"; do
        audit_user "$user"
    done
    
    # Clean each user
    print_section "🔧 CLEANING USER ACCOUNTS"
    for user in "${USERS[@]}"; do
        if user_exists "$user"; then
            log "🧹 Starting cleanup for user: $user"
            
            clean_microsoft_components "$user"
            clean_keychain "$user"
            clean_browser_profiles "$user"
            clean_downloads "$user"
            
            log "✅ Cleanup completed for user: $user"
        else
            log "❌ Skipping non-existent user: $user"
        fi
    done
    
    # Final audit
    print_section "🔍 FINAL AUDIT"
    for user in "${USERS[@]}"; do
        if user_exists "$user"; then
            audit_user "$user"
        fi
    done
    
    # System-wide cleanup
    print_section "🔧 SYSTEM-WIDE CLEANUP"
    
    # Remove system-wide Microsoft components
    sudo rm -rf "/Library/Application Support/Microsoft" 2>/dev/null || true
    sudo rm -rf "/Library/LaunchDaemons/com.microsoft.*" 2>/dev/null || true
    sudo rm -rf "/Library/LaunchAgents/com.microsoft.*" 2>/dev/null || true
    sudo rm -rf "/System/Volumes/Data/Library/Application Support/Microsoft" 2>/dev/null || true
    
    # Clean system caches
    sudo rm -rf "/Library/Caches/com.microsoft" 2>/dev/null || true
    sudo rm -rf "/System/Volumes/Data/Library/Caches/com.microsoft" 2>/dev/null || true
    
    log "✅ System-wide cleanup completed"
    
    # Final verification
    print_section "🔍 FINAL VERIFICATION"
    
    # Check for remaining Microsoft processes
    local remaining_processes=$(ps aux | grep -i microsoft | grep -v grep | wc -l)
    log "🔍 Remaining Microsoft processes: $remaining_processes"
    
    # Check for remaining Microsoft files
    local remaining_files=$(sudo find /Users -name "*microsoft*" -o -name "*intune*" 2>/dev/null | wc -l)
    log "🔍 Remaining Microsoft files: $remaining_files"
    
    # Check keychain integrity
    for user in "${USERS[@]}"; do
        if user_exists "$user"; then
            if sudo -u "$user" security list-keychains >/dev/null 2>&1; then
                log "✅ Keychain integrity OK for user: $user"
            else
                log "❌ Keychain integrity compromised for user: $user"
            fi
        fi
    done
    
    print_section "🛡️ CLEANUP COMPLETE"
    log "Multi-user cleanup completed at $(date '+%Y-%m-%d %H:%M:%S')"
    log "Log file: $CLEANUP_LOG"
    
    echo "" | tee -a "$CLEANUP_LOG"
    echo "🛡️ MULTI-USER CLEANUP COMPLETE" | tee -a "$CLEANUP_LOG"
    echo "================================" | tee -a "$CLEANUP_LOG"
    echo "" | tee -a "$CLEANUP_LOG"
    echo "⚠️  IMPORTANT: Restart your system to ensure all changes take effect" | tee -a "$CLEANUP_LOG"
    echo "⚠️  After restart, sign out and sign back in to Apple ID for all users" | tee -a "$CLEANUP_LOG"
    echo "⚠️  Check Apple ID security settings for any suspicious activity" | tee -a "$CLEANUP_LOG"
    echo "⚠️  Monitor system for 24 hours for any re-emerging threats" | tee -a "$CLEANUP_LOG"
}

# Execute main function
main "$@"
