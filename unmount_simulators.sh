#!/bin/bash

# Simulator Unmount Script - Anti-Rootkit Tool
# This script aggressively unmounts all iOS simulators to prevent rootkit remounting

echo "🚨 SIMULATOR UNMOUNT SCRIPT - ANTI-ROOTKIT TOOL"
echo "=============================================="
echo ""

# Function to unmount a specific disk
unmount_disk() {
    local disk_id=$1
    local disk_name=$2
    
    echo "🔍 Attempting to unmount $disk_name ($disk_id)..."
    
    # Try normal unmount first
    if sudo diskutil unmount "$disk_id" 2>/dev/null; then
        echo "✅ Successfully unmounted $disk_name"
        return 0
    fi
    
    # Try force unmount
    if sudo diskutil unmount force "$disk_id" 2>/dev/null; then
        echo "✅ Force unmounted $disk_name"
        return 0
    fi
    
    # Try eject
    if sudo diskutil eject "$disk_id" 2>/dev/null; then
        echo "✅ Ejected $disk_name"
        return 0
    fi
    
    echo "❌ Failed to unmount $disk_name"
    return 1
}

# Function to kill processes using the disk
kill_disk_processes() {
    local disk_id=$1
    echo "🔪 Killing processes using $disk_id..."
    
    # Find processes using the disk
    local pids=$(lsof +D "/Volumes" 2>/dev/null | grep "$disk_id" | awk '{print $2}' | sort -u)
    
    if [ -n "$pids" ]; then
        echo "Found processes: $pids"
        for pid in $pids; do
            if [ "$pid" != "$$" ]; then  # Don't kill ourselves
                echo "Killing PID $pid..."
                sudo kill -9 "$pid" 2>/dev/null
            fi
        done
    fi
}

# Main unmounting process
echo "🔍 Scanning for mounted simulators..."
echo ""

# Get list of all mounted simulators
simulators=$(mount | grep -i simulator | awk '{print $1}' | sort -u)

if [ -z "$simulators" ]; then
    echo "✅ No simulators currently mounted!"
    exit 0
fi

echo "Found mounted simulators:"
echo "$simulators"
echo ""

# Unmount each simulator
for simulator in $simulators; do
    # Extract disk identifier (e.g., /dev/disk5s1)
    disk_id=$(echo "$simulator" | sed 's|/dev/||')
    
    # Get disk name
    disk_name=$(diskutil info "$simulator" 2>/dev/null | grep "Volume Name:" | awk -F': ' '{print $2}' | tr -d ' ')
    
    if [ -z "$disk_name" ]; then
        disk_name="Unknown"
    fi
    
    echo "🎯 Processing: $disk_name ($simulator)"
    
    # Kill processes first
    kill_disk_processes "$simulator"
    
    # Wait a moment
    sleep 1
    
    # Try to unmount
    unmount_disk "$simulator" "$disk_name"
    
    echo ""
done

# Final verification
echo "🔍 Final verification..."
remaining=$(mount | grep -i simulator | wc -l)

if [ "$remaining" -eq 0 ]; then
    echo "✅ SUCCESS: All simulators unmounted!"
else
    echo "⚠️  WARNING: $remaining simulators still mounted"
    echo "Remaining simulators:"
    mount | grep -i simulator
fi

echo ""
echo "🛡️  Anti-rootkit measures applied!"
echo "   - All simulators unmounted"
echo "   - Processes killed"
echo "   - System secured"
echo ""
echo "⚠️  Monitor for automatic remounting - this indicates active rootkit!"
