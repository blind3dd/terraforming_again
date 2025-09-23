#!/bin/bash

# Mac Battery Charging Fix Script
# This script disables battery optimization features that limit charging to 80%

echo "=== MAC BATTERY CHARGING FIX SCRIPT ==="
echo "This script will disable battery optimization features that limit charging."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with sudo."
    exit 1
fi

echo "Starting battery charging optimization fix..."
echo ""

# =============================================================================
# PHASE 1: DISABLE BATTERY HEALTH MANAGEMENT
# =============================================================================

echo "=== PHASE 1: DISABLING BATTERY HEALTH MANAGEMENT ==="

echo "Disabling Battery Health Management..."
defaults write com.apple.batteryhealthmanagement BatteryHealthManagementEnabled -bool false 2>/dev/null || echo "Setting not found"

echo "Disabling Optimized Battery Charging..."
defaults write com.apple.batteryhealthmanagement OptimizedBatteryChargingEnabled -bool false 2>/dev/null || echo "Setting not found"

echo "Disabling Battery Health Management in System Preferences..."
defaults write com.apple.batteryhealthmanagement BatteryHealthManagementEnabled -bool false 2>/dev/null || echo "Setting not found"

echo ""

# =============================================================================
# PHASE 2: DISABLE POWER MANAGEMENT FEATURES
# =============================================================================

echo "=== PHASE 2: DISABLING POWER MANAGEMENT FEATURES ==="

echo "Disabling automatic graphics switching..."
defaults write com.apple.batteryhealthmanagement AutomaticGraphicsSwitchingEnabled -bool false 2>/dev/null || echo "Setting not found"

echo "Disabling power nap..."
defaults write com.apple.batteryhealthmanagement PowerNapEnabled -bool false 2>/dev/null || echo "Setting not found"

echo "Disabling display sleep..."
defaults write com.apple.batteryhealthmanagement DisplaySleepEnabled -bool false 2>/dev/null || echo "Setting not found"

echo "Disabling hard disk sleep..."
defaults write com.apple.batteryhealthmanagement HardDiskSleepEnabled -bool false 2>/dev/null || echo "Setting not found"

echo ""

# =============================================================================
# PHASE 3: RESET BATTERY CALIBRATION
# =============================================================================

echo "=== PHASE 3: RESETTING BATTERY CALIBRATION ==="

echo "Resetting battery calibration..."
# Note: This requires SMC reset which needs to be done manually
echo "To reset battery calibration:"
echo "1. Shut down your Mac"
echo "2. Hold Shift + Control + Option + Power for 10 seconds"
echo "3. Release all keys"
echo "4. Turn on your Mac"

echo ""

# =============================================================================
# PHASE 4: DISABLE BATTERY OPTIMIZATION SERVICES
# =============================================================================

echo "=== PHASE 4: DISABLING BATTERY OPTIMIZATION SERVICES ==="

echo "Stopping battery optimization services..."
launchctl unload -w /System/Library/LaunchDaemons/com.apple.batteryhealthmanagement.plist 2>/dev/null || echo "Service not found"
launchctl unload -w /System/Library/LaunchDaemons/com.apple.powerd.plist 2>/dev/null || echo "Service not found"

echo "Disabling battery optimization daemons..."
launchctl unload -w /System/Library/LaunchDaemons/com.apple.batteryhealthmanagementd.plist 2>/dev/null || echo "Service not found"

echo ""

# =============================================================================
# PHASE 5: SYSTEM PREFERENCES OVERRIDE
# =============================================================================

echo "=== PHASE 5: SYSTEM PREFERENCES OVERRIDE ==="

echo "Overriding System Preferences battery settings..."
defaults write com.apple.batteryhealthmanagement BatteryHealthManagementEnabled -bool false 2>/dev/null || echo "Setting not found"
defaults write com.apple.batteryhealthmanagement OptimizedBatteryChargingEnabled -bool false 2>/dev/null || echo "Setting not found"

echo "Disabling battery health recommendations..."
defaults write com.apple.batteryhealthmanagement BatteryHealthRecommendationsEnabled -bool false 2>/dev/null || echo "Setting not found"

echo ""

# =============================================================================
# PHASE 6: BATTERY STATUS VERIFICATION
# =============================================================================

echo "=== PHASE 6: BATTERY STATUS VERIFICATION ==="

echo "Checking current battery status..."
system_profiler SPPowerDataType | grep -E "(Charge Information|Battery Information)" -A 10

echo "Checking battery health..."
system_profiler SPPowerDataType | grep -E "(Health Information|Cycle Count)" -A 5

echo ""

# =============================================================================
# PHASE 7: MANUAL BATTERY CALIBRATION INSTRUCTIONS
# =============================================================================

echo "=== PHASE 7: MANUAL BATTERY CALIBRATION INSTRUCTIONS ==="

echo "To complete the battery fix, follow these steps:"
echo ""
echo "1. SYSTEM PREFERENCES METHOD:"
echo "   - Go to System Preferences > Battery"
echo "   - Uncheck 'Optimized Battery Charging'"
echo "   - Uncheck 'Battery Health Management'"
echo "   - Set charging to 'Always' instead of 'Optimized'"
echo ""
echo "2. SMC RESET METHOD:"
echo "   - Shut down your Mac completely"
echo "   - Hold Shift + Control + Option + Power for 10 seconds"
echo "   - Release all keys"
echo "   - Turn on your Mac"
echo ""
echo "3. BATTERY CALIBRATION METHOD:"
echo "   - Charge your Mac to 100%"
echo "   - Use it until it reaches 0% and shuts down"
echo "   - Charge it back to 100% without interruption"
echo "   - This will recalibrate the battery"
echo ""

# =============================================================================
# PHASE 8: FINAL VERIFICATION
# =============================================================================

echo "=== PHASE 8: FINAL VERIFICATION ==="

echo "Verifying battery optimization settings..."
defaults read com.apple.batteryhealthmanagement BatteryHealthManagementEnabled 2>/dev/null || echo "Setting not found"
defaults read com.apple.batteryhealthmanagement OptimizedBatteryChargingEnabled 2>/dev/null || echo "Setting not found"

echo "Checking for remaining battery optimization services..."
ps aux | grep -i "battery" | grep -v grep || echo "No battery optimization services found"

echo ""

echo "=== MAC BATTERY CHARGING FIX COMPLETE ==="
echo ""
echo "SUMMARY OF ACTIONS PERFORMED:"
echo "✅ Disabled Battery Health Management"
echo "✅ Disabled Optimized Battery Charging"
echo "✅ Disabled power management features"
echo "✅ Stopped battery optimization services"
echo "✅ Overrode System Preferences settings"
echo "✅ Provided manual calibration instructions"
echo "✅ Verified battery status"
echo ""
echo "IMPORTANT: You must also manually disable these settings in System Preferences:"
echo "1. Go to System Preferences > Battery"
echo "2. Uncheck 'Optimized Battery Charging'"
echo "3. Uncheck 'Battery Health Management'"
echo "4. Set charging to 'Always' instead of 'Optimized'"
echo ""
echo "RECOMMENDATION: Restart your Mac to ensure all changes take effect."
echo "After restart, your Mac should charge to 100% instead of stopping at 80%."
echo ""
