#!/bin/bash

# Static Tundra/FSB-linked Rootkit Detection & Removal Toolkit
# Comprehensive security tool based on real-world investigation
# Can be used on any macOS system to detect similar attacks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="rootkit_audit_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    echo "=========================================="
    print_status $CYAN "🔍 $1"
    echo "=========================================="
    echo ""
}

print_critical() {
    print_status $RED "🚨 CRITICAL: $1"
}

print_success() {
    print_status $GREEN "✅ $1"
}

print_warning() {
    print_status $YELLOW "⚠️  $1"
}

print_info() {
    print_status $BLUE "ℹ️  $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root - some checks may not work properly"
        print_info "Consider running as regular user for better detection"
    fi
}

# Function to detect malicious Ansible modules
detect_malicious_ansible() {
    print_header "MALICIOUS ANSIBLE MODULES DETECTION"
    
    local found_malicious=false
    
    # Check for Meraki modules
    if find ~/Library/Python/*/lib/python/site-packages/ -name "*meraki*" -o -name "*netflow*" 2>/dev/null | grep -q .; then
        print_critical "Meraki NetFlow modules detected!"
        find ~/Library/Python/*/lib/python/site-packages/ -name "*meraki*" -o -name "*netflow*" 2>/dev/null
        found_malicious=true
    fi
    
    # Check for Fortinet modules
    if find ~/Library/Python/*/lib/python/site-packages/ -name "*fortinet*" -o -name "*sniffer*" 2>/dev/null | grep -q .; then
        print_critical "Fortinet Sniffer modules detected!"
        find ~/Library/Python/*/lib/python/site-packages/ -name "*fortinet*" -o -name "*sniffer*" 2>/dev/null
        found_malicious=true
    fi
    
    # Check for Cisco modules
    if find ~/Library/Python/*/lib/python/site-packages/ -name "*ciscosmb*" -o -name "*cisco*" 2>/dev/null | grep -q .; then
        print_critical "Cisco modules detected!"
        find ~/Library/Python/*/lib/python/site-packages/ -name "*ciscosmb*" -o -name "*cisco*" 2>/dev/null
        found_malicious=true
    fi
    
    # Check for Inspur modules
    if find ~/Library/Python/*/lib/python/site-packages/ -name "*inspur*" -o -name "*capture*" 2>/dev/null | grep -q .; then
        print_critical "Inspur capture modules detected!"
        find ~/Library/Python/*/lib/python/site-packages/ -name "*inspur*" -o -name "*capture*" 2>/dev/null
        found_malicious=true
    fi
    
    # Check file timestamps
    print_info "Checking file timestamps for suspicious installation dates..."
    find ~/Library/Python/*/lib/python/site-packages/ansible_collections/ -name "*.py" -exec ls -la {} \; 2>/dev/null | grep -E "(meraki|cisco|fortinet|netflow|sniffer)" | head -10
    
    if [ "$found_malicious" = true ]; then
        print_critical "MALICIOUS ANSIBLE MODULES DETECTED!"
        return 1
    else
        print_success "No malicious Ansible modules found"
        return 0
    fi
}

# Function to detect rootkit processes
detect_rootkit_processes() {
    print_header "ROOTKIT PROCESS DETECTION"
    
    local found_rootkit=false
    
    # Check for disk arbitration daemon
    if ps aux | grep -q "[d]iskarbitrationd"; then
        print_critical "Disk arbitration daemon running (potential rootkit)"
        ps aux | grep "[d]iskarbitrationd"
        found_rootkit=true
    fi
    
    # Check for disk images I/O daemon
    if ps aux | grep -q "[d]iskimagesiod"; then
        print_critical "Disk images I/O daemon running (potential rootkit)"
        ps aux | grep "[d]iskimagesiod"
        found_rootkit=true
    fi
    
    # Check for Core Simulator services
    if ps aux | grep -q "[s]imdiskimaged"; then
        print_critical "Core Simulator disk image daemon running (potential rootkit)"
        ps aux | grep "[s]imdiskimaged"
        found_rootkit=true
    fi
    
    # Check for suspicious launchd processes
    local suspicious_launchd=$(ps aux | grep launchd | grep -v "^root.*1.*launchd$" | wc -l)
    if [ "$suspicious_launchd" -gt 0 ]; then
        print_warning "Suspicious launchd processes detected"
        ps aux | grep launchd | grep -v "^root.*1.*launchd$"
    fi
    
    if [ "$found_rootkit" = true ]; then
        print_critical "ROOTKIT PROCESSES DETECTED!"
        return 1
    else
        print_success "No rootkit processes detected"
        return 0
    fi
}

# Function to detect suspicious network interfaces
detect_suspicious_interfaces() {
    print_header "SUSPICIOUS NETWORK INTERFACES DETECTION"
    
    local found_suspicious=false
    
    # Check for tunnel interfaces
    local tunnel_count=$(ifconfig | grep -c "utun[0-9]" || true)
    if [ "$tunnel_count" -gt 0 ]; then
        print_critical "Tunnel interfaces detected: $tunnel_count"
        ifconfig | grep -A 3 -B 1 "utun[0-9]"
        found_suspicious=true
    fi
    
    # Check for bridge interfaces
    if ifconfig | grep -q "bridge[0-9]"; then
        print_critical "Bridge interfaces detected"
        ifconfig | grep -A 5 -B 1 "bridge[0-9]"
        found_suspicious=true
    fi
    
    # Check for suspicious AP interfaces
    if ifconfig | grep -q "ap[0-9]"; then
        print_warning "AP interfaces detected"
        ifconfig | grep -A 3 -B 1 "ap[0-9]"
    fi
    
    if [ "$found_suspicious" = true ]; then
        print_critical "SUSPICIOUS NETWORK INTERFACES DETECTED!"
        return 1
    else
        print_success "No suspicious network interfaces detected"
        return 0
    fi
}

# Function to detect suspicious ports
detect_suspicious_ports() {
    print_header "SUSPICIOUS PORTS DETECTION"
    
    local found_suspicious=false
    
    # Check for port 8021 (suspicious service)
    if netstat -an | grep -q ":8021.*LISTEN"; then
        print_critical "Port 8021 listening (suspicious service)"
        netstat -an | grep ":8021"
        found_suspicious=true
    fi
    
    # Check for SSH/SFTP
    if netstat -an | grep -q ":22.*LISTEN"; then
        print_warning "SSH port 22 listening"
        netstat -an | grep ":22"
    fi
    
    # Check for FTP
    if netstat -an | grep -q ":21.*LISTEN"; then
        print_warning "FTP port 21 listening"
        netstat -an | grep ":21"
    fi
    
    # Check for TFTP
    if netstat -an | grep -q ":69.*LISTEN"; then
        print_warning "TFTP port 69 listening"
        netstat -an | grep ":69"
    fi
    
    if [ "$found_suspicious" = true ]; then
        print_critical "SUSPICIOUS PORTS DETECTED!"
        return 1
    else
        print_success "No suspicious ports detected"
        return 0
    fi
}

# Function to detect mounted simulators
detect_mounted_simulators() {
    print_header "MOUNTED SIMULATORS DETECTION"
    
    local simulator_count=$(mount | grep -ci simulator || true)
    
    if [ "$simulator_count" -gt 0 ]; then
        print_critical "Mounted simulators detected: $simulator_count"
        mount | grep -i simulator
        return 1
    else
        print_success "No mounted simulators detected"
        return 0
    fi
}

# Function to remove malicious Ansible modules
remove_malicious_ansible() {
    print_header "REMOVING MALICIOUS ANSIBLE MODULES"
    
    local removed=false
    
    # Remove Meraki modules
    if [ -d ~/Library/Python/*/lib/python/site-packages/ansible_collections/cisco/meraki/ ]; then
        print_info "Removing Meraki modules..."
        rm -rf ~/Library/Python/*/lib/python/site-packages/ansible_collections/cisco/meraki/
        removed=true
    fi
    
    # Remove Fortinet modules
    if [ -d ~/Library/Python/*/lib/python/site-packages/ansible_collections/fortinet/ ]; then
        print_info "Removing Fortinet modules..."
        rm -rf ~/Library/Python/*/lib/python/site-packages/ansible_collections/fortinet/
        removed=true
    fi
    
    # Remove Cisco modules
    if [ -d ~/Library/Python/*/lib/python/site-packages/ansible_collections/cisco/ ]; then
        print_info "Removing Cisco modules..."
        rm -rf ~/Library/Python/*/lib/python/site-packages/ansible_collections/cisco/
        removed=true
    fi
    
    # Remove Inspur modules
    if [ -d ~/Library/Python/*/lib/python/site-packages/ansible_collections/inspur/ ]; then
        print_info "Removing Inspur modules..."
        rm -rf ~/Library/Python/*/lib/python/site-packages/ansible_collections/inspur/
        removed=true
    fi
    
    if [ "$removed" = true ]; then
        print_success "Malicious Ansible modules removed"
    else
        print_info "No malicious Ansible modules to remove"
    fi
}

# Function to disable tunnel interfaces
disable_tunnel_interfaces() {
    print_header "DISABLING TUNNEL INTERFACES"
    
    local disabled=false
    
    for i in {0..9}; do
        if ifconfig | grep -q "utun$i"; then
            print_info "Disabling utun$i..."
            sudo ifconfig "utun$i" down 2>/dev/null || true
            disabled=true
        fi
    done
    
    if [ "$disabled" = true ]; then
        print_success "Tunnel interfaces disabled"
    else
        print_info "No tunnel interfaces to disable"
    fi
}

# Function to destroy bridge interfaces
destroy_bridge_interfaces() {
    print_header "DESTROYING BRIDGE INTERFACES"
    
    local destroyed=false
    
    for i in {0..9}; do
        if ifconfig | grep -q "bridge$i"; then
            print_info "Destroying bridge$i..."
            sudo ifconfig "bridge$i" down 2>/dev/null || true
            sudo ifconfig "bridge$i" destroy 2>/dev/null || true
            destroyed=true
        fi
    done
    
    if [ "$destroyed" = true ]; then
        print_success "Bridge interfaces destroyed"
    else
        print_info "No bridge interfaces to destroy"
    fi
}

# Function to unmount simulators
unmount_simulators() {
    print_header "UNMOUNTING SIMULATORS"
    
    local unmounted=false
    
    # Get list of mounted simulators
    local simulators=$(mount | grep -i simulator | awk '{print $1}' | sort -u)
    
    if [ -n "$simulators" ]; then
        for simulator in $simulators; do
            print_info "Unmounting $simulator..."
            sudo diskutil unmount force "$simulator" 2>/dev/null || true
            unmounted=true
        done
        
        if [ "$unmounted" = true ]; then
            print_success "Simulators unmounted"
        fi
    else
        print_info "No simulators to unmount"
    fi
}

# Function to block suspicious ports
block_suspicious_ports() {
    print_header "BLOCKING SUSPICIOUS PORTS"
    
    print_info "Enabling pfctl firewall..."
    sudo pfctl -e 2>/dev/null || true
    
    print_info "Adding firewall rules..."
    cat << 'EOF' | sudo pfctl -f - 2>/dev/null || true
block in proto tcp from any to any port 8021
block in proto tcp from any to any port 22
block in proto tcp from any to any port 21
block in proto tcp from any to any port 69
EOF
    
    print_success "Suspicious ports blocked"
}

# Function to kill rootkit processes
kill_rootkit_processes() {
    print_header "KILLING ROOTKIT PROCESSES"
    
    local killed=false
    
    # Kill disk arbitration daemon
    if pgrep -f diskarbitrationd >/dev/null; then
        print_info "Killing diskarbitrationd..."
        sudo pkill -9 -f diskarbitrationd 2>/dev/null || true
        killed=true
    fi
    
    # Kill disk images I/O daemon
    if pgrep -f diskimagesiod >/dev/null; then
        print_info "Killing diskimagesiod..."
        sudo pkill -9 -f diskimagesiod 2>/dev/null || true
        killed=true
    fi
    
    # Kill Core Simulator services
    if pgrep -f simdiskimaged >/dev/null; then
        print_info "Killing simdiskimaged..."
        sudo pkill -9 -f simdiskimaged 2>/dev/null || true
        killed=true
    fi
    
    if [ "$killed" = true ]; then
        print_success "Rootkit processes killed"
    else
        print_info "No rootkit processes to kill"
    fi
}

# Function to disable rootkit services
disable_rootkit_services() {
    print_header "DISABLING ROOTKIT SERVICES"
    
    local disabled=false
    
    # Disable disk arbitration daemon
    if sudo launchctl print system/com.apple.diskarbitrationd >/dev/null 2>&1; then
        print_info "Disabling diskarbitrationd..."
        sudo launchctl disable system/com.apple.diskarbitrationd 2>/dev/null || true
        disabled=true
    fi
    
    # Disable Core Simulator services
    if sudo launchctl print system/com.apple.CoreSimulator.simdiskimaged >/dev/null 2>&1; then
        print_info "Disabling CoreSimulator.simdiskimaged..."
        sudo launchctl disable system/com.apple.CoreSimulator.simdiskimaged 2>/dev/null || true
        disabled=true
    fi
    
    if [ "$disabled" = true ]; then
        print_success "Rootkit services disabled"
    else
        print_info "No rootkit services to disable"
    fi
}

# Function to generate security report
generate_report() {
    print_header "GENERATING SECURITY REPORT"
    
    local report_file="security_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
STATIC TUNDRA/FSB-LINKED ROOTKIT DETECTION REPORT
================================================

Date: $(date)
System: $(hostname) - $(uname -a)
User: $(whoami)

DETECTION RESULTS:
- Malicious Ansible modules: $(detect_malicious_ansible && echo "CLEAN" || echo "DETECTED")
- Rootkit processes: $(detect_rootkit_processes && echo "CLEAN" || echo "DETECTED")
- Suspicious interfaces: $(detect_suspicious_interfaces && echo "CLEAN" || echo "DETECTED")
- Suspicious ports: $(detect_suspicious_ports && echo "CLEAN" || echo "DETECTED")
- Mounted simulators: $(detect_mounted_simulators && echo "CLEAN" || echo "DETECTED")

RECOMMENDATIONS:
1. If any threats detected, disconnect from internet immediately
2. Document all findings for law enforcement
3. Check all other devices for similar compromise
4. Report to authorities (FBI, CISA)
5. Consider professional forensic assistance
6. May require hardware replacement for firmware-level compromise

This tool is based on real-world investigation of Static Tundra
FSB-linked rootkit attacks targeting macOS systems.

EOF
    
    print_success "Security report generated: $report_file"
}

# Main execution
main() {
    print_status $PURPLE "🚨 STATIC TUNDRA/FSB-LINKED ROOTKIT DETECTION & REMOVAL TOOLKIT"
    print_status $PURPLE "=================================================================="
    echo ""
    print_info "Based on real-world investigation of sophisticated state-sponsored attacks"
    print_info "Log file: $LOG_FILE"
    echo ""
    
    check_root
    
    # Detection phase
    print_status $CYAN "🔍 DETECTION PHASE"
    echo "=================="
    
    local threats_detected=false
    
    if ! detect_malicious_ansible; then
        threats_detected=true
    fi
    
    if ! detect_rootkit_processes; then
        threats_detected=true
    fi
    
    if ! detect_suspicious_interfaces; then
        threats_detected=true
    fi
    
    if ! detect_suspicious_ports; then
        threats_detected=true
    fi
    
    if ! detect_mounted_simulators; then
        threats_detected=true
    fi
    
    echo ""
    
    if [ "$threats_detected" = true ]; then
        print_critical "THREATS DETECTED! Proceeding with removal..."
        echo ""
        
        # Removal phase
        print_status $CYAN "🛡️  REMOVAL PHASE"
        echo "=================="
        
        remove_malicious_ansible
        kill_rootkit_processes
        disable_rootkit_services
        disable_tunnel_interfaces
        destroy_bridge_interfaces
        unmount_simulators
        block_suspicious_ports
        
        echo ""
        print_warning "Removal completed. Monitor system for 24 hours for reinfection."
        print_warning "If threats return, this indicates firmware-level compromise."
        
    else
        print_success "No threats detected. System appears clean."
    fi
    
    # Generate report
    generate_report
    
    echo ""
    print_status $GREEN "🛡️  SECURITY AUDIT COMPLETE"
    print_status $GREEN "============================"
    print_info "Log file: $LOG_FILE"
    print_info "Report file: security_report_$(date +%Y%m%d_%H%M%S).txt"
    echo ""
    print_info "This toolkit can be used on any macOS system to detect similar attacks."
    print_info "Based on investigation of Static Tundra FSB-linked rootkit."
}

# Run main function
main "$@"
