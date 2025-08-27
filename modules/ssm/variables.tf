# AWS SSM Parameter Store - Variables
# This file defines all variables used in the SSM module

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

# Secret configuration
# variable "secrets" {
#   description = "Map of secrets to create as SecureString parameters"
#   type = map(object({
#     description       = string
#     value            = optional(string, null)
#     length           = optional(number, 32)
#     special          = optional(bool, true)
#     override_special = optional(string, "!@#$%^&*()_+-=[]{}|;:,.<>?")
#     min_lower        = optional(number, 1)
#     min_upper        = optional(number, 1)
#     min_numeric      = optional(number, 1)
#     min_special      = optional(number, 1)
#     kms_key_id       = optional(string, null)
#     tags             = optional(map(string), {})
#   }))
#   default = {}
# }


# KMS configuration
variable "create_kms_key" {
  description = "Whether to create a KMS key for parameter encryption"
  type        = bool
  default     = false
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7
}

variable "db_password_param_user" {
  type = string
  default = "/opt/go-mysql-api/${var.environment}/username"
  description = "The parameter name of the db username"
}
variable "db_password_param_pass" {
  type = string
  default = "/opt/go-mysql-api/${var.environment}/password"
  description = "The parameter name of the db password"
}

variable "db_host_param" {
  type = string
  default = "/opt/go-mysql-api/${var.environment}/host"
  description = "The parameter name of the db host"
}

variable "database_port" {
  type = string
  default = "3306"
  description = "The port of the db"
}

variable "kms_key_id" {
  type = string
  default = "something"
  description = "The KMS key ID for the SSM parameters"
}