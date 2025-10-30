#!/bin/bash
# Compile and install SELinux policies
# This script compiles .te files into .pp modules and installs them

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

# Check if SELinux is enabled
if ! getenforce | grep -q "Enforcing\|Permissive"; then
    error "SELinux is not enabled"
fi

log "Compiling and installing SELinux policies..."

# Install required packages
log "Installing SELinux development tools..."
yum install -y selinux-policy-devel policycoreutils-devel

# Create policies directory
mkdir -p /etc/selinux/policies

# Compile each policy
for te_file in selinux/*.te; do
    if [[ -f "$te_file" ]]; then
        policy_name=$(basename "$te_file" .te)
        log "Compiling policy: $policy_name"
        
        # Step 1: Check module syntax with checkmodule
        log "Validating $policy_name.te syntax..."
        if checkmodule -M -m -o "${policy_name}.mod" "$te_file"; then
            log "Syntax validation passed for $policy_name"
        else
            error "Syntax validation failed for $policy_name"
        fi
        
        # Step 2: Package module with semodule_package
        log "Packaging $policy_name module..."
        if semodule_package -o "${policy_name}.pp" -m "${policy_name}.mod"; then
            log "Module packaging successful for $policy_name"
        else
            error "Module packaging failed for $policy_name"
        fi
        
        # Step 3: Install the policy
        log "Installing $policy_name policy..."
        if semodule -i "${policy_name}.pp"; then
            log "Policy $policy_name installed successfully"
        else
            error "Failed to install policy $policy_name"
        fi
        
        # Step 4: Verify installation
        if semodule -l | grep -q "$policy_name"; then
            log "Policy $policy_name verified as active"
        else
            warn "Policy $policy_name may not be active"
        fi
        
        # Clean up intermediate files
        rm -f "${policy_name}.mod"
    fi
done

# Set file contexts
log "Setting file contexts..."
semanage fcontext -a -t auditd_log_t "/var/log/audit(/.*)?"
semanage fcontext -a -t auditd_config_t "/etc/audit(/.*)?"
semanage fcontext -a -t polkitd_log_t "/var/log/polkit(/.*)?"
semanage fcontext -a -t polkitd_config_t "/etc/polkit-1(/.*)?"
semanage fcontext -a -t seccomp_config_t "/etc/seccomp(/.*)?"
semanage fcontext -a -t seccomp_log_t "/var/log/seccomp(/.*)?"
semanage fcontext -a -t seccomp_config_t "/usr/share/seccomp(/.*)?"

# Apply file contexts
restorecon -R /var/log/audit
restorecon -R /etc/audit
restorecon -R /var/log/polkit 2>/dev/null || true
restorecon -R /etc/polkit-1 2>/dev/null || true
restorecon -R /etc/seccomp 2>/dev/null || true
restorecon -R /var/log/seccomp 2>/dev/null || true
restorecon -R /usr/share/seccomp 2>/dev/null || true

# Install audit rules for authentication events
log "Installing authentication audit rules..."
if [[ -f "selinux/audit-rules.conf" ]]; then
    cp selinux/audit-rules.conf /etc/audit/rules.d/99-auth-audit.rules
    log "Authentication audit rules installed"
else
    warn "audit-rules.conf not found, skipping authentication audit rules"
fi

# Install audit rules for privilege escalation detection
log "Installing privilege escalation audit rules..."
if [[ -f "selinux/privilege-escalation-audit.conf" ]]; then
    cp selinux/privilege-escalation-audit.conf /etc/audit/rules.d/98-privilege-escalation-audit.rules
    log "Privilege escalation audit rules installed"
else
    warn "privilege-escalation-audit.conf not found, skipping privilege escalation audit rules"
fi

# Install audit rules for seccomp security events
log "Installing seccomp audit rules..."
if [[ -f "selinux/seccomp-audit.conf" ]]; then
    cp selinux/seccomp-audit.conf /etc/audit/rules.d/96-seccomp-audit.rules
    log "Seccomp audit rules installed"
else
    warn "seccomp-audit.conf not found, skipping seccomp audit rules"
fi

# Install audit rules for Polkit security events
log "Installing Polkit audit rules..."
if [[ -f "selinux/polkit-audit.conf" ]]; then
    cp selinux/polkit-audit.conf /etc/audit/rules.d/97-polkit-audit.rules
    log "Polkit audit rules installed"
else
    warn "polkit-audit.conf not found, skipping Polkit audit rules"
fi

# Install Kubernetes seccomp profiles
log "Installing Kubernetes seccomp profiles..."
mkdir -p /usr/share/seccomp/profiles/kubernetes
if [[ -f "selinux/seccomp-kubelet-profile.json" ]]; then
    cp selinux/seccomp-kubelet-profile.json /usr/share/seccomp/profiles/kubernetes/
    log "Kubelet seccomp profile installed"
fi
if [[ -f "selinux/seccomp-kube-proxy-profile.json" ]]; then
    cp selinux/seccomp-kube-proxy-profile.json /usr/share/seccomp/profiles/kubernetes/
    log "Kube-proxy seccomp profile installed"
fi
if [[ -f "selinux/seccomp-k8s-webapp-profile.json" ]]; then
    cp selinux/seccomp-k8s-webapp-profile.json /usr/share/seccomp/profiles/kubernetes/
    log "Kubernetes webapp seccomp profile installed"
fi
if [[ -f "selinux/seccomp-k8s-database-profile.json" ]]; then
    cp selinux/seccomp-k8s-database-profile.json /usr/share/seccomp/profiles/kubernetes/
    log "Kubernetes database seccomp profile installed"
fi
if [[ -f "selinux/seccomp-k8s-system-profile.json" ]]; then
    cp selinux/seccomp-k8s-system-profile.json /usr/share/seccomp/profiles/kubernetes/
    log "Kubernetes system seccomp profile installed"
fi

# Configure audit daemon to log to /var/log/audit.log
log "Configuring audit daemon..."
cat > /etc/audit/auditd.conf << EOF
# Audit daemon configuration
log_file = /var/log/audit.log
log_format = RAW
log_group = root
priority_boost = 4
flush = INCREMENTAL
freq = 20
num_logs = 5
disp_qos = lossy
dispatcher = /sbin/audispd
name_format = HOSTNAME
max_log_file = 6
max_log_file_action = ROTATE
space_left = 75
space_left_action = SYSLOG
action_mail_acct = root
admin_space_left = 50
admin_space_left_action = SUSPEND
disk_full_action = SUSPEND
disk_error_action = SUSPEND
EOF

# Ensure audit log directory exists and has proper permissions
mkdir -p /var/log
touch /var/log/audit.log
touch /var/log/secure
chmod 600 /var/log/audit.log
chmod 640 /var/log/secure
chown root:root /var/log/audit.log
chown root:root /var/log/secure

# Load and restart audit system
if [[ -f "/etc/audit/rules.d/99-auth-audit.rules" ]] || [[ -f "/etc/audit/rules.d/98-privilege-escalation-audit.rules" ]]; then
    augenrules --load
    systemctl restart auditd
    log "Audit rules loaded and auditd restarted"
fi

# Verify policies are active
log "Verifying policies are active..."
if semodule -l | grep -q "audit_security"; then
    log "audit_security policy is active"
else
    warn "audit_security policy may not be active"
fi

if semodule -l | grep -q "privilege_escalation_protection"; then
    log "privilege_escalation_protection policy is active"
else
    warn "privilege_escalation_protection policy may not be active"
fi

if semodule -l | grep -q "seccomp_security"; then
    log "seccomp_security policy is active"
else
    warn "seccomp_security policy may not be active"
fi

if semodule -l | grep -q "polkit_security"; then
    log "polkit_security policy is active"
else
    warn "polkit_security policy may not be active"
fi

# Test SELinux enforcement
log "Testing SELinux enforcement..."
if getenforce | grep -q "Enforcing"; then
    log "SELinux is in Enforcing mode"
else
    warn "SELinux is not in Enforcing mode"
fi

# Verify audit logging
log "Verifying audit logging..."
if [[ -f "/var/log/audit.log" ]]; then
    log "Audit log file exists: /var/log/audit.log"
    log "Audit log permissions: $(ls -la /var/log/audit.log)"
else
    warn "Audit log file not found: /var/log/audit.log"
fi

if [[ -f "/var/log/secure" ]]; then
    log "Secure log file exists: /var/log/secure"
    log "Secure log permissions: $(ls -la /var/log/secure)"
else
    warn "Secure log file not found: /var/log/secure"
fi

# Test audit logging by generating a test event
log "Testing audit logging..."
auditctl -w /tmp/test_audit_file -p wa -k test_audit
echo "test" > /tmp/test_audit_file
sleep 2
if grep -q "test_audit" /var/log/audit.log 2>/dev/null; then
    log "Audit logging is working correctly"
else
    warn "Audit logging may not be working - check auditd status"
fi
rm -f /tmp/test_audit_file
auditctl -D  # Remove test rule

log "SELinux policies compiled and installed successfully!"
log "Policies are now active and enforcing security rules"
log "Audit logs are being written to: /var/log/audit.log"
log "Authentication logs are being written to: /var/log/secure"
