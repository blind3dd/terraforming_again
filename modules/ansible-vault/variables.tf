# Ansible Vault Module Variables

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Ansible Vault Configuration
variable "create_vault_password" {
  description = "Whether to create the Ansible Vault password in SSM"
  type        = bool
  default     = true
}

variable "vault_password_parameter_name" {
  description = "SSM parameter name for the Ansible Vault password"
  type        = string
  default     = "/ansible/vault/password"
}

variable "vault_password_value" {
  description = "Explicit vault password value (if null, will generate random)"
  type        = string
  default     = null
  sensitive   = true
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting the vault password"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "AWS region for SSM parameter"
  type        = string
  default     = "us-west-2"
}

# File Generation Options
variable "create_ansible_config" {
  description = "Whether to create ansible.cfg file"
  type        = bool
  default     = true
}

variable "create_group_vars" {
  description = "Whether to create group_vars files"
  type        = bool
  default     = true
}

variable "create_vault_template" {
  description = "Whether to create vault.yml template"
  type        = bool
  default     = true
}

variable "create_documentation" {
  description = "Whether to create setup documentation"
  type        = bool
  default     = true
}

variable "ansible_directory" {
  description = "Directory where Ansible files should be created"
  type        = string
  default     = "./ansible"
}

# Database Configuration for group_vars
variable "db_host" {
  description = "Database host for Ansible variables"
  type        = string
  default     = "localhost"
}

variable "db_port" {
  description = "Database port for Ansible variables"
  type        = string
  default     = "3306"
}

variable "db_name" {
  description = "Database name for Ansible variables"
  type        = string
  default     = "database"
}

variable "db_user" {
  description = "Database user for Ansible variables"
  type        = string
  default     = "admin"
}

variable "rds_password_placeholder" {
  description = "Placeholder value for RDS password in vault template"
  type        = string
  default     = "CHANGE_ME_TO_ACTUAL_PASSWORD"
}

# AWS Credentials for injection into vault
variable "aws_access_key_id" {
  description = "AWS Access Key ID to inject into vault"
  type        = string
  default     = "foobar_aws_access_key_123"
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key to inject into vault"
  type        = string
  default     = "foobar_aws_secret_key_123"
  sensitive   = true
}

variable "aws_session_token" {
  description = "AWS Session Token to inject into vault (for temporary credentials)"
  type        = string
  default     = "foobar_aws_session_token_123"
  sensitive   = true
}
