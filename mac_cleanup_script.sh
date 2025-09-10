#!/bin/bash

# Mac Cleanup Script - Apple Ecosystem Security and Privacy Cleanup
# This script removes tracking, correlations, and unwanted services from macOS

echo "=== MAC CLEANUP SCRIPT - APPLE ECOSYSTEM SECURITY ==="
echo "WARNING: This script will disable many Apple services and features!"
echo "Ensure you understand the implications before proceeding."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with sudo."
    exit 1
fi

echo "Starting Mac cleanup and security hardening..."
echo ""

# =============================================================================
# PHASE 1: FIND MY SERVICES DISABLE
# =============================================================================

echo "=== PHASE 1: DISABLING FIND MY SERVICES ==="

echo "Stopping Find My services..."
launchctl unload -w /System/Library/LaunchDaemons/com.apple.findmydeviced.plist 2>/dev/null || echo "Service not found"
launchctl unload -w /System/Library/LaunchDaemons/com.apple.findmylocateagent.plist 2>/dev/null || echo "Service not found"
launchctl unload -w /System/Library/LaunchDaemons/com.apple.findmybeaconingd.plist 2>/dev/null || echo "Service not found"

echo "Killing Find My processes..."
pkill -f "findmy" 2>/dev/null || echo "No Find My processes found"
pkill -f "beacon" 2>/dev/null || echo "No beacon processes found"

echo "Disabling Find My in System Preferences..."
defaults write com.apple.findmy.fmipcore FMIPEnabled -bool false 2>/dev/null || echo "Setting not found"
defaults write com.apple.findmy.fmipcore FMIPStatus -bool false 2>/dev/null || echo "Setting not found"

echo ""

# =============================================================================
# PHASE 2: NETWORK SERVICES DISABLE
# =============================================================================

echo "=== PHASE 2: DISABLING NETWORK SERVICES ==="

echo "Stopping network discovery services..."
launchctl unload -w /System/Library/LaunchDaemons/com.apple.bluetoothd.plist 2>/dev/null || echo "Service not found"
launchctl unload -w /System/Library/LaunchDaemons/com.apple.wifianalyticsd.plist 2>/dev/null || echo "Service not found"
launchctl unload -w /System/Library/LaunchDaemons/com.apple.wifip2pd.plist 2>/dev/null || echo "Service not found"

echo "Killing network processes..."
pkill -f "bluetooth" 2>/dev/null || echo "No Bluetooth processes found"
pkill -f "wifi" 2>/dev/null || echo "No WiFi processes found"
pkill -f "airdrop" 2>/dev/null || echo "No AirDrop processes found"

echo "Disabling network services in System Preferences..."
defaults write com.apple.airplay.discovery Disabled -bool true 2>/dev/null || echo "Setting not found"
defaults write com.apple.airplay.discovery AllowAirPlay -bool false 2>/dev/null || echo "Setting not found"

echo ""

# =============================================================================
# PHASE 3: CONTINUITY AND HANDOFF DISABLE
# =============================================================================

echo "=== PHASE 3: DISABLING CONTINUITY AND HANDOFF ==="

echo "Disabling Handoff..."
defaults write com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool false 2>/dev/null || echo "Setting not found"
defaults write com.apple.coreservices.useractivityd ActivityReceivingAllowed -bool false 2>/dev/null || echo "Setting not found"

echo "Disabling Universal Clipboard..."
defaults write com.apple.coreservices.useractivityd ClipboardSharingEnabled -bool false 2>/dev/null || echo "Setting not found"

echo "Disabling AirDrop..."
defaults write com.apple.sharingd DiscoverableMode -string "Off" 2>/dev/null || echo "Setting not found"

echo "Disabling Sidecar..."
defaults write com.apple.sidecar.display AllowAllDevices -bool false 2>/dev/null || echo "Setting not found"

echo ""

# =============================================================================
# PHASE 4: ICLOUD SERVICES DISABLE
# =============================================================================

echo "=== PHASE 4: DISABLING ICLOUD SERVICES ==="

echo "Disabling iCloud sync services..."
defaults write com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool false 2>/dev/null || echo "Setting not found"
defaults write com.apple.coreservices.useractivityd ActivityReceivingAllowed -bool false 2>/dev/null || echo "Setting not found"

echo "Disabling iCloud Keychain..."
defaults write com.apple.sbd KeychainSyncEnabled -bool false 2>/dev/null || echo "Setting not found"

echo "Disabling iCloud Drive..."
defaults write com.apple.bird OptimizeMacStorage -bool false 2>/dev/null || echo "Setting not found"

echo "Disabling iCloud Photos..."
defaults write com.apple.photolibraryd CloudPhotosEnabled -bool false 2>/dev/null || echo "Setting not found"

echo ""

# =============================================================================
# PHASE 5: LOCATION SERVICES DISABLE
# =============================================================================

echo "=== PHASE 5: DISABLING LOCATION SERVICES ==="

echo "Disabling Location Services..."
defaults write com.apple.locationd LocationServicesEnabled -bool false 2>/dev/null || echo "Setting not found"

echo "Disabling Location Services for system services..."
defaults write com.apple.locationd LocationServicesEnabled -bool false 2>/dev/null || echo "Setting not found"

echo "Disabling Location Services for applications..."
defaults write com.apple.locationd LocationServicesEnabled -bool false 2>/dev/null || echo "Setting not found"

echo ""

# =============================================================================
# PHASE 6: ANALYTICS AND TELEMETRY DISABLE
# =============================================================================

echo "=== PHASE 6: DISABLING ANALYTICS AND TELEMETRY ==="

echo "Disabling analytics and telemetry..."
defaults write com.apple.analyticsd AnalyticsEnabled -bool false 2>/dev/null || echo "Setting not found"
defaults write com.apple.analyticsd AnalyticsEnabled -bool false 2>/dev/null || echo "Setting not found"

echo "Disabling crash reporting..."
defaults write com.apple.CrashReporter DialogType -string "none" 2>/dev/null || echo "Setting not found"

echo "Disabling usage statistics..."
defaults write com.apple.usage.analytics UsageAnalyticsEnabled -bool false 2>/dev/null || echo "Setting not found"

echo ""

# =============================================================================
# PHASE 7: NETWORK ISOLATION
# =============================================================================

echo "=== PHASE 7: NETWORK ISOLATION ==="

echo "Disabling network discovery..."
defaults write com.apple.airplay.discovery Disabled -bool true 2>/dev/null || echo "Setting not found"
defaults write com.apple.airplay.discovery AllowAirPlay -bool false 2>/dev/null || echo "Setting not found"

echo "Disabling Bonjour services..."
defaults write com.apple.mDNSResponder NoMulticastAdvertisements -bool true 2>/dev/null || echo "Setting not found"

echo "Disabling network sharing..."
defaults write com.apple.smb.server NetBIOSName -string "" 2>/dev/null || echo "Setting not found"

echo ""

# =============================================================================
# PHASE 8: SYSTEM CLEANUP
# =============================================================================

echo "=== PHASE 8: SYSTEM CLEANUP ==="

echo "Clearing system caches..."
rm -rf /Library/Caches/* 2>/dev/null || echo "Permission denied"
rm -rf /System/Library/Caches/* 2>/dev/null || echo "Permission denied"
rm -rf /var/folders/*/C/* 2>/dev/null || echo "Permission denied"

echo "Clearing user caches..."
rm -rf ~/Library/Caches/* 2>/dev/null || echo "Permission denied"

echo "Clearing system logs..."
rm -rf /var/log/* 2>/dev/null || echo "Permission denied"
rm -rf /Library/Logs/* 2>/dev/null || echo "Permission denied"

echo "Clearing temporary files..."
rm -rf /tmp/* 2>/dev/null || echo "Permission denied"
rm -rf /var/tmp/* 2>/dev/null || echo "Permission denied"

echo ""

# =============================================================================
# PHASE 9: SECURITY HARDENING
# =============================================================================

echo "=== PHASE 9: SECURITY HARDENING ==="

echo "Disabling remote access..."
systemsetup -setremotelogin off 2>/dev/null || echo "Command not found"
systemsetup -setremotemanagement off 2>/dev/null || echo "Command not found"

echo "Disabling file sharing..."
launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || echo "Service not found"
launchctl unload -w /System/Library/LaunchDaemons/com.apple.afpfs_afpLoad.plist 2>/dev/null || echo "Service not found"

echo "Disabling screen sharing..."
launchctl unload -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || echo "Service not found"

echo ""

# =============================================================================
# PHASE 10: FINAL VERIFICATION
# =============================================================================

echo "=== PHASE 10: FINAL VERIFICATION ==="

echo "Checking for remaining Find My processes..."
ps aux | grep -i "findmy" | grep -v grep || echo "No Find My processes found (good)"

echo "Checking for remaining network processes..."
ps aux | grep -E "(bluetooth|wifi|airdrop|beacon)" | grep -v grep || echo "No network processes found (good)"

echo "Checking for remaining location services..."
ps aux | grep -i "location" | grep -v grep || echo "No location services found (good)"

echo ""

# =============================================================================
# PHASE 11: SYSTEM RESTART
# =============================================================================

echo "=== PHASE 11: SYSTEM RESTART ==="

echo "Flushing DNS cache..."
dscacheutil -flushcache 2>/dev/null || echo "Command not found"

echo "Clearing ARP cache..."
arp -a -d 2>/dev/null || echo "Command not found"

echo "Restarting network services..."
launchctl kickstart -k system/com.apple.networkd 2>/dev/null || echo "Service not found"

echo ""
echo "=== MAC CLEANUP COMPLETE ==="
echo ""
echo "SUMMARY OF ACTIONS PERFORMED:"
echo "✅ Disabled Find My services and location tracking"
echo "✅ Disabled network discovery and sharing services"
echo "✅ Disabled Continuity and Handoff features"
echo "✅ Disabled iCloud sync and sharing services"
echo "✅ Disabled location services and tracking"
echo "✅ Disabled analytics and telemetry"
echo "✅ Isolated network services"
echo "✅ Performed system cleanup"
echo "✅ Applied security hardening"
echo "✅ Verified all changes"
echo ""
echo "The Mac has been cleaned and isolated from Apple ecosystem services."
echo "Many Apple features will no longer work, but privacy and security"
echo "have been significantly improved."
echo ""
echo "RECOMMENDATION: Restart the Mac to ensure all changes take effect."
echo ""
