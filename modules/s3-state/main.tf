# S3 State Bucket Module
# Creates an S3 bucket for Terraform state storage with security best practices

resource "aws_s3_bucket" "state_bucket" {
  bucket = var.bucket_name

  tags = merge(var.tags, {
    Name        = "Terraform State Bucket"
    Purpose     = "terraform-state"
    Module      = "s3-state"
  })
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.encryption_algorithm
    }
    bucket_key_enabled = var.bucket_key_enabled
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "state_bucket" {
  count  = var.lifecycle_enabled ? 1 : 0
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    id     = "terraform_state_lifecycle"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_upload_days
    }
  }
}

# S3 Bucket Notification Configuration (optional)
resource "aws_s3_bucket_notification" "state_bucket" {
  count  = var.notification_enabled ? 1 : 0
  bucket = aws_s3_bucket.state_bucket.id

  dynamic "eventbridge" {
    for_each = var.eventbridge_enabled ? [1] : []
    content {
      eventbridge_enabled = true
    }
  }
}
