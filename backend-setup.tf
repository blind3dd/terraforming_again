# Terraform Backend Infrastructure Setup
# This creates the S3 bucket and DynamoDB table needed for remote state management using modules

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

# Variables for backend configuration
variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "terraform-state-bucket-database-ci"
}

variable "state_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "region" {
  description = "AWS region for the backend resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "production"
}

# S3 Bucket for Terraform State using module
module "s3_state_bucket" {
  source = "./modules/s3-state"

  bucket_name = var.state_bucket_name
  versioning_enabled = true
  encryption_algorithm = "AES256"
  lifecycle_enabled = true
  noncurrent_version_expiration_days = 30
  abort_incomplete_multipart_upload_days = 7

  tags = {
    Environment = var.environment
    Project     = "database-ci"
    ManagedBy   = "terraform"
  }
}

# DynamoDB Table for State Locking using module
module "dynamodb_state_lock" {
  source = "./modules/dynamodb-state-lock"

  table_name = var.state_table_name
  billing_mode = "PAY_PER_REQUEST"
  point_in_time_recovery_enabled = true
  server_side_encryption_enabled = true

  tags = {
    Environment = var.environment
    Project     = "database-ci"
    ManagedBy   = "terraform"
  }
}

# Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = module.s3_state_bucket.bucket_id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = module.dynamodb_state_lock.table_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3_state_bucket.bucket_arn
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.dynamodb_state_lock.table_arn
}
