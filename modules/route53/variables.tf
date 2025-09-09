# Route53 Module Variables

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the hosted zone"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for private hosted zone"
  type        = string
}

variable "create_private_zone" {
  description = "Whether to create a private hosted zone"
  type        = bool
  default     = false
}

variable "records" {
  description = "Map of Route53 records to create"
  type = map(object({
    name    = string
    type    = string
    ttl     = optional(number)
    records = optional(list(string))
    zone_type = string # "public" or "private"
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = bool
    }))
  }))
  default = {}
}

variable "create_certificate" {
  description = "Whether to create an ACM certificate"
  type        = bool
  default     = false
}

variable "certificate_domain_name" {
  description = "Domain name for the ACM certificate"
  type        = string
  default     = null
}

variable "certificate_san_domains" {
  description = "Subject alternative names for the ACM certificate"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
