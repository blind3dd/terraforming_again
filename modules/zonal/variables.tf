variable "environment" {}
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
    condition = contains(["{$prefix", "test-canary"], var.environment)
    error_message = "Environment must be either test or test-canary"
  }
}

variable "subnet_type" {
  type = string
  default = "regional"
  description = "The type of subnet"
  validation {
    condition = contains(["regional", "zonal"], var.subnet_type)
    error_message = "Subnet type must be either regional or zonal"
  }
}

variable "aws_region_zones" {
  type = list(object({
    region = string
    zones = list(object({
      name = string
    }))
  }))
}