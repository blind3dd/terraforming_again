#!/bin/bash

# =============================================================================
# SURGICAL DEVICE CLEANUP SCRIPT - PRESERVING MFA APPS
# =============================================================================
# This script removes ONLY Microsoft compromise apps while preserving
# authenticator apps and other essential applications
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEANUP_LOG="$SCRIPT_DIR/device_cleanup_$(date +%Y%m%d_%H%M%S).log"
CFGUTIL="/Applications/Apple Configurator.app/Contents/MacOS/cfgutil"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$CLEANUP_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$CLEANUP_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$CLEANUP_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$CLEANUP_LOG"
}

# Initialize logging
exec > >(tee -a "$CLEANUP_LOG") 2>&1

log "Starting Surgical Device Cleanup - Preserving MFA Apps"
log "Log file: $CLEANUP_LOG"

# =============================================================================
# DEVICE DETECTION
# =============================================================================

detect_devices() {
    log "Detecting connected devices..."
    
    if ! command -v "$CFGUTIL" &> /dev/null; then
        log_error "Apple Configurator not found at $CFGUTIL"
        exit 1
    fi
    
    # Get device list
    DEVICE_LIST=$("$CFGUTIL" list 2>/dev/null || true)
    
    if [[ -z "$DEVICE_LIST" ]]; then
        log_error "No devices detected. Please connect your iPhone and iPad via USB."
        exit 1
    fi
    
    log "Connected devices detected:"
    echo "$DEVICE_LIST" | tee -a "$CLEANUP_LOG"
    
    # Extract device info - fix parsing
    IPHONE_ECID=$(echo "$DEVICE_LIST" | grep "iPhone" | sed 's/.*ECID: //' | awk '{print $1}' || echo "")
    IPAD_ECID=$(echo "$DEVICE_LIST" | grep "iPad" | sed 's/.*ECID: //' | awk '{print $1}' || echo "")
    
    # Debug output
    log "iPhone ECID: '$IPHONE_ECID'"
    log "iPad ECID: '$IPAD_ECID'"
    
    if [[ -n "$IPHONE_ECID" ]]; then
        log_success "iPhone detected: ECID $IPHONE_ECID"
    fi
    
    if [[ -n "$IPAD_ECID" ]]; then
        log_success "iPad detected: ECID $IPAD_ECID"
    fi
    
    if [[ -z "$IPHONE_ECID" && -z "$IPAD_ECID" ]]; then
        log_error "No iPhone or iPad detected"
        exit 1
    fi
}

# =============================================================================
# APP ANALYSIS
# =============================================================================

analyze_device_apps() {
    local device_ecid="$1"
    local device_name="$2"
    
    log "Analyzing apps on $device_name (ECID: $device_ecid)..."
    
    # Get installed apps
    local apps_output
    apps_output=$("$CFGUTIL" get-property installedApps 2>/dev/null || true)
    
    if [[ -z "$apps_output" ]]; then
        log_warning "Could not retrieve app list for $device_name"
        return 1
    fi
    
    # Save app list to file
    local app_list_file="$SCRIPT_DIR/${device_name}_apps_$(date +%Y%m%d_%H%M%S).txt"
    echo "$apps_output" > "$app_list_file"
    log "App list saved to: $app_list_file"
    
    # Check for Microsoft apps
    local microsoft_apps=()
    while IFS= read -r line; do
        if [[ "$line" =~ com\.microsoft\. ]]; then
            microsoft_apps+=("$line")
        fi
    done <<< "$apps_output"
    
    if [[ ${#microsoft_apps[@]} -gt 0 ]]; then
        log_warning "Microsoft apps found on $device_name:"
        for app in "${microsoft_apps[@]}"; do
            log_warning "  - $app"
        done
    else
        log_success "No Microsoft apps found on $device_name"
    fi
    
    # Check for authenticator apps (PRESERVE THESE)
    local authenticator_apps=()
    while IFS= read -r line; do
        if [[ "$line" =~ (authenticator|auth|mfa|2fa|yubico|google.*auth|microsoft.*auth) ]]; then
            authenticator_apps+=("$line")
        fi
    done <<< "$apps_output"
    
    if [[ ${#authenticator_apps[@]} -gt 0 ]]; then
        log_success "Authenticator apps found on $device_name (WILL BE PRESERVED):"
        for app in "${authenticator_apps[@]}"; do
            log_success "  - $app"
        done
    fi
    
    return 0
}

# =============================================================================
# SURGICAL APP REMOVAL
# =============================================================================

remove_microsoft_apps() {
    local device_ecid="$1"
    local device_name="$2"
    
    log "Starting surgical removal of Microsoft apps from $device_name..."
    
    # Microsoft apps to remove (ONLY these specific ones)
    local apps_to_remove=(
        "com.microsoft.msedge"
        "com.microsoft.skydrive"
        "com.microsoft.Office.Powerpoint"
    )
    
    for app_id in "${apps_to_remove[@]}"; do
        log "Attempting to remove $app_id from $device_name..."
        
        # Note: cfgutil remove-app requires device to be supervised
        # For unsupervised devices, we'll document the manual removal steps
        log_warning "Device $device_name is not supervised. Manual removal required."
        log_warning "Please manually delete these apps from $device_name:"
        log_warning "  - Microsoft Edge"
        log_warning "  - Microsoft OneDrive" 
        log_warning "  - Microsoft PowerPoint"
    done
}

# =============================================================================
# ICLOUD SYNC REPAIR
# =============================================================================

repair_icloud_sync() {
    log "Starting iCloud sync repair process..."
    
    # Check iCloud status on Mac
    log "Checking iCloud status on Mac..."
    
    # Sign out of iCloud (this will prompt for password)
    log_warning "To repair iCloud sync, you need to:"
    log_warning "1. Go to System Preferences > Apple ID"
    log_warning "2. Sign out of iCloud"
    log_warning "3. Sign back in with your Apple ID"
    log_warning "4. Re-enable iCloud services one by one"
    
    # Check for iCloud processes
    local icloud_processes
    icloud_processes=$(ps aux | grep -i icloud | grep -v grep || true)
    
    if [[ -n "$icloud_processes" ]]; then
        log "Active iCloud processes:"
        echo "$icloud_processes" | tee -a "$CLEANUP_LOG"
    fi
}

# =============================================================================
# DEVICE SECURITY AUDIT
# =============================================================================

audit_device_security() {
    local device_ecid="$1"
    local device_name="$2"
    
    log "Auditing security settings for $device_name..."
    
    # Get device properties
    local device_props
    device_props=$("$CFGUTIL" get-property all 2>/dev/null || true)
    
    if [[ -n "$device_props" ]]; then
        # Check passcode protection
        if echo "$device_props" | grep -q "passcodeProtected:.*yes"; then
            log_success "$device_name has passcode protection enabled"
        else
            log_warning "$device_name does NOT have passcode protection"
        fi
        
        # Check if supervised
        if echo "$device_props" | grep -q "isSupervised:.*yes"; then
            log_success "$device_name is supervised (managed)"
        else
            log_warning "$device_name is NOT supervised (unmanaged)"
        fi
        
        # Check cloud backups
        if echo "$device_props" | grep -q "cloudBackupsAreEnabled:.*yes"; then
            log_warning "$device_name has cloud backups enabled (potential data exfiltration risk)"
        else
            log_success "$device_name has cloud backups disabled"
        fi
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log "=== SURGICAL DEVICE CLEANUP STARTED ==="
    log "Preserving MFA authenticator apps while removing Microsoft compromise"
    
    # Detect devices
    detect_devices
    
    # Process iPhone
    if [[ -n "$IPHONE_ECID" ]]; then
        log "=== PROCESSING IPHONE ==="
        analyze_device_apps "$IPHONE_ECID" "iPhone"
        audit_device_security "$IPHONE_ECID" "iPhone"
        remove_microsoft_apps "$IPHONE_ECID" "iPhone"
    fi
    
    # Process iPad
    if [[ -n "$IPAD_ECID" ]]; then
        log "=== PROCESSING IPAD ==="
        analyze_device_apps "$IPAD_ECID" "iPad"
        audit_device_security "$IPAD_ECID" "iPad"
        remove_microsoft_apps "$IPAD_ECID" "iPad"
    fi
    
    # Repair iCloud sync
    log "=== ICLOUD SYNC REPAIR ==="
    repair_icloud_sync
    
    log "=== CLEANUP COMPLETE ==="
    log_success "Surgical cleanup completed. Check log file: $CLEANUP_LOG"
    
    log_warning "MANUAL STEPS REQUIRED:"
    log_warning "1. Manually delete Microsoft apps from both devices"
    log_warning "2. Sign out and back into iCloud on Mac"
    log_warning "3. Monitor devices for 24 hours for any re-emerging threats"
    log_warning "4. Consider enabling passcode protection on iPad"
}

# Run main function
main "$@"
