# EC2 Module Variables

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
}

variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "go-mysql-api"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the VPC where the EC2 instance will be created"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the subnet where the EC2 instance will be created (can be public or private)"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group to attach to the EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP address with the instance"
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 10
}

variable "root_volume_type" {
  description = "Type of the root volume"
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "Root volume type must be one of: gp2, gp3, io1, io2."
  }
}

variable "encrypt_root_volume" {
  description = "Whether to encrypt the root volume"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = null
}

variable "create_ec2_user_password" {
  description = "Whether to create a random password for ec2-user"
  type        = bool
  default     = false
}

variable "create_cloudinit_config" {
  description = "Whether to create cloudinit configuration"
  type        = bool
  default     = false
}

# Database connection variables for cloudinit
variable "db_host" {
  description = "Database host for cloudinit script"
  type        = string
  default     = null
}

variable "db_port" {
  description = "Database port for cloudinit script"
  type        = number
  default     = 3306
}

variable "db_name" {
  description = "Database name for cloudinit script"
  type        = string
  default     = null
}

variable "db_user" {
  description = "Database user for cloudinit script"
  type        = string
  default     = null
}

variable "db_password_param" {
  description = "SSM parameter name for database password"
  type        = string
  default     = null
}

variable "ecr_repository_url" {
  description = "ECR repository URL for cloudinit script"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}