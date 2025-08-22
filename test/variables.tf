variable region {
   type = string
   default = "us-east-1"
   description = "The region to deploy to"
   validation {
    condition = contains(["us-east-1", "us-west-2"], var.region)
    error_message = "Region must be either us-east-1 or us-west-2"
   }
}

variable "environment" {
  type = string
  default = "test"
  description = "The environment to deploy to"
  validation {
    condition = contains(["dev", "test"], var.environment)
    error_message = "Environment must be either development or production"
  }
}

variable "main_vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
  description = "The CIDR block for the main VPC"
}

variable "private_subnet_range_a" {
  type = string
  default = "10.0.1.0/24"
  description = "The CIDR block for the private subnet A"
}

variable "private_subnet_range_b" {
  type = string
  default = "10.0.2.0/24"
  description = "The CIDR block for the private subnet B"
}

variable "public_subnet_range" {
  type = string
  default = "10.0.3.0/24"
  description = "The CIDR block for the public subnet"
}

variable "service_name" {
  type = string
  default = "go-mysql-api"
  description = "The name of the service"
}

variable "instance_os" {
  type = string
  default = "Ubuntu 22.04"
  description = "The OS of the instance"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
  description = "The type of the instance"
}

variable "instance_ami" {
  type = string
  default = "ami-58d7e821"
  description = "The AMI of the instance"
}

variable "aws_key_pair_name" {
  type = string
  default = "ec2_key_pair"
  description = "The name of the key pair"
}

variable "key_algorithm" {
  type = string
  default = "RSA"
  description = "The algorithm of the key pair"
}

variable "key_bits_size" {
  type = number
  default = 4096
  description = "The size of the key pair"
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

variable "associate_public_ip_address" {
  type = bool
  default = true
  description = "Whether to associate a public IP address with the instance"
}

variable "db_name" {
  type = string
  default = "mock_user"
  description = "The name of the database"
}

variable "db_username" {
  type = string
  default = "mock_pass"
}

variable "rds_engine_version" {
  type = string
  default = "8.0.32"
  description = "The version of the RDS engine"
}

variable "infra_builder" {
  type = string
  default = "iacrunner"
  description = "The name of the person who created the infrastructure"
}

variable "ec2_instance_role_name" {
  type = string
  default = "ec2-instance-role"
  description = "The name of the instance role"
}

variable "ec2_instance_profile_name" {
  type = string
  default = "ec2-instance-profile"
  description = "The name of the instance profile"
}

variable "go_mysql_api_path" {
  type = string
  default = "/app/go-mysql-api"
  description = "The path to the go mysql api"
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

variable "aws_region_zones_count" {
  type = number
  default = 1
  description = "The number of regions in the AWS region"
}
