#!/bin/bash

# Complete Xcode Removal Script
# This script removes all Xcode installations, command line tools, and related files

set -e

echo "🚀 Starting complete Xcode removal process..."
echo "⚠️  WARNING: This will remove ALL Xcode installations and related files!"
echo "📋 This includes:"
echo "   - Xcode.app (if present)"
echo "   - Command Line Tools"
echo "   - Simulators and device support"
echo "   - Derived data and caches"
echo "   - All Xcode preferences and settings"
echo ""

# Function to safely remove directory
safe_remove() {
    local path="$1"
    if [ -e "$path" ]; then
        echo "🗑️  Removing: $path"
        sudo rm -rf "$path"
    else
        echo "ℹ️  Not found: $path"
    fi
}

# Function to safely remove user directory
safe_remove_user() {
    local path="$1"
    if [ -e "$path" ]; then
        echo "🗑️  Removing: $path"
        rm -rf "$path"
    else
        echo "ℹ️  Not found: $path"
    fi
}

echo "🔍 Checking for Xcode installations..."

# Check if Xcode.app exists
if [ -d "/Applications/Xcode.app" ]; then
    echo "📱 Found Xcode.app in Applications"
    echo "⚠️  You may need to quit Xcode if it's running"
    read -p "Continue with removal? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted by user"
        exit 1
    fi
fi

echo ""
echo "🧹 Phase 1: Removing Xcode.app and related applications"
safe_remove "/Applications/Xcode.app"
safe_remove "/Applications/Xcode-beta.app"
safe_remove "/Applications/Xcode.app.zip"

echo ""
echo "🧹 Phase 2: Removing Command Line Tools"
# Uninstall command line tools
if [ -d "/Library/Developer/CommandLineTools" ]; then
    echo "🔧 Removing Command Line Tools..."
    sudo rm -rf "/Library/Developer/CommandLineTools"
fi

# Remove command line tools installer
safe_remove "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"

echo ""
echo "🧹 Phase 3: Removing user Library files"
safe_remove_user "$HOME/Library/Developer"
safe_remove_user "$HOME/Library/Application Support/Xcode"
safe_remove_user "$HOME/Library/Caches/com.apple.dt.Xcode"
safe_remove_user "$HOME/Library/Caches/com.apple.python/Applications/Xcode.app"
safe_remove_user "$HOME/Library/HTTPStorages/com.apple.dt.Xcode"
safe_remove_user "$HOME/Library/Preferences/com.apple.dt.Xcode.plist"
safe_remove_user "$HOME/Library/Preferences/com.apple.dt.Xcode.LSSharedFileList.plist"
safe_remove_user "$HOME/Library/Saved Application State/com.apple.dt.Xcode.savedState"
safe_remove_user "$HOME/Library/WebKit/com.apple.dt.Xcode"

echo ""
echo "🧹 Phase 4: Removing system-wide Developer files"
safe_remove "/Library/Developer"
safe_remove "/System/Library/Developer"

echo ""
echo "🧹 Phase 5: Removing derived data and build artifacts"
safe_remove_user "$HOME/Library/Developer/Xcode/DerivedData"
safe_remove_user "$HOME/Library/Developer/Xcode/Archives"
safe_remove_user "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
safe_remove_user "$HOME/Library/Developer/Xcode/watchOS DeviceSupport"
safe_remove_user "$HOME/Library/Developer/Xcode/tvOS DeviceSupport"

echo ""
echo "🧹 Phase 6: Removing simulators and device support"
safe_remove_user "$HOME/Library/Developer/CoreSimulator"
safe_remove_user "$HOME/Library/Developer/XCTestDevices"
safe_remove_user "$HOME/Library/Developer/Xcode/UserData"

echo ""
echo "🧹 Phase 7: Removing additional Xcode-related files"
# Remove any remaining Xcode-related files in user directories
find "$HOME/Library" -name "*Xcode*" -type d 2>/dev/null | while read -r dir; do
    safe_remove_user "$dir"
done

find "$HOME/Library" -name "*xcode*" -type d 2>/dev/null | while read -r dir; do
    safe_remove_user "$dir"
done

# Remove Xcode-related files
find "$HOME/Library" -name "*Xcode*" -type f 2>/dev/null | while read -r file; do
    safe_remove_user "$file"
done

echo ""
echo "🧹 Phase 8: Cleaning up system caches"
safe_remove "/System/Library/Caches/com.apple.dt.Xcode"
safe_remove "/Library/Caches/com.apple.dt.Xcode"

echo ""
echo "🧹 Phase 9: Removing Xcode command line tools references"
# Reset xcode-select path
if command -v xcode-select >/dev/null 2>&1; then
    echo "🔧 Resetting xcode-select path..."
    sudo xcode-select --reset 2>/dev/null || true
fi

echo ""
echo "🧹 Phase 10: Final cleanup"
# Remove any remaining Xcode-related processes
echo "🔄 Checking for running Xcode processes..."
if pgrep -f "Xcode" >/dev/null; then
    echo "⚠️  Found running Xcode processes. Attempting to quit..."
    pkill -f "Xcode" 2>/dev/null || true
    sleep 2
fi

# Clean up any remaining temporary files
safe_remove "/tmp/com.apple.dt.Xcode*"
safe_remove "/tmp/.Xcode*"

echo ""
echo "✅ Xcode removal completed!"
echo ""
echo "📋 Summary of what was removed:"
echo "   ✓ Xcode.app and related applications"
echo "   ✓ Command Line Tools"
echo "   ✓ All simulators and device support"
echo "   ✓ Derived data and build artifacts"
echo "   ✓ User preferences and settings"
echo "   ✓ System caches and temporary files"
echo ""
echo "🔄 Recommended next steps:"
echo "   1. Restart your Mac to ensure all processes are cleaned up"
echo "   2. If you need development tools later, you can reinstall from:"
echo "      - App Store (for Xcode.app)"
echo "      - xcode-select --install (for Command Line Tools only)"
echo ""
echo "🎉 Xcode has been completely removed from your system!"

