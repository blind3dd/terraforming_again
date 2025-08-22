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

variable "aws_region_zones" {
  type = list(object({
    region = string
    zones = list(object({
      name = string
    }))
  }))
}