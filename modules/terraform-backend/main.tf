# Terraform Backend Infrastructure Module
# Creates S3 bucket and DynamoDB table for remote state management

# S3 Bucket for Terraform State using s3-state module
module "s3_state_bucket" {
  source = "../s3-state"

  bucket_name = var.state_bucket_name
  versioning_enabled = true
  encryption_algorithm = "AES256"
  lifecycle_enabled = true
  noncurrent_version_expiration_days = 30
  abort_incomplete_multipart_upload_days = 7

  tags = merge(var.tags, {
    Environment = var.environment
    Project     = "database-ci"
    ManagedBy   = "terraform"
    Module      = "terraform-backend"
  })
}

# DynamoDB Table for State Locking using dynamodb-state-lock module
module "dynamodb_state_lock" {
  source = "../dynamodb-state-lock"

  table_name = var.state_table_name
  billing_mode = "PAY_PER_REQUEST"
  point_in_time_recovery_enabled = true
  server_side_encryption_enabled = true

  tags = merge(var.tags, {
    Environment = var.environment
    Project     = "database-ci"
    ManagedBy   = "terraform"
    Module      = "terraform-backend"
  })
}
