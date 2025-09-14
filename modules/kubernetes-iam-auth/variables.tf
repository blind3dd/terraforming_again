# Variables for Kubernetes IAM Authentication Module

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "go-mysql-api-cluster"
}

variable "cluster_domain" {
  description = "Domain name for the Kubernetes cluster"
  type        = string
  default     = "local"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "namespace" {
  description = "Kubernetes namespace for service accounts"
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account"
  type        = string
  default     = "aws-iam-authenticator"
}

variable "iam_users" {
  description = "List of IAM users to map to Kubernetes users"
  type = list(object({
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "enable_cluster_admin" {
  description = "Enable cluster admin role"
  type        = bool
  default     = true
}

variable "enable_developer" {
  description = "Enable developer role"
  type        = bool
  default     = true
}

variable "enable_readonly" {
  description = "Enable read-only role"
  type        = bool
  default     = true
}

variable "enable_service_account" {
  description = "Enable service account role"
  type        = bool
  default     = true
}

variable "additional_policies" {
  description = "Additional IAM policies to attach to roles"
  type = map(object({
    policy_document = string
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
