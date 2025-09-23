# iOS Device Audit and Cleanup Guide

This guide provides comprehensive tools and procedures for auditing and cleaning iOS devices, similar to the macOS audit and cleanup scripts already in your project.

## Overview

The iOS audit and cleanup toolkit includes five main scripts that provide comprehensive security auditing, cleanup, and monitoring capabilities for iOS devices:

1. **Enhanced iOS Device Audit** - Comprehensive security audit
2. **Enhanced Emergency iOS Cleanup** - Automated threat removal
3. **Enhanced Selective iOS Cleanup** - Intelligent cleanup with app preservation
4. **iOS Automation Tools** - Advanced device management
5. **iOS Device Verification** - Health monitoring and verification

## Prerequisites

### Required Tools

Before using these scripts, ensure you have the following tools installed:

```bash
# Install libimobiledevice tools
brew install libimobiledevice ideviceinstaller idevicediagnostics idevicebackup2

# Verify installation
ideviceinfo --version
ideviceinstaller --version
```

### Device Requirements

- iOS device connected via USB
- Device must be trusted (unlock device when prompted)
- For some operations, Apple Configurator 2 may be required

## Scripts Overview

### 1. Enhanced iOS Device Audit (`enhanced_ios_device_audit.sh`)

**Purpose**: Comprehensive security audit of iOS devices

**Features**:
- Device information collection
- Configuration profile audit
- Installed applications audit
- Network configuration audit
- Account and iCloud audit
- Security settings audit
- Certificate audit
- Backup analysis
- Suspicious domain detection
- Comprehensive reporting

**Usage**:
```bash
./enhanced_ios_device_audit.sh
```

**Output Files**:
- `enhanced_ios_audit_YYYYMMDD_HHMMSS.log` - Detailed audit log
- `ios_device_info_YYYYMMDD_HHMMSS.txt` - Device information
- `suspicious_ios_apps_YYYYMMDD_HHMMSS.txt` - Suspicious applications found
- `ios_security_report_YYYYMMDD_HHMMSS.txt` - Comprehensive security report

### 2. Enhanced Emergency iOS Cleanup (`enhanced_emergency_ios_cleanup.sh`)

**Purpose**: Automated remediation for infected iOS devices

**Features**:
- Emergency backup creation
- Suspicious profile removal
- Malicious application removal
- Network configuration cleanup
- Account cleanup
- Certificate cleanup
- Device restart
- Comprehensive reporting

**Usage**:
```bash
./enhanced_emergency_ios_cleanup.sh
```

**Output Files**:
- `enhanced_ios_cleanup_YYYYMMDD_HHMMSS.log` - Cleanup log
- `ios_emergency_backup_YYYYMMDD_HHMMSS/` - Emergency backup directory
- `removed_suspicious_items_YYYYMMDD_HHMMSS.txt` - Items removed
- `ios_cleanup_report_YYYYMMDD_HHMMSS.txt` - Cleanup report

### 3. Enhanced Selective iOS Cleanup (`enhanced_selective_ios_cleanup.sh`)

**Purpose**: Intelligent cleanup that preserves essential apps

**Features**:
- Essential app identification and preservation
- Suspicious app detection and removal
- Selective profile removal
- Network configuration cleanup
- Account cleanup
- Certificate cleanup
- Comprehensive reporting

**Essential Apps Preserved**:
- Authenticator apps (Google Authenticator, Microsoft Authenticator, Authy, 1Password, LastPass)
- Banking apps (Bank of America, Chase, Wells Fargo, Citibank, PayPal, Venmo, Cash App)
- Productivity apps (Slack, Microsoft Office, Apple Mail, Messages, Phone, Camera, Safari)
- System apps (Calendar, Contacts, Notes, Reminders, Find My, Health, Music, Podcasts, TV, Books, News, Stocks, Weather, Calculator, Compass, Measure, Voice Memos, FaceTime)

**Usage**:
```bash
./enhanced_selective_ios_cleanup.sh
```

**Output Files**:
- `enhanced_selective_ios_cleanup_YYYYMMDD_HHMMSS.log` - Cleanup log
- `ios_selective_backup_YYYYMMDD_HHMMSS/` - Selective backup directory
- `preserved_essential_apps_YYYYMMDD_HHMMSS.txt` - Essential apps preserved
- `removed_suspicious_items_YYYYMMDD_HHMMSS.txt` - Items removed
- `ios_selective_cleanup_report_YYYYMMDD_HHMMSS.txt` - Cleanup report

### 4. iOS Automation Tools (`ios_automation_tools.sh`)

**Purpose**: Advanced device management and automation

**Features**:
- Device information retrieval
- Application management (install/uninstall)
- Backup and restore operations
- Device control (restart/shutdown)
- Log collection
- Screenshot capture
- Crash log retrieval
- Profile and certificate management
- Network configuration management
- Account information retrieval
- Security settings management
- Comprehensive device analysis

**Usage**:
```bash
# Get device information
./ios_automation_tools.sh info

# List installed applications
./ios_automation_tools.sh apps

# Install application
./ios_automation_tools.sh install /path/to/app.ipa

# Uninstall application
./ios_automation_tools.sh uninstall com.example.app

# Create backup
./ios_automation_tools.sh backup /path/to/backup

# Restore from backup
./ios_automation_tools.sh restore /path/to/backup

# Restart device
./ios_automation_tools.sh restart

# Take screenshot
./ios_automation_tools.sh screenshot /path/to/screenshot.png

# Get device logs
./ios_automation_tools.sh logs /path/to/logs.txt

# Get crash logs
./ios_automation_tools.sh crashlogs /path/to/crashlogs/

# Get provisioning profiles
./ios_automation_tools.sh profiles

# Get certificates
./ios_automation_tools.sh certificates

# Get network configuration
./ios_automation_tools.sh network

# Get account information
./ios_automation_tools.sh accounts

# Get security settings
./ios_automation_tools.sh security

# Perform comprehensive analysis
./ios_automation_tools.sh analysis
```

### 5. iOS Device Verification (`ios_device_verification.sh`)

**Purpose**: Health monitoring and device integrity verification

**Features**:
- Device baseline establishment
- Connectivity monitoring
- Health metrics monitoring
- Application change detection
- Profile change detection
- Certificate change detection
- Suspicious activity detection
- Security settings verification
- Continuous monitoring
- Health reporting

**Usage**:
```bash
# Establish device baseline
./ios_device_verification.sh baseline

# Perform health check
./ios_device_verification.sh check

# Start continuous monitoring
./ios_device_verification.sh monitor

# Generate health report
./ios_device_verification.sh report
```

## Workflow Recommendations

### Initial Device Assessment

1. **Run Enhanced iOS Device Audit**:
   ```bash
   ./enhanced_ios_device_audit.sh
   ```

2. **Review the security report** for any suspicious findings

3. **Establish device baseline**:
   ```bash
   ./ios_device_verification.sh baseline
   ```

### Regular Monitoring

1. **Perform periodic health checks**:
   ```bash
   ./ios_device_verification.sh check
   ```

2. **Monitor for changes**:
   ```bash
   ./ios_device_verification.sh monitor
   ```

### Threat Response

#### For Infected Devices (Emergency Cleanup)

1. **Run Emergency Cleanup**:
   ```bash
   ./enhanced_emergency_ios_cleanup.sh
   ```

2. **Follow manual steps** in Apple Configurator 2 as indicated

3. **Verify cleanup** with another audit

#### For Selective Cleanup (Preserve Essential Apps)

1. **Run Selective Cleanup**:
   ```bash
   ./enhanced_selective_ios_cleanup.sh
   ```

2. **Test essential apps** to ensure they're working

3. **Follow manual steps** in Apple Configurator 2 as indicated

### Ongoing Management

1. **Use automation tools** for device management:
   ```bash
   ./ios_automation_tools.sh analysis
   ```

2. **Regular backups**:
   ```bash
   ./ios_automation_tools.sh backup /path/to/backup
   ```

3. **Monitor device health**:
   ```bash
   ./ios_device_verification.sh check
   ```

## Security Considerations

### Suspicious Indicators

The scripts check for the following suspicious indicators:

**Applications**:
- VPN, proxy, tunnel, remote access apps
- Enterprise, MDM, corporate apps
- Microsoft, Intune, Ansible apps
- Admin, debug, developer tools
- Jailbreak tools (Cydia, Sileo, Zebra, Filza)

**Configuration Profiles**:
- Enterprise profiles
- MDM profiles
- Corporate profiles
- Unknown configuration profiles

**Network Configurations**:
- VPN configurations
- Proxy settings
- Suspicious WiFi networks

**Certificates**:
- Enterprise certificates
- Suspicious trusted certificates
- Unknown certificates

**Accounts**:
- Enterprise accounts
- Corporate accounts
- Suspicious email accounts

### Manual Steps Required

Some operations require manual intervention through Apple Configurator 2:

1. **Profile Removal**: Must be done through Apple Configurator 2 GUI
2. **Certificate Removal**: Must be done through device settings
3. **Network Configuration**: Must be done through device settings
4. **Account Removal**: Must be done through device settings

## Troubleshooting

### Common Issues

1. **Device Not Detected**:
   - Ensure device is connected via USB
   - Unlock device and trust computer
   - Check USB cable and port

2. **Permission Denied**:
   - Ensure device is trusted
   - Check device passcode
   - Restart device if needed

3. **libimobiledevice Issues**:
   - Reinstall libimobiledevice tools
   - Check device compatibility
   - Update iOS version if possible

4. **Backup/Restore Issues**:
   - Ensure sufficient storage space
   - Check device encryption status
   - Verify backup integrity

### Log Files

All scripts generate detailed log files with timestamps. Check these files for:
- Error messages
- Warning indicators
- Operation results
- Detailed diagnostics

## Integration with Existing macOS Scripts

These iOS scripts complement your existing macOS audit and cleanup scripts:

- **Similar structure** and logging patterns
- **Consistent naming** conventions
- **Compatible output** formats
- **Integrated workflow** recommendations

## Best Practices

1. **Always create backups** before cleanup operations
2. **Test essential apps** after selective cleanup
3. **Monitor devices** for 24 hours after cleanup
4. **Keep iOS updated** to latest version
5. **Use strong passcodes** and biometric authentication
6. **Review app permissions** regularly
7. **Avoid unknown app sources**
8. **Enable Find My iPhone** for device tracking

## Support and Maintenance

- **Regular updates** to script logic
- **New threat detection** patterns
- **Enhanced automation** capabilities
- **Improved reporting** features

For issues or enhancements, refer to the generated log files and reports for detailed diagnostics.
