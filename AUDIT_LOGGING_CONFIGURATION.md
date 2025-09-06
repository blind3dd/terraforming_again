# Audit Logging Configuration

This document explains the comprehensive audit logging setup for the secure infrastructure.

## Log File Locations

### 1. `/var/log/audit.log` - Audit Daemon Logs
- **Purpose**: System audit events from the Linux audit daemon
- **Content**: All system calls, file access, authentication attempts, privilege escalations
- **Format**: RAW audit format
- **Permissions**: `600` (root read/write only)
- **Rotation**: Automatic (6 files, rotates when full)

### 2. `/var/log/secure` - Authentication Logs
- **Purpose**: Authentication and security-related events
- **Content**: SSH logins, sudo usage, authentication failures, system access
- **Format**: Standard syslog format
- **Permissions**: `640` (root read/write, group read)
- **Rotation**: Managed by logrotate

## What Gets Logged

### Authentication Events
- **SSH connections** - All SSH login attempts and connections
- **SSSD events** - Directory service authentication
- **PAM events** - Pluggable Authentication Module events
- **Login/logout** - User session management
- **Sudo usage** - Privilege escalation attempts
- **Polkit events** - PolicyKit privilege requests and authentication

### Security Events
- **SUID/SGID operations** - Set user/group ID file operations
- **File permission changes** - Dangerous permission modifications
- **Privilege escalation** - Unauthorized privilege escalation attempts
- **System configuration changes** - Critical system file modifications

### System Events
- **Service starts/stops** - System service management
- **Configuration changes** - System configuration modifications
- **User management** - User account creation/modification
- **Network access** - Network connection attempts

## Log Monitoring Commands

### View Recent Events
```bash
# View recent audit events
tail -f /var/log/audit.log

# View recent authentication events
tail -f /var/log/secure

# View both logs simultaneously
tail -f /var/log/audit.log /var/log/secure
```

### Search for Specific Events
```bash
# Search for SUID file creation attempts
grep "suid_file_creation" /var/log/audit.log

# Search for privilege escalation attempts
grep "privilege_escalation" /var/log/audit.log

# Search for SSH connection attempts
grep "sshd_connect" /var/log/audit.log

# Search for failed login attempts
grep "Failed password" /var/log/secure

# Search for sudo usage
grep "sudo" /var/log/secure

# Search for Polkit privilege requests
grep "polkit_dbus" /var/log/audit.log

# Search for Polkit authentication events
grep "polkit" /var/log/secure
```

### Advanced Log Analysis
```bash
# Count authentication failures by user
grep "Failed password" /var/log/secure | awk '{print $9}' | sort | uniq -c

# Find all SUID file creation attempts
grep "suid_file_creation" /var/log/audit.log | awk '{print $1, $2, $3}'

# Count Polkit privilege requests by user
grep "polkit_dbus_send" /var/log/audit.log | awk '{print $15}' | sort | uniq -c

# Monitor real-time authentication events
journalctl -f -u sshd -u auditd -u polkit

# View audit rules
auditctl -l

# Check audit daemon status
systemctl status auditd
```

## Log Rotation and Management

### Audit Log Rotation
- **Automatic rotation** when log reaches maximum size
- **6 log files** maintained (audit.log, audit.log.1, audit.log.2, etc.)
- **Space management** with alerts and suspension

### Secure Log Rotation
- **Managed by logrotate** with standard rotation policies
- **Compression** of old log files
- **Retention** based on time and size

### Manual Log Management
```bash
# Rotate audit logs manually
auditctl -r

# Clear audit logs (use with caution)
> /var/log/audit.log

# Archive old logs
tar -czf audit-logs-$(date +%Y%m%d).tar.gz /var/log/audit.log.*
```

## Security Considerations

### Log File Permissions
- **Audit logs**: `600` (root only) - Maximum security
- **Secure logs**: `640` (root read/write, group read) - Standard security
- **No world access** to any log files

### Log Integrity
- **Immutable logs** - Log files cannot be modified by users
- **Audit trail** - All log access is itself logged
- **Tamper detection** - File modification attempts are logged

### Log Monitoring
- **Real-time alerts** for critical security events
- **Automated analysis** of log patterns
- **Forensic capabilities** for incident investigation

## Integration with Security Tools

### SIEM Integration
- **Log forwarding** to SIEM systems
- **Structured logging** for automated analysis
- **Alert correlation** across multiple log sources

### Monitoring Tools
- **Prometheus metrics** from log analysis
- **Grafana dashboards** for log visualization
- **AlertManager** for critical event notifications

### Compliance
- **Audit requirements** - Meets compliance standards
- **Retention policies** - Configurable log retention
- **Access controls** - Restricted log access

## Troubleshooting

### Common Issues

1. **Log files not being created**
   ```bash
   # Check audit daemon status
   systemctl status auditd
   
   # Check audit rules
   auditctl -l
   
   # Restart audit daemon
   systemctl restart auditd
   ```

2. **Permission denied errors**
   ```bash
   # Check file permissions
   ls -la /var/log/audit.log /var/log/secure
   
   # Fix permissions if needed
   chmod 600 /var/log/audit.log
   chmod 640 /var/log/secure
   ```

3. **Disk space issues**
   ```bash
   # Check disk usage
   df -h /var/log
   
   # Check log file sizes
   ls -lh /var/log/audit.log* /var/log/secure*
   
   # Clean old logs if needed
   find /var/log -name "*.log.*" -mtime +30 -delete
   ```

### Log Analysis Tools
```bash
# Install log analysis tools
yum install -y auditd-utils

# Use ausearch for audit log analysis
ausearch -k suid_file_creation
ausearch -k privilege_escalation
ausearch -k sshd_connect

# Use aureport for audit reports
aureport --summary
aureport --failed
aureport --login
```

## Best Practices

### Log Monitoring
- **Regular review** of log files
- **Automated analysis** for patterns
- **Alert on anomalies** and security events

### Log Security
- **Secure storage** of log files
- **Backup procedures** for log retention
- **Access controls** for log viewing

### Performance
- **Log rotation** to prevent disk space issues
- **Efficient filtering** to reduce noise
- **Optimized rules** for better performance

## Configuration Files

### Audit Daemon Configuration
- **File**: `/etc/audit/auditd.conf`
- **Purpose**: Configure audit daemon behavior
- **Key settings**: Log file location, rotation, space management

### Audit Rules
- **File**: `/etc/audit/rules.d/`
- **Purpose**: Define what events to audit
- **Key rules**: Authentication, privilege escalation, file access

### Logrotate Configuration
- **File**: `/etc/logrotate.d/`
- **Purpose**: Configure log rotation policies
- **Key settings**: Rotation frequency, retention, compression

This comprehensive logging setup provides complete visibility into system security events and ensures compliance with security best practices.
