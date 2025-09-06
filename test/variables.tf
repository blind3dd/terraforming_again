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
    condition = contains(["test", "test-canary"], var.environment)
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
  description = "The CIDR block for the public subnet A"
}

variable "existing_vpc_id" {
  type = string
  default = ""
  description = "Existing VPC ID to use instead of creating new one"
}

variable "existing_subnet_ids" {
  type = list(string)
  default = []
  description = "Existing subnet IDs to use instead of creating new ones"
}

variable "service_name" {
  type = string
  default = "go-mysql-api"
  description = "The name of the service"
}

variable "instance_os" {
  type = string
  default = "Amazon Linux 1.5"
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

variable "db_password_param" {
  type = string
  default = "/opt/go-mysql-api/db/password"
  description = "The parameter name of the db password"
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

variable "db_password" {
  type = string
  default = "password"
  description = "The password of the database"
}

variable "db_username" {
  type = string
  default = "username"
  description = "The username of the database"
}

variable "db_port" {
  type = number
  default = 3306
  description = "The port of the database"
}

variable "db_engine" {
  type = string
  default = "mysql"
  description = "The engine of the database"
}

variable "db_engine_version" {
  type = string
  default = "8.0.32" // # 9?
  description = "The version of the database engine"
}

variable "db_instance_class" {
  type = string
  default = "db.t2.micro"
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID for cert-manager Route53 integration"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for cert-manager Route53 integration"
  type        = string
  default     = ""
  sensitive   = true
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS01 challenge"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for the Kubernetes API and certificates"
  type        = string
  default     = "coderedalarmtech.com"
}

variable "rds_password" {
  description = "Password for the RDS MySQL database"
  type        = string
  sensitive   = true
  default     = "SecurePassword123!"
}