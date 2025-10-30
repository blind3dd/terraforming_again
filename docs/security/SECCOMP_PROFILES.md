# Seccomp Security Profiles

This document describes the different seccomp (Secure Computing Mode) profiles available for different use cases.

## Overview

Seccomp profiles provide system call filtering to enhance security by restricting which system calls a process can make. We provide different profiles for different security requirements and use cases.

## Available Profiles

### 1. Default Profile (`seccomp-profiles.json`)

**Purpose**: General-purpose profile for most applications
**Default Action**: `SCMP_ACT_ERRNO` (deny by default)
**Use Case**: Standard applications, services, and user processes

**Features**:
- Allows common system calls (read, write, open, etc.)
- Denies dangerous system calls (mount, chroot, setuid, etc.)
- Blocks privilege escalation attempts
- Prevents kernel module operations
- Blocks BPF and performance monitoring

**When to Use**:
- Standard applications
- Web servers
- Database services
- User applications
- Most system services

### 2. Bastion Profile (`seccomp-bastion-profile.json`)

**Purpose**: Bastion host and jump server profile
**Default Action**: `SCMP_ACT_ERRNO` (deny by default)
**Use Case**: Jump hosts, bastion servers, secure access points

**Features**:
- Allows all common system calls
- Allows filesystem mounting operations
- Allows chroot operations
- Allows privilege escalation system calls
- Allows capability setting
- Allows process tracing (ptrace)
- Allows kernel module operations
- Allows BPF system calls
- Allows performance monitoring
- **Denies system reboot** (too dangerous even for bastion)

**When to Use**:
- Jump hosts and bastion servers
- Secure access points
- Administrative access points
- VPN servers
- System maintenance interfaces

### 3. Root Profile (`seccomp-root-profile.json`)

**Purpose**: Root user operations profile
**Default Action**: `SCMP_ACT_ALLOW` (allow by default)
**Use Case**: Root user operations, system-level tasks

**Features**:
- Allows all system calls by default
- Denies only the most dangerous operations (reboot, kernel execution)
- Minimal restrictions for root operations
- **Denies system reboot** (require explicit approval)

**When to Use**:
- Root user operations
- System-level administration
- Kernel development
- System recovery operations

### 4. Container Profile (`seccomp-container-profile.json`)

**Purpose**: Highly restrictive profile for containers
**Default Action**: `SCMP_ACT_ERRNO` (deny by default)
**Use Case**: Containerized applications, microservices

**Features**:
- Allows only essential system calls
- Denies all dangerous system calls
- Denies filesystem mounting
- Denies chroot operations
- Denies privilege escalation
- Denies capability setting
- Denies process tracing
- Denies kernel module operations
- Denies BPF system calls
- Denies performance monitoring

**When to Use**:
- Docker containers
- Kubernetes pods
- Microservices
- Isolated applications
- High-security environments

## Usage Examples

### Docker Container

```bash
# Use container profile for maximum security
docker run --security-opt seccomp=seccomp-container-profile.json myapp

# Use default profile for standard applications
docker run --security-opt seccomp=seccomp-profiles.json myapp

# Use bastion profile for jump hosts
docker run --security-opt seccomp=seccomp-bastion-profile.json bastion-host

# Use root profile for root operations
docker run --security-opt seccomp=seccomp-root-profile.json --user root admin-tool
```

### Kubernetes Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: seccomp-container-profile.json
  containers:
  - name: app
    image: myapp:latest
```

### System Service

```bash
# Apply bastion profile for jump host services
systemd-run --property=SystemCallFilter=@seccomp-bastion-profile.json bastion-service

# Apply root profile for root services
systemd-run --property=SystemCallFilter=@seccomp-root-profile.json root-service
```

## Security Considerations

### Bastion Profile Risks

The bastion profile allows many privileged operations:
- **Privilege escalation**: setuid, setgid, etc.
- **System modification**: mount, chroot, etc.
- **Kernel operations**: module loading, BPF, etc.
- **Process control**: ptrace, kill, etc.

**Mitigation**:
- Only use for legitimate administrative tasks
- Monitor usage through audit logs
- Use SELinux to restrict access
- Implement proper authentication

### Container Profile Benefits

The container profile provides maximum security:
- **Minimal attack surface**: Only essential system calls
- **No privilege escalation**: Cannot gain root access
- **No system modification**: Cannot modify host system
- **Isolation**: Cannot access host resources

### Default Profile Balance

The default profile provides a good balance:
- **Functional**: Allows normal application operation
- **Secure**: Blocks dangerous operations
- **Flexible**: Can be customized for specific needs

## Monitoring and Auditing

All seccomp profiles are monitored through audit logs:

```bash
# Monitor seccomp violations
grep "seccomp" /var/log/audit.log

# Monitor seccomp profile loading
grep "seccomp_config" /var/log/audit.log

# Monitor seccomp filter installation
grep "seccomp_install" /var/log/audit.log
```

## Customization

Profiles can be customized for specific needs:

1. **Add system calls**: Add to the "names" array
2. **Remove system calls**: Remove from the "names" array
3. **Change actions**: Modify the "action" field
4. **Add conditions**: Use "args" for conditional filtering

## Best Practices

1. **Start restrictive**: Begin with container profile, relax as needed
2. **Test thoroughly**: Ensure applications work with chosen profile
3. **Monitor violations**: Watch audit logs for blocked system calls
4. **Document exceptions**: Keep track of why certain system calls are allowed
5. **Regular review**: Periodically review and update profiles
6. **Use least privilege**: Only allow system calls that are actually needed

## Troubleshooting

### Common Issues

1. **Application fails to start**: Check if required system calls are blocked
2. **Performance issues**: Some system calls may be needed for optimization
3. **Debugging problems**: Admin profile may be needed for troubleshooting

### Debugging Commands

```bash
# Check seccomp status
cat /proc/self/status | grep Seccomp

# Monitor seccomp violations
dmesg | grep seccomp

# Test system call filtering
strace -e trace=all your-application
```

## Conclusion

Choose the appropriate seccomp profile based on your security requirements:

- **Container Profile**: Maximum security for containers
- **Default Profile**: Balanced security for most applications
- **Bastion Profile**: Jump hosts and secure access points
- **Root Profile**: Root user operations and system administration

Remember that seccomp is just one layer of security. Combine with SELinux, capabilities, and other security measures for defense in depth.
