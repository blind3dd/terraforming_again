# Kubernetes Operators Module Variables

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

# Namespace Configuration
variable "create_namespace" {
  description = "Whether to create a namespace for operators"
  type        = bool
  default     = true
}

variable "namespace_name" {
  description = "Name of the namespace for operators"
  type        = string
  default     = "operators"
}

# Terraform Operator Configuration
variable "create_terraform_operator" {
  description = "Whether to create the Terraform operator"
  type        = bool
  default     = true
}

variable "terraform_operator_image" {
  description = "Docker image for Terraform operator"
  type        = string
  default     = "ubuntu:22.04"
}

variable "terraform_operator_replicas" {
  description = "Number of replicas for Terraform operator"
  type        = number
  default     = 1
}

variable "terraform_operator_cpu_request" {
  description = "CPU request for Terraform operator"
  type        = string
  default     = "100m"
}

variable "terraform_operator_memory_request" {
  description = "Memory request for Terraform operator"
  type        = string
  default     = "256Mi"
}

variable "terraform_operator_cpu_limit" {
  description = "CPU limit for Terraform operator"
  type        = string
  default     = "500m"
}

variable "terraform_operator_memory_limit" {
  description = "Memory limit for Terraform operator"
  type        = string
  default     = "1Gi"
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = "terraform-state-bucket"
}

variable "terraform_state_table" {
  description = "DynamoDB table for Terraform state locking"
  type        = string
  default     = "terraform-state-lock"
}

# Ansible Operator Configuration
variable "create_ansible_operator" {
  description = "Whether to create the Ansible operator"
  type        = bool
  default     = true
}

variable "ansible_operator_image" {
  description = "Docker image for Ansible operator"
  type        = string
  default     = "ubuntu:22.04"
}

variable "ansible_operator_replicas" {
  description = "Number of replicas for Ansible operator"
  type        = number
  default     = 1
}

variable "ansible_operator_cpu_request" {
  description = "CPU request for Ansible operator"
  type        = string
  default     = "100m"
}

variable "ansible_operator_memory_request" {
  description = "Memory request for Ansible operator"
  type        = string
  default     = "256Mi"
}

variable "ansible_operator_cpu_limit" {
  description = "CPU limit for Ansible operator"
  type        = string
  default     = "500m"
}

variable "ansible_operator_memory_limit" {
  description = "Memory limit for Ansible operator"
  type        = string
  default     = "1Gi"
}

variable "ansible_vault_password" {
  description = "Ansible vault password"
  type        = string
  default     = "foobar123"
  sensitive   = true
}
