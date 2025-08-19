variable "aws_region" {}
variable "main_vpc_cidr" {}
variable "private_subnet_range_a" {}
variable "private_subnet_range_b" {}
variable "public_subnet_range" {}
variable "service_name" {}
variable "infra_builder" {}
variable "ec2_instance_ami" {}
variable "ec2_instance_type" {}
variable "ec2_instance_role_name" {}
variable "ec2_instance_profile_name" {}
variable "environment" {
  type = string
  default = "test"
  description = "The environment to deploy to"
  validation {
    condition = contains(["test", "test-canary"], var.environment)
    error_message = "Environment must be either test or test-canary"
  }
}
