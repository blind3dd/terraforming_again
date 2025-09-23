# macOS Kubernetes Security Quick Reference

## Quick Setup

```bash
# Run the simple security script
./scripts/simple-macos-k8s-security.sh

# Validate your security configuration
validate-k8s-security

# Monitor for security events
~/security-monitor.sh
```

## Key Security Features

### 1. ImpersonationFilter
- **Prevents**: Unauthorized user/group/service account impersonation
- **Configuration**: Disabled by default, fail-closed on attempts
- **Monitoring**: All impersonation attempts logged

### 2. Pod Security Standards
- **Namespace**: `secure-workloads` with restricted enforcement
- **Features**: Non-root containers, read-only filesystems, dropped capabilities
- **Usage**: Deploy sensitive workloads in this namespace

### 3. Network Policies
- **Default**: Deny all ingress/egress traffic
- **Scope**: Applied to `default` and `secure-workloads` namespaces
- **Benefit**: Prevents lateral movement and data exfiltration

### 4. RBAC (Role-Based Access Control)
- **Principle**: Least privilege access
- **Scope**: Minimal permissions for local development
- **Monitoring**: All RBAC changes audited

## Usage Examples

### Deploy Secure Application
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: secure-workloads
spec:
  template:
    spec:
      # Pod-level security context
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
      containers:
      - name: app
        image: nginx:1.21
        # Container-level security context
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          runAsGroup: 1000
          capabilities:
            drop:
            - ALL
          seccompProfile:
            type: RuntimeDefault
        volumeMounts:
        - name: tmp
          mountPath: /tmp
      volumes:
      - name: tmp
        emptyDir: {}
```

### Using Custom Seccomp Profiles
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app-custom
  namespace: secure-workloads
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
      containers:
      - name: app
        image: nginx:1.21
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
          # Use our custom seccomp profile
          seccompProfile:
            type: Localhost
            localhostProfile: profiles/kubernetes/seccomp-k8s-webapp-profile.json
```

### Check Security Status
```bash
# Validate security configuration
validate-k8s-security

# Check for impersonation attempts
kubectl logs -n kube-system | grep -i "impersonate"

# Check network policies
kubectl get networkpolicy --all-namespaces

# Check Pod Security Standards
kubectl get namespace secure-workloads -o yaml | grep pod-security
```

## Security Best Practices

1. **Use secure-workloads namespace** for sensitive applications
2. **Run containers as non-root** with dropped capabilities
3. **Use read-only root filesystems** where possible
4. **Apply network policies** to restrict traffic
5. **Monitor audit logs** for suspicious activity
6. **Keep Kubernetes updated** regularly
7. **Use trusted container images** only

## Troubleshooting

### Common Issues

1. **Pod Creation Fails**
   ```bash
   # Check Pod Security Standards compliance
   kubectl describe pod <pod-name> -n secure-workloads
   
   # Check if container runs as non-root
   kubectl get pod <pod-name> -o yaml | grep runAsUser
   ```

2. **Network Connectivity Issues**
   ```bash
   # Check network policies
   kubectl get networkpolicy -n <namespace>
   
   # Test connectivity
   kubectl exec -it <pod-name> -- ping <target>
   ```

3. **Permission Denied Errors**
   ```bash
   # Check RBAC configuration
   kubectl get clusterrole macos-restricted-user
   kubectl get clusterrolebinding macos-user-binding
   
   # Check audit logs
   kubectl logs -n kube-system | grep -i "unauthorized"
   ```

### Emergency Procedures

#### Disable Security (Emergency Only)
```bash
# Remove network policies
kubectl delete networkpolicy default-deny-all -n default
kubectl delete networkpolicy default-deny-all -n secure-workloads

# Remove Pod Security Standards
kubectl label namespace secure-workloads pod-security.kubernetes.io/enforce-
kubectl label namespace secure-workloads pod-security.kubernetes.io/audit-
kubectl label namespace secure-workloads pod-security.kubernetes.io/warn-
```

#### Re-enable Security
```bash
# Re-run the security script
./scripts/simple-macos-k8s-security.sh
```

## Monitoring Commands

```bash
# Monitor for impersonation attempts
kubectl logs -n kube-system --follow | grep -i "impersonate"

# Monitor for privilege escalation
kubectl logs -n kube-system --follow | grep -i "privilege"

# Monitor for RBAC changes
kubectl logs -n kube-system --follow | grep -i "rbac"

# Check security events
kubectl get events --all-namespaces | grep -i "security"
```

## macOS Specific Security

### FileVault
```bash
# Check FileVault status
fdesetup status

# Enable FileVault (if not enabled)
sudo fdesetup enable
```

### Firewall
```bash
# Check firewall status
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# Enable firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
```

### Automatic Login
```bash
# Check automatic login
sudo defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser

# Disable automatic login
sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser -string ""
```

## Security Validation Checklist

- [ ] ImpersonationFilter configured
- [ ] Pod Security Standards enforced
- [ ] Network Policies applied
- [ ] Restrictive RBAC configured
- [ ] Audit logging enabled
- [ ] FileVault enabled (if available)
- [ ] Firewall enabled
- [ ] Automatic login disabled
- [ ] Regular security monitoring
- [ ] Kubernetes updated

## Quick Commands Reference

```bash
# Security setup
./scripts/simple-macos-k8s-security.sh

# Validation
validate-k8s-security

# Monitoring
~/security-monitor.sh

# Check logs
kubectl logs -n kube-system | grep -i "impersonate"

# Check policies
kubectl get networkpolicy --all-namespaces

# Check RBAC
kubectl get clusterrole macos-restricted-user

# Check namespaces
kubectl get namespace secure-workloads -o yaml | grep pod-security
```

## Support

For issues:
1. Check the validation script output
2. Review audit logs
3. Check this quick reference
4. Consider emergency procedures if needed

Remember: Security is an ongoing process. Regular monitoring and updates are essential.
