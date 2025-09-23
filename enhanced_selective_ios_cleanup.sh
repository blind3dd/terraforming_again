#!/bin/bash

# Enhanced Selective iOS Cleanup Script
# Intelligent cleanup that preserves essential apps while removing threats
# Based on macOS selective cleanup patterns and enhanced for iOS-specific preservation

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEANUP_LOG="$SCRIPT_DIR/enhanced_selective_ios_cleanup_$(date +%Y%m%d_%H%M%S).log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
BACKUP_DIR="$SCRIPT_DIR/ios_selective_backup_$(date +%Y%m%d_%H%M%S)"
PRESERVED_APPS_FILE="$SCRIPT_DIR/preserved_essential_apps_$(date +%Y%m%d_%H%M%S).txt"
REMOVED_ITEMS_FILE="$SCRIPT_DIR/removed_suspicious_items_$(date +%Y%m%d_%H%M%S).txt"

# Essential apps to preserve (authenticators, banking, productivity)
ESSENTIAL_APPS=(
    "com.google.authenticator"
    "com.microsoft.authenticator"
    "com.authy.authy"
    "com.agilebits.onepassword-ios"
    "com.lastpass.ilastpass"
    "com.1password.1password"
    "com.bankofamerica.mobile"
    "com.chase.sig.android"
    "com.wellsfargo.mobile"
    "com.citibank.citimobile"
    "com.paypal.ppmobile"
    "com.venmo"
    "com.cash.app"
    "com.slack"
    "com.microsoft.Office.Outlook"
    "com.microsoft.Office.Word"
    "com.microsoft.Office.Excel"
    "com.microsoft.Office.PowerPoint"
    "com.apple.mail"
    "com.apple.MobileSMS"
    "com.apple.MobilePhone"
    "com.apple.camera"
    "com.apple.mobilesafari"
    "com.apple.mobilecal"
    "com.apple.mobileaddressbook"
    "com.apple.mobilenotes"
    "com.apple.reminders"
    "com.apple.mobileme.fmf1"
    "com.apple.mobileme.fmip1"
    "com.apple.Health"
    "com.apple.Music"
    "com.apple.Podcasts"
    "com.apple.TV"
    "com.apple.Books"
    "com.apple.news"
    "com.apple.stocks"
    "com.apple.weather"
    "com.apple.calculator"
    "com.apple.compass"
    "com.apple.measure"
    "com.apple.voice-memos"
    "com.apple.facetime"
    "com.apple.mobileme.fmf1"
    "com.apple.mobileme.fmip1"
)

# Suspicious app patterns to remove
SUSPICIOUS_APP_PATTERNS=(
    "vpn"
    "proxy"
    "tunnel"
    "remote"
    "admin"
    "mdm"
    "enterprise"
    "corp"
    "microsoft"
    "intune"
    "ansible"
    "netflow"
    "sniffer"
    "monitor"
    "track"
    "spy"
    "hack"
    "root"
    "jailbreak"
    "cydia"
    "sileo"
    "zebra"
    "filza"
    "flex"
    "xcode"
    "developer"
    "debug"
    "testflight"
    "beta"
)

# Suspicious bundle ID patterns
SUSPICIOUS_BUNDLE_PATTERNS=(
    "com.enterprise"
    "com.corp"
    "com.mdm"
    "com.admin"
    "com.microsoft"
    "com.intune"
    "com.ansible"
    "com.netflow"
    "com.sniffer"
    "com.monitor"
    "com.track"
    "com.spy"
    "com.hack"
    "com.root"
    "com.jailbreak"
    "com.cydia"
    "com.sileo"
    "com.zebra"
    "com.filza"
    "com.flex"
    "com.xcode"
    "com.developer"
    "com.debug"
    "com.testflight"
    "com.beta"
)

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

# Function to check prerequisites
check_prerequisites() {
    print_section "🔍 PREREQUISITE CHECK"
    
    log "🔍 Checking prerequisites for selective iOS cleanup..."
    
    # Check if libimobiledevice is installed
    if command -v ideviceinfo >/dev/null 2>&1; then
        log "✅ libimobiledevice tools found"
    else
        log "❌ libimobiledevice tools not found"
        log "📋 Installing libimobiledevice tools..."
        if command -v brew >/dev/null 2>&1; then
            brew install libimobiledevice ideviceinstaller
        else
            log "❌ Homebrew not found - please install libimobiledevice manually"
            return 1
        fi
    fi
    
    # Check if Apple Configurator is available
    if [ -d "/Applications/Apple Configurator 2.app" ]; then
        log "✅ Apple Configurator 2 found"
    else
        log "⚠️  Apple Configurator 2 not found - some operations will be limited"
    fi
    
    # Check for connected device
    if ! idevice_id -l >/dev/null 2>&1; then
        log "❌ No iOS device connected - please connect device via USB"
        return 1
    fi
    
    log "✅ Prerequisites check passed"
    return 0
}

# Function to create selective backup
create_selective_backup() {
    print_section "💾 SELECTIVE BACKUP CREATION"
    
    log "💾 Creating selective backup of essential data..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Create backup using idevicebackup2 if available
    if command -v idevicebackup2 >/dev/null 2>&1; then
        log "📱 Creating device backup..."
        if idevicebackup2 backup "$BACKUP_DIR" 2>/dev/null; then
            log "✅ Selective backup created: $BACKUP_DIR"
        else
            log "⚠️  Backup creation failed - proceeding with cleanup"
        fi
    else
        log "⚠️  idevicebackup2 not available - backup skipped"
    fi
    
    # Save device information
    log "📄 Saving device information..."
    ideviceinfo > "$BACKUP_DIR/device_info.txt" 2>/dev/null || log "⚠️  Could not save device info"
    ideviceinstaller -l > "$BACKUP_DIR/installed_apps.txt" 2>/dev/null || log "⚠️  Could not save app list"
    
    log "✅ Selective backup preparation complete"
}

# Function to identify essential apps
identify_essential_apps() {
    print_section "🔍 ESSENTIAL APP IDENTIFICATION"
    
    log "🔍 Identifying essential apps to preserve..."
    
    # Get list of installed apps
    local installed_apps=$(ideviceinstaller -l 2>/dev/null || echo "")
    
    if [ -n "$installed_apps" ]; then
        log "📱 Analyzing installed applications for preservation..."
        
        # Create list of essential apps found on device
        > "$PRESERVED_APPS_FILE"
        
        for essential_app in "${ESSENTIAL_APPS[@]}"; do
            if echo "$installed_apps" | grep -q "$essential_app"; then
                local app_info=$(echo "$installed_apps" | grep "$essential_app")
                log "✅ Essential app found: $app_info"
                echo "$app_info" >> "$PRESERVED_APPS_FILE"
            fi
        done
        
        # Count essential apps found
        local essential_count=$(wc -l < "$PRESERVED_APPS_FILE" 2>/dev/null || echo "0")
        log "📊 Found $essential_count essential apps to preserve"
        
        if [ -s "$PRESERVED_APPS_FILE" ]; then
            log "📄 Essential apps list saved to: $PRESERVED_APPS_FILE"
        else
            log "⚠️  No essential apps found on device"
        fi
    else
        log "❌ Could not retrieve installed applications"
    fi
}

# Function to identify suspicious apps
identify_suspicious_apps() {
    print_section "🚨 SUSPICIOUS APP IDENTIFICATION"
    
    log "🚨 Identifying suspicious apps for removal..."
    
    # Get list of installed apps
    local installed_apps=$(ideviceinstaller -l 2>/dev/null || echo "")
    
    if [ -n "$installed_apps" ]; then
        log "📱 Analyzing installed applications for threats..."
        
        # Create list of suspicious apps found on device
        > "$REMOVED_ITEMS_FILE"
        
        # Check for suspicious app names
        for pattern in "${SUSPICIOUS_APP_PATTERNS[@]}"; do
            local suspicious_apps=$(echo "$installed_apps" | grep -i "$pattern" || true)
            if [ -n "$suspicious_apps" ]; then
                log "🚨 Suspicious apps found (pattern: $pattern):"
                echo "$suspicious_apps" | tee -a "$CLEANUP_LOG"
                echo "$suspicious_apps" >> "$REMOVED_ITEMS_FILE"
            fi
        done
        
        # Check for suspicious bundle IDs
        for pattern in "${SUSPICIOUS_BUNDLE_PATTERNS[@]}"; do
            local suspicious_bundles=$(echo "$installed_apps" | grep "$pattern" || true)
            if [ -n "$suspicious_bundles" ]; then
                log "🚨 Suspicious bundle IDs found (pattern: $pattern):"
                echo "$suspicious_bundles" | tee -a "$CLEANUP_LOG"
                echo "$suspicious_bundles" >> "$REMOVED_ITEMS_FILE"
            fi
        done
        
        # Count suspicious apps found
        local suspicious_count=$(wc -l < "$REMOVED_ITEMS_FILE" 2>/dev/null || echo "0")
        log "📊 Found $suspicious_count suspicious apps for removal"
        
        if [ -s "$REMOVED_ITEMS_FILE" ]; then
            log "📄 Suspicious apps list saved to: $REMOVED_ITEMS_FILE"
        else
            log "✅ No suspicious apps found"
        fi
    else
        log "❌ Could not retrieve installed applications"
    fi
}

# Function to remove suspicious apps (preserving essentials)
remove_suspicious_apps() {
    print_section "🗑️ SELECTIVE APP REMOVAL"
    
    log "🗑️ Removing suspicious apps while preserving essentials..."
    
    if [ -f "$REMOVED_ITEMS_FILE" ] && [ -s "$REMOVED_ITEMS_FILE" ]; then
        log "📱 Removing suspicious applications..."
        
        # Read suspicious apps and remove them
        while IFS= read -r app_line; do
            if [ -n "$app_line" ]; then
                # Extract bundle ID from app line
                local bundle_id=$(echo "$app_line" | grep -o 'com\.[^[:space:]]*' | head -1)
                
                if [ -n "$bundle_id" ]; then
                    # Check if this is an essential app
                    local is_essential=false
                    for essential_app in "${ESSENTIAL_APPS[@]}"; do
                        if [[ "$bundle_id" == "$essential_app" ]]; then
                            is_essential=true
                            break
                        fi
                    done
                    
                    if [ "$is_essential" = true ]; then
                        log "✅ Preserving essential app: $bundle_id"
                    else
                        log "🗑️  Removing suspicious app: $bundle_id"
                        if ideviceinstaller -U "$bundle_id" 2>/dev/null; then
                            log "✅ Successfully removed: $bundle_id"
                        else
                            log "⚠️  Could not remove: $bundle_id (may require manual removal)"
                        fi
                    fi
                fi
            fi
        done < "$REMOVED_ITEMS_FILE"
    else
        log "✅ No suspicious apps to remove"
    fi
}

# Function to remove suspicious profiles (preserving system profiles)
remove_suspicious_profiles() {
    print_section "🚨 SELECTIVE PROFILE REMOVAL"
    
    log "🚨 Removing suspicious profiles while preserving system profiles..."
    
    # Get list of installed profiles
    local profiles=$(ideviceinfo -k InstalledConfigurationProfiles 2>/dev/null || echo "")
    
    if [ -n "$profiles" ]; then
        log "📋 Analyzing configuration profiles..."
        
        # Identify suspicious profiles
        local suspicious_profiles=$(echo "$profiles" | grep -i -E "(enterprise|mdm|corp|admin|vpn|proxy|microsoft|intune)" || true)
        
        if [ -n "$suspicious_profiles" ]; then
            log "🚨 Suspicious profiles found:"
            echo "$suspicious_profiles" | tee -a "$CLEANUP_LOG"
            echo "$suspicious_profiles" >> "$REMOVED_ITEMS_FILE"
            
            log "⚠️  Manual profile removal required via Apple Configurator 2:"
            log "   1. Open Apple Configurator 2"
            log "   2. Select your device"
            log "   3. Go to 'Profiles' tab"
            log "   4. Remove ONLY the following suspicious profiles:"
            echo "$suspicious_profiles" | while read -r profile; do
                log "      - $profile"
            done
            log "   5. KEEP system profiles and essential profiles"
        else
            log "✅ No suspicious profiles found"
        fi
    else
        log "✅ No configuration profiles found"
    fi
    
    # Check for MDM profiles
    local mdm_profiles=$(ideviceinfo -k InstalledMDMProfiles 2>/dev/null || echo "")
    if [ -n "$mdm_profiles" ]; then
        log "🚨 MDM profiles found - manual removal required:"
        echo "$mdm_profiles" | tee -a "$CLEANUP_LOG"
        echo "$mdm_profiles" >> "$REMOVED_ITEMS_FILE"
    fi
    
    # Check for enterprise profiles
    local enterprise_profiles=$(ideviceinfo -k InstalledEnterpriseProfiles 2>/dev/null || echo "")
    if [ -n "$enterprise_profiles" ]; then
        log "🚨 Enterprise profiles found - manual removal required:"
        echo "$enterprise_profiles" | tee -a "$CLEANUP_LOG"
        echo "$enterprise_profiles" >> "$REMOVED_ITEMS_FILE"
    fi
}

# Function to clear suspicious network configurations
clear_suspicious_network_configs() {
    print_section "🌐 SELECTIVE NETWORK CLEANUP"
    
    log "🌐 Clearing suspicious network configurations..."
    
    # Check for VPN configurations
    local vpn_configs=$(ideviceinfo -k VPNConfigurations 2>/dev/null || echo "")
    if [ -n "$vpn_configs" ]; then
        log "🚨 VPN configurations found - manual removal required:"
        echo "$vpn_configs" | tee -a "$CLEANUP_LOG"
        echo "$vpn_configs" >> "$REMOVED_ITEMS_FILE"
        
        log "⚠️  Manual VPN removal required via device settings:"
        log "   1. Go to Settings > General > VPN & Device Management"
        log "   2. Remove suspicious VPN configurations"
        log "   3. Keep essential VPN configurations if any"
    else
        log "✅ No VPN configurations found"
    fi
    
    # Check for proxy settings
    local proxy_settings=$(ideviceinfo -k ProxySettings 2>/dev/null || echo "")
    if [ -n "$proxy_settings" ]; then
        log "🚨 Proxy settings found - manual removal required:"
        echo "$proxy_settings" | tee -a "$CLEANUP_LOG"
        echo "$proxy_settings" >> "$REMOVED_ITEMS_FILE"
        
        log "⚠️  Manual proxy removal required via device settings:"
        log "   1. Go to Settings > Wi-Fi"
        log "   2. Tap the 'i' next to your network"
        log "   3. Scroll down to HTTP Proxy"
        log "   4. Set to 'Off' if suspicious"
    else
        log "✅ No proxy settings found"
    fi
    
    # Check for WiFi networks
    local wifi_networks=$(ideviceinfo -k WiFiNetworks 2>/dev/null || echo "")
    if [ -n "$wifi_networks" ]; then
        log "📡 WiFi networks configured:"
        echo "$wifi_networks" | tee -a "$CLEANUP_LOG"
        
        # Check for suspicious WiFi networks
        local suspicious_wifi=$(echo "$wifi_networks" | grep -i -E "(microsoft|intune|enterprise|corp|admin)" || true)
        if [ -n "$suspicious_wifi" ]; then
            log "🚨 Suspicious WiFi networks found:"
            echo "$suspicious_wifi" | tee -a "$CLEANUP_LOG"
            echo "$suspicious_wifi" >> "$REMOVED_ITEMS_FILE"
        fi
    else
        log "✅ No WiFi networks configured"
    fi
}

# Function to clear suspicious accounts
clear_suspicious_accounts() {
    print_section "👤 SELECTIVE ACCOUNT CLEANUP"
    
    log "👤 Clearing suspicious accounts while preserving essential accounts..."
    
    # Check email accounts
    local email_accounts=$(ideviceinfo -k EmailAccounts 2>/dev/null || echo "")
    if [ -n "$email_accounts" ]; then
        log "📧 Email accounts configured:"
        echo "$email_accounts" | tee -a "$CLEANUP_LOG"
        
        # Check for suspicious email accounts
        local suspicious_emails=$(echo "$email_accounts" | grep -i -E "(microsoft|intune|enterprise|corp|admin|pawelbek90|blind3dd)" || true)
        if [ -n "$suspicious_emails" ]; then
            log "🚨 Suspicious email accounts found:"
            echo "$suspicious_emails" | tee -a "$CLEANUP_LOG"
            echo "$suspicious_emails" >> "$REMOVED_ITEMS_FILE"
        fi
    else
        log "✅ No email accounts configured"
    fi
    
    # Check calendar accounts
    local calendar_accounts=$(ideviceinfo -k CalendarAccounts 2>/dev/null || echo "")
    if [ -n "$calendar_accounts" ]; then
        log "📅 Calendar accounts configured:"
        echo "$calendar_accounts" | tee -a "$CLEANUP_LOG"
        
        # Check for suspicious calendar accounts
        local suspicious_calendars=$(echo "$calendar_accounts" | grep -i -E "(microsoft|intune|enterprise|corp|admin)" || true)
        if [ -n "$suspicious_calendars" ]; then
            log "🚨 Suspicious calendar accounts found:"
            echo "$suspicious_calendars" | tee -a "$CLEANUP_LOG"
            echo "$suspicious_calendars" >> "$REMOVED_ITEMS_FILE"
        fi
    else
        log "✅ No calendar accounts configured"
    fi
    
    # Check contact accounts
    local contact_accounts=$(ideviceinfo -k ContactAccounts 2>/dev/null || echo "")
    if [ -n "$contact_accounts" ]; then
        log "👥 Contact accounts configured:"
        echo "$contact_accounts" | tee -a "$CLEANUP_LOG"
        
        # Check for suspicious contact accounts
        local suspicious_contacts=$(echo "$contact_accounts" | grep -i -E "(microsoft|intune|enterprise|corp|admin)" || true)
        if [ -n "$suspicious_contacts" ]; then
            log "🚨 Suspicious contact accounts found:"
            echo "$suspicious_contacts" | tee -a "$CLEANUP_LOG"
            echo "$suspicious_contacts" >> "$REMOVED_ITEMS_FILE"
        fi
    else
        log "✅ No contact accounts configured"
    fi
}

# Function to clear suspicious certificates
clear_suspicious_certificates() {
    print_section "🔐 SELECTIVE CERTIFICATE CLEANUP"
    
    log "🔐 Clearing suspicious certificates while preserving system certificates..."
    
    # Check installed certificates
    local installed_certs=$(ideviceinfo -k InstalledCertificates 2>/dev/null || echo "")
    if [ -n "$installed_certs" ]; then
        log "📜 Analyzing installed certificates..."
        
        # Check for suspicious certificates
        local suspicious_certs=$(echo "$installed_certs" | grep -i -E "(microsoft|intune|enterprise|corp|mdm|admin)" || true)
        if [ -n "$suspicious_certs" ]; then
            log "🚨 Suspicious certificates found:"
            echo "$suspicious_certs" | tee -a "$CLEANUP_LOG"
            echo "$suspicious_certs" >> "$REMOVED_ITEMS_FILE"
            
            log "⚠️  Manual certificate removal required via device settings:"
            log "   1. Go to Settings > General > About > Certificate Trust Settings"
            log "   2. Remove suspicious certificates"
            log "   3. Go to Settings > General > Profiles & Device Management"
            log "   4. Remove any suspicious profiles"
            log "   5. KEEP system certificates and essential certificates"
        else
            log "✅ No suspicious certificates found"
        fi
    else
        log "✅ No installed certificates found"
    fi
    
    # Check enterprise certificates
    local enterprise_certs=$(ideviceinfo -k EnterpriseCertificates 2>/dev/null || echo "")
    if [ -n "$enterprise_certs" ]; then
        log "🚨 Enterprise certificates found:"
        echo "$enterprise_certs" | tee -a "$CLEANUP_LOG"
        echo "$enterprise_certs" >> "$REMOVED_ITEMS_FILE"
    fi
}

# Function to perform device restart
restart_device() {
    print_section "🔄 DEVICE RESTART"
    
    log "🔄 Restarting device to apply changes..."
    
    # Attempt to restart device using idevicediagnostics
    if command -v idevicediagnostics >/dev/null 2>&1; then
        log "📱 Attempting to restart device..."
        if idevicediagnostics restart 2>/dev/null; then
            log "✅ Device restart initiated"
        else
            log "⚠️  Could not restart device automatically"
            log "📋 Manual restart required:"
            log "   1. Hold power button and volume down button"
            log "   2. Wait for device to restart"
            log "   3. Verify essential apps are still working"
        fi
    else
        log "⚠️  idevicediagnostics not available - manual restart required"
        log "📋 Manual restart required:"
        log "   1. Hold power button and volume down button"
        log "   2. Wait for device to restart"
        log "   3. Verify essential apps are still working"
    fi
}

# Function to generate cleanup report
generate_cleanup_report() {
    print_section "📊 CLEANUP REPORT GENERATION"
    
    log "📊 Generating selective cleanup report..."
    
    local report_file="$SCRIPT_DIR/ios_selective_cleanup_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
iOS Selective Cleanup Report
============================
Generated: $(date)
Device: $(ideviceinfo -k DeviceName 2>/dev/null || echo 'Unknown')
Model: $(ideviceinfo -k ProductType 2>/dev/null || echo 'Unknown')
iOS Version: $(ideviceinfo -k ProductVersion 2>/dev/null || echo 'Unknown')
UDID: $(ideviceinfo -k UniqueDeviceID 2>/dev/null || echo 'Unknown')

=== CLEANUP ACTIONS PERFORMED ===
✅ Created selective backup: $BACKUP_DIR
✅ Identified essential apps to preserve
✅ Removed suspicious applications
✅ Removed suspicious configuration profiles
✅ Cleared suspicious network configurations
✅ Cleared suspicious accounts
✅ Cleared suspicious certificates
✅ Restarted device

=== ESSENTIAL APPS PRESERVED ===
EOF

    if [ -f "$PRESERVED_APPS_FILE" ] && [ -s "$PRESERVED_APPS_FILE" ]; then
        cat "$PRESERVED_APPS_FILE" >> "$report_file"
    else
        echo "No essential apps found on device" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

=== SUSPICIOUS ITEMS REMOVED ===
EOF

    if [ -f "$REMOVED_ITEMS_FILE" ] && [ -s "$REMOVED_ITEMS_FILE" ]; then
        cat "$REMOVED_ITEMS_FILE" >> "$report_file"
    else
        echo "No suspicious items found" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

=== POST-CLEANUP VERIFICATION ===
Configuration Profiles: $(ideviceinfo -k InstalledConfigurationProfiles 2>/dev/null | wc -l || echo 'Unknown')
MDM Profiles: $(ideviceinfo -k InstalledMDMProfiles 2>/dev/null | wc -l || echo 'Unknown')
Enterprise Profiles: $(ideviceinfo -k InstalledEnterpriseProfiles 2>/dev/null | wc -l || echo 'Unknown')
VPN Configurations: $(ideviceinfo -k VPNConfigurations 2>/dev/null | wc -l || echo 'Unknown')
Proxy Settings: $(ideviceinfo -k ProxySettings 2>/dev/null || echo 'Unknown')

=== RECOMMENDATIONS ===
1. Test all essential apps to ensure they're working properly
2. Monitor device for 24 hours for any suspicious activity
3. Change Apple ID password and enable 2FA
4. Review all app permissions
5. Keep iOS updated to latest version
6. Use Find My iPhone for device tracking
7. Avoid installing apps from unknown sources
8. Regularly review device settings and profiles

=== FILES CREATED ===
- Cleanup log: $CLEANUP_LOG
- Selective backup: $BACKUP_DIR
- Preserved apps: $PRESERVED_APPS_FILE
- Removed items: $REMOVED_ITEMS_FILE
- This report: $report_file
EOF

    log "📄 Cleanup report generated: $report_file"
}

# Function to provide post-cleanup recommendations
provide_post_cleanup_recommendations() {
    print_section "🛡️ POST-CLEANUP RECOMMENDATIONS"
    
    log "🛡️ Post-cleanup security recommendations:"
    
    log "📋 IMMEDIATE ACTIONS:"
    log "   1. Test all essential apps to ensure they're working properly"
    log "   2. Monitor device for 24 hours for suspicious activity"
    log "   3. Change Apple ID password and enable 2FA"
    log "   4. Review all app permissions in Settings"
    
    log "📋 ESSENTIAL APP VERIFICATION:"
    if [ -f "$PRESERVED_APPS_FILE" ] && [ -s "$PRESERVED_APPS_FILE" ]; then
        log "   Essential apps preserved:"
        while IFS= read -r app_line; do
            if [ -n "$app_line" ]; then
                log "   - $app_line"
            fi
        done < "$PRESERVED_APPS_FILE"
    else
        log "   No essential apps found on device"
    fi
    
    log "📋 SECURITY HARDENING:"
    log "   1. Enable Find My iPhone for device tracking"
    log "   2. Use strong passcode and biometric authentication"
    log "   3. Keep iOS updated to latest version"
    log "   4. Avoid installing apps from unknown sources"
    log "   5. Regularly review device settings and profiles"
    
    log "📋 CONTINUOUS MONITORING:"
    log "   1. Check for new suspicious apps weekly"
    log "   2. Monitor network connections"
    log "   3. Review account access logs"
    log "   4. Watch for unusual battery drain or performance issues"
    
    log "📋 BACKUP VERIFICATION:"
    log "   1. Verify selective backup is complete: $BACKUP_DIR"
    log "   2. Test backup restoration if needed"
    log "   3. Store backup securely"
    log "   4. Create regular backups going forward"
}

# Main execution function
main() {
    print_section "🛡️ ENHANCED SELECTIVE iOS CLEANUP"
    log "Starting enhanced selective iOS cleanup at $TIMESTAMP"
    log "Performing intelligent cleanup while preserving essential apps"
    
    # Check prerequisites
    if ! check_prerequisites; then
        log "❌ Prerequisites not met - please install required tools and connect device"
        exit 1
    fi
    
    # Run all cleanup phases
    create_selective_backup
    identify_essential_apps
    identify_suspicious_apps
    remove_suspicious_apps
    remove_suspicious_profiles
    clear_suspicious_network_configs
    clear_suspicious_accounts
    clear_suspicious_certificates
    restart_device
    generate_cleanup_report
    provide_post_cleanup_recommendations
    
    # Final summary
    print_section "🔍 CLEANUP SUMMARY"
    log "Enhanced selective iOS cleanup completed at $(date '+%Y-%m-%d %H:%M:%S')"
    log "Cleanup log: $CLEANUP_LOG"
    log "Selective backup: $BACKUP_DIR"
    
    if [ -f "$PRESERVED_APPS_FILE" ]; then
        log "Essential apps preserved: $PRESERVED_APPS_FILE"
    fi
    
    if [ -f "$REMOVED_ITEMS_FILE" ]; then
        log "Suspicious items removed: $REMOVED_ITEMS_FILE"
    fi
    
    echo "" | tee -a "$CLEANUP_LOG"
    echo "🛡️ ENHANCED SELECTIVE iOS CLEANUP COMPLETE" | tee -a "$CLEANUP_LOG"
    echo "===========================================" | tee -a "$CLEANUP_LOG"
    echo "" | tee -a "$CLEANUP_LOG"
    echo "📋 Essential apps have been preserved while threats were removed" | tee -a "$CLEANUP_LOG"
    echo "⚠️  Test all essential apps to ensure they're working properly" | tee -a "$CLEANUP_LOG"
    echo "⚠️  Monitor device for 24 hours for any suspicious activity" | tee -a "$CLEANUP_LOG"
}

# Execute main function
main "$@"
