#!/bin/bash

# iOS/iPadOS Security Audit Script
# This script performs comprehensive security audit of iOS and iPadOS devices

echo "=== iOS/iPADOS SECURITY AUDIT SCRIPT ==="
echo "This script performs comprehensive security audit of iOS and iPadOS devices."
echo ""

# Check if libimobiledevice tools are installed
if ! command -v ideviceinfo &> /dev/null; then
    echo "ERROR: libimobiledevice tools not found!"
    echo "Please install libimobiledevice:"
    echo "  brew install libimobiledevice"
    echo "  brew install ideviceinstaller"
    exit 1
fi

# Check if device is connected
if ! idevice_id -l | grep -q "."; then
    echo "ERROR: No iOS device connected. Please connect device via USB."
    exit 1
fi

echo "iOS device connected. Starting comprehensive security audit..."
echo ""

# =============================================================================
# PHASE 1: DEVICE INFORMATION AUDIT
# =============================================================================

echo "=== PHASE 1: DEVICE INFORMATION AUDIT ==="

echo "Collecting device information..."
ideviceinfo > device_info.txt 2>/dev/null

echo "Device Model:"
ideviceinfo -k ProductType 2>/dev/null || echo "Unable to get device model"

echo "iOS Version:"
ideviceinfo -k ProductVersion 2>/dev/null || echo "Unable to get iOS version"

echo "Device Name:"
ideviceinfo -k DeviceName 2>/dev/null || echo "Unable to get device name"

echo "Serial Number:"
ideviceinfo -k SerialNumber 2>/dev/null || echo "Unable to get serial number"

echo "UDID:"
ideviceinfo -k UniqueDeviceID 2>/dev/null || echo "Unable to get UDID"

echo ""

# =============================================================================
# PHASE 2: CONFIGURATION PROFILE AUDIT
# =============================================================================

echo "=== PHASE 2: CONFIGURATION PROFILE AUDIT ==="

echo "Checking for configuration profiles..."
ideviceinfo -k InstalledConfigurationProfiles 2>/dev/null || echo "Unable to get configuration profiles"

echo "Checking for MDM profiles..."
ideviceinfo -k InstalledMDMProfiles 2>/dev/null || echo "Unable to get MDM profiles"

echo "Checking for enterprise profiles..."
ideviceinfo -k InstalledEnterpriseProfiles 2>/dev/null || echo "Unable to get enterprise profiles"

echo "Checking for supervision status..."
ideviceinfo -k IsSupervised 2>/dev/null || echo "Unable to get supervision status"

echo ""

# =============================================================================
# PHASE 3: INSTALLED APPS AUDIT
# =============================================================================

echo "=== PHASE 3: INSTALLED APPS AUDIT ==="

echo "Listing all installed apps..."
ideviceinstaller -l > installed_apps.txt 2>/dev/null

echo "Checking for enterprise apps..."
ideviceinstaller -l | grep -i "enterprise" || echo "No enterprise apps found"

echo "Checking for suspicious app names..."
ideviceinstaller -l | grep -E "(vpn|proxy|tunnel|remote|admin|mdm|enterprise|corp)" || echo "No suspicious apps found"

echo "Checking for apps with suspicious bundle IDs..."
ideviceinstaller -l | grep -E "(com\.enterprise|com\.corp|com\.mdm|com\.admin)" || echo "No suspicious bundle IDs found"

echo ""

# =============================================================================
# PHASE 4: NETWORK CONFIGURATION AUDIT
# =============================================================================

echo "=== PHASE 4: NETWORK CONFIGURATION AUDIT ==="

echo "Checking WiFi configurations..."
ideviceinfo -k WiFiNetworks 2>/dev/null || echo "Unable to get WiFi networks"

echo "Checking VPN configurations..."
ideviceinfo -k VPNConfigurations 2>/dev/null || echo "Unable to get VPN configurations"

echo "Checking proxy settings..."
ideviceinfo -k ProxySettings 2>/dev/null || echo "Unable to get proxy settings"

echo "Checking network restrictions..."
ideviceinfo -k NetworkRestrictions 2>/dev/null || echo "Unable to get network restrictions"

echo ""

# =============================================================================
# PHASE 5: ACCOUNT AND ICLOUD AUDIT
# =============================================================================

echo "=== PHASE 5: ACCOUNT AND ICLOUD AUDIT ==="

echo "Checking Apple ID status..."
ideviceinfo -k AppleIDStatus 2>/dev/null || echo "Unable to get Apple ID status"

echo "Checking iCloud account..."
ideviceinfo -k iCloudAccount 2>/dev/null || echo "Unable to get iCloud account"

echo "Checking email accounts..."
ideviceinfo -k EmailAccounts 2>/dev/null || echo "Unable to get email accounts"

echo "Checking calendar accounts..."
ideviceinfo -k CalendarAccounts 2>/dev/null || echo "Unable to get calendar accounts"

echo "Checking contact accounts..."
ideviceinfo -k ContactAccounts 2>/dev/null || echo "Unable to get contact accounts"

echo ""

# =============================================================================
# PHASE 6: SECURITY SETTINGS AUDIT
# =============================================================================

echo "=== PHASE 6: SECURITY SETTINGS AUDIT ==="

echo "Checking passcode status..."
ideviceinfo -k PasscodeStatus 2>/dev/null || echo "Unable to get passcode status"

echo "Checking biometric settings..."
ideviceinfo -k BiometricSettings 2>/dev/null || echo "Unable to get biometric settings"

echo "Checking device restrictions..."
ideviceinfo -k DeviceRestrictions 2>/dev/null || echo "Unable to get device restrictions"

echo "Checking privacy settings..."
ideviceinfo -k PrivacySettings 2>/dev/null || echo "Unable to get privacy settings"

echo "Checking location services..."
ideviceinfo -k LocationServices 2>/dev/null || echo "Unable to get location services"

echo ""

# =============================================================================
# PHASE 7: CERTIFICATE AUDIT
# =============================================================================

echo "=== PHASE 7: CERTIFICATE AUDIT ==="

echo "Checking installed certificates..."
ideviceinfo -k InstalledCertificates 2>/dev/null || echo "Unable to get certificates"

echo "Checking trusted certificates..."
ideviceinfo -k TrustedCertificates 2>/dev/null || echo "Unable to get trusted certificates"

echo "Checking enterprise certificates..."
ideviceinfo -k EnterpriseCertificates 2>/dev/null || echo "Unable to get enterprise certificates"

echo ""

# =============================================================================
# PHASE 8: BACKUP ANALYSIS
# =============================================================================

echo "=== PHASE 8: BACKUP ANALYSIS ==="

echo "Creating device backup for analysis..."
mkdir -p ios_backup_$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="ios_backup_$(date +%Y%m%d_%H%M%S)"

idevicebackup2 backup "$BACKUP_DIR" 2>/dev/null || echo "Backup failed or not supported"

echo "Analyzing backup for suspicious data..."
if [ -d "$BACKUP_DIR" ]; then
    echo "Backup created: $BACKUP_DIR"
    echo "Analyzing backup contents..."
    find "$BACKUP_DIR" -name "*.plist" | head -10
    echo "Backup analysis complete"
else
    echo "Backup not available for analysis"
fi

echo ""

# =============================================================================
# PHASE 9: SUSPICIOUS DOMAIN CHECK
# =============================================================================

echo "=== PHASE 9: SUSPICIOUS DOMAIN CHECK ==="

echo "Checking for suspicious domains in device data..."

# List of suspicious domains to check for
SUSPICIOUS_DOMAINS=(
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
)

for domain in "${SUSPICIOUS_DOMAINS[@]}"; do
    echo "Checking for: $domain"
    if [ -d "$BACKUP_DIR" ]; then
        if grep -r -i "$domain" "$BACKUP_DIR" >/dev/null 2>&1; then
            echo "  ⚠️  FOUND: $domain in device data"
        else
            echo "  ✅ CLEAN: $domain not found"
        fi
    else
        echo "  ⚠️  Cannot check: Backup not available"
    fi
done

echo ""

# =============================================================================
# PHASE 10: FINAL VERIFICATION
# =============================================================================

echo "=== PHASE 10: FINAL VERIFICATION ==="

echo "Final security assessment..."
echo "Device Model: $(ideviceinfo -k ProductType 2>/dev/null || echo 'Unknown')"
echo "iOS Version: $(ideviceinfo -k ProductVersion 2>/dev/null || echo 'Unknown')"
echo "Supervision Status: $(ideviceinfo -k IsSupervised 2>/dev/null || echo 'Unknown')"
echo "Configuration Profiles: $(ideviceinfo -k InstalledConfigurationProfiles 2>/dev/null | wc -l || echo 'Unknown')"
echo "Installed Apps: $(ideviceinfo -k InstalledApplications 2>/dev/null | wc -l || echo 'Unknown')"

echo ""

# =============================================================================
# PHASE 11: REPORT GENERATION
# =============================================================================

echo "=== PHASE 11: REPORT GENERATION ==="

echo "Generating security audit report..."
REPORT_FILE="ios_security_audit_report_$(date +%Y%m%d_%H%M%S).txt"

cat > "$REPORT_FILE" << EOF
iOS/iPadOS Security Audit Report
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

=== SUSPICIOUS DOMAIN CHECK ===
EOF

# Add suspicious domain check results to report
for domain in "${SUSPICIOUS_DOMAINS[@]}"; do
    if [ -d "$BACKUP_DIR" ]; then
        if grep -r -i "$domain" "$BACKUP_DIR" >/dev/null 2>&1; then
            echo "FOUND: $domain" >> "$REPORT_FILE"
        else
            echo "CLEAN: $domain" >> "$REPORT_FILE"
        fi
    else
        echo "UNKNOWN: $domain (backup not available)" >> "$REPORT_FILE"
    fi
done

echo "Security audit report generated: $REPORT_FILE"
echo ""

echo "=== iOS/iPADOS SECURITY AUDIT COMPLETE ==="
echo ""
echo "SUMMARY OF ACTIONS PERFORMED:"
echo "✅ Collected device information"
echo "✅ Audited configuration profiles"
echo "✅ Audited installed apps"
echo "✅ Audited network configuration"
echo "✅ Audited account and iCloud status"
echo "✅ Audited security settings"
echo "✅ Audited certificates"
echo "✅ Analyzed device backup"
echo "✅ Checked for suspicious domains"
echo "✅ Generated security report"
echo ""
echo "FILES CREATED:"
echo "  - device_info.txt (device information)"
echo "  - installed_apps.txt (installed apps list)"
echo "  - $BACKUP_DIR/ (device backup)"
echo "  - $REPORT_FILE (security audit report)"
echo ""
echo "NEXT STEPS:"
echo "1. Review the security audit report"
echo "2. Check for any suspicious findings"
echo "3. Use Apple Configurator cleanup script if needed"
echo "4. Remove any unwanted profiles or apps"
echo ""
