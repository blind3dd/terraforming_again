# ECR Module Variables

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
}

variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "go-mysql-api"
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "The encryption type to use for the repository"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Encryption type must be either AES256 or KMS."
  }
}

variable "create_repository_policy" {
  description = "Whether to create a repository policy"
  type        = bool
  default     = true
}

variable "repository_policy" {
  description = "The policy document for the repository. If null, a default policy will be created"
  type        = string
  default     = null
}

variable "create_lifecycle_policy" {
  description = "Whether to create a lifecycle policy"
  type        = bool
  default     = true
}

variable "lifecycle_policy" {
  description = "The lifecycle policy document for the repository. If null, a default policy will be created"
  type        = string
  default     = null
}

variable "keep_tagged_images" {
  description = "Number of tagged images to keep"
  type        = number
  default     = 5
}

variable "tag_prefix_list" {
  description = "List of tag prefixes to apply lifecycle policy to"
  type        = list(string)
  default     = ["v"]
}

variable "untagged_image_retention_days" {
  description = "Number of days to retain untagged images"
  type        = number
  default     = 1
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
