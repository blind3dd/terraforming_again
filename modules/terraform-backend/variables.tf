# Terraform Backend Module Variables

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
}

variable "state_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
}

variable "region" {
  description = "AWS region for the backend resources"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
