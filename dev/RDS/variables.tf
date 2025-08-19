
variable "aws_region" {}
variable "main_vpc_cidr" {}
variable "private_subnet_range_a" {}
variable "private_subnet_range_b" {}
variable "public_subnet_range" {}
variable "service_name" {}
variable "infra_builder" {}
variable "environment" {
  type = string
  default = "dev"
  description = "The environment to deploy to"
  validation {
    condition = contains(["dev", "dev-canary"], var.environment)
    error_message = "Environment must be either dev or dev-canary"
  }
}
