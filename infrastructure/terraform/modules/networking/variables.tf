# Networking Module Variables

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "create_dhcp_options" {
  description = "Create DHCP options set for private FQDNs"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for private FQDNs"
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

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["172.16.0.0/16"]
}

variable "http_cidr_blocks" {
  description = "CIDR blocks allowed for HTTP access"
  type        = list(string)
  default     = ["172.16.0.0/16"]
}

variable "https_cidr_blocks" {
  description = "CIDR blocks allowed for HTTPS access"
  type        = list(string)
  default     = ["172.16.0.0/16"]
}

variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}



