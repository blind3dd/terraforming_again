#!/bin/bash

# 🚨 CRASH INVESTIGATION SCRIPT
# =============================
# Investigates app crashes and system events for rootkit behavior
# Analyzes dmesg, crash logs, and system events for data leakage

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVESTIGATION_LOG="$SCRIPT_DIR/crash_investigation_$(date +%Y%m%d_%H%M%S).log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Logging function
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$INVESTIGATION_LOG"
}

# Print section header
print_section() {
    echo "" | tee -a "$INVESTIGATION_LOG"
    echo "==========================================" | tee -a "$INVESTIGATION_LOG"
    echo "$1" | tee -a "$INVESTIGATION_LOG"
    echo "==========================================" | tee -a "$INVESTIGATION_LOG"
    echo "" | tee -a "$INVESTIGATION_LOG"
}

# Function to investigate dmesg for rootkit activity
investigate_dmesg() {
    print_section "🔍 DMESG ANALYSIS - ROOTKIT BEHAVIOR"
    
    log "🔍 Analyzing kernel messages for rootkit activity..."
    
    # Check for suspicious kernel messages
    log "📋 Recent kernel messages (last 100 lines):"
    dmesg | tail -100 | tee -a "$INVESTIGATION_LOG"
    
    # Look for specific rootkit indicators
    log "🔍 Searching for rootkit indicators in dmesg..."
    
    # Check for suspicious module loading
    local suspicious_modules=$(dmesg | grep -i -E "(module|driver|kext)" | grep -v -E "(apple|system)" | tail -20)
    if [ -n "$suspicious_modules" ]; then
        log "🚨 Suspicious module activity detected:"
        echo "$suspicious_modules" | tee -a "$INVESTIGATION_LOG"
    else
        log "✅ No suspicious module activity detected"
    fi
    
    # Check for memory corruption or buffer overflows
    local memory_issues=$(dmesg | grep -i -E "(corruption|overflow|panic|oops)" | tail -10)
    if [ -n "$memory_issues" ]; then
        log "🚨 Memory issues detected:"
        echo "$memory_issues" | tee -a "$INVESTIGATION_LOG"
    else
        log "✅ No memory issues detected"
    fi
    
    # Check for network interface anomalies
    local network_issues=$(dmesg | grep -i -E "(utun|bridge|tunnel)" | tail -10)
    if [ -n "$network_issues" ]; then
        log "🚨 Network interface anomalies detected:"
        echo "$network_issues" | tee -a "$INVESTIGATION_LOG"
    else
        log "✅ No network interface anomalies detected"
    fi
    
    # Check for disk arbitration issues
    local disk_issues=$(dmesg | grep -i -E "(disk|arbitration|mount)" | tail -10)
    if [ -n "$disk_issues" ]; then
        log "🚨 Disk arbitration issues detected:"
        echo "$disk_issues" | tee -a "$INVESTIGATION_LOG"
    else
        log "✅ No disk arbitration issues detected"
    fi
}

# Function to investigate crash logs
investigate_crash_logs() {
    print_section "🔍 CRASH LOG ANALYSIS - DATA LEAKAGE"
    
    log "🔍 Analyzing crash logs for rootkit data leakage..."
    
    # Check system crash logs
    if [ -d "/Library/Logs/DiagnosticReports" ]; then
        log "📋 Recent system crash reports:"
        ls -la /Library/Logs/DiagnosticReports/ | head -20 | tee -a "$INVESTIGATION_LOG"
        
        # Look for suspicious crash patterns
        local suspicious_crashes=$(find /Library/Logs/DiagnosticReports/ -name "*.crash" -mtime -1 | head -10)
        if [ -n "$suspicious_crashes" ]; then
            log "🚨 Recent crash reports found:"
            echo "$suspicious_crashes" | tee -a "$INVESTIGATION_LOG"
            
            # Analyze each crash report
            for crash in $suspicious_crashes; do
                log "🔍 Analyzing crash report: $crash"
                
                # Look for suspicious strings in crash reports
                local suspicious_strings=$(grep -i -E "(microsoft|intune|ansible|netflow|sniffer|tunnel|bridge)" "$crash" 2>/dev/null || true)
                if [ -n "$suspicious_strings" ]; then
                    log "🚨 Suspicious strings found in $crash:"
                    echo "$suspicious_strings" | tee -a "$INVESTIGATION_LOG"
                fi
                
                # Look for memory addresses that might indicate rootkit
                local memory_addresses=$(grep -E "0x[0-9a-f]{8,}" "$crash" 2>/dev/null | head -5 || true)
                if [ -n "$memory_addresses" ]; then
                    log "🔍 Memory addresses in $crash:"
                    echo "$memory_addresses" | tee -a "$INVESTIGATION_LOG"
                fi
            done
        else
            log "✅ No recent crash reports found"
        fi
    else
        log "❌ Crash logs directory not found"
    fi
    
    # Check user crash logs
    if [ -d "$HOME/Library/Logs/DiagnosticReports" ]; then
        log "📋 Recent user crash reports:"
        ls -la "$HOME/Library/Logs/DiagnosticReports/" | head -20 | tee -a "$INVESTIGATION_LOG"
        
        # Look for suspicious user crashes
        local user_crashes=$(find "$HOME/Library/Logs/DiagnosticReports/" -name "*.crash" -mtime -1 | head -10)
        if [ -n "$user_crashes" ]; then
            log "🚨 Recent user crash reports found:"
            echo "$user_crashes" | tee -a "$INVESTIGATION_LOG"
            
            # Analyze user crash reports
            for crash in $user_crashes; do
                log "🔍 Analyzing user crash report: $crash"
                
                # Look for suspicious strings
                local suspicious_strings=$(grep -i -E "(microsoft|intune|ansible|netflow|sniffer|tunnel|bridge)" "$crash" 2>/dev/null || true)
                if [ -n "$suspicious_strings" ]; then
                    log "🚨 Suspicious strings found in $crash:"
                    echo "$suspicious_strings" | tee -a "$INVESTIGATION_LOG"
                fi
            done
        else
            log "✅ No recent user crash reports found"
        fi
    else
        log "❌ User crash logs directory not found"
    fi
}

# Function to investigate system events
investigate_system_events() {
    print_section "🔍 SYSTEM EVENTS ANALYSIS - PERSISTENCE MECHANISMS"
    
    log "🔍 Analyzing system events for rootkit persistence..."
    
    # Check system log for suspicious activity
    log "📋 Recent system log entries (last 50 lines):"
    log show --predicate 'process == "kernel"' --last 1h | tail -50 | tee -a "$INVESTIGATION_LOG"
    
    # Check for launchd anomalies
    log "🔍 Checking for launchd anomalies..."
    local launchd_issues=$(log show --predicate 'process == "launchd"' --last 1h | grep -i -E "(error|failed|denied)" | tail -10)
    if [ -n "$launchd_issues" ]; then
        log "🚨 Launchd issues detected:"
        echo "$launchd_issues" | tee -a "$INVESTIGATION_LOG"
    else
        log "✅ No launchd issues detected"
    fi
    
    # Check for disk arbitration anomalies
    log "🔍 Checking for disk arbitration anomalies..."
    local disk_arbitration_issues=$(log show --predicate 'process == "diskarbitrationd"' --last 1h | tail -20)
    if [ -n "$disk_arbitration_issues" ]; then
        log "🚨 Disk arbitration activity detected:"
        echo "$disk_arbitration_issues" | tee -a "$INVESTIGATION_LOG"
    else
        log "✅ No disk arbitration anomalies detected"
    fi
    
    # Check for CoreSimulator anomalies
    log "🔍 Checking for CoreSimulator anomalies..."
    local coresimulator_issues=$(log show --predicate 'process == "CoreSimulator"' --last 1h | tail -20)
    if [ -n "$coresimulator_issues" ]; then
        log "🚨 CoreSimulator activity detected:"
        echo "$coresimulator_issues" | tee -a "$INVESTIGATION_LOG"
    else
        log "✅ No CoreSimulator anomalies detected"
    fi
    
    # Check for network anomalies
    log "🔍 Checking for network anomalies..."
    local network_issues=$(log show --predicate 'process == "networkd"' --last 1h | grep -i -E "(error|failed|denied)" | tail -10)
    if [ -n "$network_issues" ]; then
        log "🚨 Network issues detected:"
        echo "$network_issues" | tee -a "$INVESTIGATION_LOG"
    else
        log "✅ No network anomalies detected"
    fi
}

# Function to investigate memory dumps
investigate_memory_dumps() {
    print_section "🔍 MEMORY DUMP ANALYSIS - ROOTKIT COMPONENTS"
    
    log "🔍 Analyzing memory dumps for rootkit components..."
    
    # Check for memory dumps
    local memory_dumps=$(find /var/vm -name "*.dmp" -o -name "*.dump" 2>/dev/null | head -10)
    if [ -n "$memory_dumps" ]; then
        log "🚨 Memory dumps found:"
        echo "$memory_dumps" | tee -a "$INVESTIGATION_LOG"
        
        # Analyze memory dumps for suspicious content
        for dump in $memory_dumps; do
            log "🔍 Analyzing memory dump: $dump"
            
            # Look for suspicious strings in memory dumps
            local suspicious_strings=$(strings "$dump" 2>/dev/null | grep -i -E "(microsoft|intune|ansible|netflow|sniffer|tunnel|bridge)" | head -10 || true)
            if [ -n "$suspicious_strings" ]; then
                log "🚨 Suspicious strings found in $dump:"
                echo "$suspicious_strings" | tee -a "$INVESTIGATION_LOG"
            fi
        done
    else
        log "✅ No memory dumps found"
    fi
    
    # Check for core dumps
    local core_dumps=$(find /cores -name "core.*" 2>/dev/null | head -10)
    if [ -n "$core_dumps" ]; then
        log "🚨 Core dumps found:"
        echo "$core_dumps" | tee -a "$INVESTIGATION_LOG"
        
        # Analyze core dumps
        for core in $core_dumps; do
            log "🔍 Analyzing core dump: $core"
            
            # Look for suspicious strings in core dumps
            local suspicious_strings=$(strings "$core" 2>/dev/null | grep -i -E "(microsoft|intune|ansible|netflow|sniffer|tunnel|bridge)" | head -10 || true)
            if [ -n "$suspicious_strings" ]; then
                log "🚨 Suspicious strings found in $core:"
                echo "$suspicious_strings" | tee -a "$INVESTIGATION_LOG"
            fi
        done
    else
        log "✅ No core dumps found"
    fi
}

# Function to investigate process crashes
investigate_process_crashes() {
    print_section "🔍 PROCESS CRASH ANALYSIS - ROOTKIT INTERFERENCE"
    
    log "🔍 Analyzing process crashes for rootkit interference..."
    
    # Check for processes that crashed recently
    local crashed_processes=$(ps aux | grep -E "(crashed|killed|terminated)" | grep -v grep || true)
    if [ -n "$crashed_processes" ]; then
        log "🚨 Recently crashed processes:"
        echo "$crashed_processes" | tee -a "$INVESTIGATION_LOG"
    else
        log "✅ No recently crashed processes detected"
    fi
    
    # Check for suspicious process behavior
    log "🔍 Checking for suspicious process behavior..."
    
    # Look for processes with unusual memory usage
    local high_memory_processes=$(ps aux | awk '$6 > 1000000 {print $0}' | head -10)
    if [ -n "$high_memory_processes" ]; then
        log "🚨 High memory usage processes:"
        echo "$high_memory_processes" | tee -a "$INVESTIGATION_LOG"
    else
        log "✅ No high memory usage processes detected"
    fi
    
    # Look for processes with unusual CPU usage
    local high_cpu_processes=$(ps aux | awk '$3 > 50.0 {print $0}' | head -10)
    if [ -n "$high_cpu_processes" ]; then
        log "🚨 High CPU usage processes:"
        echo "$high_cpu_processes" | tee -a "$INVESTIGATION_LOG"
    else
        log "✅ No high CPU usage processes detected"
    fi
}

# Function to investigate network anomalies
investigate_network_anomalies() {
    print_section "🔍 NETWORK ANOMALY ANALYSIS - ROOTKIT COMMUNICATION"
    
    log "🔍 Analyzing network anomalies for rootkit communication..."
    
    # Check for suspicious network connections
    local suspicious_connections=$(netstat -an | grep -E "(ESTABLISHED.*:443|ESTABLISHED.*:80|ESTABLISHED.*:8080)" | head -10)
    if [ -n "$suspicious_connections" ]; then
        log "🚨 Suspicious network connections:"
        echo "$suspicious_connections" | tee -a "$INVESTIGATION_LOG"
    else
        log "✅ No suspicious network connections detected"
    fi
    
    # Check for tunnel interfaces
    local tunnel_interfaces=$(ifconfig | grep -E "(utun|bridge)" | head -10)
    if [ -n "$tunnel_interfaces" ]; then
        log "🚨 Tunnel interfaces detected:"
        echo "$tunnel_interfaces" | tee -a "$INVESTIGATION_LOG"
    else
        log "✅ No tunnel interfaces detected"
    fi
    
    # Check for suspicious listening ports
    local suspicious_ports=$(netstat -an | grep LISTEN | grep -E ":(8021|8080|8443|9000)" | head -10)
    if [ -n "$suspicious_ports" ]; then
        log "🚨 Suspicious listening ports:"
        echo "$suspicious_ports" | tee -a "$INVESTIGATION_LOG"
    else
        log "✅ No suspicious listening ports detected"
    fi
}

# Main execution
main() {
    print_section "🚨 CRASH INVESTIGATION SCRIPT"
    log "Starting crash investigation at $TIMESTAMP"
    log "Investigating app crashes and system events for rootkit behavior"
    
    # Run all investigations
    investigate_dmesg
    investigate_crash_logs
    investigate_system_events
    investigate_memory_dumps
    investigate_process_crashes
    investigate_network_anomalies
    
    # Final summary
    print_section "🔍 INVESTIGATION SUMMARY"
    log "Crash investigation completed at $(date '+%Y-%m-%d %H:%M:%S')"
    log "Log file: $INVESTIGATION_LOG"
    
    echo "" | tee -a "$INVESTIGATION_LOG"
    echo "🛡️ CRASH INVESTIGATION COMPLETE" | tee -a "$INVESTIGATION_LOG"
    echo "================================" | tee -a "$INVESTIGATION_LOG"
    echo "" | tee -a "$INVESTIGATION_LOG"
    echo "📋 Key findings documented in log file" | tee -a "$INVESTIGATION_LOG"
    echo "⚠️  Review all findings for rootkit behavior patterns" | tee -a "$INVESTIGATION_LOG"
    echo "⚠️  Monitor for continued app crashes and system anomalies" | tee -a "$INVESTIGATION_LOG"
}

# Execute main function
main "$@"
