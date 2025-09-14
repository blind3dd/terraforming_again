# Kubernetes Operators Module Outputs

output "namespace_name" {
  description = "Name of the operators namespace"
  value       = var.create_namespace ? kubernetes_namespace.operators[0].metadata[0].name : var.namespace_name
}

output "terraform_operator_deployment_name" {
  description = "Name of the Terraform operator deployment"
  value       = var.create_terraform_operator ? kubernetes_deployment.terraform_operator[0].metadata[0].name : null
}

output "terraform_operator_service_account_name" {
  description = "Name of the Terraform operator service account"
  value       = var.create_terraform_operator ? kubernetes_service_account.terraform_operator[0].metadata[0].name : null
}

output "terraform_operator_config_map_name" {
  description = "Name of the Terraform operator config map"
  value       = var.create_terraform_operator ? kubernetes_config_map.terraform_operator_config[0].metadata[0].name : null
}

output "ansible_operator_deployment_name" {
  description = "Name of the Ansible operator deployment"
  value       = var.create_ansible_operator ? kubernetes_deployment.ansible_operator[0].metadata[0].name : null
}

output "ansible_operator_service_account_name" {
  description = "Name of the Ansible operator service account"
  value       = var.create_ansible_operator ? kubernetes_service_account.ansible_operator[0].metadata[0].name : null
}

output "ansible_operator_config_map_name" {
  description = "Name of the Ansible operator config map"
  value       = var.create_ansible_operator ? kubernetes_config_map.ansible_operator_config[0].metadata[0].name : null
}

output "ansible_vault_secret_name" {
  description = "Name of the Ansible vault password secret"
  value       = var.create_ansible_operator ? kubernetes_secret.ansible_vault_password[0].metadata[0].name : null
}

output "operators_info" {
  description = "Complete information about the operators"
  value = {
    namespace = var.create_namespace ? kubernetes_namespace.operators[0].metadata[0].name : var.namespace_name
    terraform_operator = var.create_terraform_operator ? {
      deployment_name = kubernetes_deployment.terraform_operator[0].metadata[0].name
      service_account = kubernetes_service_account.terraform_operator[0].metadata[0].name
      config_map      = kubernetes_config_map.terraform_operator_config[0].metadata[0].name
    } : null
    ansible_operator = var.create_ansible_operator ? {
      deployment_name = kubernetes_deployment.ansible_operator[0].metadata[0].name
      service_account = kubernetes_service_account.ansible_operator[0].metadata[0].name
      config_map      = kubernetes_config_map.ansible_operator_config[0].metadata[0].name
      vault_secret    = kubernetes_secret.ansible_vault_password[0].metadata[0].name
    } : null
  }
}
