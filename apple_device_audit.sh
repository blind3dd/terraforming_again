#!/bin/bash

# 🚨 APPLE DEVICE SECURITY AUDIT SCRIPT
# =====================================
# Comprehensive security audit for iPhone, iPad, and Apple Watch
# Checks for Static Tundra rootkit spread and compromise indicators

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIT_LOG="$SCRIPT_DIR/apple_device_audit_$(date +%Y%m%d_%H%M%S).log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Logging function
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$AUDIT_LOG"
}

# Print section header
print_section() {
    echo "" | tee -a "$AUDIT_LOG"
    echo "==========================================" | tee -a "$AUDIT_LOG"
    echo "$1" | tee -a "$AUDIT_LOG"
    echo "==========================================" | tee -a "$AUDIT_LOG"
    echo "" | tee -a "$AUDIT_LOG"
}

# Function to check if Apple Configurator is available
check_apple_configurator() {
    print_section "🔍 APPLE CONFIGURATOR AVAILABILITY"
    
    if [ -d "/Applications/Apple Configurator.app" ]; then
        log "✅ Apple Configurator is installed"
        return 0
    else
        log "❌ Apple Configurator not found - please install from App Store"
        log "📋 Apple Configurator is required for device auditing"
        return 1
    fi
}

# Function to check connected devices
check_connected_devices() {
    print_section "🔍 CONNECTED DEVICE DETECTION"
    
    log "🔍 Checking for connected Apple devices..."
    
    # Check for connected devices via system_profiler
    local connected_devices=$(system_profiler SPUSBDataType | grep -A 10 -B 2 -i "iphone\|ipad\|apple watch" || true)
    if [ -n "$connected_devices" ]; then
        log "📱 Connected devices detected:"
        echo "$connected_devices" | tee -a "$AUDIT_LOG"
    else
        log "❌ No connected devices detected"
        log "📋 Please connect your iPhone, iPad, and Apple Watch via USB"
        return 1
    fi
    
    # Check for devices via idevice_id (if libimobiledevice is installed)
    if command -v idevice_id >/dev/null 2>&1; then
        local device_ids=$(idevice_id -l 2>/dev/null || true)
        if [ -n "$device_ids" ]; then
            log "📱 Device IDs detected:"
            echo "$device_ids" | tee -a "$AUDIT_LOG"
        else
            log "❌ No device IDs detected via libimobiledevice"
        fi
    else
        log "⚠️  libimobiledevice not installed - install with: brew install libimobiledevice"
    fi
    
    return 0
}

# Function to audit device trust relationships
audit_device_trust() {
    print_section "🔍 DEVICE TRUST RELATIONSHIP AUDIT"
    
    log "🔍 Auditing device trust relationships..."
    
    # Check for trusted devices in keychain
    local trusted_devices=$(security find-certificate -a | grep -i "trusted" | head -10 || true)
    if [ -n "$trusted_devices" ]; then
        log "🔑 Trusted devices found in keychain:"
        echo "$trusted_devices" | tee -a "$AUDIT_LOG"
    else
        log "✅ No trusted devices found in keychain"
    fi
    
    # Check for device certificates
    local device_certificates=$(security find-certificate -a | grep -i -E "(iphone|ipad|watch)" | head -10 || true)
    if [ -n "$device_certificates" ]; then
        log "📱 Device certificates found:"
        echo "$device_certificates" | tee -a "$AUDIT_LOG"
    else
        log "✅ No device certificates found"
    fi
    
    # Check for suspicious certificates
    local suspicious_certificates=$(security find-certificate -a | grep -i -E "(microsoft|intune|ansible)" | head -10 || true)
    if [ -n "$suspicious_certificates" ]; then
        log "🚨 Suspicious certificates found:"
        echo "$suspicious_certificates" | tee -a "$AUDIT_LOG"
    else
        log "✅ No suspicious certificates found"
    fi
}

# Function to audit iCloud sync settings
audit_icloud_sync() {
    print_section "🔍 ICLOUD SYNC AUDIT"
    
    log "🔍 Auditing iCloud sync settings..."
    
    # Check iCloud account status
    local icloud_status=$(defaults read com.apple.icloud 2>/dev/null || echo "No iCloud settings found")
    log "📋 iCloud status: $icloud_status"
    
    # Check iCloud Drive sync
    local icloud_drive=$(defaults read com.apple.icloud.drive 2>/dev/null || echo "No iCloud Drive settings found")
    log "📋 iCloud Drive status: $icloud_drive"
    
    # Check keychain sync
    local keychain_sync=$(defaults read com.apple.icloud.keychain 2>/dev/null || echo "No keychain sync settings found")
    log "📋 Keychain sync status: $keychain_sync"
    
    # Check for suspicious iCloud files
    local suspicious_icloud_files=$(find ~/Library/Mobile\ Documents -name "*microsoft*" -o -name "*intune*" 2>/dev/null | head -10 || true)
    if [ -n "$suspicious_icloud_files" ]; then
        log "🚨 Suspicious iCloud files found:"
        echo "$suspicious_icloud_files" | tee -a "$AUDIT_LOG"
    else
        log "✅ No suspicious iCloud files found"
    fi
}

# Function to audit AirDrop history
audit_airdrop_history() {
    print_section "🔍 AIRDROP HISTORY AUDIT"
    
    log "🔍 Auditing AirDrop history..."
    
    # Check AirDrop preferences
    local airdrop_prefs=$(defaults read com.apple.airdrop 2>/dev/null || echo "No AirDrop preferences found")
    log "📋 AirDrop preferences: $airdrop_prefs"
    
    # Check for AirDrop logs
    local airdrop_logs=$(find ~/Library/Logs -name "*airdrop*" 2>/dev/null | head -10 || true)
    if [ -n "$airdrop_logs" ]; then
        log "📋 AirDrop logs found:"
        echo "$airdrop_logs" | tee -a "$AUDIT_LOG"
        
        # Analyze AirDrop logs for suspicious activity
        for log_file in $airdrop_logs; do
            log "🔍 Analyzing AirDrop log: $log_file"
            local suspicious_activity=$(grep -i -E "(microsoft|intune|ansible|netflow|sniffer)" "$log_file" 2>/dev/null || true)
            if [ -n "$suspicious_activity" ]; then
                log "🚨 Suspicious AirDrop activity found:"
                echo "$suspicious_activity" | tee -a "$AUDIT_LOG"
            fi
        done
    else
        log "✅ No AirDrop logs found"
    fi
}

# Function to audit Handoff and Continuity
audit_handoff_continuity() {
    print_section "🔍 HANDOFF AND CONTINUITY AUDIT"
    
    log "🔍 Auditing Handoff and Continuity settings..."
    
    # Check Handoff preferences
    local handoff_prefs=$(defaults read com.apple.handoff 2>/dev/null || echo "No Handoff preferences found")
    log "📋 Handoff preferences: $handoff_prefs"
    
    # Check Continuity preferences
    local continuity_prefs=$(defaults read com.apple.continuity 2>/dev/null || echo "No Continuity preferences found")
    log "📋 Continuity preferences: $continuity_prefs"
    
    # Check for Handoff logs
    local handoff_logs=$(find ~/Library/Logs -name "*handoff*" 2>/dev/null | head -10 || true)
    if [ -n "$handoff_logs" ]; then
        log "📋 Handoff logs found:"
        echo "$handoff_logs" | tee -a "$AUDIT_LOG"
    else
        log "✅ No Handoff logs found"
    fi
    
    # Check for Continuity logs
    local continuity_logs=$(find ~/Library/Logs -name "*continuity*" 2>/dev/null | head -10 || true)
    if [ -n "$continuity_logs" ]; then
        log "📋 Continuity logs found:"
        echo "$continuity_logs" | tee -a "$AUDIT_LOG"
    else
        log "✅ No Continuity logs found"
    fi
}

# Function to audit shared keychain
audit_shared_keychain() {
    print_section "🔍 SHARED KEYCHAIN AUDIT"
    
    log "🔍 Auditing shared keychain items..."
    
    # Check for shared keychain items
    local shared_items=$(security dump-keychain | grep -i -E "(iphone|ipad|watch|shared)" | head -20 || true)
    if [ -n "$shared_items" ]; then
        log "🔑 Shared keychain items found:"
        echo "$shared_items" | tee -a "$AUDIT_LOG"
    else
        log "✅ No shared keychain items found"
    fi
    
    # Check for suspicious keychain items
    local suspicious_items=$(security dump-keychain | grep -i -E "(microsoft|intune|ansible|netflow|sniffer)" | head -20 || true)
    if [ -n "$suspicious_items" ]; then
        log "🚨 Suspicious keychain items found:"
        echo "$suspicious_items" | tee -a "$AUDIT_LOG"
    else
        log "✅ No suspicious keychain items found"
    fi
}

# Function to audit device backups
audit_device_backups() {
    print_section "🔍 DEVICE BACKUP AUDIT"
    
    log "🔍 Auditing device backups..."
    
    # Check for iTunes backups
    local itunes_backups=$(find ~/Library/Application\ Support/MobileSync/Backup -type d 2>/dev/null | head -10 || true)
    if [ -n "$itunes_backups" ]; then
        log "📱 iTunes backups found:"
        echo "$itunes_backups" | tee -a "$AUDIT_LOG"
        
        # Check backup timestamps
        for backup in $itunes_backups; do
            local backup_time=$(stat -f "%Sm" "$backup" 2>/dev/null || echo "Unknown")
            log "📅 Backup time: $backup_time"
        done
    else
        log "✅ No iTunes backups found"
    fi
    
    # Check for iCloud backups
    local icloud_backups=$(find ~/Library/Mobile\ Documents -name "*backup*" 2>/dev/null | head -10 || true)
    if [ -n "$icloud_backups" ]; then
        log "☁️ iCloud backups found:"
        echo "$icloud_backups" | tee -a "$AUDIT_LOG"
    else
        log "✅ No iCloud backups found"
    fi
}

# Function to audit device logs
audit_device_logs() {
    print_section "🔍 DEVICE LOG AUDIT"
    
    log "🔍 Auditing device logs..."
    
    # Check for device logs
    local device_logs=$(find ~/Library/Logs -name "*device*" -o -name "*iphone*" -o -name "*ipad*" 2>/dev/null | head -10 || true)
    if [ -n "$device_logs" ]; then
        log "📋 Device logs found:"
        echo "$device_logs" | tee -a "$AUDIT_LOG"
        
        # Analyze device logs for suspicious activity
        for log_file in $device_logs; do
            log "🔍 Analyzing device log: $log_file"
            local suspicious_activity=$(grep -i -E "(microsoft|intune|ansible|netflow|sniffer|tunnel|bridge)" "$log_file" 2>/dev/null || true)
            if [ -n "$suspicious_activity" ]; then
                log "🚨 Suspicious device activity found:"
                echo "$suspicious_activity" | tee -a "$AUDIT_LOG"
            fi
        done
    else
        log "✅ No device logs found"
    fi
}

# Function to create device audit checklist
create_audit_checklist() {
    print_section "📋 DEVICE AUDIT CHECKLIST"
    
    log "📋 Creating device audit checklist..."
    
    cat << 'EOF' | tee -a "$AUDIT_LOG"
🔍 APPLE DEVICE SECURITY AUDIT CHECKLIST
========================================

📱 DEVICE CONNECTION:
□ Connect iPhone via USB
□ Connect iPad via USB  
□ Connect Apple Watch via USB
□ Verify device recognition in Apple Configurator
□ Check device trust relationships

🔑 KEYCHAIN AUDIT:
□ Review shared keychain items
□ Check for suspicious certificates
□ Verify device certificates
□ Remove any Microsoft/Intune certificates
□ Reset keychain if compromised

☁️ ICLOUD AUDIT:
□ Check iCloud account status
□ Review iCloud Drive sync settings
□ Audit keychain sync settings
□ Check for suspicious iCloud files
□ Review iCloud backup settings

📡 AIRDROP AUDIT:
□ Review AirDrop history
□ Check for suspicious file transfers
□ Analyze AirDrop logs
□ Verify AirDrop settings

🔄 HANDOFF/CONTINUITY AUDIT:
□ Review Handoff settings
□ Check Continuity preferences
□ Analyze Handoff logs
□ Verify device continuity

💾 BACKUP AUDIT:
□ Review iTunes backups
□ Check iCloud backups
□ Verify backup integrity
□ Check backup timestamps

📊 LOG ANALYSIS:
□ Analyze device logs
□ Check for suspicious activity
□ Review system logs
□ Monitor for rootkit indicators

🛡️ SECURITY MEASURES:
□ Enable Find My on all devices
□ Review device passcodes
□ Check Touch ID/Face ID settings
□ Verify device encryption
□ Review app permissions

⚠️ REMEDIATION:
□ Remove suspicious apps
□ Reset network settings if needed
□ Clear browser data
□ Update all devices to latest iOS
□ Change Apple ID password
EOF
}

# Main execution
main() {
    print_section "🚨 APPLE DEVICE SECURITY AUDIT SCRIPT"
    log "Starting Apple device security audit at $TIMESTAMP"
    log "Auditing iPhone, iPad, and Apple Watch for Static Tundra rootkit spread"
    
    # Check prerequisites
    if ! check_apple_configurator; then
        log "❌ Apple Configurator not available - please install first"
        exit 1
    fi
    
    # Run all audits
    check_connected_devices
    audit_device_trust
    audit_icloud_sync
    audit_airdrop_history
    audit_handoff_continuity
    audit_shared_keychain
    audit_device_backups
    audit_device_logs
    create_audit_checklist
    
    # Final summary
    print_section "🔍 AUDIT SUMMARY"
    log "Apple device security audit completed at $(date '+%Y-%m-%d %H:%M:%S')"
    log "Log file: $AUDIT_LOG"
    
    echo "" | tee -a "$AUDIT_LOG"
    echo "🛡️ APPLE DEVICE AUDIT COMPLETE" | tee -a "$AUDIT_LOG"
    echo "===============================" | tee -a "$AUDIT_LOG"
    echo "" | tee -a "$AUDIT_LOG"
    echo "📋 Review audit checklist and connect devices for detailed analysis" | tee -a "$AUDIT_LOG"
    echo "⚠️  Ensure all devices are updated to latest iOS version" | tee -a "$AUDIT_LOG"
    echo "⚠️  Change Apple ID password and enable 2FA if not already enabled" | tee -a "$AUDIT_LOG"
    echo "⚠️  Monitor devices for 24 hours for any suspicious activity" | tee -a "$AUDIT_LOG"
}

# Execute main function
main "$@"
