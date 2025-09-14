#!/bin/bash

# Post-NVRAM Reset Security Script
# Run this after NVRAM reset to secure the system

echo "🛡️  POST-NVRAM RESET SECURITY SCRIPT"
echo "===================================="
echo ""

# Check if we're in a clean state
echo "🔍 Checking system state after NVRAM reset..."

# Check for rootkit processes
echo "Checking for rootkit processes..."
rootkit_processes=$(ps aux | grep -E "(diskarbitrationd|diskimagesiod|simdiskimaged)" | grep -v grep)

if [ -n "$rootkit_processes" ]; then
    echo "❌ ROOTKIT PROCESSES STILL ACTIVE:"
    echo "$rootkit_processes"
    echo ""
    echo "🚨 NVRAM reset failed to remove rootkit!"
    echo "   This indicates firmware-level compromise."
else
    echo "✅ No rootkit processes detected!"
fi

# Check for mounted simulators
echo ""
echo "Checking for mounted simulators..."
simulators=$(mount | grep -i simulator | wc -l)

if [ "$simulators" -gt 0 ]; then
    echo "⚠️  $simulators simulators still mounted"
    echo "Running unmount script..."
    ./unmount_simulators.sh
else
    echo "✅ No simulators mounted!"
fi

# Check for malicious files
echo ""
echo "Checking for malicious Ansible modules..."
malicious_files=$(find ~/Library/Python/3.9/lib/python/site-packages/ -name "*meraki*" -o -name "*cisco*" -o -name "*fortinet*" -o -name "*netflow*" -o -name "*sniffer*" 2>/dev/null)

if [ -n "$malicious_files" ]; then
    echo "❌ Malicious files still present:"
    echo "$malicious_files"
    echo ""
    echo "Removing malicious files..."
    rm -rf ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/cisco/
    rm -rf ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/fortinet/
    rm -rf ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/inspur/
    echo "✅ Malicious files removed!"
else
    echo "✅ No malicious files detected!"
fi

# Check tunnel interfaces
echo ""
echo "Checking tunnel interfaces..."
tunnels=$(ifconfig | grep -E "utun[0-9]" | wc -l)

if [ "$tunnels" -gt 0 ]; then
    echo "⚠️  $tunnels tunnel interfaces detected"
    echo "Disabling tunnel interfaces..."
    for i in {0..9}; do
        sudo ifconfig "utun$i" down 2>/dev/null
    done
    echo "✅ Tunnel interfaces disabled!"
else
    echo "✅ No tunnel interfaces detected!"
fi

# Final security check
echo ""
echo "🔍 Final security assessment..."

# Check for suspicious ports
suspicious_ports=$(netstat -an | grep -E ":8021|:22|:21|:69" | grep LISTEN | wc -l)

if [ "$suspicious_ports" -gt 0 ]; then
    echo "⚠️  $suspicious_ports suspicious ports listening"
    echo "Ports:"
    netstat -an | grep -E ":8021|:22|:21|:69" | grep LISTEN
else
    echo "✅ No suspicious ports detected!"
fi

echo ""
echo "🛡️  SECURITY ASSESSMENT COMPLETE"
echo "================================"

# Overall status
if [ -z "$rootkit_processes" ] && [ "$simulators" -eq 0 ] && [ -z "$malicious_files" ] && [ "$tunnels" -eq 0 ]; then
    echo "✅ SYSTEM APPEARS CLEAN!"
    echo "   - No rootkit processes"
    echo "   - No mounted simulators"
    echo "   - No malicious files"
    echo "   - No tunnel interfaces"
    echo ""
    echo "🎉 NVRAM reset successful - rootkit appears to be removed!"
else
    echo "⚠️  SYSTEM STILL COMPROMISED!"
    echo "   - Rootkit may have firmware-level persistence"
    echo "   - Consider professional forensic assistance"
    echo "   - May require hardware replacement"
fi

echo ""
echo "📋 Next steps:"
echo "   1. Monitor system for 24 hours"
echo "   2. Check for automatic remounting"
echo "   3. Install security tools"
echo "   4. Document all findings"
echo ""
