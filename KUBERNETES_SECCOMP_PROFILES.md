# Kubernetes Seccomp Profiles

This document describes the dedicated seccomp profiles for Kubernetes components and workloads, designed to provide enhanced security for containerized applications.

## Overview

Seccomp (Secure Computing Mode) is a Linux kernel feature that restricts the system calls available to a process. These Kubernetes-specific profiles are tailored for different types of workloads and system components.

## Profile Types

### 1. Kubelet Profile (`seccomp-kubelet-profile.json`)

**Purpose**: Kubernetes kubelet component profile
**Default Action**: `SCMP_ACT_ERRNO` (deny by default)
**Use Case**: Kubelet daemon running on worker nodes

**Features**:
- Allows all common system calls needed for container management
- Allows process management (fork, execve, ptrace)
- Allows filesystem operations (chroot, mount operations)
- Allows capability management (capget, capset)
- Allows seccomp system calls for nested container security
- **Denies dangerous operations** (kernel modules, reboot, BPF)

**Usage**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubelet-secure
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/kubernetes/seccomp-kubelet-profile.json
  containers:
  - name: kubelet
    image: k8s.gcr.io/kubelet:v1.28.0
```

### 2. Kube-proxy Profile (`seccomp-kube-proxy-profile.json`)

**Purpose**: Kubernetes kube-proxy component profile
**Default Action**: `SCMP_ACT_ERRNO` (deny by default)
**Use Case**: Kube-proxy daemon for service networking

**Features**:
- Allows network operations (socket, bind, listen, connect)
- Allows process management for network handling
- Allows filesystem operations for configuration
- **Denies dangerous operations** (chroot, ptrace, BPF, kernel modules)

**Usage**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-proxy-secure
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/kubernetes/seccomp-kube-proxy-profile.json
  containers:
  - name: kube-proxy
    image: k8s.gcr.io/kube-proxy:v1.28.0
```

### 3. Web Application Profile (`seccomp-k8s-webapp-profile.json`)

**Purpose**: Web application workload profile
**Default Action**: `SCMP_ACT_ERRNO` (deny by default)
**Use Case**: Web servers, APIs, microservices

**Features**:
- Allows HTTP server operations (socket, bind, listen, accept)
- Allows file I/O for serving content
- Allows process management for request handling
- **Denies dangerous operations** (capabilities, chroot, ptrace, BPF)

**Usage**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-secure
spec:
  template:
    spec:
      securityContext:
        seccompProfile:
          type: Localhost
          localhostProfile: profiles/kubernetes/seccomp-k8s-webapp-profile.json
      containers:
      - name: webapp
        image: nginx:1.21
```

### 4. Database Profile (`seccomp-k8s-database-profile.json`)

**Purpose**: Database workload profile
**Default Action**: `SCMP_ACT_ERRNO` (deny by default)
**Use Case**: MySQL, PostgreSQL, MongoDB, Redis

**Features**:
- Allows database operations (file I/O, memory management)
- Allows network operations for client connections
- Allows process management for query handling
- **Denies dangerous operations** (capabilities, chroot, ptrace, BPF)

**Usage**:
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql-secure
spec:
  template:
    spec:
      securityContext:
        seccompProfile:
          type: Localhost
          localhostProfile: profiles/kubernetes/seccomp-k8s-database-profile.json
      containers:
      - name: mysql
        image: mysql:8.0
```

### 5. System Profile (`seccomp-k8s-system-profile.json`)

**Purpose**: System-level workload profile
**Default Action**: `SCMP_ACT_ERRNO` (deny by default)
**Use Case**: System daemons, monitoring, logging

**Features**:
- Allows system operations (process management, filesystem)
- Allows capability management (capget, capset)
- Allows seccomp operations for nested security
- Allows ptrace for debugging and monitoring
- **Denies dangerous operations** (kernel modules, reboot, BPF)

**Usage**:
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: system-monitor-secure
spec:
  template:
    spec:
      securityContext:
        seccompProfile:
          type: Localhost
          localhostProfile: profiles/kubernetes/seccomp-k8s-system-profile.json
      containers:
      - name: system-monitor
        image: prom/node-exporter:v1.6.0
```

## Installation

The profiles are automatically installed by the SELinux compilation script:

```bash
sudo ./scripts/compile-selinux-policies.sh
```

This installs all profiles to `/usr/share/seccomp/profiles/kubernetes/`.

## Security Considerations

### Default Action: SCMP_ACT_ERRNO

All Kubernetes profiles use `SCMP_ACT_ERRNO` as the default action, which:
- **Denies unknown system calls** by default
- **Provides strong security** against new attack vectors
- **Requires explicit allow lists** for all needed operations
- **Prevents privilege escalation** through unknown syscalls

### Explicit Allow Lists

Each profile includes comprehensive allow lists for:
- **Common system calls**: read, write, open, close, etc.
- **Process management**: fork, execve, wait, kill, etc.
- **Network operations**: socket, bind, listen, connect, etc.
- **Filesystem operations**: stat, chmod, chown, etc.
- **Memory management**: mmap, munmap, mprotect, etc.

### Explicit Deny Lists

All profiles explicitly deny dangerous operations:
- **Kernel modules**: init_module, delete_module, finit_module
- **System control**: reboot, kexec_load, kexec_file_load
- **Advanced debugging**: BPF, perf_event_open
- **Container escape**: chroot (where not needed), ptrace (where not needed)

## Integration with Kubernetes

### Pod Security Standards

These profiles align with Kubernetes Pod Security Standards:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-workloads
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### Security Context

Apply profiles at the pod or container level:

```yaml
# Pod-level security context
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/kubernetes/seccomp-k8s-webapp-profile.json

# Container-level security context
spec:
  containers:
  - name: app
    securityContext:
      seccompProfile:
        type: Localhost
        localhostProfile: profiles/kubernetes/seccomp-k8s-webapp-profile.json
```

### Admission Controllers

Use admission controllers to enforce seccomp profiles:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionWebhook
metadata:
  name: seccomp-enforcer
spec:
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
```

## Monitoring and Auditing

### Audit Logs

Seccomp violations are logged to `/var/log/audit.log`:

```bash
# Monitor seccomp violations
sudo tail -f /var/log/audit.log | grep seccomp

# Check for specific violations
sudo ausearch -k seccomp_violation
```

### Metrics

Monitor seccomp violations with Prometheus:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: seccomp-metrics
data:
  seccomp-metrics.yaml: |
    groups:
    - name: seccomp
      rules:
      - alert: SeccompViolation
        expr: increase(seccomp_violations_total[5m]) > 10
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "High seccomp violation rate detected"
```

## Troubleshooting

### Common Issues

1. **Application fails to start**
   - Check if required system calls are in the allow list
   - Review audit logs for denied syscalls
   - Consider using a more permissive profile temporarily

2. **Performance degradation**
   - Monitor system call overhead
   - Consider optimizing the allow list
   - Use profiling tools to identify bottlenecks

3. **Debugging difficulties**
   - Use the system profile for debugging
   - Enable ptrace in the profile if needed
   - Consider temporary profile relaxation

### Testing Profiles

Test profiles before production deployment:

```bash
# Test with a simple container
docker run --security-opt seccomp=seccomp-k8s-webapp-profile.json nginx:1.21

# Test with Kubernetes
kubectl run test-pod --image=nginx:1.21 --overrides='
{
  "spec": {
    "securityContext": {
      "seccompProfile": {
        "type": "Localhost",
        "localhostProfile": "profiles/kubernetes/seccomp-k8s-webapp-profile.json"
      }
    }
  }
}'
```

## Best Practices

1. **Start with restrictive profiles** and relax as needed
2. **Monitor audit logs** for violations and adjust profiles
3. **Use different profiles** for different workload types
4. **Test thoroughly** before production deployment
5. **Document exceptions** and justify any profile relaxations
6. **Regular review** of profiles for security and functionality
7. **Automate profile deployment** through CI/CD pipelines

## Profile Maintenance

### Updates

Regularly update profiles to:
- Add new system calls as needed
- Remove unused system calls
- Address security vulnerabilities
- Improve performance

### Version Control

All profiles are version controlled and should be:
- Reviewed before changes
- Tested in non-production environments
- Documented with change reasons
- Rolled back if issues occur

## Conclusion

These Kubernetes seccomp profiles provide a strong security foundation for containerized workloads while maintaining functionality. They follow the principle of least privilege and provide comprehensive protection against system call-based attacks.

For questions or issues, refer to the audit logs and consider the troubleshooting section above.
