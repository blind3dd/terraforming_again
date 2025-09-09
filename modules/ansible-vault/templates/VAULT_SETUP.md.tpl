# Ansible Vault Setup Guide

This guide explains how to set up and use Ansible Vault with AWS SSM Parameter Store integration.

## Overview

The Ansible Vault password is stored securely in AWS SSM Parameter Store at:
`${parameter_name}`

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Ansible installed
3. Access to the SSM parameter containing the vault password

## Setup Steps

### 1. Verify SSM Parameter

Check that the vault password parameter exists:
```bash
aws ssm get-parameter --name "${parameter_name}" --with-decryption
```

### 2. Test Vault Password Script

Test the vault password retrieval script:
```bash
./get-vault-password.sh
```

### 3. Encrypt the Vault File

Encrypt the `group_vars/vault.yml` file:
```bash
ansible-vault encrypt group_vars/vault.yml
```

When prompted for a password, the script will automatically retrieve it from SSM.

### 4. Edit Encrypted Vault File

To edit the encrypted vault file:
```bash
ansible-vault edit group_vars/vault.yml
```

### 5. View Encrypted Vault File

To view the encrypted vault file:
```bash
ansible-vault view group_vars/vault.yml
```

### 6. Run Ansible Playbooks

Run playbooks that use vault variables:
```bash
ansible-playbook -i inventory/ playbook.yml
```

## Environment: ${environment}

This setup is configured for the **${environment}** environment.

## Troubleshooting

### Permission Issues
Ensure your AWS credentials have the following permissions:
- `ssm:GetParameter`
- `ssm:GetParameters`
- `kms:Decrypt` (if using KMS encryption)

### Script Execution Issues
Make sure the script is executable:
```bash
chmod +x get-vault-password.sh
```

### Vault Password Issues
If the vault password is incorrect, you can update it in SSM:
```bash
aws ssm put-parameter --name "${parameter_name}" --value "new_password" --overwrite
```

## Security Notes

- Never commit encrypted vault files to version control
- Rotate vault passwords regularly
- Use least-privilege IAM policies
- Monitor SSM parameter access in CloudTrail
