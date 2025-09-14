# Shared Environment Variables
# Common variables used across all environments

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "database-ci"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "infrastructure-team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

variable "create_vpc" {
  description = "Whether to create a new VPC or use existing"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "test", "sandbox", "shared"], var.environment)
    error_message = "Environment must be one of: dev, test, sandbox, shared."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Domain name for the project"
  type        = string
  default     = "coderedalarmtech.com"
}

variable "internal_domain" {
  description = "Internal domain name"
  type        = string
  default     = "internal.coderedalarmtech.com"
}
