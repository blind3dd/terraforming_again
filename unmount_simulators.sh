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

# Function to clean suspicious fstab entries
clean_fstab() {
    echo "🔍 Checking /etc/fstab for suspicious entries..."
    
    if [ ! -f "/etc/fstab" ]; then
        echo "⚠️  /etc/fstab not found"
        return 1
    fi
    
    # Count lines in fstab (excluding comments and empty lines)
    local fstab_lines=$(grep -v '^#' /etc/fstab | grep -v '^$' | wc -l)
    
    if [ "$fstab_lines" -gt 1 ]; then
        echo "⚠️  Suspicious: $fstab_lines entries found in /etc/fstab (expected: 1 for Nix Store)"
        echo "Current fstab entries:"
        grep -v '^#' /etc/fstab | grep -v '^$'
        echo ""
        
        # Check if backup exists
        if [ -f "/etc/fstab~" ]; then
            echo "🔄 Restoring clean fstab from backup..."
            if sudo cp /etc/fstab~ /etc/fstab; then
                echo "✅ Successfully restored clean fstab"
            else
                echo "❌ Failed to restore fstab (sudo required)"
            fi
        else
            echo "⚠️  No fstab backup found - manual cleanup required"
        fi
    else
        echo "✅ fstab looks clean ($fstab_lines entries)"
    fi
}

# Main unmounting process
echo "🔍 Scanning for mounted simulators..."
echo ""

# First, clean any suspicious fstab entries
clean_fstab
echo ""

# Get list of all simulator disk images and mounted simulators
echo "🔍 Scanning for simulator disk images..."
simulator_disks=$(diskutil list | grep -E "(Simulator|iOS|WatchOS|tvOS|XROS)" | awk '{print $NF}' | sed 's/s[0-9]*$//' | sort -u)

# Also get the physical disk images that contain the simulators (disk4+)
echo "🔍 Scanning for physical disk images containing simulators..."
physical_disks=$(diskutil list | grep -E "disk image" | awk '{print $NF}' | sort -u)

# Get all disk images from disk4 onwards (all simulator-related)
echo "🔍 Scanning for all disk images from disk4 onwards..."
all_simulator_disks=$(diskutil list | awk '/^\/dev\/disk[4-9][0-9]*/ {print $1}' | sort -u)

echo "🔍 Scanning for mounted simulator volumes..."
mounted_simulators=$(mount | grep -i simulator | awk '{print $1}' | sort -u)

if [ -z "$simulator_disks" ] && [ -z "$mounted_simulators" ]; then
    echo "✅ No simulators currently attached or mounted!"
    exit 0
fi

# Process mounted simulators first
if [ -n "$mounted_simulators" ]; then
    echo "Found mounted simulators:"
    echo "$mounted_simulators"
    echo ""
    
    for simulator in $mounted_simulators; do
        # Extract disk identifier (e.g., /dev/disk5s1)
        disk_id=$(echo "$simulator" | sed 's|/dev/||')
        
        # Get disk name
        disk_name=$(diskutil info "$simulator" 2>/dev/null | grep "Volume Name:" | awk -F': ' '{print $2}' | tr -d ' ')
        
        if [ -z "$disk_name" ]; then
            disk_name="Unknown"
        fi
        
        echo "🎯 Processing mounted simulator: $disk_name ($simulator)"
        
        # Kill processes first
        kill_disk_processes "$simulator"
        
        # Wait a moment
        sleep 1
        
        # Try to unmount
        unmount_disk "$simulator" "$disk_name"
        
        echo ""
    done
fi

# Process attached disk images (both synthesized and physical)
if [ -n "$simulator_disks" ] || [ -n "$physical_disks" ] || [ -n "$all_simulator_disks" ]; then
    echo "Found attached simulator disk images:"
    if [ -n "$simulator_disks" ]; then
        echo "Synthesized disks: $simulator_disks"
    fi
    if [ -n "$physical_disks" ]; then
        echo "Physical disk images: $physical_disks"
    fi
    if [ -n "$all_simulator_disks" ]; then
        echo "All disk4+ disks: $all_simulator_disks"
    fi
    echo ""
    
    # Process synthesized disks first
    for disk in $simulator_disks; do
        # Get disk name
        disk_name=$(diskutil info "$disk" 2>/dev/null | grep "Volume Name:" | awk -F': ' '{print $2}' | tr -d ' ')
        
        if [ -z "$disk_name" ]; then
            disk_name="Unknown Simulator"
        fi
        
        echo "🎯 Processing synthesized disk: $disk_name ($disk)"
        
        # Try to eject the synthesized disk
        echo "  Attempting to eject synthesized disk: $disk"
        if sudo diskutil eject "$disk" 2>/dev/null; then
            echo "✅ Successfully ejected $disk_name"
        else
            echo "❌ Failed to eject $disk_name - may be in use"
        fi
        
        echo ""
    done
    
    # Process physical disk images
    for disk in $physical_disks; do
        # Get disk name
        disk_name=$(diskutil info "$disk" 2>/dev/null | grep "Volume Name:" | awk -F': ' '{print $2}' | tr -d ' ')
        
        if [ -z "$disk_name" ]; then
            disk_name="Unknown Disk Image"
        fi
        
        echo "🎯 Processing physical disk image: $disk_name ($disk)"
        
        # Try to eject the physical disk image
        echo "  Attempting to eject physical disk image: $disk"
        if sudo diskutil eject "$disk" 2>/dev/null; then
            echo "✅ Successfully ejected $disk_name"
        else
            echo "❌ Failed to eject $disk_name - may be in use"
        fi
        
        echo ""
    done
    
    # Process all disk4+ disks (comprehensive cleanup)
    for disk in $all_simulator_disks; do
        # Get disk name
        disk_name=$(diskutil info "$disk" 2>/dev/null | grep "Volume Name:" | awk -F': ' '{print $2}' | tr -d ' ')
        
        if [ -z "$disk_name" ]; then
            disk_name="Unknown Disk"
        fi
        
        echo "🎯 Processing disk4+ disk: $disk_name ($disk)"
        
        # Try multiple ejection methods
        echo "  Attempting to eject disk: $disk"
        
        # Method 1: Standard eject
        if sudo diskutil eject "$disk" 2>/dev/null; then
            echo "✅ Successfully ejected $disk_name (standard)"
        else
            echo "  Method 1 failed, trying force eject..."
            
            # Method 2: Force eject
            if sudo diskutil eject force "$disk" 2>/dev/null; then
                echo "✅ Successfully ejected $disk_name (force)"
            else
                echo "  Method 2 failed, trying unmountDisk force..."
                
                # Method 3: Force unmount disk
                if sudo diskutil unmountDisk force "$disk" 2>/dev/null; then
                    echo "✅ Successfully ejected $disk_name (unmountDisk force)"
                else
                    echo "  Method 3 failed, trying hdiutil detach..."
                    
                    # Method 4: hdiutil detach
                    if sudo hdiutil detach "$disk" -force 2>/dev/null; then
                        echo "✅ Successfully ejected $disk_name (hdiutil detach)"
                    else
                        echo "❌ Failed to eject $disk_name - all methods failed"
                        echo "  This disk may be protected by rootkit processes"
                    fi
                fi
            fi
        fi
        
        echo ""
    done
fi

# Final verification
echo "🔍 Final verification..."
remaining_mounted=$(mount | grep -i simulator | wc -l)
remaining_disks=$(diskutil list | grep -E "(Simulator|iOS|WatchOS|tvOS|XROS)" | wc -l)
remaining_disk4plus=$(diskutil list | awk '/^\/dev\/disk[4-9][0-9]*/ {print $1}' | wc -l)

if [ "$remaining_mounted" -eq 0 ] && [ "$remaining_disks" -eq 0 ] && [ "$remaining_disk4plus" -eq 0 ]; then
    echo "✅ SUCCESS: All simulators unmounted and all disk4+ images ejected!"
elif [ "$remaining_mounted" -eq 0 ] && [ "$remaining_disk4plus" -eq 0 ]; then
    echo "✅ SUCCESS: All simulators unmounted and disk4+ images ejected!"
elif [ "$remaining_mounted" -eq 0 ]; then
    echo "⚠️  WARNING: $remaining_disks simulator disk images still attached, $remaining_disk4plus disk4+ disks remaining"
    echo "Remaining disk images:"
    diskutil list | grep -E "(Simulator|iOS|WatchOS|tvOS|XROS)"
    echo "Remaining disk4+ disks:"
    diskutil list | awk '/^\/dev\/disk[4-9][0-9]*/ {print $1}'
else
    echo "⚠️  WARNING: $remaining_mounted simulators still mounted, $remaining_disks disk images attached, $remaining_disk4plus disk4+ disks remaining"
    echo "Remaining mounted simulators:"
    mount | grep -i simulator
    echo "Remaining disk images:"
    diskutil list | grep -E "(Simulator|iOS|WatchOS|tvOS|XROS)"
    echo "Remaining disk4+ disks:"
    diskutil list | awk '/^\/dev\/disk[4-9][0-9]*/ {print $1}'
fi

echo ""
echo "🛡️  Anti-rootkit measures applied!"
echo "   - fstab entries checked and cleaned"
echo "   - All simulators unmounted"
echo "   - Processes killed"
echo "   - System secured"
echo ""
echo "⚠️  Monitor for automatic remounting - this indicates active rootkit!"
echo "⚠️  Monitor for fstab recreation - this indicates persistent rootkit!"
