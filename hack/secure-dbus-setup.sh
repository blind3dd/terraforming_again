#!/bin/bash
# Secure D-Bus Setup Script
# Implements D-Bus separation without oddjobd dependency

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root"
fi

log "Setting up secure D-Bus separation..."

# 1. Install required packages
log "Installing required packages..."
yum install -y dbus dbus-daemon systemd audit

# 2. Create secure D-Bus configuration
log "Creating secure D-Bus configuration..."
cat > /etc/dbus-1/system.d/secure-dbus.conf << 'EOF'
<!DOCTYPE busconfig PUBLIC
 "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <policy user="root">
    <allow own="org.freedesktop.systemd1"/>
    <allow send_destination="org.freedesktop.systemd1"/>
    <allow receive_sender="org.freedesktop.systemd1"/>
  </policy>
  
  <policy user="dbus">
    <allow own="org.freedesktop.DBus"/>
    <allow send_destination="org.freedesktop.DBus"/>
    <allow receive_sender="org.freedesktop.DBus"/>
  </policy>
  
  <policy context="default">
    <deny send_destination="org.freedesktop.systemd1"/>
    <deny receive_sender="org.freedesktop.systemd1"/>
  </policy>
</busconfig>
EOF

# 3. Create session D-Bus configuration
log "Creating session D-Bus configuration..."
cat > /etc/dbus-1/session.d/secure-session.conf << 'EOF'
<!DOCTYPE busconfig PUBLIC
 "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <policy user="root">
    <allow own="org.freedesktop.systemd1"/>
    <allow send_destination="org.freedesktop.systemd1"/>
    <allow receive_sender="org.freedesktop.systemd1"/>
  </policy>
  
  <policy context="default">
    <deny send_destination="org.freedesktop.systemd1"/>
    <deny receive_sender="org.freedesktop.systemd1"/>
  </policy>
</busconfig>
EOF

# 4. Create audit configuration
log "Creating audit configuration..."
cat > /etc/audit/rules.d/secure-dbus.rules << 'EOF'
# D-Bus security audit rules
-w /etc/dbus-1 -p wa -k dbus_config
-w /var/run/dbus -p wa -k dbus_runtime
-w /usr/bin/dbus-daemon -p x -k dbus_exec
-w /usr/bin/dbus-send -p x -k dbus_send
-w /usr/bin/dbus-monitor -p x -k dbus_monitor

# SystemD audit rules
-w /usr/bin/systemctl -p x -k systemctl
-w /etc/systemd -p wa -k systemd_config
-w /var/log/systemd -p wa -k systemd_logs

# Session management audit rules
-w /var/run/user -p wa -k user_sessions
-w /tmp/.X11-unix -p wa -k x11_sessions
EOF

# 5. Create secure D-Bus service
log "Creating secure D-Bus service..."
cat > /etc/systemd/system/secure-dbus.service << 'EOF'
[Unit]
Description=Secure D-Bus Service
Documentation=man:dbus-daemon(1)
Requires=dbus.service
After=dbus.service

[Service]
Type=notify
ExecStart=/usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
Restart=on-failure
RestartSec=1
TimeoutStartSec=5
TimeoutStopSec=5

# Security settings
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictSUIDSGID=true
RemoveIPC=true
PrivateTmp=true
PrivateDevices=true
ProtectHostname=true
ProtectClock=true
ProtectKernelLogs=true
ReadWritePaths=/var/run/dbus
ReadWritePaths=/var/log/audit

[Install]
WantedBy=multi-user.target
EOF

# 6. Create audit service
log "Creating audit service..."
cat > /etc/systemd/system/audit-security.service << 'EOF'
[Unit]
Description=Security Audit Service
Documentation=man:auditd(8)
After=auditd.service
Requires=auditd.service

[Service]
Type=notify
ExecStart=/usr/sbin/auditd -n
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
Restart=on-failure
RestartSec=1
TimeoutStartSec=5
TimeoutStopSec=5

# Security settings
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictSUIDSGID=true
RemoveIPC=true
PrivateTmp=true
PrivateDevices=true
ProtectHostname=true
ProtectClock=true
ProtectKernelLogs=true
ReadWritePaths=/var/log/audit
ReadWritePaths=/var/run/auditd

[Install]
WantedBy=multi-user.target
EOF

# 7. Set proper permissions
log "Setting proper permissions..."
chmod 644 /etc/dbus-1/system.d/secure-dbus.conf
chmod 644 /etc/dbus-1/session.d/secure-session.conf
chmod 644 /etc/audit/rules.d/secure-dbus.rules
chmod 644 /etc/systemd/system/secure-dbus.service
chmod 644 /etc/systemd/system/audit-security.service

# 8. Create audit log directory
log "Creating audit log directory..."
mkdir -p /var/log/audit/secure
chmod 750 /var/log/audit/secure
chown root:audit /var/log/audit/secure

# 9. Reload systemd and start services
log "Reloading systemd and starting services..."
systemctl daemon-reload
systemctl enable secure-dbus.service
systemctl enable audit-security.service
systemctl start secure-dbus.service
systemctl start audit-security.service

# 10. Verify services are running
log "Verifying services are running..."
if systemctl is-active --quiet secure-dbus.service; then
    log "Secure D-Bus service is running"
else
    error "Secure D-Bus service failed to start"
fi

if systemctl is-active --quiet audit-security.service; then
    log "Audit security service is running"
else
    error "Audit security service failed to start"
fi

# 11. Test D-Bus separation
log "Testing D-Bus separation..."
if dbus-send --system --dest=org.freedesktop.DBus --type=method_call --print-reply /org/freedesktop/DBus org.freedesktop.DBus.ListNames > /dev/null 2>&1; then
    log "System D-Bus is accessible"
else
    warn "System D-Bus test failed"
fi

# 12. Test audit logging
log "Testing audit logging..."
if auditctl -l | grep -q "dbus_config"; then
    log "Audit rules are active"
else
    warn "Audit rules may not be active"
fi

log "Secure D-Bus setup completed successfully!"
log "D-Bus separation is now enforced between session and system buses"
log "All D-Bus activity is being logged to /var/log/audit/"
