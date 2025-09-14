# Ansible Vault Module
# This module sets up Ansible Vault with SSM Parameter Store integration

# Create SSM parameter for Ansible Vault password
resource "aws_ssm_parameter" "ansible_vault_password" {
  count = var.create_vault_password ? 1 : 0
  
  name        = var.vault_password_parameter_name
  description = "Ansible Vault password for ${var.environment} environment"
  type        = "SecureString"
  value       = var.vault_password_value != null ? var.vault_password_value : random_password.vault_password[0].result
  key_id      = var.kms_key_id

  tags = merge(
    var.common_tags,
    {
      Name        = "ansible-vault-password"
      Type        = "SecureString"
      Environment = var.environment
      Purpose     = "Ansible Vault"
    }
  )

  lifecycle {
    ignore_changes = [value]
  }
}

# Generate random password if not provided
resource "random_password" "vault_password" {
  count = var.create_vault_password && var.vault_password_value == null ? 1 : 0
  
  length  = 32
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Create the vault password retrieval script
resource "local_file" "get_vault_password_script" {
  count = var.create_vault_password ? 1 : 0
  
  filename = "${var.ansible_directory}/get-vault-password.sh"
  content = templatefile("${path.module}/templates/get-vault-password.sh.tpl", {
    parameter_name = var.vault_password_parameter_name
    aws_region     = var.aws_region
  })
  
  file_permission = "0755"
}

# Create ansible.cfg with vault configuration
resource "local_file" "ansible_cfg" {
  count = var.create_ansible_config ? 1 : 0
  
  filename = "${var.ansible_directory}/ansible.cfg"
  content = templatefile("${path.module}/templates/ansible.cfg.tpl", {
    vault_password_file = "./get-vault-password.sh"
  })
}

# Create group_vars/all.yml with non-sensitive variables
resource "local_file" "group_vars_all" {
  count = var.create_group_vars ? 1 : 0
  
  filename = "${var.ansible_directory}/group_vars/all.yml"
  content = templatefile("${path.module}/templates/group_vars_all.yml.tpl", {
    environment = var.environment
    db_host     = var.db_host
    db_port     = var.db_port
    db_name     = var.db_name
    db_user     = var.db_user
  })
}

# Create group_vars/vault.yml template (to be encrypted)
resource "local_file" "group_vars_vault_template" {
  count = var.create_vault_template ? 1 : 0
  
  filename = "${var.ansible_directory}/group_vars/vault.yml"
  content = templatefile("${path.module}/templates/vault.yml.tpl", {
    rds_password = var.rds_password_placeholder
    aws_access_key_id = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
    aws_session_token = var.aws_session_token
  })
}

# Create setup documentation
resource "local_file" "vault_setup_docs" {
  count = var.create_documentation ? 1 : 0
  
  filename = "${var.ansible_directory}/VAULT_SETUP.md"
  content = templatefile("${path.module}/templates/VAULT_SETUP.md.tpl", {
    parameter_name = var.vault_password_parameter_name
    environment    = var.environment
  })
}
