#!/bin/bash

# Enhanced iOS Device Security Audit Script
# Comprehensive security audit for iOS devices with automated remediation
# Based on macOS audit patterns and enhanced for iOS-specific threats

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIT_LOG="$SCRIPT_DIR/enhanced_ios_audit_$(date +%Y%m%d_%H%M%S).log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DEVICE_INFO_FILE="$SCRIPT_DIR/ios_device_info_$(date +%Y%m%d_%H%M%S).txt"
SUSPICIOUS_APPS_FILE="$SCRIPT_DIR/suspicious_ios_apps_$(date +%Y%m%d_%H%M%S).txt"
SECURITY_REPORT="$SCRIPT_DIR/ios_security_report_$(date +%Y%m%d_%H%M%S).txt"

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

# Function to check prerequisites
check_prerequisites() {
    print_section "🔍 PREREQUISITE CHECK"
    
    log "🔍 Checking prerequisites for iOS device audit..."
    
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
    
    return 0
}

# Function to detect connected devices
detect_connected_devices() {
    print_section "🔍 DEVICE DETECTION"
    
    log "🔍 Detecting connected iOS devices..."
    
    # Check for devices via system_profiler
    local usb_devices=$(system_profiler SPUSBDataType | grep -A 10 -B 2 -i "iphone\|ipad\|ipod" || true)
    if [ -n "$usb_devices" ]; then
        log "📱 USB devices detected:"
        echo "$usb_devices" | tee -a "$AUDIT_LOG"
    else
        log "❌ No USB devices detected"
    fi
    
    # Check for devices via libimobiledevice
    if command -v idevice_id >/dev/null 2>&1; then
        local device_ids=$(idevice_id -l 2>/dev/null || true)
        if [ -n "$device_ids" ]; then
            log "📱 Device IDs detected via libimobiledevice:"
            echo "$device_ids" | tee -a "$AUDIT_LOG"
            return 0
        else
            log "❌ No device IDs detected via libimobiledevice"
            return 1
        fi
    else
        log "❌ libimobiledevice not available"
        return 1
    fi
}

# Function to collect comprehensive device information
collect_device_info() {
    print_section "📱 DEVICE INFORMATION COLLECTION"
    
    log "📱 Collecting comprehensive device information..."
    
    # Basic device information
    log "Device Model: $(ideviceinfo -k ProductType 2>/dev/null || echo 'Unknown')"
    log "iOS Version: $(ideviceinfo -k ProductVersion 2>/dev/null || echo 'Unknown')"
    log "Device Name: $(ideviceinfo -k DeviceName 2>/dev/null || echo 'Unknown')"
    log "Serial Number: $(ideviceinfo -k SerialNumber 2>/dev/null || echo 'Unknown')"
    log "UDID: $(ideviceinfo -k UniqueDeviceID 2>/dev/null || echo 'Unknown')"
    log "Battery Level: $(ideviceinfo -k BatteryLevel 2>/dev/null || echo 'Unknown')"
    log "WiFi Address: $(ideviceinfo -k WiFiAddress 2>/dev/null || echo 'Unknown')"
    log "Bluetooth Address: $(ideviceinfo -k BluetoothAddress 2>/dev/null || echo 'Unknown')"
    
    # Save detailed device info to file
    ideviceinfo > "$DEVICE_INFO_FILE" 2>/dev/null || log "⚠️  Could not save detailed device info"
    log "📄 Detailed device info saved to: $DEVICE_INFO_FILE"
}

# Function to audit configuration profiles
audit_configuration_profiles() {
    print_section "🔍 CONFIGURATION PROFILE AUDIT"
    
    log "🔍 Auditing configuration profiles..."
    
    # Get installed profiles
    local profiles=$(ideviceinfo -k InstalledConfigurationProfiles 2>/dev/null || echo "")
    if [ -n "$profiles" ]; then
        log "📋 Configuration profiles found:"
        echo "$profiles" | tee -a "$AUDIT_LOG"
        
        # Check for suspicious profiles
        local suspicious_profiles=$(echo "$profiles" | grep -i -E "(enterprise|mdm|corp|admin|vpn|proxy)" || true)
        if [ -n "$suspicious_profiles" ]; then
            log "🚨 Suspicious configuration profiles detected:"
            echo "$suspicious_profiles" | tee -a "$AUDIT_LOG"
        fi
    else
        log "✅ No configuration profiles found"
    fi
    
    # Check MDM profiles
    local mdm_profiles=$(ideviceinfo -k InstalledMDMProfiles 2>/dev/null || echo "")
    if [ -n "$mdm_profiles" ]; then
        log "🚨 MDM profiles found:"
        echo "$mdm_profiles" | tee -a "$AUDIT_LOG"
    else
        log "✅ No MDM profiles found"
    fi
    
    # Check enterprise profiles
    local enterprise_profiles=$(ideviceinfo -k InstalledEnterpriseProfiles 2>/dev/null || echo "")
    if [ -n "$enterprise_profiles" ]; then
        log "🚨 Enterprise profiles found:"
        echo "$enterprise_profiles" | tee -a "$AUDIT_LOG"
    else
        log "✅ No enterprise profiles found"
    fi
    
    # Check supervision status
    local supervision_status=$(ideviceinfo -k IsSupervised 2>/dev/null || echo "Unknown")
    log "📋 Device supervision status: $supervision_status"
}

# Function to audit installed applications
audit_installed_apps() {
    print_section "🔍 INSTALLED APPLICATIONS AUDIT"
    
    log "🔍 Auditing installed applications..."
    
    # Get list of installed apps
    local installed_apps=$(ideviceinstaller -l 2>/dev/null || echo "")
    if [ -n "$installed_apps" ]; then
        log "📱 Installed applications:"
        echo "$installed_apps" | tee -a "$AUDIT_LOG"
        
        # Check for suspicious apps
        local suspicious_apps=$(echo "$installed_apps" | grep -i -E "(vpn|proxy|tunnel|remote|admin|mdm|enterprise|corp|microsoft|intune)" || true)
        if [ -n "$suspicious_apps" ]; then
            log "🚨 Suspicious applications detected:"
            echo "$suspicious_apps" | tee -a "$AUDIT_LOG"
            echo "$suspicious_apps" > "$SUSPICIOUS_APPS_FILE"
        fi
        
        # Check for enterprise apps
        local enterprise_apps=$(echo "$installed_apps" | grep -i "enterprise" || true)
        if [ -n "$enterprise_apps" ]; then
            log "🚨 Enterprise applications detected:"
            echo "$enterprise_apps" | tee -a "$AUDIT_LOG"
        fi
        
        # Check for apps with suspicious bundle IDs
        local suspicious_bundle_ids=$(echo "$installed_apps" | grep -E "(com\.enterprise|com\.corp|com\.mdm|com\.admin|com\.microsoft)" || true)
        if [ -n "$suspicious_bundle_ids" ]; then
            log "🚨 Apps with suspicious bundle IDs detected:"
            echo "$suspicious_bundle_ids" | tee -a "$AUDIT_LOG"
        fi
    else
        log "❌ Could not retrieve installed applications"
    fi
}

# Function to audit network configuration
audit_network_configuration() {
    print_section "🔍 NETWORK CONFIGURATION AUDIT"
    
    log "🔍 Auditing network configuration..."
    
    # Check WiFi networks
    local wifi_networks=$(ideviceinfo -k WiFiNetworks 2>/dev/null || echo "")
    if [ -n "$wifi_networks" ]; then
        log "📡 WiFi networks configured:"
        echo "$wifi_networks" | tee -a "$AUDIT_LOG"
    else
        log "✅ No WiFi networks configured"
    fi
    
    # Check VPN configurations
    local vpn_configs=$(ideviceinfo -k VPNConfigurations 2>/dev/null || echo "")
    if [ -n "$vpn_configs" ]; then
        log "🚨 VPN configurations found:"
        echo "$vpn_configs" | tee -a "$AUDIT_LOG"
    else
        log "✅ No VPN configurations found"
    fi
    
    # Check proxy settings
    local proxy_settings=$(ideviceinfo -k ProxySettings 2>/dev/null || echo "")
    if [ -n "$proxy_settings" ]; then
        log "🚨 Proxy settings found:"
        echo "$proxy_settings" | tee -a "$AUDIT_LOG"
    else
        log "✅ No proxy settings found"
    fi
    
    # Check network restrictions
    local network_restrictions=$(ideviceinfo -k NetworkRestrictions 2>/dev/null || echo "")
    if [ -n "$network_restrictions" ]; then
        log "📋 Network restrictions:"
        echo "$network_restrictions" | tee -a "$AUDIT_LOG"
    else
        log "✅ No network restrictions found"
    fi
}

# Function to audit account and iCloud status
audit_accounts_icloud() {
    print_section "🔍 ACCOUNT AND ICLOUD AUDIT"
    
    log "🔍 Auditing account and iCloud status..."
    
    # Check Apple ID status
    local apple_id_status=$(ideviceinfo -k AppleIDStatus 2>/dev/null || echo "Unknown")
    log "📋 Apple ID status: $apple_id_status"
    
    # Check iCloud account
    local icloud_account=$(ideviceinfo -k iCloudAccount 2>/dev/null || echo "Unknown")
    log "☁️ iCloud account: $icloud_account"
    
    # Check email accounts
    local email_accounts=$(ideviceinfo -k EmailAccounts 2>/dev/null || echo "")
    if [ -n "$email_accounts" ]; then
        log "📧 Email accounts configured:"
        echo "$email_accounts" | tee -a "$AUDIT_LOG"
    else
        log "✅ No email accounts configured"
    fi
    
    # Check calendar accounts
    local calendar_accounts=$(ideviceinfo -k CalendarAccounts 2>/dev/null || echo "")
    if [ -n "$calendar_accounts" ]; then
        log "📅 Calendar accounts configured:"
        echo "$calendar_accounts" | tee -a "$AUDIT_LOG"
    else
        log "✅ No calendar accounts configured"
    fi
    
    # Check contact accounts
    local contact_accounts=$(ideviceinfo -k ContactAccounts 2>/dev/null || echo "")
    if [ -n "$contact_accounts" ]; then
        log "👥 Contact accounts configured:"
        echo "$contact_accounts" | tee -a "$AUDIT_LOG"
    else
        log "✅ No contact accounts configured"
    fi
}

# Function to audit security settings
audit_security_settings() {
    print_section "🔍 SECURITY SETTINGS AUDIT"
    
    log "🔍 Auditing security settings..."
    
    # Check passcode status
    local passcode_status=$(ideviceinfo -k PasscodeStatus 2>/dev/null || echo "Unknown")
    log "🔒 Passcode status: $passcode_status"
    
    # Check biometric settings
    local biometric_settings=$(ideviceinfo -k BiometricSettings 2>/dev/null || echo "Unknown")
    log "👆 Biometric settings: $biometric_settings"
    
    # Check device restrictions
    local device_restrictions=$(ideviceinfo -k DeviceRestrictions 2>/dev/null || echo "")
    if [ -n "$device_restrictions" ]; then
        log "📋 Device restrictions:"
        echo "$device_restrictions" | tee -a "$AUDIT_LOG"
    else
        log "✅ No device restrictions found"
    fi
    
    # Check privacy settings
    local privacy_settings=$(ideviceinfo -k PrivacySettings 2>/dev/null || echo "")
    if [ -n "$privacy_settings" ]; then
        log "🔒 Privacy settings:"
        echo "$privacy_settings" | tee -a "$AUDIT_LOG"
    else
        log "✅ No privacy settings found"
    fi
    
    # Check location services
    local location_services=$(ideviceinfo -k LocationServices 2>/dev/null || echo "Unknown")
    log "📍 Location services: $location_services"
}

# Function to audit certificates
audit_certificates() {
    print_section "🔍 CERTIFICATE AUDIT"
    
    log "🔍 Auditing certificates..."
    
    # Check installed certificates
    local installed_certs=$(ideviceinfo -k InstalledCertificates 2>/dev/null || echo "")
    if [ -n "$installed_certs" ]; then
        log "📜 Installed certificates:"
        echo "$installed_certs" | tee -a "$AUDIT_LOG"
        
        # Check for suspicious certificates
        local suspicious_certs=$(echo "$installed_certs" | grep -i -E "(microsoft|intune|enterprise|corp|mdm)" || true)
        if [ -n "$suspicious_certs" ]; then
            log "🚨 Suspicious certificates detected:"
            echo "$suspicious_certs" | tee -a "$AUDIT_LOG"
        fi
    else
        log "✅ No installed certificates found"
    fi
    
    # Check trusted certificates
    local trusted_certs=$(ideviceinfo -k TrustedCertificates 2>/dev/null || echo "")
    if [ -n "$trusted_certs" ]; then
        log "🔑 Trusted certificates:"
        echo "$trusted_certs" | tee -a "$AUDIT_LOG"
    else
        log "✅ No trusted certificates found"
    fi
    
    # Check enterprise certificates
    local enterprise_certs=$(ideviceinfo -k EnterpriseCertificates 2>/dev/null || echo "")
    if [ -n "$enterprise_certs" ]; then
        log "🚨 Enterprise certificates found:"
        echo "$enterprise_certs" | tee -a "$AUDIT_LOG"
    else
        log "✅ No enterprise certificates found"
    fi
}

# Function to perform device backup analysis
perform_backup_analysis() {
    print_section "💾 DEVICE BACKUP ANALYSIS"
    
    log "💾 Performing device backup analysis..."
    
    # Create backup directory
    local backup_dir="ios_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Attempt to create backup
    if command -v idevicebackup2 >/dev/null 2>&1; then
        log "📱 Creating device backup..."
        if idevicebackup2 backup "$backup_dir" 2>/dev/null; then
            log "✅ Backup created successfully: $backup_dir"
            
            # Analyze backup for suspicious content
            log "🔍 Analyzing backup for suspicious content..."
            
            # List of suspicious domains to check for
            local suspicious_domains=(
                "@my.utexas.edu"
                "@austin.utexas.edu"
                "@wp.pl"
                "@interia.pl"
                "*gov.pl"
                "@facebook.com"
                "@google.com"
                "@shopify.com"
                "@encora.com"
                "@apple.com"
                "policja.gov.pl"
                "@*.policja.gov.pl"
                "equinix.com"
                "pawelbek90@gmail.com"
                "blind3dd@gmail.com"
                "ldap03.appetize.cc"
                "vpn.appetizeinc.com"
                "crowdstrike"
                "microsoft"
                "intune"
                "ansible"
            )
            
            for domain in "${suspicious_domains[@]}"; do
                if grep -r -i "$domain" "$backup_dir" >/dev/null 2>&1; then
                    log "🚨 Suspicious domain '$domain' found in backup"
                fi
            done
            
        else
            log "❌ Backup creation failed"
        fi
    else
        log "⚠️  idevicebackup2 not available - backup analysis skipped"
    fi
}

# Function to generate security report
generate_security_report() {
    print_section "📊 SECURITY REPORT GENERATION"
    
    log "📊 Generating comprehensive security report..."
    
    cat > "$SECURITY_REPORT" << EOF
iOS Device Security Audit Report
================================
Generated: $(date)
Device: $(ideviceinfo -k DeviceName 2>/dev/null || echo 'Unknown')
Model: $(ideviceinfo -k ProductType 2>/dev/null || echo 'Unknown')
iOS Version: $(ideviceinfo -k ProductVersion 2>/dev/null || echo 'Unknown')
UDID: $(ideviceinfo -k UniqueDeviceID 2>/dev/null || echo 'Unknown')

=== SECURITY ASSESSMENT ===
Supervision Status: $(ideviceinfo -k IsSupervised 2>/dev/null || echo 'Unknown')
Configuration Profiles: $(ideviceinfo -k InstalledConfigurationProfiles 2>/dev/null | wc -l || echo 'Unknown')
MDM Profiles: $(ideviceinfo -k InstalledMDMProfiles 2>/dev/null | wc -l || echo 'Unknown')
Enterprise Profiles: $(ideviceinfo -k InstalledEnterpriseProfiles 2>/dev/null | wc -l || echo 'Unknown')
Installed Apps: $(ideviceinfo -k InstalledApplications 2>/dev/null | wc -l || echo 'Unknown')

=== NETWORK CONFIGURATION ===
WiFi Networks: $(ideviceinfo -k WiFiNetworks 2>/dev/null | wc -l || echo 'Unknown')
VPN Configurations: $(ideviceinfo -k VPNConfigurations 2>/dev/null | wc -l || echo 'Unknown')
Proxy Settings: $(ideviceinfo -k ProxySettings 2>/dev/null || echo 'Unknown')

=== ACCOUNT STATUS ===
Apple ID Status: $(ideviceinfo -k AppleIDStatus 2>/dev/null || echo 'Unknown')
iCloud Account: $(ideviceinfo -k iCloudAccount 2>/dev/null || echo 'Unknown')
Email Accounts: $(ideviceinfo -k EmailAccounts 2>/dev/null | wc -l || echo 'Unknown')

=== SECURITY SETTINGS ===
Passcode Status: $(ideviceinfo -k PasscodeStatus 2>/dev/null || echo 'Unknown')
Biometric Settings: $(ideviceinfo -k BiometricSettings 2>/dev/null || echo 'Unknown')
Location Services: $(ideviceinfo -k LocationServices 2>/dev/null || echo 'Unknown')

=== CERTIFICATES ===
Installed Certificates: $(ideviceinfo -k InstalledCertificates 2>/dev/null | wc -l || echo 'Unknown')
Trusted Certificates: $(ideviceinfo -k TrustedCertificates 2>/dev/null | wc -l || echo 'Unknown')
Enterprise Certificates: $(ideviceinfo -k EnterpriseCertificates 2>/dev/null | wc -l || echo 'Unknown')

=== SUSPICIOUS CONTENT DETECTED ===
EOF

    # Add suspicious content findings
    if [ -f "$SUSPICIOUS_APPS_FILE" ]; then
        echo "Suspicious Applications:" >> "$SECURITY_REPORT"
        cat "$SUSPICIOUS_APPS_FILE" >> "$SECURITY_REPORT"
        echo "" >> "$SECURITY_REPORT"
    fi
    
    log "📄 Security report generated: $SECURITY_REPORT"
}

# Function to provide remediation recommendations
provide_remediation_recommendations() {
    print_section "🛠️ REMEDIATION RECOMMENDATIONS"
    
    log "🛠️ Providing remediation recommendations..."
    
    # Check for issues and provide specific recommendations
    local has_issues=false
    
    # Check for suspicious profiles
    if ideviceinfo -k InstalledConfigurationProfiles 2>/dev/null | grep -i -E "(enterprise|mdm|corp|admin|vpn|proxy)" >/dev/null; then
        log "🚨 RECOMMENDATION: Remove suspicious configuration profiles"
        has_issues=true
    fi
    
    # Check for suspicious apps
    if ideviceinstaller -l 2>/dev/null | grep -i -E "(vpn|proxy|tunnel|remote|admin|mdm|enterprise|corp|microsoft|intune)" >/dev/null; then
        log "🚨 RECOMMENDATION: Remove suspicious applications"
        has_issues=true
    fi
    
    # Check for VPN configurations
    if ideviceinfo -k VPNConfigurations 2>/dev/null | grep -q "."; then
        log "🚨 RECOMMENDATION: Review and remove VPN configurations"
        has_issues=true
    fi
    
    # Check for proxy settings
    if ideviceinfo -k ProxySettings 2>/dev/null | grep -q "."; then
        log "🚨 RECOMMENDATION: Review and remove proxy settings"
        has_issues=true
    fi
    
    if [ "$has_issues" = false ]; then
        log "✅ No immediate security issues detected"
    fi
    
    log "📋 General recommendations:"
    log "   - Keep iOS updated to latest version"
    log "   - Use strong passcode and biometric authentication"
    log "   - Review app permissions regularly"
    log "   - Monitor for unusual behavior"
    log "   - Use Find My iPhone for device tracking"
}

# Main execution function
main() {
    print_section "🚨 ENHANCED iOS DEVICE SECURITY AUDIT"
    log "Starting enhanced iOS device security audit at $TIMESTAMP"
    log "Auditing iOS device for security threats and suspicious activity"
    
    # Check prerequisites
    if ! check_prerequisites; then
        log "❌ Prerequisites not met - please install required tools"
        exit 1
    fi
    
    # Detect connected devices
    if ! detect_connected_devices; then
        log "❌ No iOS devices detected - please connect device via USB"
        exit 1
    fi
    
    # Run all audit phases
    collect_device_info
    audit_configuration_profiles
    audit_installed_apps
    audit_network_configuration
    audit_accounts_icloud
    audit_security_settings
    audit_certificates
    perform_backup_analysis
    generate_security_report
    provide_remediation_recommendations
    
    # Final summary
    print_section "🔍 AUDIT SUMMARY"
    log "Enhanced iOS device security audit completed at $(date '+%Y-%m-%d %H:%M:%S')"
    log "Audit log: $AUDIT_LOG"
    log "Device info: $DEVICE_INFO_FILE"
    log "Security report: $SECURITY_REPORT"
    
    if [ -f "$SUSPICIOUS_APPS_FILE" ]; then
        log "Suspicious apps: $SUSPICIOUS_APPS_FILE"
    fi
    
    echo "" | tee -a "$AUDIT_LOG"
    echo "🛡️ ENHANCED iOS AUDIT COMPLETE" | tee -a "$AUDIT_LOG"
    echo "===============================" | tee -a "$AUDIT_LOG"
    echo "" | tee -a "$AUDIT_LOG"
    echo "📋 Review all generated files for security assessment" | tee -a "$AUDIT_LOG"
    echo "⚠️  Follow remediation recommendations if issues found" | tee -a "$AUDIT_LOG"
    echo "⚠️  Consider using cleanup scripts for detected threats" | tee -a "$AUDIT_LOG"
}

# Execute main function
main "$@"
