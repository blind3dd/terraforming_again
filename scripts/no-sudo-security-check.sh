#!/bin/bash

echo "🔍 NO-SUDO SECURITY CHECK FOR CLEAN ACCOUNT"
echo "==========================================="
echo
echo "Current user: $(whoami)"
echo "Account type: $(groups)"
echo

echo "🔍 CHECKING FOR MALWARE INDICATORS (NO SUDO REQUIRED)..."
echo

# Check for utun interfaces (no sudo needed)
echo "UTUN interfaces:"
ifconfig | grep -c utun
echo "found"

# Check for suspicious processes
echo "Suspicious processes:"
ps aux | grep -E "(box|cursor|vpn|tunnel|malware)" | grep -v grep | head -5

# Check network connections
echo "Active network connections:"
netstat -an | grep ESTABLISHED | wc -l
echo "connections found"

# Check for suspicious files in user directory
echo "Suspicious files in home directory:"
find ~ -name "*box*" -o -name "*vpn*" -o -name "*tunnel*" 2>/dev/null | head -5

# Check launch agents (user-level, no sudo needed)
echo "User launch agents:"
ls -la ~/Library/LaunchAgents/ 2>/dev/null | grep -E "(box|vpn|tunnel)" || echo "No suspicious launch agents found"

# Check browser extensions
echo "Browser extensions (if any):"
ls -la ~/Library/Application\ Support/ 2>/dev/null | grep -E "(box|cursor|vpn)" | head -3

echo
echo "✅ RECOMMENDATIONS:"
echo "1. If this account shows clean results, it's safe to use"
echo "2. You can work from here and switch to compromised account only for cleanup"
echo "3. Consider this your 'command center' for security operations"
echo "4. Use this account to plan and coordinate cleanup of the other account"
