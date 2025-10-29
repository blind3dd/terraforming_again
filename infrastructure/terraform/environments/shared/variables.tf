# Variable Definitions
# Shared variables file for all environments

# =============================================================================
# GENERAL CONFIGURATION
# =============================================================================

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod"
  }
}

variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "go-mysql-api"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "terraforming-again"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# =============================================================================
# VPC CONFIGURATION
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "172.16.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["172.16.10.0/24", "172.16.11.0/24", "172.16.12.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

# =============================================================================
# DHCP CONFIGURATION
# =============================================================================

variable "create_dhcp_options" {
  description = "Create DHCP options set"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for DHCP options"
  type        = string
  default     = "internal.coderedalarmtech.com"
}

variable "dhcp_domain_name_servers" {
  description = "DHCP domain name servers"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_ntp_servers" {
  description = "DHCP NTP servers"
  type        = list(string)
  default     = ["169.254.169.123"]
}

# =============================================================================
# SECURITY GROUPS CONFIGURATION
# =============================================================================

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

# =============================================================================
# COMPUTE CONFIGURATION
# =============================================================================

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "instance_ami" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0c02fb55956c7d316"  # Amazon Linux 2023
}

variable "associate_public_ip_address" {
  description = "Associate public IP address with instances"
  type        = bool
  default     = true
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 instances"
  type        = string
  default     = ""
  sensitive   = true
}

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "mock_user"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "db_user"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "RDS engine version"
  type        = string
  default     = "8.0.35"
}

# =============================================================================
# TAILSCALE CONFIGURATION
# =============================================================================

variable "enable_tailscale" {
  description = "Enable Tailscale VPN"
  type        = bool
  default     = false
}

variable "tailscale_auth_key" {
  description = "Tailscale auth key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = ""
}

