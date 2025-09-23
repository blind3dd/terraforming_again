#!/bin/bash

# iOS Device Verification and Health Check Script
# Comprehensive device health monitoring and verification for iOS devices
# Provides ongoing security monitoring and device integrity verification

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFICATION_LOG="$SCRIPT_DIR/ios_verification_$(date +%Y%m%d_%H%M%S).log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HEALTH_REPORT="$SCRIPT_DIR/ios_health_report_$(date +%Y%m%d_%H%M%S).txt"
BASELINE_FILE="$SCRIPT_DIR/ios_baseline_$(date +%Y%m%d_%H%M%S).txt"

# Health check thresholds
BATTERY_WARNING_THRESHOLD=20
BATTERY_CRITICAL_THRESHOLD=10
STORAGE_WARNING_THRESHOLD=80
STORAGE_CRITICAL_THRESHOLD=90

# Logging function
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$VERIFICATION_LOG"
}

# Print section header
print_section() {
    echo "" | tee -a "$VERIFICATION_LOG"
    echo "==========================================" | tee -a "$VERIFICATION_LOG"
    echo "$1" | tee -a "$VERIFICATION_LOG"
    echo "==========================================" | tee -a "$VERIFICATION_LOG"
    echo "" | tee -a "$VERIFICATION_LOG"
}

# Function to check prerequisites
check_prerequisites() {
    print_section "🔍 PREREQUISITE CHECK"
    
    log "🔍 Checking prerequisites for iOS device verification..."
    
    # Check if libimobiledevice is installed
    if command -v ideviceinfo >/dev/null 2>&1; then
        log "✅ libimobiledevice tools found"
    else
        log "❌ libimobiledevice tools not found"
        log "📋 Installing libimobiledevice tools..."
        if command -v brew >/dev/null 2>&1; then
            brew install libimobiledevice ideviceinstaller idevicediagnostics
        else
            log "❌ Homebrew not found - please install libimobiledevice manually"
            return 1
        fi
    fi
    
    # Check for connected device
    if ! idevice_id -l >/dev/null 2>&1; then
        log "❌ No iOS device connected - please connect device via USB"
        return 1
    fi
    
    log "✅ Prerequisites check passed"
    return 0
}

# Function to establish device baseline
establish_baseline() {
    print_section "📊 DEVICE BASELINE ESTABLISHMENT"
    
    log "📊 Establishing device baseline for future comparisons..."
    
    # Get device information
    local device_name=$(ideviceinfo -k DeviceName 2>/dev/null || echo "Unknown")
    local device_model=$(ideviceinfo -k ProductType 2>/dev/null || echo "Unknown")
    local ios_version=$(ideviceinfo -k ProductVersion 2>/dev/null || echo "Unknown")
    local serial_number=$(ideviceinfo -k SerialNumber 2>/dev/null || echo "Unknown")
    local udid=$(ideviceinfo -k UniqueDeviceID 2>/dev/null || echo "Unknown")
    
    # Get installed applications count
    local app_count=$(ideviceinstaller -l 2>/dev/null | wc -l || echo "0")
    
    # Get configuration profiles count
    local profile_count=$(ideviceinfo -k InstalledConfigurationProfiles 2>/dev/null | wc -l || echo "0")
    
    # Get certificates count
    local cert_count=$(ideviceinfo -k InstalledCertificates 2>/dev/null | wc -l || echo "0")
    
    # Create baseline file
    cat > "$BASELINE_FILE" << EOF
iOS Device Baseline
===================
Established: $(date)
Device Name: $device_name
Device Model: $device_model
iOS Version: $ios_version
Serial Number: $serial_number
UDID: $udid

=== BASELINE METRICS ===
Installed Applications: $app_count
Configuration Profiles: $profile_count
Installed Certificates: $cert_count

=== BASELINE APPLICATIONS ===
$(ideviceinstaller -l 2>/dev/null || echo "Could not retrieve applications")

=== BASELINE PROFILES ===
$(ideviceinfo -k InstalledConfigurationProfiles 2>/dev/null || echo "Could not retrieve profiles")

=== BASELINE CERTIFICATES ===
$(ideviceinfo -k InstalledCertificates 2>/dev/null || echo "Could not retrieve certificates")
EOF

    log "✅ Device baseline established: $BASELINE_FILE"
}

# Function to check device connectivity
check_connectivity() {
    print_section "🔗 CONNECTIVITY CHECK"
    
    log "🔗 Checking device connectivity..."
    
    # Check if device is still connected
    if idevice_id -l >/dev/null 2>&1; then
        log "✅ Device is connected and responsive"
        return 0
    else
        log "❌ Device is not connected or not responsive"
        return 1
    fi
}

# Function to check device health
check_device_health() {
    print_section "🏥 DEVICE HEALTH CHECK"
    
    log "🏥 Checking device health metrics..."
    
    local health_issues=0
    
    # Check battery level
    local battery_level=$(ideviceinfo -k BatteryLevel 2>/dev/null || echo "Unknown")
    if [ "$battery_level" != "Unknown" ]; then
        log "🔋 Battery level: $battery_level%"
        
        if [ "$battery_level" -le "$BATTERY_CRITICAL_THRESHOLD" ]; then
            log "🚨 CRITICAL: Battery level is critically low ($battery_level%)"
            health_issues=$((health_issues + 1))
        elif [ "$battery_level" -le "$BATTERY_WARNING_THRESHOLD" ]; then
            log "⚠️  WARNING: Battery level is low ($battery_level%)"
            health_issues=$((health_issues + 1))
        else
            log "✅ Battery level is healthy ($battery_level%)"
        fi
    else
        log "⚠️  Could not retrieve battery level"
    fi
    
    # Check device temperature (if available)
    local device_temp=$(ideviceinfo -k DeviceTemperature 2>/dev/null || echo "Unknown")
    if [ "$device_temp" != "Unknown" ]; then
        log "🌡️  Device temperature: $device_temp"
        
        # Check for overheating (assuming temperature is in Celsius)
        if [ "$device_temp" -gt 40 ]; then
            log "🚨 WARNING: Device temperature is high ($device_temp°C)"
            health_issues=$((health_issues + 1))
        else
            log "✅ Device temperature is normal ($device_temp°C)"
        fi
    else
        log "⚠️  Could not retrieve device temperature"
    fi
    
    # Check device storage (if available)
    local device_storage=$(ideviceinfo -k DeviceStorage 2>/dev/null || echo "Unknown")
    if [ "$device_storage" != "Unknown" ]; then
        log "💾 Device storage: $device_storage"
        
        # Extract storage percentage (assuming format like "80%")
        local storage_percent=$(echo "$device_storage" | grep -o '[0-9]*%' | sed 's/%//' || echo "0")
        if [ "$storage_percent" -ge "$STORAGE_CRITICAL_THRESHOLD" ]; then
            log "🚨 CRITICAL: Device storage is critically full ($storage_percent%)"
            health_issues=$((health_issues + 1))
        elif [ "$storage_percent" -ge "$STORAGE_WARNING_THRESHOLD" ]; then
            log "⚠️  WARNING: Device storage is getting full ($storage_percent%)"
            health_issues=$((health_issues + 1))
        else
            log "✅ Device storage is healthy ($storage_percent%)"
        fi
    else
        log "⚠️  Could not retrieve device storage information"
    fi
    
    # Check device supervision status
    local supervision_status=$(ideviceinfo -k IsSupervised 2>/dev/null || echo "Unknown")
    log "📋 Device supervision status: $supervision_status"
    
    if [ "$supervision_status" = "true" ]; then
        log "⚠️  WARNING: Device is supervised (managed by organization)"
        health_issues=$((health_issues + 1))
    else
        log "✅ Device is not supervised (personal device)"
    fi
    
    return $health_issues
}

# Function to check for new applications
check_new_applications() {
    print_section "📱 APPLICATION CHANGE CHECK"
    
    log "📱 Checking for new or removed applications..."
    
    if [ ! -f "$BASELINE_FILE" ]; then
        log "⚠️  No baseline file found - cannot compare applications"
        return 1
    fi
    
    # Get current applications
    local current_apps=$(ideviceinstaller -l 2>/dev/null || echo "")
    local baseline_apps=$(grep -A 1000 "=== BASELINE APPLICATIONS ===" "$BASELINE_FILE" | tail -n +2 || echo "")
    
    if [ -n "$current_apps" ] && [ -n "$baseline_apps" ]; then
        # Find new applications
        local new_apps=$(comm -13 <(echo "$baseline_apps" | sort) <(echo "$current_apps" | sort) || true)
        if [ -n "$new_apps" ]; then
            log "🚨 NEW APPLICATIONS DETECTED:"
            echo "$new_apps" | while read -r app; do
                log "   + $app"
            done
        else
            log "✅ No new applications detected"
        fi
        
        # Find removed applications
        local removed_apps=$(comm -23 <(echo "$baseline_apps" | sort) <(echo "$current_apps" | sort) || true)
        if [ -n "$removed_apps" ]; then
            log "📱 REMOVED APPLICATIONS DETECTED:"
            echo "$removed_apps" | while read -r app; do
                log "   - $app"
            done
        else
            log "✅ No applications removed"
        fi
    else
        log "⚠️  Could not compare applications"
    fi
}

# Function to check for new profiles
check_new_profiles() {
    print_section "📋 PROFILE CHANGE CHECK"
    
    log "📋 Checking for new or removed configuration profiles..."
    
    if [ ! -f "$BASELINE_FILE" ]; then
        log "⚠️  No baseline file found - cannot compare profiles"
        return 1
    fi
    
    # Get current profiles
    local current_profiles=$(ideviceinfo -k InstalledConfigurationProfiles 2>/dev/null || echo "")
    local baseline_profiles=$(grep -A 1000 "=== BASELINE PROFILES ===" "$BASELINE_FILE" | tail -n +2 || echo "")
    
    if [ -n "$current_profiles" ] && [ -n "$baseline_profiles" ]; then
        # Find new profiles
        local new_profiles=$(comm -13 <(echo "$baseline_profiles" | sort) <(echo "$current_profiles" | sort) || true)
        if [ -n "$new_profiles" ]; then
            log "🚨 NEW CONFIGURATION PROFILES DETECTED:"
            echo "$new_profiles" | while read -r profile; do
                log "   + $profile"
            done
        else
            log "✅ No new configuration profiles detected"
        fi
        
        # Find removed profiles
        local removed_profiles=$(comm -23 <(echo "$baseline_profiles" | sort) <(echo "$current_profiles" | sort) || true)
        if [ -n "$removed_profiles" ]; then
            log "📋 REMOVED CONFIGURATION PROFILES DETECTED:"
            echo "$removed_profiles" | while read -r profile; do
                log "   - $profile"
            done
        else
            log "✅ No configuration profiles removed"
        fi
    else
        log "⚠️  Could not compare profiles"
    fi
}

# Function to check for new certificates
check_new_certificates() {
    print_section "🔐 CERTIFICATE CHANGE CHECK"
    
    log "🔐 Checking for new or removed certificates..."
    
    if [ ! -f "$BASELINE_FILE" ]; then
        log "⚠️  No baseline file found - cannot compare certificates"
        return 1
    fi
    
    # Get current certificates
    local current_certs=$(ideviceinfo -k InstalledCertificates 2>/dev/null || echo "")
    local baseline_certs=$(grep -A 1000 "=== BASELINE CERTIFICATES ===" "$BASELINE_FILE" | tail -n +2 || echo "")
    
    if [ -n "$current_certs" ] && [ -n "$baseline_certs" ]; then
        # Find new certificates
        local new_certs=$(comm -13 <(echo "$baseline_certs" | sort) <(echo "$current_certs" | sort) || true)
        if [ -n "$new_certs" ]; then
            log "🚨 NEW CERTIFICATES DETECTED:"
            echo "$new_certs" | while read -r cert; do
                log "   + $cert"
            done
        else
            log "✅ No new certificates detected"
        fi
        
        # Find removed certificates
        local removed_certs=$(comm -23 <(echo "$baseline_certs" | sort) <(echo "$current_certs" | sort) || true)
        if [ -n "$removed_certs" ]; then
            log "🔐 REMOVED CERTIFICATES DETECTED:"
            echo "$removed_certs" | while read -r cert; do
                log "   - $cert"
            done
        else
            log "✅ No certificates removed"
        fi
    else
        log "⚠️  Could not compare certificates"
    fi
}

# Function to check for suspicious activity
check_suspicious_activity() {
    print_section "🚨 SUSPICIOUS ACTIVITY CHECK"
    
    log "🚨 Checking for suspicious activity..."
    
    local suspicious_found=false
    
    # Check for suspicious applications
    local installed_apps=$(ideviceinstaller -l 2>/dev/null || echo "")
    if [ -n "$installed_apps" ]; then
        local suspicious_apps=$(echo "$installed_apps" | grep -i -E "(vpn|proxy|tunnel|remote|admin|mdm|enterprise|corp|microsoft|intune)" || true)
        if [ -n "$suspicious_apps" ]; then
            log "🚨 SUSPICIOUS APPLICATIONS DETECTED:"
            echo "$suspicious_apps" | while read -r app; do
                log "   ⚠️  $app"
            done
            suspicious_found=true
        fi
    fi
    
    # Check for suspicious profiles
    local profiles=$(ideviceinfo -k InstalledConfigurationProfiles 2>/dev/null || echo "")
    if [ -n "$profiles" ]; then
        local suspicious_profiles=$(echo "$profiles" | grep -i -E "(enterprise|mdm|corp|admin|vpn|proxy|microsoft|intune)" || true)
        if [ -n "$suspicious_profiles" ]; then
            log "🚨 SUSPICIOUS CONFIGURATION PROFILES DETECTED:"
            echo "$suspicious_profiles" | while read -r profile; do
                log "   ⚠️  $profile"
            done
            suspicious_found=true
        fi
    fi
    
    # Check for VPN configurations
    local vpn_configs=$(ideviceinfo -k VPNConfigurations 2>/dev/null || echo "")
    if [ -n "$vpn_configs" ]; then
        log "🚨 VPN CONFIGURATIONS DETECTED:"
        echo "$vpn_configs" | while read -r vpn; do
            log "   ⚠️  $vpn"
        done
        suspicious_found=true
    fi
    
    # Check for proxy settings
    local proxy_settings=$(ideviceinfo -k ProxySettings 2>/dev/null || echo "")
    if [ -n "$proxy_settings" ]; then
        log "🚨 PROXY SETTINGS DETECTED:"
        echo "$proxy_settings" | while read -r proxy; do
            log "   ⚠️  $proxy"
        done
        suspicious_found=true
    fi
    
    if [ "$suspicious_found" = false ]; then
        log "✅ No suspicious activity detected"
    fi
}

# Function to check security settings
check_security_settings() {
    print_section "🔒 SECURITY SETTINGS CHECK"
    
    log "🔒 Checking security settings..."
    
    local security_issues=0
    
    # Check passcode status
    local passcode_status=$(ideviceinfo -k PasscodeStatus 2>/dev/null || echo "Unknown")
    log "🔐 Passcode status: $passcode_status"
    
    if [ "$passcode_status" != "true" ] && [ "$passcode_status" != "1" ]; then
        log "🚨 WARNING: Device passcode is not enabled"
        security_issues=$((security_issues + 1))
    else
        log "✅ Device passcode is enabled"
    fi
    
    # Check biometric settings
    local biometric_settings=$(ideviceinfo -k BiometricSettings 2>/dev/null || echo "Unknown")
    log "👆 Biometric settings: $biometric_settings"
    
    if [ "$biometric_settings" = "Unknown" ]; then
        log "⚠️  Could not retrieve biometric settings"
    else
        log "✅ Biometric settings retrieved"
    fi
    
    # Check location services
    local location_services=$(ideviceinfo -k LocationServices 2>/dev/null || echo "Unknown")
    log "📍 Location services: $location_services"
    
    if [ "$location_services" = "true" ] || [ "$location_services" = "1" ]; then
        log "⚠️  WARNING: Location services are enabled"
        security_issues=$((security_issues + 1))
    else
        log "✅ Location services are disabled"
    fi
    
    return $security_issues
}

# Function to generate health report
generate_health_report() {
    print_section "📊 HEALTH REPORT GENERATION"
    
    log "📊 Generating comprehensive health report..."
    
    # Get device information
    local device_name=$(ideviceinfo -k DeviceName 2>/dev/null || echo "Unknown")
    local device_model=$(ideviceinfo -k ProductType 2>/dev/null || echo "Unknown")
    local ios_version=$(ideviceinfo -k ProductVersion 2>/dev/null || echo "Unknown")
    local udid=$(ideviceinfo -k UniqueDeviceID 2>/dev/null || echo "Unknown")
    
    # Get current metrics
    local app_count=$(ideviceinstaller -l 2>/dev/null | wc -l || echo "0")
    local profile_count=$(ideviceinfo -k InstalledConfigurationProfiles 2>/dev/null | wc -l || echo "0")
    local cert_count=$(ideviceinfo -k InstalledCertificates 2>/dev/null | wc -l || echo "0")
    local battery_level=$(ideviceinfo -k BatteryLevel 2>/dev/null || echo "Unknown")
    local supervision_status=$(ideviceinfo -k IsSupervised 2>/dev/null || echo "Unknown")
    local passcode_status=$(ideviceinfo -k PasscodeStatus 2>/dev/null || echo "Unknown")
    local location_services=$(ideviceinfo -k LocationServices 2>/dev/null || echo "Unknown")
    
    # Create health report
    cat > "$HEALTH_REPORT" << EOF
iOS Device Health Report
========================
Generated: $(date)
Device Name: $device_name
Device Model: $device_model
iOS Version: $ios_version
UDID: $udid

=== DEVICE METRICS ===
Installed Applications: $app_count
Configuration Profiles: $profile_count
Installed Certificates: $cert_count
Battery Level: $battery_level%
Supervision Status: $supervision_status

=== SECURITY STATUS ===
Passcode Enabled: $passcode_status
Location Services: $location_services

=== HEALTH ASSESSMENT ===
EOF

    # Add health assessment based on checks
    if check_device_health; then
        echo "Device Health: ✅ HEALTHY" >> "$HEALTH_REPORT"
    else
        echo "Device Health: ⚠️  ISSUES DETECTED" >> "$HEALTH_REPORT"
    fi
    
    if check_security_settings; then
        echo "Security Status: ✅ SECURE" >> "$HEALTH_REPORT"
    else
        echo "Security Status: ⚠️  ISSUES DETECTED" >> "$HEALTH_REPORT"
    fi
    
    cat >> "$HEALTH_REPORT" << EOF

=== RECOMMENDATIONS ===
1. Keep iOS updated to latest version
2. Use strong passcode and biometric authentication
3. Review app permissions regularly
4. Monitor for suspicious applications
5. Check configuration profiles periodically
6. Use Find My iPhone for device tracking
7. Avoid installing apps from unknown sources

=== FILES CREATED ===
- Verification log: $VERIFICATION_LOG
- Health report: $HEALTH_REPORT
- Baseline file: $BASELINE_FILE
EOF

    log "📄 Health report generated: $HEALTH_REPORT"
}

# Function to show usage information
show_usage() {
    echo "iOS Device Verification and Health Check - Usage"
    echo "================================================"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  baseline    - Establish device baseline"
    echo "  check       - Perform health check"
    echo "  monitor     - Continuous monitoring"
    echo "  report      - Generate health report"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 baseline    # Establish baseline for future comparisons"
    echo "  $0 check       # Perform comprehensive health check"
    echo "  $0 monitor     # Start continuous monitoring"
    echo "  $0 report      # Generate health report"
}

# Function to perform continuous monitoring
continuous_monitoring() {
    print_section "🔄 CONTINUOUS MONITORING"
    
    log "🔄 Starting continuous device monitoring..."
    log "Press Ctrl+C to stop monitoring"
    
    while true; do
        log "🔍 Performing monitoring check..."
        
        # Check connectivity
        if ! check_connectivity; then
            log "❌ Device disconnected - stopping monitoring"
            break
        fi
        
        # Check for changes
        check_new_applications
        check_new_profiles
        check_new_certificates
        check_suspicious_activity
        
        # Wait before next check
        log "⏳ Waiting 60 seconds before next check..."
        sleep 60
    done
}

# Main execution function
main() {
    print_section "🛡️ iOS DEVICE VERIFICATION AND HEALTH CHECK"
    log "Starting iOS device verification at $TIMESTAMP"
    
    # Check prerequisites
    if ! check_prerequisites; then
        log "❌ Prerequisites not met - please install required tools and connect device"
        exit 1
    fi
    
    # Parse command line arguments
    case "${1:-help}" in
        "baseline")
            establish_baseline
            ;;
        "check")
            check_connectivity
            check_device_health
            check_new_applications
            check_new_profiles
            check_new_certificates
            check_suspicious_activity
            check_security_settings
            generate_health_report
            ;;
        "monitor")
            continuous_monitoring
            ;;
        "report")
            generate_health_report
            ;;
        "help"|*)
            show_usage
            ;;
    esac
    
    # Final summary
    print_section "🔍 VERIFICATION SUMMARY"
    log "iOS device verification completed at $(date '+%Y-%m-%d %H:%M:%S')"
    log "Verification log: $VERIFICATION_LOG"
    
    if [ -f "$HEALTH_REPORT" ]; then
        log "Health report: $HEALTH_REPORT"
    fi
    
    if [ -f "$BASELINE_FILE" ]; then
        log "Baseline file: $BASELINE_FILE"
    fi
    
    echo "" | tee -a "$VERIFICATION_LOG"
    echo "🛡️ iOS DEVICE VERIFICATION COMPLETE" | tee -a "$VERIFICATION_LOG"
    echo "====================================" | tee -a "$VERIFICATION_LOG"
}

# Execute main function
main "$@"
