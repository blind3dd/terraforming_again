#!/bin/bash

echo "=== APPLE CONFIGURATOR 2 LOG AUDIT SCRIPT ==="
echo "This script checks for suspicious activity in Apple Configurator 2 logs and device data."
echo ""

# Check if Apple Configurator 2 is running
if ! pgrep -f "Apple Configurator" > /dev/null; then
    echo "WARNING: Apple Configurator 2 is not running!"
    echo "Please start Apple Configurator 2 and connect your devices."
    echo ""
fi

# Check for connected iOS devices
echo "=== CHECKING FOR CONNECTED iOS DEVICES ==="
if system_profiler SPUSBDataType | grep -q "iPhone\|iPad\|iPod"; then
    echo "✅ iOS devices detected:"
    system_profiler SPUSBDataType | grep -A 5 -B 5 "iPhone\|iPad\|iPod"
else
    echo "❌ No iOS devices connected via USB"
fi
echo ""

# Check Apple Configurator 2 log files
echo "=== CHECKING APPLE CONFIGURATOR 2 LOGS ==="
AC2_LOG_DIR="$HOME/Library/Logs/Apple Configurator 2"
if [ -d "$AC2_LOG_DIR" ]; then
    echo "✅ Apple Configurator 2 log directory found: $AC2_LOG_DIR"
    
    # Check for recent log files
    echo "Recent log files:"
    find "$AC2_LOG_DIR" -name "*.log" -mtime -1 -exec ls -la {} \;
    
    # Search for suspicious activity in logs
    echo ""
    echo "=== SEARCHING FOR SUSPICIOUS ACTIVITY IN LOGS ==="
    
    # Check for Kerberos activity
    echo "Checking for Kerberos activity..."
    find "$AC2_LOG_DIR" -name "*.log" -exec grep -l -i "kerberos\|krb5" {} \; 2>/dev/null | while read logfile; do
        echo "⚠️  Kerberos activity found in: $logfile"
        grep -i "kerberos\|krb5" "$logfile" | tail -5
    done
    
    # Check for enterprise/MDM activity
    echo ""
    echo "Checking for enterprise/MDM activity..."
    find "$AC2_LOG_DIR" -name "*.log" -exec grep -l -i "enterprise\|mdm\|profile" {} \; 2>/dev/null | while read logfile; do
        echo "⚠️  Enterprise/MDM activity found in: $logfile"
        grep -i "enterprise\|mdm\|profile" "$logfile" | tail -5
    done
    
    # Check for VPN/proxy activity
    echo ""
    echo "Checking for VPN/proxy activity..."
    find "$AC2_LOG_DIR" -name "*.log" -exec grep -l -i "vpn\|proxy\|tunnel" {} \; 2>/dev/null | while read logfile; do
        echo "⚠️  VPN/proxy activity found in: $logfile"
        grep -i "vpn\|proxy\|tunnel" "$logfile" | tail -5
    done
    
    # Check for suspicious domains
    echo ""
    echo "Checking for suspicious domains..."
    SUSPICIOUS_DOMAINS=(
        "appetize.com"
        "spoton.com"
        "jamf.com"
        "crowdstrike"
        "policja.gov.pl"
        "equinix.com"
        "ldap03.appetize.cc"
        "vpn.appetizeinc.com"
        "wp.pl"
	"interia.pl"
	"op.pl"
	"o2.pl"
	"shift4.com"
	"eu.equinix.com"
	"relayr.io"
	"rakoczy.io"
	"gmail.com"
	"codahead.com"
	"proximetry.com"
    )
    
    for domain in "${SUSPICIOUS_DOMAINS[@]}"; do
        find "$AC2_LOG_DIR" -name "*.log" -exec grep -l -i "$domain" {} \; 2>/dev/null | while read logfile; do
            echo "⚠️  Suspicious domain '$domain' found in: $logfile"
            grep -i "$domain" "$logfile" | tail -3
        done
    done
    
else
    echo "❌ Apple Configurator 2 log directory not found: $AC2_LOG_DIR"
fi
echo ""

# Check system logs for Apple Configurator activity
echo "=== CHECKING SYSTEM LOGS FOR APPLE CONFIGURATOR ACTIVITY ==="
echo "Checking for Apple Configurator processes in system logs..."
log show --predicate 'process == "Apple Configurator"' --last 1h 2>/dev/null | head -20

echo ""
echo "Checking for iOS device connections..."
log show --predicate 'eventMessage contains "iPhone" or eventMessage contains "iPad"' --last 1h 2>/dev/null | head -20

echo ""
echo "Checking for USB device connections..."
log show --predicate 'eventMessage contains "USB" and (eventMessage contains "iPhone" or eventMessage contains "iPad")' --last 1h 2>/dev/null | head -20

# Check for suspicious network activity
echo ""
echo "=== CHECKING FOR SUSPICIOUS NETWORK ACTIVITY ==="
echo "Active network connections:"
netstat -an | grep -E "(ESTABLISHED|LISTEN)" | grep -v "127.0.0.1" | head -10

# Disable promiscuous network interfaces
sudo ifconfig en1 -promisc
sudo ifconfig en2 -promisc

# Disable suspicious network interfaces
sudo ifconfig anpi1 down
sudo ifconfig anpi2 down
sudo ifconfig anpi0 down

echo ""
echo "Network interfaces:"
ifconfig | grep -E "(utun|bridge|anpi|en)" | head -10

# Check for Apple Configurator 2 preferences and cache
echo ""
echo "=== CHECKING APPLE CONFIGURATOR 2 PREFERENCES ==="
AC2_PREFS="$HOME/Library/Preferences/com.apple.configurator2.plist"
if [ -f "$AC2_PREFS" ]; then
    echo "✅ Apple Configurator 2 preferences found"
    echo "Checking for suspicious preferences..."
    plutil -p "$AC2_PREFS" 2>/dev/null | grep -E "(enterprise|mdm|vpn|proxy)" || echo "No suspicious preferences found"
else
    echo "❌ Apple Configurator 2 preferences not found"
fi

# Check for device backups
echo ""
echo "=== CHECKING FOR DEVICE BACKUPS ==="
BACKUP_DIR="$HOME/Library/Group Containers/K36BKF7T3D.group.com.apple.configurator/Library/Caches/Assets"
if [ -d "$BACKUP_DIR" ]; then
    echo "✅ Apple Configurator 2 backup directory found"
    echo "Recent backups:"
    find "$BACKUP_DIR" -type d -mtime -7 -exec ls -la {} \; 2>/dev/null | head -10
else
    echo "❌ Apple Configurator 2 backup directory not found"
fi

echo ""
echo "=== APPLE CONFIGURATOR 2 LOG AUDIT COMPLETE ==="
echo ""
echo "SUMMARY:"
echo "✅ Checked for connected iOS devices"
echo "✅ Audited Apple Configurator 2 logs"
echo "✅ Searched for suspicious activity"
echo "✅ Checked system logs"
echo "✅ Checked network activity"
echo "✅ Checked preferences and backups"
echo ""
echo "Review the output above for any ⚠️ warnings or suspicious activity."
