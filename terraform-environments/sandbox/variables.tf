# Test Environment Variables
# This file defines all variables for the test environment

# =============================================================================
# GENERAL CONFIGURATION
# =============================================================================

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "sandbox"
}

variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "database-ci"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "database-ci"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile to use"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "test"
    Service     = "database-ci"
    ManagedBy   = "Terraform"
    Project     = "database-ci"
  }
}

# =============================================================================
# VPC CONFIGURATION
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.2.10.0/24", "10.2.20.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# DHCP Options
variable "create_dhcp_options" {
  description = "Whether to create DHCP options set"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for DHCP options"
  type        = string
  default     = "test.internal"
}

variable "dhcp_domain_name_servers" {
  description = "Domain name servers for DHCP options"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_ntp_servers" {
  description = "NTP servers for DHCP options"
  type        = list(string)
  default     = ["169.254.169.123"]
}

variable "dhcp_netbios_name_servers" {
  description = "NetBIOS name servers for DHCP options"
  type        = list(string)
  default     = []
}

variable "dhcp_netbios_node_type" {
  description = "NetBIOS node type for DHCP options"
  type        = number
  default     = 2
}

# Security Groups
variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "http_cidr_blocks" {
  description = "CIDR blocks allowed for HTTP access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_cidr_blocks" {
  description = "CIDR blocks allowed for HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "custom_ingress_rules" {
  description = "Custom ingress rules for security groups"
  type        = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

# =============================================================================
# EC2 CONFIGURATION
# =============================================================================

variable "ec2_ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0c02fb55956c7d316"  # Amazon Linux 2
}

variable "ec2_instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
  default     = "t3.medium"
}

variable "ec2_associate_public_ip" {
  description = "Whether to associate public IP with EC2 instances"
  type        = bool
  default     = true
}

variable "ec2_root_volume_size" {
  description = "Size of the root volume for EC2 instances"
  type        = number
  default     = 20
}

variable "ec2_root_volume_type" {
  description = "Type of the root volume for EC2 instances"
  type        = string
  default     = "gp3"
}

variable "ec2_encrypt_root_volume" {
  description = "Whether to encrypt the root volume"
  type        = bool
  default     = true
}

variable "ec2_user_data" {
  description = "User data script for EC2 instances"
  type        = string
  default     = ""
}

variable "ec2_create_cloudinit_config" {
  description = "Whether to create CloudInit configuration"
  type        = bool
  default     = true
}

variable "ec2_create_ec2_user_password" {
  description = "Whether to create EC2 user password"
  type        = bool
  default     = true
}

# =============================================================================
# RDS CONFIGURATION
# =============================================================================

variable "rds_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage for RDS instance"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Maximum allocated storage for RDS instance"
  type        = number
  default     = 100
}

variable "rds_storage_type" {
  description = "Storage type for RDS instance"
  type        = string
  default     = "gp2"
}

variable "rds_storage_encrypted" {
  description = "Whether to encrypt RDS storage"
  type        = bool
  default     = true
}

variable "rds_database_name" {
  description = "Name of the database"
  type        = string
  default     = "database_ci_test"
}

variable "rds_master_username" {
  description = "Master username for RDS instance"
  type        = string
  default     = "admin"
}

variable "rds_master_password" {
  description = "Master password for RDS instance"
  type        = string
  default     = "TestPassword123!"
  sensitive   = true
}

variable "rds_master_password_param" {
  description = "SSM parameter name for RDS master password"
  type        = string
  default     = "/rds/test/master-password"
}

variable "rds_backup_retention_period" {
  description = "Backup retention period for RDS instance"
  type        = number
  default     = 7
}

variable "rds_backup_window" {
  description = "Backup window for RDS instance"
  type        = string
  default     = "03:00-04:00"
}

variable "rds_maintenance_window" {
  description = "Maintenance window for RDS instance"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "rds_multi_az" {
  description = "Whether to enable Multi-AZ for RDS instance"
  type        = bool
  default     = false
}

variable "rds_monitoring_interval" {
  description = "Monitoring interval for RDS instance"
  type        = number
  default     = 0
}

variable "rds_deletion_protection" {
  description = "Whether to enable deletion protection for RDS instance"
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Whether to skip final snapshot when deleting RDS instance"
  type        = bool
  default     = true
}

variable "rds_mysql_cidr_blocks" {
  description = "CIDR blocks allowed for MySQL access"
  type        = list(object({
    cidr_block = string
    description = string
  }))
  default = [{
    cidr_block = "10.1.0.0/16"
    description = "VPC CIDR for MySQL access"
  }]
}

# =============================================================================
# ROUTE53 CONFIGURATION
# =============================================================================

variable "create_private_zone" {
  description = "Whether to create private Route53 zone"
  type        = bool
  default     = true
}

variable "route53_records" {
  description = "Route53 records to create"
  type        = map(object({
    name    = string
    type    = string
    ttl     = optional(number)
    records = optional(list(string))
    zone_type = string
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = bool
    }))
  }))
  default = {}
}

variable "create_certificate" {
  description = "Whether to create SSL certificate"
  type        = bool
  default     = false
}

variable "certificate_domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = "*.test.example.com"
}

variable "certificate_san_domains" {
  description = "Subject Alternative Names for SSL certificate"
  type        = list(string)
  default     = []
}

# =============================================================================
# ECR CONFIGURATION
# =============================================================================

variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
  default     = ""
}
