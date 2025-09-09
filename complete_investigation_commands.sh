#!/bin/bash

# Complete Security Investigation Commands
# Static Tundra/FSB-linked Rootkit Investigation
# August 27 - September 9, 2025
# 
# This script contains ALL commands used during the investigation
# Run sections as needed for similar investigations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo "=========================================="
    echo -e "${CYAN}🔍 $1${NC}"
    echo "=========================================="
    echo ""
}

print_command() {
    echo -e "${BLUE}Command:${NC} $1"
    echo -e "${YELLOW}Purpose:${NC} $2"
    echo ""
}

# =============================================================================
# INITIAL INVESTIGATION COMMANDS
# =============================================================================

print_header "INITIAL INVESTIGATION COMMANDS"

print_command "ifconfig" "Check network interfaces for suspicious tunnels and bridges"
ifconfig

print_command "netstat -rn" "Check routing table for tunnel interfaces"
netstat -rn | grep -E "(utun|bridge|tunnel)"

print_command "ps aux | grep -E '(python|ansible|netflow|sniffer)'" "Check for suspicious processes"
ps aux | grep -E "(python|ansible|netflow|sniffer)" | grep -v grep

print_command "mount | grep -i simulator" "Check for mounted iOS simulators"
mount | grep -i simulator

print_command "diskutil list" "List all disk devices including simulators"
diskutil list

# =============================================================================
# MALICIOUS ANSIBLE MODULES INVESTIGATION
# =============================================================================

print_header "MALICIOUS ANSIBLE MODULES INVESTIGATION"

print_command "find ~/Library/Python/3.9/lib/python/site-packages/ -name '*meraki*' -o -name '*cisco*' -o -name '*fortinet*' -o -name '*netflow*' -o -name '*sniffer*'" "Search for malicious Ansible modules"
find ~/Library/Python/3.9/lib/python/site-packages/ -name "*meraki*" -o -name "*cisco*" -o -name "*fortinet*" -o -name "*netflow*" -o -name "*sniffer*" 2>/dev/null

print_command "ls -la ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/cisco/meraki/plugins/modules/networks_netflow.py" "Check Meraki NetFlow module timestamp"
ls -la ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/cisco/meraki/plugins/modules/networks_netflow.py

print_command "ls -la ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/fortinet/fortios/plugins/modules/fortios_firewall_sniffer.py" "Check Fortinet Sniffer module timestamp"
ls -la ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/fortinet/fortios/plugins/modules/fortios_firewall_sniffer.py

print_command "find ~/Library/Python/3.9/lib/python/site-packages/ -name '*.py' -exec ls -la {} \; | grep -E '(meraki|cisco|fortinet|netflow|sniffer)'" "Check file timestamps for suspicious installation dates"
find ~/Library/Python/3.9/lib/python/site-packages/ -name "*.py" -exec ls -la {} \; 2>/dev/null | grep -E "(meraki|cisco|fortinet|netflow|sniffer)" | head -10

# =============================================================================
# ROOTKIT PROCESS DETECTION
# =============================================================================

print_header "ROOTKIT PROCESS DETECTION"

print_command "ps aux | grep -E '(diskarbitrationd|diskimagesiod|simdiskimaged)'" "Check for rootkit processes"
ps aux | grep -E "(diskarbitrationd|diskimagesiod|simdiskimaged)" | grep -v grep

print_command "sudo launchctl list | grep -i simulator" "Check for CoreSimulator services"
sudo launchctl list | grep -i simulator

print_command "sudo launchctl print system/com.apple.diskarbitrationd" "Check disk arbitration daemon status"
sudo launchctl print system/com.apple.diskarbitrationd

print_command "sudo launchctl print-disabled system" "Check disabled system services"
sudo launchctl print-disabled system

# =============================================================================
# NETWORK INTERFACE ANALYSIS
# =============================================================================

print_header "NETWORK INTERFACE ANALYSIS"

print_command "ifconfig | grep -E '(utun|bridge|ap1)'" "Check for suspicious network interfaces"
ifconfig | grep -E "(utun|bridge|ap1)"

print_command "ifconfig | grep -A 5 -B 1 -E '(utun|bridge|ap1)'" "Detailed network interface information"
ifconfig | grep -A 5 -B 1 -E "(utun|bridge|ap1)"

print_command "netstat -rn | grep -E '(utun|bridge|tunnel)'" "Check routing table for tunnel interfaces"
netstat -rn | grep -E "(utun|bridge|tunnel)"

# =============================================================================
# SUSPICIOUS PORTS AND CONNECTIONS
# =============================================================================

print_header "SUSPICIOUS PORTS AND CONNECTIONS"

print_command "netstat -an | grep -E ':8021|:22|:21|:69'" "Check for suspicious ports"
netstat -an | grep -E ":8021|:22|:21|:69"

print_command "sudo lsof -i :8021" "Check what's using port 8021"
sudo lsof -i :8021

print_command "sudo lsof -i | grep -E '(tftp|ftp|gre|tunnel)'" "Check for suspicious network connections"
sudo lsof -i | grep -E "(tftp|ftp|gre|tunnel)" | head -10

print_command "netstat -an | grep -E '(LISTEN|ESTABLISHED)'" "Check active network connections"
netstat -an | grep -E "(LISTEN|ESTABLISHED)" | head -10

# =============================================================================
# SYSTEM INTEGRITY AND SECURITY
# =============================================================================

print_header "SYSTEM INTEGRITY AND SECURITY"

print_command "csrutil status" "Check System Integrity Protection status"
csrutil status

print_command "sudo kextstat | head -20" "Check loaded kernel extensions"
sudo kextstat | head -20

print_command "sudo kextstat | grep -E '(disk|simulator|arbitration)'" "Check for suspicious kernel extensions"
sudo kextstat | grep -E "(disk|simulator|arbitration)" | head -10

print_command "sudo pfctl -s rules" "Check firewall rules"
sudo pfctl -s rules

# =============================================================================
# REMEDIATION COMMANDS
# =============================================================================

print_header "REMEDIATION COMMANDS"

print_command "rm -rf ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/cisco/meraki/" "Remove Meraki modules"
rm -rf ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/cisco/meraki/

print_command "rm -rf ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/fortinet/" "Remove Fortinet modules"
rm -rf ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/fortinet/

print_command "rm -rf ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/cisco/" "Remove all Cisco modules"
rm -rf ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/cisco/

print_command "rm -rf ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/inspur/" "Remove Inspur modules"
rm -rf ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/inspur/

print_command "rm -rf ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/netapp/ontap/plugins/modules/na_ontap_domain_tunnel.py" "Remove domain tunnel module"
rm -rf ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/netapp/ontap/plugins/modules/na_ontap_domain_tunnel.py

# =============================================================================
# PROCESS TERMINATION COMMANDS
# =============================================================================

print_header "PROCESS TERMINATION COMMANDS"

print_command "sudo pkill -f diskarbitrationd" "Kill disk arbitration daemon"
sudo pkill -f diskarbitrationd

print_command "sudo pkill -f diskimagesiod" "Kill disk images I/O daemon"
sudo pkill -f diskimagesiod

print_command "sudo pkill -f CoreSimulator" "Kill Core Simulator services"
sudo pkill -f CoreSimulator

print_command "sudo kill -9 [PID]" "Force kill specific processes (replace [PID] with actual process ID)"
echo "Example: sudo kill -9 28872 28022 28191"

# =============================================================================
# NETWORK INTERFACE DISABLING
# =============================================================================

print_header "NETWORK INTERFACE DISABLING"

print_command "sudo ifconfig utun0 down" "Disable tunnel interface 0"
sudo ifconfig utun0 down

print_command "sudo ifconfig utun1 down" "Disable tunnel interface 1"
sudo ifconfig utun1 down

print_command "sudo ifconfig utun2 down" "Disable tunnel interface 2"
sudo ifconfig utun2 down

print_command "sudo ifconfig utun3 down" "Disable tunnel interface 3"
sudo ifconfig utun3 down

print_command "sudo ifconfig bridge0 down" "Disable bridge interface"
sudo ifconfig bridge0 down

print_command "sudo ifconfig bridge0 destroy" "Destroy bridge interface"
sudo ifconfig bridge0 destroy

# =============================================================================
# ROUTING TABLE CLEANUP
# =============================================================================

print_header "ROUTING TABLE CLEANUP"

print_command "sudo route delete -inet6 fe80::%utun0" "Delete tunnel 0 routing entry"
sudo route delete -inet6 fe80::%utun0

print_command "sudo route delete -inet6 fe80::%utun1" "Delete tunnel 1 routing entry"
sudo route delete -inet6 fe80::%utun1

print_command "sudo route delete -inet6 fe80::%utun2" "Delete tunnel 2 routing entry"
sudo route delete -inet6 fe80::%utun2

print_command "sudo route delete -inet6 fe80::%utun3" "Delete tunnel 3 routing entry"
sudo route delete -inet6 fe80::%utun3

# =============================================================================
# SIMULATOR UNMOUNTING COMMANDS
# =============================================================================

print_header "SIMULATOR UNMOUNTING COMMANDS"

print_command "sudo diskutil unmount force /dev/disk5s1" "Force unmount simulator 1"
sudo diskutil unmount force /dev/disk5s1

print_command "sudo diskutil unmount force /dev/disk7s1" "Force unmount simulator 2"
sudo diskutil unmount force /dev/disk7s1

print_command "sudo diskutil unmount force /dev/disk9s1" "Force unmount simulator 3"
sudo diskutil unmount force /dev/disk9s1

print_command "sudo diskutil unmount force /dev/disk11s1" "Force unmount simulator 4"
sudo diskutil unmount force /dev/disk11s1

print_command "sudo diskutil unmount force /dev/disk13s1" "Force unmount simulator 5"
sudo diskutil unmount force /dev/disk13s1

print_command "sudo diskutil unmount force /dev/disk15s1" "Force unmount simulator 6"
sudo diskutil unmount force /dev/disk15s1

print_command "sudo diskutil unmount force /dev/disk17s1" "Force unmount simulator 7"
sudo diskutil unmount force /dev/disk17s1

print_command "sudo diskutil unmount force /dev/disk19s1" "Force unmount simulator 8"
sudo diskutil unmount force /dev/disk19s1

# =============================================================================
# FIREWALL CONFIGURATION
# =============================================================================

print_header "FIREWALL CONFIGURATION"

print_command "sudo pfctl -e" "Enable pfctl firewall"
sudo pfctl -e

print_command "echo 'block in proto tcp from any to any port 8021
block in proto tcp from any to any port 22
block in proto tcp from any to any port 21
block in proto tcp from any to any port 69' | sudo pfctl -f -" "Block suspicious ports"
echo "block in proto tcp from any to any port 8021
block in proto tcp from any to any port 22
block in proto tcp from any to any port 21
block in proto tcp from any to any port 69" | sudo pfctl -f -

# =============================================================================
# SERVICE DISABLING COMMANDS
# =============================================================================

print_header "SERVICE DISABLING COMMANDS"

print_command "sudo launchctl disable system/com.apple.diskarbitrationd" "Disable disk arbitration daemon"
sudo launchctl disable system/com.apple.diskarbitrationd

print_command "sudo launchctl disable system/com.apple.CoreSimulator.simdiskimaged" "Disable CoreSimulator service"
sudo launchctl disable system/com.apple.CoreSimulator.simdiskimaged

print_command "sudo launchctl bootout system /System/Library/LaunchDaemons/com.apple.diskarbitrationd.plist" "Boot out disk arbitration daemon"
sudo launchctl bootout system /System/Library/LaunchDaemons/com.apple.diskarbitrationd.plist

# =============================================================================
# SYSTEM BINARY PROTECTION CHECK
# =============================================================================

print_header "SYSTEM BINARY PROTECTION CHECK"

print_command "sudo chmod 000 /usr/libexec/diskarbitrationd" "Test if system binary can be modified"
sudo chmod 000 /usr/libexec/diskarbitrationd

print_command "sudo chmod 000 /usr/libexec/diskimagesiod" "Test if system binary can be modified"
sudo chmod 000 /usr/libexec/diskimagesiod

print_command "sudo chmod 000 /Library/Developer/PrivateFrameworks/CoreSimulator.framework/Resources/bin/simdiskimaged" "Test if system binary can be modified"
sudo chmod 000 /Library/Developer/PrivateFrameworks/CoreSimulator.framework/Resources/bin/simdiskimaged

# =============================================================================
# NVRAM AND FIRMWARE COMMANDS
# =============================================================================

print_header "NVRAM AND FIRMWARE COMMANDS"

print_command "sudo nvram boot-args" "Check current boot arguments"
sudo nvram boot-args

print_command "sudo nvram boot-args='-x'" "Set boot arguments for safe mode"
sudo nvram boot-args="-x"

print_command "sudo nvram boot-args='kext-dev-mode=1 -v'" "Set boot arguments for kernel extension development mode"
sudo nvram boot-args="kext-dev-mode=1 -v"

# =============================================================================
# VERIFICATION COMMANDS
# =============================================================================

print_header "VERIFICATION COMMANDS"

print_command "find ~/Library/Python/3.9/lib/python/site-packages/ -name '*meraki*' -o -name '*cisco*' -o -name '*fortinet*' -o -name '*netflow*' -o -name '*sniffer*'" "Verify malicious modules are removed"
find ~/Library/Python/3.9/lib/python/site-packages/ -name "*meraki*" -o -name "*cisco*" -o -name "*fortinet*" -o -name "*netflow*" -o -name "*sniffer*" 2>/dev/null

print_command "ps aux | grep -E '(diskarbitrationd|diskimagesiod|simdiskimaged)'" "Verify rootkit processes are terminated"
ps aux | grep -E "(diskarbitrationd|diskimagesiod|simdiskimaged)" | grep -v grep

print_command "mount | grep -i simulator" "Verify simulators are unmounted"
mount | grep -i simulator

print_command "ifconfig | grep -E '(utun|bridge)'" "Verify network interfaces are disabled"
ifconfig | grep -E "(utun|bridge)"

print_command "netstat -rn | grep -E '(utun|bridge|tunnel)' | wc -l" "Count remaining tunnel routing entries"
netstat -rn | grep -E "(utun|bridge|tunnel)" | wc -l

print_command "sudo pfctl -s rules" "Verify firewall rules are active"
sudo pfctl -s rules

# =============================================================================
# EVIDENCE GATHERING COMMANDS
# =============================================================================

print_header "EVIDENCE GATHERING COMMANDS"

print_command "date" "Record investigation timestamp"
date

print_command "uname -a" "Record system information"
uname -a

print_command "whoami" "Record user information"
whoami

print_command "hostname" "Record hostname"
hostname

print_command "uptime" "Record system uptime"
uptime

print_command "ls -la ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/ | grep -E '(cisco|fortinet|meraki|netflow|sniffer|inspur|netapp)'" "List suspicious Ansible collections"
ls -la ~/Library/Python/3.9/lib/python/site-packages/ansible_collections/ | grep -E "(cisco|fortinet|meraki|netflow|sniffer|inspur|netapp)"

# =============================================================================
# NVRAM RESET INSTRUCTIONS
# =============================================================================

print_header "NVRAM RESET INSTRUCTIONS"

echo -e "${RED}🚨 NVRAM RESET PROCEDURE${NC}"
echo ""
echo -e "${YELLOW}For Intel Macs:${NC}"
echo "1. Power off completely"
echo "2. Hold: Command + Option + P + R"
echo "3. Power on while holding keys"
echo "4. Hold for 20 seconds (hear startup chime twice)"
echo "5. Release keys"
echo ""
echo -e "${YELLOW}For Apple Silicon (M1/M2/M3) Macs:${NC}"
echo "1. Power off completely"
echo "2. Hold power button until 'Loading startup options'"
echo "3. Hold: Command + Option + P + R"
echo "4. Click 'Continue' while holding keys"
echo "5. Hold for 20 seconds then release"
echo ""
echo -e "${GREEN}After NVRAM reset, run: ./post_nvram_reset.sh${NC}"

# =============================================================================
# SCRIPT COMPLETION
# =============================================================================

print_header "INVESTIGATION COMMANDS COMPLETE"

echo -e "${GREEN}✅ All investigation commands documented${NC}"
echo -e "${BLUE}📋 This script contains every command used during the investigation${NC}"
echo -e "${YELLOW}⚠️  Run sections as needed for similar investigations${NC}"
echo -e "${RED}🚨 Remember: This was a sophisticated state-sponsored attack${NC}"
echo ""
echo -e "${PURPLE}Investigation Period: August 27 - September 9, 2025${NC}"
echo -e "${PURPLE}Attack Vector: Static Tundra (FSB-linked) via Meraki SD-WAN${NC}"
echo -e "${PURPLE}Compromise Level: FIRMWARE-LEVEL ROOTKIT${NC}"
echo ""
echo -e "${CYAN}🛡️  Community Security: Share this knowledge to protect others!${NC}"
