# VPC Module Variables

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

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
  description = "Custom ingress rules for the security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "create_dhcp_options" {
  description = "Whether to create DHCP options set"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name for private FQDN resolution"
  type        = string
  default     = null
}

variable "dhcp_domain_name_servers" {
  description = "List of DNS servers for DHCP options"
  type        = list(string)
  default     = ["AmazonProvidedDNS", "8.8.8.8", "8.8.4.4"]
}

variable "dhcp_ntp_servers" {
  description = "List of NTP servers for DHCP options"
  type        = list(string)
  default     = ["169.254.169.123", "pool.ntp.org"]
}

variable "dhcp_netbios_name_servers" {
  description = "List of NetBIOS name servers for DHCP options"
  type        = list(string)
  default     = ["169.254.169.123"]
}

variable "dhcp_netbios_node_type" {
  description = "NetBIOS node type for DHCP options"
  type        = number
  default     = 2
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}