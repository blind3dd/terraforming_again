# Test Terraform Syntax Highlighting
# This file should show proper syntax highlighting when opened in VSCode/Cursor

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Test data source - should be highlighted
data "aws_caller_identity" "current" {}

# Test local values - should be highlighted
locals {
  test_value = "hello-world"
  test_tags = {
    Name        = "test-resource"
    Environment = "test"
  }
}

# Test resource - should be highlighted
resource "aws_s3_bucket" "test" {
  bucket = "test-bucket-${data.aws_caller_identity.current.account_id}"

  tags = local.test_tags
}

# Test output - should be highlighted
output "bucket_name" {
  description = "Name of the test bucket"
  value       = aws_s3_bucket.test.bucket
}



