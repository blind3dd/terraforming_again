# Ansible Playbooks for Database CI Infrastructure

This directory contains Ansible playbooks that convert all the shell scripts in the `scripts/` directory into infrastructure-as-code playbooks. The original scripts are preserved and can still be used independently.

## 📁 Directory Structure

```
ansible/
├── README.md                           # This file
├── requirements.txt                    # Python package requirements
├── requirements-dev.txt                # Development requirements
├── requirements.yml                    # Ansible Galaxy requirements
├── setup-venv.sh                      # Virtual environment setup script
├── activate-venv.sh                   # Environment activation script
├── deactivate-venv.sh                 # Environment deactivation script
├── setup-dev.sh                       # Development environment setup
├── quick-start.sh                     # Quick start guide
├── inventory                          # Ansible inventory file
├── group_vars/
│   └── all.yml                        # Global variables
├── playbooks/
│   ├── site.yml                       # Master playbook (orchestrates all)
│   ├── compile-selinux-policies.yml   # SELinux policies compilation
│   ├── secure-macos-k8s.yml          # macOS Kubernetes security
│   ├── setup-k8s-seccomp-profiles.yml # Kubernetes seccomp profiles
│   ├── install-aws-iam-authenticator.yml # AWS IAM Authenticator
│   ├── istio-ambient-rds-deployment.yml # Istio ambient mode RDS app
│   └── aws-resource-audit.yml        # AWS resource audit and cleanup
└── templates/                         # Jinja2 templates (existing)
```

## 🚀 Quick Start

### 1. Setup Python Virtual Environment

```bash
# Option 1: Use the automated setup script (recommended)
./setup-venv.sh

# Option 2: Manual setup
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
ansible-galaxy install -r requirements.yml

# Option 3: Quick start
./quick-start.sh
```

### 2. Activate Virtual Environment

```bash
# Activate the virtual environment
source venv/bin/activate
# or
./activate-venv.sh
```

### 3. Run Individual Playbooks

```bash
# Compile SELinux policies
ansible-playbook playbooks/compile-selinux-policies.yml

# Setup Kubernetes seccomp profiles
ansible-playbook playbooks/setup-k8s-seccomp-profiles.yml

# Secure macOS Kubernetes
ansible-playbook playbooks/secure-macos-k8s.yml

# Install AWS IAM Authenticator
ansible-playbook playbooks/install-aws-iam-authenticator.yml

# Deploy Istio ambient mode RDS application
ansible-playbook playbooks/istio-ambient-rds-deployment.yml

# Audit AWS resources
ansible-playbook playbooks/aws-resource-audit.yml
```

### 4. Run Complete Infrastructure Setup

```bash
# Run the master playbook (orchestrates everything)
ansible-playbook playbooks/site.yml
```

### 5. Deactivate Virtual Environment

```bash
# When done, deactivate the virtual environment
deactivate
# or
./deactivate-venv.sh
```

## 📋 Playbook Descriptions

### `site.yml` - Master Playbook
- **Purpose**: Orchestrates all individual playbooks
- **Features**: Complete infrastructure setup with verification
- **Variables**: Configurable via `group_vars/all.yml`

### `compile-selinux-policies.yml`
- **Purpose**: Compiles and installs SELinux policies
- **Converts**: `scripts/compile-selinux-policies.sh`
- **Features**: 
  - Compiles `.te` files to `.pp` modules
  - Installs audit rules
  - Configures seccomp profiles
  - Sets file contexts

### `secure-macos-k8s.yml`
- **Purpose**: Secures local macOS Kubernetes cluster
- **Converts**: `scripts/secure-macos-k8s.sh`
- **Features**:
  - ImpersonationFilter configuration
  - Pod Security Standards
  - Network policies
  - RBAC configuration

### `setup-k8s-seccomp-profiles.yml`
- **Purpose**: Installs Kubernetes seccomp profiles
- **Converts**: `scripts/setup-k8s-seccomp-profiles.sh`
- **Features**:
  - Copies seccomp profiles to correct location
  - Creates symlinks for easier access
  - Creates ConfigMap with profiles

### `install-aws-iam-authenticator.yml`
- **Purpose**: Installs AWS IAM Authenticator for Kubernetes
- **Converts**: `scripts/install-aws-iam-authenticator.sh`
- **Features**:
  - Downloads and installs binary
  - Creates configuration files
  - Generates IAM roles and policies
  - Creates Kubernetes manifests

### `istio-ambient-rds-deployment.yml`
- **Purpose**: Deploys Istio ambient mode RDS application
- **Converts**: `scripts/deploy-istio-ambient-rds.sh`
- **Features**:
  - Istio ambient mode (no sidecar)
  - Seccomp profiles
  - RDS connectivity
  - Security hardening

### `aws-resource-audit.yml`
- **Purpose**: Audits and cleans up AWS resources
- **Converts**: `scripts/ec2-only-audit.sh`, `scripts/cleanup-eu-north-1-resources.sh`
- **Features**:
  - Comprehensive resource audit
  - Backup before cleanup
  - Dangerous resource identification
  - Automated cleanup (optional)

## ⚙️ Configuration

### Global Variables (`group_vars/all.yml`)

```yaml
# Application Configuration
app_name: rds-app
app_version: v1
app_port: 8080
namespace: secure-workloads

# Security Configuration
run_as_user: 1000
run_as_group: 1000
fs_group: 1000
seccomp_profile: profiles/kubernetes/seccomp-k8s-database-profile.json

# AWS Configuration
aws_region: us-east-1
aws_account_id: 123456789012
cluster_name: database-ci-cluster

# Database Configuration
rds_host: rds-endpoint.example.com
rds_username: admin
rds_password: secure-password
rds_database: myapp
```

### Inventory (`inventory`)

```ini
[local]
localhost ansible_connection=local ansible_python_interpreter=python3

[kubernetes_cluster]
localhost ansible_connection=local ansible_python_interpreter=python3

[istio_ambient]
localhost ansible_connection=local ansible_python_interpreter=python3
```

## 🔧 Usage Examples

### Run with Custom Variables

```bash
# Override variables at runtime
ansible-playbook playbooks/istio-ambient-rds-deployment.yml \
  -e "rds_host=my-rds-endpoint.com" \
  -e "rds_username=myuser" \
  -e "rds_password=mypassword"
```

### Run with Tags

```bash
# Run only specific tasks
ansible-playbook playbooks/site.yml --tags "selinux,seccomp"
```

### Run in Check Mode

```bash
# Dry run to see what would change
ansible-playbook playbooks/site.yml --check --diff
```

### Run with Verbose Output

```bash
# Detailed output
ansible-playbook playbooks/site.yml -vvv
```

## 🛡️ Security Features

### SELinux Policies
- **Authentication audit**: SSHD, SSSD, PAM monitoring
- **Privilege escalation protection**: SUID/SGID monitoring
- **Seccomp security**: System call filtering
- **Polkit security**: PolicyKit daemon protection

### Kubernetes Security
- **ImpersonationFilter**: Prevents unauthorized impersonation
- **Pod Security Standards**: Restricted mode enforcement
- **Network Policies**: Default deny all traffic
- **RBAC**: Least privilege access control
- **Seccomp Profiles**: Container system call filtering

### AWS Security
- **IAM Authenticator**: Secure Kubernetes authentication
- **Resource Audit**: Comprehensive security assessment
- **Automated Cleanup**: Removes dangerous configurations

## 📊 Monitoring and Validation

### Built-in Validation
- **SELinux status**: Verifies policies are active
- **Seccomp profiles**: Confirms profiles are installed
- **Kubernetes security**: Validates security configurations
- **AWS resources**: Audits resource security

### Monitoring Scripts
- **Security monitoring**: Continuous security event monitoring
- **Validation scripts**: Regular security validation
- **Audit logging**: Comprehensive security event logging

## 🔄 Migration from Scripts

### Original Scripts Preserved
All original shell scripts in the `scripts/` directory are preserved and can still be used:

```bash
# Original scripts still work
./scripts/compile-selinux-policies.sh
./scripts/secure-macos-k8s.sh
./scripts/setup-k8s-seccomp-profiles.sh
```

### Benefits of Ansible Playbooks over Scripts
- **Idempotent**: Can be run multiple times safely
- **Declarative**: Describes desired state
- **Verifiable**: Built-in validation and testing
- **Maintainable**: Easier to modify and extend
- **Documented**: Self-documenting infrastructure
- **Cross-platform**: Works on different operating systems
- **Modular**: Reusable components and roles

## 🚨 Troubleshooting

### Common Issues

1. **Virtual Environment Not Activated**
   ```bash
   # Make sure to activate the virtual environment first
   source venv/bin/activate
   # or
   ./activate-venv.sh
   ```

2. **Permission Denied**
   ```bash
   # Run as root for system-level configurations
   sudo ansible-playbook playbooks/compile-selinux-policies.yml
   ```

3. **Missing Dependencies**
   ```bash
   # Reinstall requirements
   pip install -r requirements.txt
   # Install required collections
   ansible-galaxy install -r requirements.yml
   ```

4. **Kubernetes Connection Issues**
   ```bash
   # Check kubectl configuration
   kubectl cluster-info
   ```

5. **AWS Credentials Issues**
   ```bash
   # Check AWS credentials
   aws sts get-caller-identity
   ```

6. **Python Version Issues**
   ```bash
   # Check Python version (requires 3.9+)
   python --version
   # Recreate virtual environment if needed
   rm -rf venv
   ./setup-venv.sh
   ```

### Debug Mode

```bash
# Run with debug output
ansible-playbook playbooks/site.yml -vvv

# Run specific task with debug
ansible-playbook playbooks/site.yml --tags "selinux" -vvv
```

## 📚 Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Kubernetes Ansible Collection](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/)
- [AWS Ansible Collection](https://docs.ansible.com/ansible/latest/collections/amazon/aws/)
- [SELinux Documentation](https://selinuxproject.org/page/Main_Page)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [Python Virtual Environments](https://docs.python.org/3/tutorial/venv.html)
- [Python venv vs pipenv](https://docs.python.org/3/tutorial/venv.html#creating-virtual-environments)

## 🤝 Contributing

1. **Modify playbooks**: Update the Ansible playbooks as needed
2. **Update variables**: Modify `group_vars/all.yml` for configuration changes
3. **Test changes**: Run playbooks in check mode first
4. **Document changes**: Update this README with any new features

## 📝 License

This project follows the same license as the main Database CI Infrastructure project.
