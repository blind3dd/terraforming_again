#!/bin/bash

# =============================================================================
# ANDROID DEVICE SECURITY AUDIT SCRIPT
# =============================================================================
# This script audits Android devices for Static Tundra rootkit compromise
# and Microsoft app installations that could interfere with iCloud sync
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIT_LOG="$SCRIPT_DIR/android_audit_$(date +%Y%m%d_%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$AUDIT_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$AUDIT_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$AUDIT_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$AUDIT_LOG"
}

# Initialize logging
exec > >(tee -a "$AUDIT_LOG") 2>&1

log "Starting Android Device Security Audit"
log "Log file: $AUDIT_LOG"

# =============================================================================
# ANDROID DEVICE DETECTION
# =============================================================================

detect_android_devices() {
    log "Detecting Android devices..."
    
    # Check if adb is available (use local installation)
    local adb_path="./platform-tools/adb"
    if [[ ! -f "$adb_path" ]]; then
        log_warning "ADB (Android Debug Bridge) not found at $adb_path"
        log_warning "Please ensure platform-tools are extracted"
        return 1
    fi
    
    log "Using ADB at: $adb_path"
    
    # Get connected devices
    local devices
    devices=$("$adb_path" devices 2>/dev/null | grep -v "List of devices" | grep -v "^$" || true)
    
    if [[ -z "$devices" ]]; then
        log_error "No Android devices detected"
        log_warning "Please:"
        log_warning "1. Connect your Android device via USB"
        log_warning "2. Enable USB Debugging in Developer Options"
        log_warning "3. Allow USB debugging when prompted"
        return 1
    fi
    
    log "Connected Android devices:"
    echo "$devices" | tee -a "$AUDIT_LOG"
    
    # Extract device IDs
    ANDROID_DEVICES=($(echo "$devices" | awk '{print $1}' | grep -v "^$"))
    
    # Set ADB path for other functions
    ADB_PATH="$adb_path"
    
    if [[ ${#ANDROID_DEVICES[@]} -eq 0 ]]; then
        log_error "No valid Android device IDs found"
        return 1
    fi
    
    log_success "Found ${#ANDROID_DEVICES[@]} Android device(s)"
    return 0
}

# =============================================================================
# DEVICE INFORMATION GATHERING
# =============================================================================

get_device_info() {
    local device_id="$1"
    
    log "Gathering information for device: $device_id"
    
    # Get device model and Android version
    local model
    model=$("$ADB_PATH" -s "$device_id" shell getprop ro.product.model 2>/dev/null || echo "Unknown")
    
    local android_version
    android_version=$("$ADB_PATH" -s "$device_id" shell getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    
    local build_number
    build_number=$("$ADB_PATH" -s "$device_id" shell getprop ro.build.display.id 2>/dev/null || echo "Unknown")
    
    log "Device: $model"
    log "Android Version: $android_version"
    log "Build: $build_number"
    
    # Save device info
    local device_info_file="$SCRIPT_DIR/android_device_${device_id}_info_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "Device ID: $device_id"
        echo "Model: $model"
        echo "Android Version: $android_version"
        echo "Build: $build_number"
        echo "Audit Date: $(date)"
        echo "=========================================="
    } > "$device_info_file"
    
    log "Device info saved to: $device_info_file"
}

# =============================================================================
# MICROSOFT APPS DETECTION
# =============================================================================

check_microsoft_apps() {
    local device_id="$1"
    
    log "Checking for Microsoft apps on device: $device_id"
    
    # Microsoft app packages to check for
    local microsoft_packages=(
        "com.microsoft.emmx"           # Microsoft Edge
        "com.microsoft.skydrive"       # Microsoft OneDrive
        "com.microsoft.office.officehubrow"  # Microsoft Office
        "com.microsoft.office.excel"   # Microsoft Excel
        "com.microsoft.office.powerpoint"  # Microsoft PowerPoint
        "com.microsoft.office.word"    # Microsoft Word
        "com.microsoft.office.outlook" # Microsoft Outlook
        "com.microsoft.teams"          # Microsoft Teams
        "com.microsoft.azure.authenticator"  # Microsoft Authenticator
        "com.microsoft.intune"         # Microsoft Intune
        "com.microsoft.intune.portal"  # Microsoft Intune Portal
    )
    
    local found_apps=()
    
    for package in "${microsoft_packages[@]}"; do
        local app_info
        app_info=$("$ADB_PATH" -s "$device_id" shell pm list packages -f "$package" 2>/dev/null || true)
        
        if [[ -n "$app_info" ]]; then
            found_apps+=("$package")
            log_warning "Microsoft app found: $package"
            
            # Get app details
            local app_name
            app_name=$("$ADB_PATH" -s "$device_id" shell dumpsys package "$package" | grep "applicationInfo" -A 5 | grep "label" | head -1 | sed 's/.*label=//' || echo "Unknown")
            
            log_warning "  App Name: $app_name"
        fi
    done
    
    if [[ ${#found_apps[@]} -eq 0 ]]; then
        log_success "No Microsoft apps found on device: $device_id"
    else
        log_warning "Found ${#found_apps[@]} Microsoft app(s) on device: $device_id"
        
        # Save Microsoft apps list
        local microsoft_apps_file="$SCRIPT_DIR/android_device_${device_id}_microsoft_apps_$(date +%Y%m%d_%H%M%S).txt"
        {
            echo "Microsoft Apps Found on Device: $device_id"
            echo "Audit Date: $(date)"
            echo "=========================================="
            for app in "${found_apps[@]}"; do
                echo "$app"
            done
        } > "$microsoft_apps_file"
        
        log "Microsoft apps list saved to: $microsoft_apps_file"
    fi
}

# =============================================================================
# AUTHENTICATOR APPS AUDIT
# =============================================================================

audit_authenticator_apps() {
    local device_id="$1"
    
    log "Auditing authenticator apps on device: $device_id"
    
    # Common authenticator app packages
    local authenticator_packages=(
        "com.google.android.apps.authenticator2"  # Google Authenticator
        "com.microsoft.azure.authenticator"       # Microsoft Authenticator
        "com.authy.authy"                         # Authy
        "com.yubico.yubioath"                     # Yubico Authenticator
        "com.duosecurity.duomobile"               # Duo Mobile
        "com.lastpass.authenticator"              # LastPass Authenticator
        "com.1password.authenticator"             # 1Password Authenticator
    )
    
    local found_authenticators=()
    
    for package in "${authenticator_packages[@]}"; do
        local app_info
        app_info=$("$ADB_PATH" -s "$device_id" shell pm list packages -f "$package" 2>/dev/null || true)
        
        if [[ -n "$app_info" ]]; then
            found_authenticators+=("$package")
            log_success "Authenticator app found: $package"
            
            # Get app details
            local app_name
            app_name=$("$ADB_PATH" -s "$device_id" shell dumpsys package "$package" | grep "applicationInfo" -A 5 | grep "label" | head -1 | sed 's/.*label=//' || echo "Unknown")
            
            log_success "  App Name: $app_name"
        fi
    done
    
    if [[ ${#found_authenticators[@]} -eq 0 ]]; then
        log_warning "No authenticator apps found on device: $device_id"
    else
        log_success "Found ${#found_authenticators[@]} authenticator app(s) on device: $device_id"
        
        # Save authenticator apps list
        local authenticator_apps_file="$SCRIPT_DIR/android_device_${device_id}_authenticators_$(date +%Y%m%d_%H%M%S).txt"
        {
            echo "Authenticator Apps Found on Device: $device_id"
            echo "Audit Date: $(date)"
            echo "=========================================="
            for app in "${found_authenticators[@]}"; do
                echo "$app"
            done
        } > "$authenticator_apps_file"
        
        log "Authenticator apps list saved to: $authenticator_apps_file"
    fi
}

# =============================================================================
# NETWORK ACTIVITY ANALYSIS
# =============================================================================

analyze_network_activity() {
    local device_id="$1"
    
    log "Analyzing network activity on device: $device_id"
    
    # Check active network connections
    local network_connections
    network_connections=$("$ADB_PATH" -s "$device_id" shell netstat -an 2>/dev/null || true)
    
    if [[ -n "$network_connections" ]]; then
        log "Active network connections found"
        
        # Save network connections
        local network_file="$SCRIPT_DIR/android_device_${device_id}_network_$(date +%Y%m%d_%H%M%S).txt"
        echo "$network_connections" > "$network_file"
        log "Network connections saved to: $network_file"
        
        # Check for suspicious ports
        local suspicious_ports=("8021" "8080" "8443" "443" "80")
        for port in "${suspicious_ports[@]}"; do
            if echo "$network_connections" | grep -q ":$port "; then
                log_warning "Suspicious port $port found in network connections"
            fi
        done
    else
        log_warning "Could not retrieve network connections"
    fi
    
    # Check DNS settings
    local dns_servers
    dns_servers=$("$ADB_PATH" -s "$device_id" shell getprop net.dns1 2>/dev/null || true)
    
    if [[ -n "$dns_servers" ]]; then
        log "Primary DNS: $dns_servers"
        
        # Check for suspicious DNS servers
        if [[ "$dns_servers" != "8.8.8.8" && "$dns_servers" != "1.1.1.1" ]]; then
            log_warning "Non-standard DNS server detected: $dns_servers"
        fi
    fi
}

# =============================================================================
# SECURITY SETTINGS AUDIT
# =============================================================================

audit_security_settings() {
    local device_id="$1"
    
    log "Auditing security settings on device: $device_id"
    
    # Check if device is rooted
    local root_status
    root_status=$("$ADB_PATH" -s "$device_id" shell su -c "id" 2>/dev/null || echo "Not rooted")
    
    if [[ "$root_status" == *"uid=0"* ]]; then
        log_warning "Device appears to be ROOTED"
    else
        log_success "Device is not rooted"
    fi
    
    # Check developer options
    local developer_options
    developer_options=$("$ADB_PATH" -s "$device_id" shell settings get global development_settings_enabled 2>/dev/null || echo "Unknown")
    
    if [[ "$developer_options" == "1" ]]; then
        log_warning "Developer options are ENABLED"
    else
        log_success "Developer options are disabled"
    fi
    
    # Check USB debugging
    local usb_debugging
    usb_debugging=$("$ADB_PATH" -s "$device_id" shell settings get global adb_enabled 2>/dev/null || echo "Unknown")
    
    if [[ "$usb_debugging" == "1" ]]; then
        log_warning "USB debugging is ENABLED"
    else
        log_success "USB debugging is disabled"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log "=== ANDROID DEVICE SECURITY AUDIT STARTED ==="
    
    # Detect Android devices
    if ! detect_android_devices; then
        log_error "Android device detection failed"
        exit 1
    fi
    
    # Process each Android device
    for device_id in "${ANDROID_DEVICES[@]}"; do
        log "=== PROCESSING ANDROID DEVICE: $device_id ==="
        
        # Get device information
        get_device_info "$device_id"
        
        # Check for Microsoft apps
        check_microsoft_apps "$device_id"
        
        # Audit authenticator apps
        audit_authenticator_apps "$device_id"
        
        # Analyze network activity
        analyze_network_activity "$device_id"
        
        # Audit security settings
        audit_security_settings "$device_id"
        
        log "=== COMPLETED PROCESSING DEVICE: $device_id ==="
    done
    
    log "=== ANDROID AUDIT COMPLETE ==="
    log_success "Android device audit completed. Check log file: $AUDIT_LOG"
    
    log_warning "NEXT STEPS:"
    log_warning "1. Review the generated audit files"
    log_warning "2. Remove any Microsoft apps found"
    log_warning "3. Check authenticator apps for compromise"
    log_warning "4. Monitor network activity for suspicious connections"
}

# Run main function
main "$@"
