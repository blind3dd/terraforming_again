# Ansible Vault Module Outputs

output "vault_password_parameter_name" {
  description = "Name of the SSM parameter containing the vault password"
  value       = var.create_vault_password ? aws_ssm_parameter.ansible_vault_password[0].name : null
}

output "vault_password_parameter_arn" {
  description = "ARN of the SSM parameter containing the vault password"
  value       = var.create_vault_password ? aws_ssm_parameter.ansible_vault_password[0].arn : null
}

output "generated_vault_password" {
  description = "The generated vault password (only if auto-generated)"
  value       = var.create_vault_password && var.vault_password_value == null ? random_password.vault_password[0].result : null
  sensitive   = true
}

output "ansible_config_file" {
  description = "Path to the generated ansible.cfg file"
  value       = var.create_ansible_config ? local_file.ansible_cfg[0].filename : null
}

output "group_vars_all_file" {
  description = "Path to the generated group_vars/all.yml file"
  value       = var.create_group_vars ? local_file.group_vars_all[0].filename : null
}

output "vault_template_file" {
  description = "Path to the generated vault.yml template file"
  value       = var.create_vault_template ? local_file.group_vars_vault_template[0].filename : null
}

output "setup_documentation_file" {
  description = "Path to the generated setup documentation"
  value       = var.create_documentation ? local_file.vault_setup_docs[0].filename : null
}

output "vault_password_script_file" {
  description = "Path to the generated vault password retrieval script"
  value       = var.create_vault_password ? local_file.get_vault_password_script[0].filename : null
}
