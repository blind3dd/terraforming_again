#!/bin/bash

# Disk and Network Integration Security Audit Script
# Checks for unwanted NFS/Samba shares, disk configurations, and network services

set -euo pipefail

echo "=== DISK & NETWORK INTEGRATION SECURITY AUDIT ==="
echo "Timestamp: $(date)"
echo

# Function to check if running as root
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        echo "⚠️  Some operations require root privileges"
        echo "   Run with 'sudo' for complete analysis"
        echo
    fi
}

# 1. Audit Disk Configurations
audit_disks() {
    echo "=== DISK CONFIGURATION AUDIT ==="
    echo
    
    echo "🔍 Disk Information:"
    diskutil list
    
    echo
    echo "🔍 Mounted Filesystems:"
    mount | grep -E "(nfs|smb|cifs|afp)" || echo "No network filesystems mounted"
    
    echo
    echo "🔍 Disk Usage:"
    df -h
    
    echo
    echo "🔍 Suspicious Mount Points:"
    mount | while read -r line; do
        if [[ "$line" =~ (nfs|smb|cifs|afp|ftp) ]]; then
            echo "  ⚠️  NETWORK FILESYSTEM: $line"
        fi
    done
    
    echo
    echo "🔍 External/Removable Disks:"
    diskutil list | grep -E "(external|removable)" || echo "No external disks detected"
    
    echo
    echo "🔍 Disk Encryption Status:"
    diskutil apfs list | grep -E "(Encrypted|FileVault)" || echo "No APFS encryption info available"
    
    echo
}

# 2. Audit NFS Services and Shares
audit_nfs() {
    echo "=== NFS SERVICES AUDIT ==="
    echo
    
    echo "🔍 NFS Daemon Status:"
    if launchctl list | grep -i nfs; then
        echo "  ⚠️  NFS services are running"
    else
        echo "  ✅ No NFS services detected"
    fi
    
    echo
    echo "🔍 NFS Configuration Files:"
    NFS_CONFIGS=(
        "/etc/exports"
        "/etc/nfs.conf"
        "/etc/nfsd.conf"
        "/etc/rc.nfsd"
    )
    
    for config in "${NFS_CONFIGS[@]}"; do
        if [[ -f "$config" ]]; then
            echo "  📁 Found: $config"
            echo "    Content:"
            cat "$config" | sed 's/^/      /'
            echo
        fi
    done
    
    echo
    echo "🔍 NFS Processes:"
    ps aux | grep -i nfs | grep -v grep || echo "No NFS processes running"
    
    echo
    echo "🔍 NFS Network Connections:"
    netstat -an | grep -E ":2049|:111" || echo "No NFS network connections"
    
    echo
}

# 3. Audit Samba/SMB Services and Shares
audit_samba() {
    echo "=== SAMBA/SMB SERVICES AUDIT ==="
    echo
    
    echo "🔍 Samba Daemon Status:"
    if launchctl list | grep -i smb; then
        echo "  ⚠️  SMB services are running"
    else
        echo "  ✅ No SMB services detected"
    fi
    
    echo
    echo "🔍 Samba Configuration Files:"
    SAMBA_CONFIGS=(
        "/etc/smb.conf"
        "/usr/local/etc/smb.conf"
        "/opt/homebrew/etc/smb.conf"
        "/etc/samba/smb.conf"
    )
    
    for config in "${SAMBA_CONFIGS[@]}"; do
        if [[ -f "$config" ]]; then
            echo "  📁 Found: $config"
            echo "    Content:"
            cat "$config" | sed 's/^/      /'
            echo
        fi
    done
    
    echo
    echo "🔍 Samba Processes:"
    ps aux | grep -E "(smbd|nmbd|winbindd)" | grep -v grep || echo "No Samba processes running"
    
    echo
    echo "🔍 SMB Network Connections:"
    netstat -an | grep -E ":445|:139" || echo "No SMB network connections"
    
    echo
    echo "🔍 macOS File Sharing Status:"
    if [[ -f "/Library/Preferences/SystemConfiguration/com.apple.smb.server.plist" ]]; then
        echo "  📁 SMB server configuration found"
        defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server 2>/dev/null || echo "Cannot read SMB config"
    else
        echo "  ✅ No SMB server configuration found"
    fi
    
    echo
}

# 4. Audit AFP (Apple Filing Protocol) Services
audit_afp() {
    echo "=== AFP SERVICES AUDIT ==="
    echo
    
    echo "🔍 AFP Daemon Status:"
    if launchctl list | grep -i afp; then
        echo "  ⚠️  AFP services are running"
    else
        echo "  ✅ No AFP services detected"
    fi
    
    echo
    echo "🔍 AFP Configuration:"
    if [[ -f "/Library/Preferences/SystemConfiguration/com.apple.AppleFileServer.plist" ]]; then
        echo "  📁 AFP server configuration found"
        defaults read /Library/Preferences/SystemConfiguration/com.apple.AppleFileServer 2>/dev/null || echo "Cannot read AFP config"
    else
        echo "  ✅ No AFP server configuration found"
    fi
    
    echo
    echo "🔍 AFP Network Connections:"
    netstat -an | grep ":548" || echo "No AFP network connections"
    
    echo
}

# 5. Audit Network Services and Ports
audit_network_services() {
    echo "=== NETWORK SERVICES AUDIT ==="
    echo
    
    echo "🔍 Listening Network Ports:"
    netstat -an | grep LISTEN | while read -r line; do
        if [[ "$line" =~ :(21|22|23|25|53|80|110|143|443|993|995|2049|445|139|548|631|8080|8443) ]]; then
            echo "  ⚠️  POTENTIAL RISK: $line"
        fi
    done
    
    echo
    echo "🔍 Active Network Connections:"
    netstat -an | grep ESTABLISHED | head -20
    
    echo
    echo "🔍 Network Interfaces:"
    ifconfig | grep -E "(inet |flags)" | while read -r line; do
        echo "  $line"
    done
    
    echo
    echo "🔍 DNS Configuration:"
    scutil --dns | grep -E "(nameserver|search domain)" | head -10
    
    echo
}

# 6. Audit WiFi and Network Configuration
audit_wifi_network() {
    echo "=== WIFI & NETWORK CONFIGURATION AUDIT ==="
    echo
    
    echo "🔍 WiFi Networks:"
    networksetup -listallhardwareports | grep -A 1 "Wi-Fi"
    
    echo
    echo "🔍 Current WiFi Network:"
    networksetup -getairportnetwork en0 2>/dev/null || echo "WiFi not available or not connected"
    
    echo
    echo "🔍 WiFi Security:"
    system_profiler SPAirPortDataType | grep -E "(Security|Encryption)" || echo "No WiFi security info available"
    
    echo
    echo "🔍 Network Locations:"
    networksetup -listlocations
    
    echo
    echo "🔍 DNS Servers:"
    networksetup -getdnsservers Wi-Fi 2>/dev/null || networksetup -getdnsservers "Wi-Fi" 2>/dev/null || echo "Cannot get DNS servers"
    
    echo
    echo "🔍 Search Domains:"
    networksetup -getsearchdomains Wi-Fi 2>/dev/null || networksetup -getsearchdomains "Wi-Fi" 2>/dev/null || echo "Cannot get search domains"
    
    echo
    echo "🔍 Local Domain Configuration:"
    scutil --dns | grep "search domain" | head -5
    
    echo
}

# 7. Audit File Sharing Services
audit_file_sharing() {
    echo "=== FILE SHARING SERVICES AUDIT ==="
    echo
    
    echo "🔍 File Sharing Status:"
    if [[ -f "/Library/Preferences/SystemConfiguration/com.apple.smb.server.plist" ]]; then
        echo "  ⚠️  File sharing may be enabled"
    else
        echo "  ✅ File sharing appears disabled"
    fi
    
    echo
    echo "🔍 Shared Folders:"
    if command -v sharing &> /dev/null; then
        sharing -l 2>/dev/null || echo "No shared folders or sharing command not available"
    else
        echo "Sharing command not available"
    fi
    
    echo
    echo "🔍 File Sharing Launch Daemons:"
    launchctl list | grep -E "(smb|afp|nfs)" || echo "No file sharing daemons running"
    
    echo
    echo "🔍 File Sharing Configuration Files:"
    find /Library/Preferences -name "*smb*" -o -name "*afp*" -o -name "*nfs*" 2>/dev/null | while read -r file; do
        echo "  📁 $file"
    done
    
    echo
}

# 8. Audit FTP/SFTP Services
audit_ftp_services() {
    echo "=== FTP/SFTP SERVICES AUDIT ==="
    echo
    
    echo "🔍 FTP/SFTP Processes:"
    FTP_PROCESSES=$(ps aux | grep -E "(ftp|sftp|vsftpd|proftpd|pure-ftpd)" | grep -v grep)
    if [[ -n "$FTP_PROCESSES" ]]; then
        echo "  ⚠️  FTP/SFTP processes running:"
        echo "$FTP_PROCESSES" | sed 's/^/    /'
    else
        echo "  ✅ No FTP/SFTP processes running"
    fi
    
    echo
    echo "🔍 FTP/SFTP Listening Ports:"
    FTP_PORTS=$(netstat -an | grep LISTEN | grep -E ":(21|22|990|989)")
    if [[ -n "$FTP_PORTS" ]]; then
        echo "  ⚠️  FTP/SFTP ports listening:"
        echo "$FTP_PORTS" | sed 's/^/    /'
    else
        echo "  ✅ No FTP/SFTP ports listening"
    fi
    
    echo
    echo "🔍 FTP/SFTP Launch Daemons:"
    FTP_DAEMONS=$(launchctl list | grep -E "(ftp|sftp)")
    if [[ -n "$FTP_DAEMONS" ]]; then
        echo "  ⚠️  FTP/SFTP daemons found:"
        echo "$FTP_DAEMONS" | sed 's/^/    /'
    else
        echo "  ✅ No FTP/SFTP daemons running"
    fi
    
    echo
    echo "🔍 FTP/SFTP Configuration Files:"
    FTP_CONFIGS=$(find /etc /usr/local/etc /opt -name "*ftp*" -type f 2>/dev/null)
    if [[ -n "$FTP_CONFIGS" ]]; then
        echo "  📁 FTP/SFTP configuration files found:"
        echo "$FTP_CONFIGS" | sed 's/^/    /'
    else
        echo "  ✅ No FTP/SFTP configuration files found"
    fi
    
    echo
    echo "🔍 FTP/SFTP Binaries:"
    FTP_BINARIES=$(find /usr/bin /usr/sbin /usr/local/bin -name "*ftp*" 2>/dev/null)
    if [[ -n "$FTP_BINARIES" ]]; then
        echo "  📁 FTP/SFTP binaries found:"
        echo "$FTP_BINARIES" | sed 's/^/    /'
    else
        echo "  ✅ No FTP/SFTP binaries found"
    fi
    
    echo
    echo "🔍 TFTP and FTP Proxy Services:"
    TFTP_SERVICES=$(find /System/Library/LaunchDaemons -name "*ftp*" 2>/dev/null)
    if [[ -n "$TFTP_SERVICES" ]]; then
        echo "  📁 System FTP services found:"
        echo "$TFTP_SERVICES" | sed 's/^/    /'
        
        # Check if they're loaded
        for service in $TFTP_SERVICES; do
            service_name=$(basename "$service" .plist)
            if launchctl list | grep -q "$service_name"; then
                echo "    ⚠️  $service_name is LOADED"
            else
                echo "    ✅ $service_name is NOT LOADED"
            fi
        done
    else
        echo "  ✅ No system FTP services found"
    fi
    
    echo
}

# 9. Audit Remote Access Services
audit_remote_access() {
    echo "=== REMOTE ACCESS SERVICES AUDIT ==="
    echo
    
    echo "🔍 SSH Status:"
    if launchctl list | grep sshd; then
        echo "  ⚠️  SSH daemon is running"
        echo "  📁 SSH config: /etc/ssh/sshd_config"
    else
        echo "  ✅ SSH daemon not running"
    fi
    
    echo
    echo "🔍 Remote Desktop (VNC):"
    if launchctl list | grep -i vnc; then
        echo "  ⚠️  VNC services are running"
    else
        echo "  ✅ No VNC services detected"
    fi
    
    echo
    echo "🔍 Remote Management:"
    if launchctl list | grep -i "remote.*management"; then
        echo "  ⚠️  Remote management services are running"
    else
        echo "  ✅ No remote management services detected"
    fi
    
    echo
    echo "🔍 Screen Sharing:"
    defaults read com.apple.screensharing 2>/dev/null || echo "Screen sharing not configured"
    
    echo
}

# 9. Generate Security Recommendations
generate_recommendations() {
    echo "=== SECURITY RECOMMENDATIONS ==="
    echo
    
    echo "🔒 DISK SECURITY:"
    echo "  • Enable FileVault for full disk encryption"
    echo "  • Remove unnecessary external drives"
    echo "  • Audit mounted network filesystems regularly"
    echo "  • Use encrypted external storage"
    echo
    
    echo "🔒 NETWORK SHARING:"
    echo "  • Disable all file sharing services if not needed"
    echo "  • Remove NFS exports: sudo rm /etc/exports"
    echo "  • Disable SMB: sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist"
    echo "  • Disable AFP: sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist"
    echo
    
    echo "🔒 WIFI SECURITY:"
    echo "  • Use WPA3 encryption when available"
    echo "  • Avoid public WiFi networks"
    echo "  • Configure local domain manually (as you mentioned)"
    echo "  • Use VPN for sensitive connections"
    echo
    
    echo "🔒 FTP/SFTP SERVICES:"
    echo "  • Remove FTP/SFTP binaries if not needed: sudo rm /usr/bin/sftp /usr/bin/tftp"
    echo "  • Disable TFTP: sudo launchctl unload -w /System/Library/LaunchDaemons/tftp.plist"
    echo "  • Disable FTP proxy: sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.ftp-proxy.plist"
    echo "  • Remove any third-party FTP server installations"
    echo
    
    echo "🔒 REMOTE ACCESS:"
    echo "  • Disable SSH if not needed: sudo launchctl unload -w /System/Library/LaunchDaemons/ssh.plist"
    echo "  • Disable screen sharing and remote management"
    echo "  • Use strong authentication for any remote access"
    echo
    
    echo "🔒 PARALLELS SETUP (as requested):"
    echo "  • Install Parallels for controlled virtualization"
    echo "  • Configure isolated network for VMs"
    echo "  • Set up local domain within Parallels environment"
    echo "  • Keep host system isolated from VM network"
    echo
    
    echo "⚠️  WARNING:"
    echo "  • Always backup before disabling services"
    echo "  • Test network connectivity after changes"
    echo "  • Some services may be required by legitimate software"
    echo
}

# 10. Create Network Hardening Script
create_network_hardening_script() {
    echo "=== CREATING NETWORK HARDENING SCRIPT ==="
    echo
    
    HARDENING_SCRIPT="/tmp/network-hardening.sh"
    
    cat > "$HARDENING_SCRIPT" << 'EOF'
#!/bin/bash

# Network Security Hardening Script
# Disables unnecessary network services and file sharing

set -euo pipefail

echo "=== NETWORK SECURITY HARDENING ==="
echo "⚠️  WARNING: This will disable network sharing services"
echo

# Disable file sharing services
echo "🚫 Disabling file sharing services..."

# Disable SMB
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.netbiosd.plist 2>/dev/null || true

# Disable AFP
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist 2>/dev/null || true

# Disable NFS (if present)
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.nfsd.plist 2>/dev/null || true

# Disable remote login
sudo systemsetup -setremotelogin off

# Disable screen sharing
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true

# Disable remote management
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -configure -access -off

# Disable SSH
sudo launchctl unload -w /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true

echo "✅ Network services disabled"
echo
echo "🔧 To re-enable services later:"
echo "  • SMB: sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist"
echo "  • SSH: sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist"
echo "  • Remote login: sudo systemsetup -setremotelogin on"
EOF
    
    chmod +x "$HARDENING_SCRIPT"
    echo "📝 Network hardening script created at: $HARDENING_SCRIPT"
    echo
}

# Main execution
main() {
    check_privileges
    audit_disks
    audit_nfs
    audit_samba
    audit_afp
    audit_network_services
    audit_wifi_network
    audit_file_sharing
    audit_ftp_services
    audit_remote_access
    generate_recommendations
    create_network_hardening_script
    
    echo "=== AUDIT COMPLETED ==="
    echo
    echo "📊 Summary:"
    echo "  • Disk configurations audited"
    echo "  • NFS/Samba services checked"
    echo "  • Network services analyzed"
    echo "  • WiFi configuration reviewed"
    echo "  • File sharing services audited"
    echo "  • Remote access services checked"
    echo "  • Network hardening script generated"
    echo
    echo "🔍 Next steps:"
    echo "  1. Review the audit results above"
    echo "  2. Disable unnecessary network services"
    echo "  3. Configure Parallels for controlled virtualization"
    echo "  4. Set up local domain within Parallels environment"
    echo "  5. Run the network hardening script if needed"
    echo
    echo "⚠️  Remember: Always test network connectivity after making changes!"
}

# Run main function
main "$@"
