# Polkit (PolicyKit) Security Configuration

This document explains the comprehensive Polkit security setup for the secure infrastructure.

## What is Polkit?

**Polkit (PolicyKit)** is a toolkit for defining and handling the policy that allows unprivileged processes to speak to privileged processes. It provides a centralized way to define and manage system-wide privileges and permissions.

## Security Importance

### Why Polkit Security Matters
- **Privilege Control**: Controls which users can perform privileged operations
- **System Integration**: Manages interactions between unprivileged and privileged processes
- **D-Bus Security**: Secures D-Bus communication for privilege requests
- **Authentication**: Handles authentication for privileged operations
- **Audit Trail**: Provides logging for privilege escalation attempts

### Security Risks Without Proper Polkit Configuration
- **Unauthorized privilege escalation** through D-Bus
- **Bypass of authentication** for system operations
- **Uncontrolled access** to system resources
- **Lack of audit trail** for privilege requests
- **Potential for privilege escalation attacks**

## Polkit Security Components

### 1. SELinux Policy (`polkit_security.te`)
- **Purpose**: Controls Polkit daemon access and operations
- **Key Features**:
  - Restricts Polkit configuration access
  - Controls D-Bus communication
  - Prevents unauthorized service transitions
  - Manages log file access

### 2. Audit Rules (`polkit-audit.conf`)
- **Purpose**: Monitors Polkit-related security events
- **Key Events**:
  - Privilege escalation requests
  - Configuration changes
  - D-Bus communication
  - Authentication attempts

### 3. File Contexts
- **Polkit Logs**: `/var/log/polkit` (polkitd_log_t)
- **Polkit Config**: `/etc/polkit-1` (polkitd_config_t)
- **Rules Directory**: `/etc/polkit-1/rules.d/`

## Polkit Configuration Files

### Main Configuration
- **File**: `/etc/polkit-1/localauthority/50-local.d/`
- **Purpose**: Local Polkit configuration
- **Security**: Restrict access to root only

### Rules Directory
- **File**: `/etc/polkit-1/rules.d/`
- **Purpose**: Custom Polkit rules
- **Security**: Monitor for unauthorized changes

### Actions Directory
- **File**: `/usr/share/polkit-1/actions/`
- **Purpose**: System-wide Polkit actions
- **Security**: Monitor for modifications

## Security Rules and Policies

### Default Polkit Rules
```javascript
// Example: Restrict network configuration to admin users
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.settings.modify.own" ||
        action.id == "org.freedesktop.NetworkManager.settings.modify.system") {
        if (subject.isInGroup("admin")) {
            return polkit.Result.YES;
        } else {
            return polkit.Result.NO;
        }
    }
});
```

### Restrictive Polkit Configuration
```javascript
// Deny all actions by default
polkit.addRule(function(action, subject) {
    return polkit.Result.NO;
});

// Allow specific actions for specific users/groups
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
    return polkit.Result.NO;
});
```

## Monitoring and Auditing

### Key Events to Monitor
1. **Privilege Requests**: All Polkit privilege escalation attempts
2. **Configuration Changes**: Modifications to Polkit rules
3. **D-Bus Communication**: Polkit D-Bus message exchanges
4. **Authentication Events**: Polkit authentication attempts
5. **Service Management**: System service start/stop requests

### Audit Commands
```bash
# View Polkit audit events
grep "polkit" /var/log/audit.log

# Monitor privilege escalation requests
grep "polkit_dbus" /var/log/audit.log

# Check Polkit configuration changes
grep "polkit_config" /var/log/audit.log

# View Polkit service status
systemctl status polkit

# Check Polkit rules
ls -la /etc/polkit-1/rules.d/
```

### Log Analysis
```bash
# Count privilege escalation attempts by user
grep "polkit_dbus_send" /var/log/audit.log | awk '{print $15}' | sort | uniq -c

# Find failed privilege requests
grep "polkit.*NO" /var/log/secure

# Monitor real-time Polkit events
journalctl -f -u polkit
```

## Security Best Practices

### 1. Principle of Least Privilege
- **Deny by default**: Start with restrictive policies
- **Explicit allow**: Only grant necessary permissions
- **Regular review**: Audit and update rules regularly

### 2. Authentication Requirements
- **Strong authentication**: Require authentication for privileged operations
- **Session management**: Control session-based privileges
- **Timeout policies**: Implement privilege timeouts

### 3. Monitoring and Logging
- **Comprehensive logging**: Log all privilege requests
- **Real-time monitoring**: Monitor for suspicious activity
- **Regular audits**: Review logs for security issues

### 4. Configuration Security
- **File permissions**: Restrict access to configuration files
- **Integrity checking**: Monitor for unauthorized changes
- **Backup policies**: Maintain secure backups

## Common Polkit Actions

### System Management
- **Service Control**: Start/stop system services
- **User Management**: Create/modify user accounts
- **Network Configuration**: Modify network settings
- **Package Management**: Install/remove software

### Hardware Access
- **Storage Devices**: Mount/unmount storage
- **Network Interfaces**: Configure network hardware
- **Power Management**: Shutdown/restart system
- **Device Access**: Access hardware devices

### Security Operations
- **Firewall Management**: Configure firewall rules
- **Authentication**: Modify authentication settings
- **Audit Configuration**: Change audit settings
- **SELinux Management**: Modify SELinux policies

## Troubleshooting

### Common Issues

1. **Polkit daemon not running**
   ```bash
   # Check status
   systemctl status polkit
   
   # Start service
   systemctl start polkit
   
   # Enable at boot
   systemctl enable polkit
   ```

2. **Permission denied errors**
   ```bash
   # Check Polkit rules
   ls -la /etc/polkit-1/rules.d/
   
   # Check user groups
   groups $USER
   
   # Test specific action
   pkaction --action-id org.freedesktop.systemd1.manage-units
   ```

3. **D-Bus communication issues**
   ```bash
   # Check D-Bus status
   systemctl status dbus
   
   # Restart D-Bus
   systemctl restart dbus
   
   # Check Polkit D-Bus interface
   dbus-send --system --dest=org.freedesktop.PolicyKit1 \
     --type=method_call --print-reply \
     /org/freedesktop/PolicyKit1/Authority \
     org.freedesktop.PolicyKit1.Authority.GetBackendName
   ```

### Debug Commands
```bash
# Enable Polkit debugging
export POLKIT_DEBUG=1

# Check Polkit configuration
pkcheck --action-id org.freedesktop.systemd1.manage-units --process $$

# List all available actions
pkaction

# Check specific user permissions
pkcheck --user $USER --action-id org.freedesktop.systemd1.manage-units
```

## Integration with Other Security Components

### SELinux Integration
- **Polkit daemon runs in polkitd_t domain**
- **Restricted access to system resources**
- **Audit logging for all operations**

### Audit Integration
- **Comprehensive audit rules for Polkit events**
- **Integration with system audit daemon**
- **Log correlation with other security events**

### D-Bus Security
- **Secure D-Bus communication**
- **Authentication for privilege requests**
- **Message filtering and validation**

## Compliance and Standards

### Security Standards
- **CIS Controls**: Aligns with privilege management controls
- **NIST Guidelines**: Follows privilege escalation prevention
- **ISO 27001**: Supports access control requirements

### Audit Requirements
- **Comprehensive logging**: Meets audit trail requirements
- **Access controls**: Implements proper access restrictions
- **Monitoring**: Provides security event monitoring

## Performance Considerations

### Optimization
- **Efficient rule evaluation**: Optimize Polkit rules for performance
- **Caching**: Use appropriate caching for authentication
- **Resource management**: Monitor Polkit resource usage

### Monitoring
- **Performance metrics**: Track Polkit performance
- **Resource usage**: Monitor memory and CPU usage
- **Response times**: Measure privilege request response times

This comprehensive Polkit security configuration provides robust protection against unauthorized privilege escalation while maintaining system functionality and providing complete audit trails for security monitoring.
