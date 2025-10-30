#!/bin/bash

# Security Analysis Script for /dev/null Redirections
# This script helps identify potentially malicious redirections to /dev/null

echo "=== /dev/null Security Analysis ==="
echo "Timestamp: $(date)"
echo

# Count total /dev/null redirections
TOTAL_DEVNULL=$(lsof | grep "/dev/null" | wc -l)
echo "Total /dev/null redirections: $TOTAL_DEVNULL"
echo

# 1. Check for suspicious executable types
echo "=== SUSPICIOUS: Scripting/Programming Languages ==="
SUSPICIOUS_PROCS=$(lsof | grep "/dev/null" | grep -E "(bash|sh|zsh|python|perl|ruby|node|java|php|go|rust)" | awk '{print $1, $2, $3}' | sort | uniq)
if [ -n "$SUSPICIOUS_PROCS" ]; then
    echo "$SUSPICIOUS_PROCS"
    echo "⚠️  WARNING: Found scripting/programming processes with /dev/null redirections"
else
    echo "✅ No suspicious scripting processes found"
fi
echo

# 2. Check for network tools
echo "=== SUSPICIOUS: Network Tools ==="
NETWORK_TOOLS=$(lsof | grep "/dev/null" | grep -E "(curl|wget|nc|netcat|socat|ncat|ssh|scp|rsync|telnet|ftp)" | awk '{print $1, $2, $3}' | sort | uniq)
if [ -n "$NETWORK_TOOLS" ]; then
    echo "$NETWORK_TOOLS"
    echo "⚠️  WARNING: Found network tools with /dev/null redirections"
else
    echo "✅ No suspicious network tools found"
fi
echo

# 3. Check for processes with unusual names or patterns
echo "=== SUSPICIOUS: Unusual Process Names ==="
UNUSUAL_NAMES=$(lsof | grep "/dev/null" | awk '{print $1}' | grep -E "(^[a-z]{1,3}$|^[0-9]+$|^[a-z]+[0-9]+$|^[0-9]+[a-z]+$)" | sort | uniq)
if [ -n "$UNUSUAL_NAMES" ]; then
    echo "$UNUSUAL_NAMES"
    echo "⚠️  WARNING: Found processes with unusual naming patterns"
else
    echo "✅ No unusual process names found"
fi
echo

# 4. Check for processes with all three file descriptors redirected
echo "=== SUSPICIOUS: All FDs Redirected (stdin, stdout, stderr) ==="
ALL_FDS_REDIRECTED=$(lsof | grep "/dev/null" | awk '{print $1, $2}' | sort | uniq -c | awk '$1 == 3 {print $2, $3}' | sort | uniq)
if [ -n "$ALL_FDS_REDIRECTED" ]; then
    echo "$ALL_FDS_REDIRECTED"
    echo "⚠️  WARNING: Found processes with all file descriptors redirected to /dev/null"
else
    echo "✅ No processes with all FDs redirected found"
fi
echo

# 5. Check for processes with network connections AND /dev/null redirections
echo "=== SUSPICIOUS: Network Activity + /dev/null Redirections ==="
NETWORK_DEVNULL=$(comm -12 <(lsof -i | awk '{print $1, $2}' | sort | uniq) <(lsof | grep "/dev/null" | awk '{print $1, $2}' | sort | uniq))
if [ -n "$NETWORK_DEVNULL" ]; then
    echo "$NETWORK_DEVNULL"
    echo "⚠️  WARNING: Found processes with both network activity and /dev/null redirections"
else
    echo "✅ No suspicious network + /dev/null combinations found"
fi
echo

# 6. Check for processes running as different users (potential privilege escalation)
echo "=== SUSPICIOUS: Non-root processes with /dev/null redirections ==="
NON_ROOT_DEVNULL=$(lsof | grep "/dev/null" | awk '$3 != "root" {print $1, $2, $3}' | sort | uniq)
if [ -n "$NON_ROOT_DEVNULL" ]; then
    echo "Found $(echo "$NON_ROOT_DEVNULL" | wc -l) non-root processes with /dev/null redirections"
    echo "Top 10:"
    echo "$NON_ROOT_DEVNULL" | head -10
else
    echo "✅ No non-root processes with /dev/null redirections found"
fi
echo

# 7. Check for processes with high file descriptor counts
echo "=== SUSPICIOUS: High FD Count + /dev/null ==="
HIGH_FD_PROCESSES=$(lsof | grep "/dev/null" | awk '{print $1, $2}' | sort | uniq -c | sort -nr | head -5)
echo "Processes with most /dev/null redirections:"
echo "$HIGH_FD_PROCESSES"
echo

# 8. Summary and recommendations
echo "=== SECURITY RECOMMENDATIONS ==="
echo "1. Monitor processes that redirect ALL file descriptors to /dev/null"
echo "2. Investigate any scripting languages with /dev/null redirections"
echo "3. Check network tools that redirect output to /dev/null"
echo "4. Look for processes with unusual names or patterns"
echo "5. Consider using 'ps aux' to cross-reference process details"
echo "6. Use 'netstat -tulpn' to check for hidden network connections"
echo

echo "=== NEXT STEPS ==="
echo "If you found suspicious processes:"
echo "1. Run: ps aux | grep <PID>"
echo "2. Run: lsof -p <PID>"
echo "3. Run: netstat -tulpn | grep <PID>"
echo "4. Check process command line: ps -p <PID> -o pid,ppid,cmd"
echo "5. Consider terminating suspicious processes: kill -9 <PID>"
