#!/bin/bash

# iOS Automation Tools
# Comprehensive automation tools for iOS device management using libimobiledevice
# Provides advanced device control, monitoring, and management capabilities

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_LOG="$SCRIPT_DIR/ios_automation_tools_$(date +%Y%m%d_%H%M%S).log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Logging function
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$TOOLS_LOG"
}

# Print section header
print_section() {
    echo "" | tee -a "$TOOLS_LOG"
    echo "==========================================" | tee -a "$TOOLS_LOG"
    echo "$1" | tee -a "$TOOLS_LOG"
    echo "==========================================" | tee -a "$TOOLS_LOG"
    echo "" | tee -a "$TOOLS_LOG"
}

# Function to check and install prerequisites
check_prerequisites() {
    print_section "🔍 PREREQUISITE CHECK"
    
    log "🔍 Checking prerequisites for iOS automation tools..."
    
    # Check if libimobiledevice is installed
    if command -v ideviceinfo >/dev/null 2>&1; then
        log "✅ libimobiledevice tools found"
    else
        log "❌ libimobiledevice tools not found"
        log "📋 Installing libimobiledevice tools..."
        if command -v brew >/dev/null 2>&1; then
            brew install libimobiledevice ideviceinstaller idevicediagnostics idevicebackup2
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

# Function to get device information
get_device_info() {
    print_section "📱 DEVICE INFORMATION"
    
    log "📱 Collecting comprehensive device information..."
    
    # Basic device information
    local device_name=$(ideviceinfo -k DeviceName 2>/dev/null || echo "Unknown")
    local device_model=$(ideviceinfo -k ProductType 2>/dev/null || echo "Unknown")
    local ios_version=$(ideviceinfo -k ProductVersion 2>/dev/null || echo "Unknown")
    local serial_number=$(ideviceinfo -k SerialNumber 2>/dev/null || echo "Unknown")
    local udid=$(ideviceinfo -k UniqueDeviceID 2>/dev/null || echo "Unknown")
    local battery_level=$(ideviceinfo -k BatteryLevel 2>/dev/null || echo "Unknown")
    local wifi_address=$(ideviceinfo -k WiFiAddress 2>/dev/null || echo "Unknown")
    local bluetooth_address=$(ideviceinfo -k BluetoothAddress 2>/dev/null || echo "Unknown")
    
    log "Device Name: $device_name"
    log "Device Model: $device_model"
    log "iOS Version: $ios_version"
    log "Serial Number: $serial_number"
    log "UDID: $udid"
    log "Battery Level: $battery_level"
    log "WiFi Address: $wifi_address"
    log "Bluetooth Address: $bluetooth_address"
    
    # Save detailed device info
    local device_info_file="$SCRIPT_DIR/device_info_$(date +%Y%m%d_%H%M%S).txt"
    ideviceinfo > "$device_info_file" 2>/dev/null || log "⚠️  Could not save detailed device info"
    log "📄 Detailed device info saved to: $device_info_file"
}

# Function to list installed applications
list_installed_apps() {
    print_section "📱 INSTALLED APPLICATIONS"
    
    log "📱 Listing all installed applications..."
    
    local apps_file="$SCRIPT_DIR/installed_apps_$(date +%Y%m%d_%H%M%S).txt"
    
    if ideviceinstaller -l > "$apps_file" 2>/dev/null; then
        log "✅ Installed applications list saved to: $apps_file"
        
        # Count applications
        local app_count=$(wc -l < "$apps_file" 2>/dev/null || echo "0")
        log "📊 Total applications installed: $app_count"
        
        # Show first 10 applications
        log "📱 First 10 applications:"
        head -10 "$apps_file" | while read -r app_line; do
            log "   $app_line"
        done
        
        if [ "$app_count" -gt 10 ]; then
            log "   ... and $((app_count - 10)) more applications"
        fi
    else
        log "❌ Could not retrieve installed applications"
    fi
}

# Function to install application
install_app() {
    local app_path="$1"
    
    print_section "📱 APPLICATION INSTALLATION"
    
    log "📱 Installing application: $app_path"
    
    if [ ! -f "$app_path" ]; then
        log "❌ Application file not found: $app_path"
        return 1
    fi
    
    if ideviceinstaller -i "$app_path" 2>/dev/null; then
        log "✅ Application installed successfully: $app_path"
    else
        log "❌ Failed to install application: $app_path"
        return 1
    fi
}

# Function to uninstall application
uninstall_app() {
    local bundle_id="$1"
    
    print_section "🗑️ APPLICATION UNINSTALLATION"
    
    log "🗑️ Uninstalling application: $bundle_id"
    
    if ideviceinstaller -U "$bundle_id" 2>/dev/null; then
        log "✅ Application uninstalled successfully: $bundle_id"
    else
        log "❌ Failed to uninstall application: $bundle_id"
        return 1
    fi
}

# Function to create device backup
create_backup() {
    local backup_path="$1"
    
    print_section "💾 DEVICE BACKUP"
    
    log "💾 Creating device backup: $backup_path"
    
    if [ ! -d "$backup_path" ]; then
        mkdir -p "$backup_path"
    fi
    
    if command -v idevicebackup2 >/dev/null 2>&1; then
        if idevicebackup2 backup "$backup_path" 2>/dev/null; then
            log "✅ Device backup created successfully: $backup_path"
        else
            log "❌ Failed to create device backup: $backup_path"
            return 1
        fi
    else
        log "❌ idevicebackup2 not available - backup not possible"
        return 1
    fi
}

# Function to restore device from backup
restore_backup() {
    local backup_path="$1"
    
    print_section "🔄 DEVICE RESTORE"
    
    log "🔄 Restoring device from backup: $backup_path"
    
    if [ ! -d "$backup_path" ]; then
        log "❌ Backup directory not found: $backup_path"
        return 1
    fi
    
    if command -v idevicebackup2 >/dev/null 2>&1; then
        if idevicebackup2 restore "$backup_path" 2>/dev/null; then
            log "✅ Device restored successfully from: $backup_path"
        else
            log "❌ Failed to restore device from: $backup_path"
            return 1
        fi
    else
        log "❌ idevicebackup2 not available - restore not possible"
        return 1
    fi
}

# Function to restart device
restart_device() {
    print_section "🔄 DEVICE RESTART"
    
    log "🔄 Restarting device..."
    
    if command -v idevicediagnostics >/dev/null 2>&1; then
        if idevicediagnostics restart 2>/dev/null; then
            log "✅ Device restart initiated"
        else
            log "❌ Failed to restart device"
            return 1
        fi
    else
        log "❌ idevicediagnostics not available - restart not possible"
        return 1
    fi
}

# Function to shutdown device
shutdown_device() {
    print_section "🔌 DEVICE SHUTDOWN"
    
    log "🔌 Shutting down device..."
    
    if command -v idevicediagnostics >/dev/null 2>&1; then
        if idevicediagnostics shutdown 2>/dev/null; then
            log "✅ Device shutdown initiated"
        else
            log "❌ Failed to shutdown device"
            return 1
        fi
    else
        log "❌ idevicediagnostics not available - shutdown not possible"
        return 1
    fi
}

# Function to get device logs
get_device_logs() {
    local log_file="$1"
    
    print_section "📋 DEVICE LOGS"
    
    log "📋 Retrieving device logs..."
    
    if command -v idevicesyslog >/dev/null 2>&1; then
        log "📋 Capturing device logs to: $log_file"
        timeout 30 idevicesyslog > "$log_file" 2>/dev/null || log "⚠️  Log capture completed or timed out"
        log "✅ Device logs saved to: $log_file"
    else
        log "❌ idevicesyslog not available - logs not retrievable"
        return 1
    fi
}

# Function to take device screenshot
take_screenshot() {
    local screenshot_path="$1"
    
    print_section "📸 DEVICE SCREENSHOT"
    
    log "📸 Taking device screenshot..."
    
    if command -v idevicescreenshot >/dev/null 2>&1; then
        if idevicescreenshot "$screenshot_path" 2>/dev/null; then
            log "✅ Screenshot saved to: $screenshot_path"
        else
            log "❌ Failed to take screenshot: $screenshot_path"
            return 1
        fi
    else
        log "❌ idevicescreenshot not available - screenshot not possible"
        return 1
    fi
}

# Function to get device crash logs
get_crash_logs() {
    local crash_log_dir="$1"
    
    print_section "💥 CRASH LOGS"
    
    log "💥 Retrieving device crash logs..."
    
    if [ ! -d "$crash_log_dir" ]; then
        mkdir -p "$crash_log_dir"
    fi
    
    if command -v idevicecrashreport >/dev/null 2>&1; then
        if idevicecrashreport "$crash_log_dir" 2>/dev/null; then
            log "✅ Crash logs saved to: $crash_log_dir"
            
            # Count crash logs
            local crash_count=$(find "$crash_log_dir" -name "*.crash" | wc -l)
            log "📊 Found $crash_count crash logs"
        else
            log "❌ Failed to retrieve crash logs: $crash_log_dir"
            return 1
        fi
    else
        log "❌ idevicecrashreport not available - crash logs not retrievable"
        return 1
    fi
}

# Function to get device provisioning profiles
get_provisioning_profiles() {
    print_section "📋 PROVISIONING PROFILES"
    
    log "📋 Retrieving provisioning profiles..."
    
    local profiles_file="$SCRIPT_DIR/provisioning_profiles_$(date +%Y%m%d_%H%M%S).txt"
    
    # Get configuration profiles
    local config_profiles=$(ideviceinfo -k InstalledConfigurationProfiles 2>/dev/null || echo "")
    if [ -n "$config_profiles" ]; then
        log "📋 Configuration profiles found:"
        echo "$config_profiles" | tee -a "$profiles_file"
    else
        log "✅ No configuration profiles found"
    fi
    
    # Get MDM profiles
    local mdm_profiles=$(ideviceinfo -k InstalledMDMProfiles 2>/dev/null || echo "")
    if [ -n "$mdm_profiles" ]; then
        log "📋 MDM profiles found:"
        echo "$mdm_profiles" | tee -a "$profiles_file"
    else
        log "✅ No MDM profiles found"
    fi
    
    # Get enterprise profiles
    local enterprise_profiles=$(ideviceinfo -k InstalledEnterpriseProfiles 2>/dev/null || echo "")
    if [ -n "$enterprise_profiles" ]; then
        log "📋 Enterprise profiles found:"
        echo "$enterprise_profiles" | tee -a "$profiles_file"
    else
        log "✅ No enterprise profiles found"
    fi
    
    if [ -f "$profiles_file" ] && [ -s "$profiles_file" ]; then
        log "📄 Provisioning profiles saved to: $profiles_file"
    fi
}

# Function to get device certificates
get_certificates() {
    print_section "🔐 CERTIFICATES"
    
    log "🔐 Retrieving device certificates..."
    
    local certs_file="$SCRIPT_DIR/certificates_$(date +%Y%m%d_%H%M%S).txt"
    
    # Get installed certificates
    local installed_certs=$(ideviceinfo -k InstalledCertificates 2>/dev/null || echo "")
    if [ -n "$installed_certs" ]; then
        log "📜 Installed certificates found:"
        echo "$installed_certs" | tee -a "$certs_file"
    else
        log "✅ No installed certificates found"
    fi
    
    # Get trusted certificates
    local trusted_certs=$(ideviceinfo -k TrustedCertificates 2>/dev/null || echo "")
    if [ -n "$trusted_certs" ]; then
        log "🔑 Trusted certificates found:"
        echo "$trusted_certs" | tee -a "$certs_file"
    else
        log "✅ No trusted certificates found"
    fi
    
    # Get enterprise certificates
    local enterprise_certs=$(ideviceinfo -k EnterpriseCertificates 2>/dev/null || echo "")
    if [ -n "$enterprise_certs" ]; then
        log "🏢 Enterprise certificates found:"
        echo "$enterprise_certs" | tee -a "$certs_file"
    else
        log "✅ No enterprise certificates found"
    fi
    
    if [ -f "$certs_file" ] && [ -s "$certs_file" ]; then
        log "📄 Certificates saved to: $certs_file"
    fi
}

# Function to get network configuration
get_network_config() {
    print_section "🌐 NETWORK CONFIGURATION"
    
    log "🌐 Retrieving network configuration..."
    
    local network_file="$SCRIPT_DIR/network_config_$(date +%Y%m%d_%H%M%S).txt"
    
    # Get WiFi networks
    local wifi_networks=$(ideviceinfo -k WiFiNetworks 2>/dev/null || echo "")
    if [ -n "$wifi_networks" ]; then
        log "📡 WiFi networks configured:"
        echo "$wifi_networks" | tee -a "$network_file"
    else
        log "✅ No WiFi networks configured"
    fi
    
    # Get VPN configurations
    local vpn_configs=$(ideviceinfo -k VPNConfigurations 2>/dev/null || echo "")
    if [ -n "$vpn_configs" ]; then
        log "🔒 VPN configurations found:"
        echo "$vpn_configs" | tee -a "$network_file"
    else
        log "✅ No VPN configurations found"
    fi
    
    # Get proxy settings
    local proxy_settings=$(ideviceinfo -k ProxySettings 2>/dev/null || echo "")
    if [ -n "$proxy_settings" ]; then
        log "🌐 Proxy settings found:"
        echo "$proxy_settings" | tee -a "$network_file"
    else
        log "✅ No proxy settings found"
    fi
    
    # Get network restrictions
    local network_restrictions=$(ideviceinfo -k NetworkRestrictions 2>/dev/null || echo "")
    if [ -n "$network_restrictions" ]; then
        log "🚫 Network restrictions found:"
        echo "$network_restrictions" | tee -a "$network_file"
    else
        log "✅ No network restrictions found"
    fi
    
    if [ -f "$network_file" ] && [ -s "$network_file" ]; then
        log "📄 Network configuration saved to: $network_file"
    fi
}

# Function to get account information
get_account_info() {
    print_section "👤 ACCOUNT INFORMATION"
    
    log "👤 Retrieving account information..."
    
    local accounts_file="$SCRIPT_DIR/accounts_$(date +%Y%m%d_%H%M%S).txt"
    
    # Get Apple ID status
    local apple_id_status=$(ideviceinfo -k AppleIDStatus 2>/dev/null || echo "Unknown")
    log "🍎 Apple ID status: $apple_id_status"
    echo "Apple ID Status: $apple_id_status" >> "$accounts_file"
    
    # Get iCloud account
    local icloud_account=$(ideviceinfo -k iCloudAccount 2>/dev/null || echo "Unknown")
    log "☁️ iCloud account: $icloud_account"
    echo "iCloud Account: $icloud_account" >> "$accounts_file"
    
    # Get email accounts
    local email_accounts=$(ideviceinfo -k EmailAccounts 2>/dev/null || echo "")
    if [ -n "$email_accounts" ]; then
        log "📧 Email accounts configured:"
        echo "$email_accounts" | tee -a "$accounts_file"
    else
        log "✅ No email accounts configured"
    fi
    
    # Get calendar accounts
    local calendar_accounts=$(ideviceinfo -k CalendarAccounts 2>/dev/null || echo "")
    if [ -n "$calendar_accounts" ]; then
        log "📅 Calendar accounts configured:"
        echo "$calendar_accounts" | tee -a "$accounts_file"
    else
        log "✅ No calendar accounts configured"
    fi
    
    # Get contact accounts
    local contact_accounts=$(ideviceinfo -k ContactAccounts 2>/dev/null || echo "")
    if [ -n "$contact_accounts" ]; then
        log "👥 Contact accounts configured:"
        echo "$contact_accounts" | tee -a "$accounts_file"
    else
        log "✅ No contact accounts configured"
    fi
    
    if [ -f "$accounts_file" ] && [ -s "$accounts_file" ]; then
        log "📄 Account information saved to: $accounts_file"
    fi
}

# Function to get security settings
get_security_settings() {
    print_section "🔒 SECURITY SETTINGS"
    
    log "🔒 Retrieving security settings..."
    
    local security_file="$SCRIPT_DIR/security_settings_$(date +%Y%m%d_%H%M%S).txt"
    
    # Get passcode status
    local passcode_status=$(ideviceinfo -k PasscodeStatus 2>/dev/null || echo "Unknown")
    log "🔐 Passcode status: $passcode_status"
    echo "Passcode Status: $passcode_status" >> "$security_file"
    
    # Get biometric settings
    local biometric_settings=$(ideviceinfo -k BiometricSettings 2>/dev/null || echo "Unknown")
    log "👆 Biometric settings: $biometric_settings"
    echo "Biometric Settings: $biometric_settings" >> "$security_file"
    
    # Get device restrictions
    local device_restrictions=$(ideviceinfo -k DeviceRestrictions 2>/dev/null || echo "")
    if [ -n "$device_restrictions" ]; then
        log "🚫 Device restrictions found:"
        echo "$device_restrictions" | tee -a "$security_file"
    else
        log "✅ No device restrictions found"
    fi
    
    # Get privacy settings
    local privacy_settings=$(ideviceinfo -k PrivacySettings 2>/dev/null || echo "")
    if [ -n "$privacy_settings" ]; then
        log "🔒 Privacy settings found:"
        echo "$privacy_settings" | tee -a "$security_file"
    else
        log "✅ No privacy settings found"
    fi
    
    # Get location services
    local location_services=$(ideviceinfo -k LocationServices 2>/dev/null || echo "Unknown")
    log "📍 Location services: $location_services"
    echo "Location Services: $location_services" >> "$security_file"
    
    if [ -f "$security_file" ] && [ -s "$security_file" ]; then
        log "📄 Security settings saved to: $security_file"
    fi
}

# Function to perform comprehensive device analysis
comprehensive_analysis() {
    print_section "🔍 COMPREHENSIVE DEVICE ANALYSIS"
    
    log "🔍 Performing comprehensive device analysis..."
    
    # Create analysis directory
    local analysis_dir="$SCRIPT_DIR/device_analysis_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$analysis_dir"
    
    # Get all device information
    get_device_info
    list_installed_apps
    get_provisioning_profiles
    get_certificates
    get_network_config
    get_account_info
    get_security_settings
    
    # Move all generated files to analysis directory
    mv "$SCRIPT_DIR"/device_info_*.txt "$analysis_dir/" 2>/dev/null || true
    mv "$SCRIPT_DIR"/installed_apps_*.txt "$analysis_dir/" 2>/dev/null || true
    mv "$SCRIPT_DIR"/provisioning_profiles_*.txt "$analysis_dir/" 2>/dev/null || true
    mv "$SCRIPT_DIR"/certificates_*.txt "$analysis_dir/" 2>/dev/null || true
    mv "$SCRIPT_DIR"/network_config_*.txt "$analysis_dir/" 2>/dev/null || true
    mv "$SCRIPT_DIR"/accounts_*.txt "$analysis_dir/" 2>/dev/null || true
    mv "$SCRIPT_DIR"/security_settings_*.txt "$analysis_dir/" 2>/dev/null || true
    
    log "✅ Comprehensive device analysis completed"
    log "📁 Analysis files saved to: $analysis_dir"
}

# Function to show usage information
show_usage() {
    echo "iOS Automation Tools - Usage"
    echo "============================"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  info                    - Get device information"
    echo "  apps                    - List installed applications"
    echo "  install <app_path>      - Install application"
    echo "  uninstall <bundle_id>   - Uninstall application"
    echo "  backup <backup_path>    - Create device backup"
    echo "  restore <backup_path>   - Restore device from backup"
    echo "  restart                 - Restart device"
    echo "  shutdown                - Shutdown device"
    echo "  logs <log_file>         - Get device logs"
    echo "  screenshot <image_path> - Take device screenshot"
    echo "  crashlogs <crash_dir>   - Get crash logs"
    echo "  profiles                - Get provisioning profiles"
    echo "  certificates            - Get certificates"
    echo "  network                 - Get network configuration"
    echo "  accounts                - Get account information"
    echo "  security                - Get security settings"
    echo "  analysis                - Perform comprehensive analysis"
    echo "  help                    - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 info"
    echo "  $0 apps"
    echo "  $0 install /path/to/app.ipa"
    echo "  $0 uninstall com.example.app"
    echo "  $0 backup /path/to/backup"
    echo "  $0 restart"
    echo "  $0 analysis"
}

# Main execution function
main() {
    print_section "🛠️ iOS AUTOMATION TOOLS"
    log "Starting iOS automation tools at $TIMESTAMP"
    
    # Check prerequisites
    if ! check_prerequisites; then
        log "❌ Prerequisites not met - please install required tools and connect device"
        exit 1
    fi
    
    # Parse command line arguments
    case "${1:-help}" in
        "info")
            get_device_info
            ;;
        "apps")
            list_installed_apps
            ;;
        "install")
            if [ -z "${2:-}" ]; then
                log "❌ Application path required for install command"
                exit 1
            fi
            install_app "$2"
            ;;
        "uninstall")
            if [ -z "${2:-}" ]; then
                log "❌ Bundle ID required for uninstall command"
                exit 1
            fi
            uninstall_app "$2"
            ;;
        "backup")
            if [ -z "${2:-}" ]; then
                log "❌ Backup path required for backup command"
                exit 1
            fi
            create_backup "$2"
            ;;
        "restore")
            if [ -z "${2:-}" ]; then
                log "❌ Backup path required for restore command"
                exit 1
            fi
            restore_backup "$2"
            ;;
        "restart")
            restart_device
            ;;
        "shutdown")
            shutdown_device
            ;;
        "logs")
            if [ -z "${2:-}" ]; then
                log "❌ Log file path required for logs command"
                exit 1
            fi
            get_device_logs "$2"
            ;;
        "screenshot")
            if [ -z "${2:-}" ]; then
                log "❌ Image path required for screenshot command"
                exit 1
            fi
            take_screenshot "$2"
            ;;
        "crashlogs")
            if [ -z "${2:-}" ]; then
                log "❌ Crash log directory required for crashlogs command"
                exit 1
            fi
            get_crash_logs "$2"
            ;;
        "profiles")
            get_provisioning_profiles
            ;;
        "certificates")
            get_certificates
            ;;
        "network")
            get_network_config
            ;;
        "accounts")
            get_account_info
            ;;
        "security")
            get_security_settings
            ;;
        "analysis")
            comprehensive_analysis
            ;;
        "help"|*)
            show_usage
            ;;
    esac
    
    # Final summary
    print_section "🔍 OPERATION SUMMARY"
    log "iOS automation tools operation completed at $(date '+%Y-%m-%d %H:%M:%S')"
    log "Tools log: $TOOLS_LOG"
    
    echo "" | tee -a "$TOOLS_LOG"
    echo "🛠️ iOS AUTOMATION TOOLS COMPLETE" | tee -a "$TOOLS_LOG"
    echo "================================" | tee -a "$TOOLS_LOG"
}

# Execute main function
main "$@"
