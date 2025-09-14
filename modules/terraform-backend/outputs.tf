# Terraform Backend Module Outputs

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

output "backend_config" {
  description = "Backend configuration for provider.tf"
  value = {
    bucket         = module.s3_state_bucket.bucket_id
    key            = "terraform.tfstate"
    region         = var.region
    dynamodb_table = module.dynamodb_state_lock.table_name
    encrypt        = true
  }
}
