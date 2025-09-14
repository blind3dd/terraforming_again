# Ansible Vault with AWS SSM Parameter Store

This setup provides secure storage of Ansible Vault passwords using AWS Systems Manager (SSM) Parameter Store.

## 🔐 Security Benefits

- **No local password files**: Vault password stored securely in AWS SSM
- **Encrypted at rest**: SSM Parameter Store encrypts data with AWS KMS
- **Access control**: IAM policies control who can access the vault password
- **Audit trail**: CloudTrail logs all access to the parameter
- **Rotation support**: Easy password rotation without changing local files

## 🚀 Quick Setup

### 1. Prerequisites

```bash
# Install AWS CLI
aws --version

# Install Ansible
ansible --version

# Configure AWS credentials
aws configure
```

### 2. Initial Setup

```bash
cd ansible/

# Run the setup script
./setup-vault-ssm.sh

# Or with a custom password
./setup-vault-ssm.sh "your-custom-password"
```

### 3. Verify Setup

```bash
# Test password retrieval
./get-vault-password.sh view

# Test vault operations
ansible-vault view group_vars/vault.yml
```

## 📁 File Structure

```
ansible/
├── ansible.cfg                    # Ansible configuration
├── get-vault-password.sh         # SSM password retrieval script
├── setup-vault-ssm.sh           # Initial setup script
├── group_vars/
│   ├── all.yml                  # Non-sensitive variables
│   └── vault.yml                # Encrypted sensitive variables
└── VAULT_SETUP.md               # This documentation
```

## 🔧 Configuration

### Environment Variables

```bash
# AWS Configuration
export AWS_REGION="us-east-1"
export AWS_PROFILE="default"

# SSM Parameter Path
export VAULT_PASSWORD_PARAM="/ansible/vault/password"
```

### ansible.cfg

```ini
[defaults]
vault_password_file = ./get-vault-password.sh
```

## 📝 Usage

### Edit Vault File

```bash
# Edit encrypted vault file
ansible-vault edit group_vars/vault.yml

# View encrypted vault file
ansible-vault view group_vars/vault.yml
```

### Run Playbooks

```bash
# Run playbook (password retrieved automatically from SSM)
ansible-playbook playbook.yml

# Run with specific inventory
ansible-playbook -i inventory playbook.yml
```

### Password Management

```bash
# View current password
./get-vault-password.sh view

# Update password
./get-vault-password.sh update "new-password"

# Generate and set random password
./get-vault-password.sh update
```

## 🔒 IAM Permissions

### Required Permissions

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter",
                "ssm:GetParameters"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/ansible/vault/password"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt"
            ],
            "Resource": "arn:aws:kms:*:*:key/*"
        }
    ]
}
```

### For Setup (Additional Permissions)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:PutParameter",
                "ssm:DeleteParameter"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/ansible/vault/password"
        }
    ]
}
```

## 🛠️ Troubleshooting

### Common Issues

1. **AWS credentials not configured**
   ```bash
   aws configure
   ```

2. **SSM parameter doesn't exist**
   ```bash
   ./setup-vault-ssm.sh
   ```

3. **Permission denied**
   - Check IAM permissions
   - Verify AWS profile/region

4. **Vault file not encrypted**
   ```bash
   ansible-vault encrypt group_vars/vault.yml
   ```

### Debug Mode

```bash
# Enable debug output
export ANSIBLE_DEBUG=1
ansible-playbook playbook.yml
```

## 🔄 Password Rotation

### Manual Rotation

```bash
# Generate new password
NEW_PASSWORD=$(openssl rand -base64 32)

# Update SSM parameter
./get-vault-password.sh update "$NEW_PASSWORD"

# Re-encrypt vault file with new password
ansible-vault rekey group_vars/vault.yml
```

### Automated Rotation

```bash
# Create rotation script
cat > rotate-vault-password.sh << 'EOF'
#!/bin/bash
NEW_PASSWORD=$(openssl rand -base64 32)
./get-vault-password.sh update "$NEW_PASSWORD"
ansible-vault rekey group_vars/vault.yml --new-vault-password-file ./get-vault-password.sh
EOF

chmod +x rotate-vault-password.sh
```

## 📊 Monitoring

### CloudTrail Events

Monitor access to the SSM parameter:

```bash
aws logs filter-log-events \
  --log-group-name CloudTrail \
  --filter-pattern "GetParameter" \
  --start-time $(date -d '1 hour ago' +%s)000
```

### SSM Parameter Access

```bash
aws ssm describe-parameters \
  --parameter-filters "Key=Name,Values=/ansible/vault/password"
```

## 🔐 Best Practices

1. **Use least privilege**: Only grant necessary SSM permissions
2. **Rotate regularly**: Change vault password periodically
3. **Monitor access**: Use CloudTrail to monitor parameter access
4. **Backup**: Keep encrypted vault files in version control
5. **Environment separation**: Use different parameters per environment

## 🆘 Emergency Access

If SSM is unavailable:

```bash
# Temporarily use local password file
echo "your-password" > ~/.vault_password_temp
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_password_temp
ansible-playbook playbook.yml
rm ~/.vault_password_temp
```

## 📚 Additional Resources

- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [AWS SSM Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [AWS KMS Encryption](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html)
