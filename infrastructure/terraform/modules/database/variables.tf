# Database Module Variables

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "database_security_group_id" {
  description = "ID of the database security group"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for Route53"
  type        = string
  default     = ""
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



