# S3 State Bucket Module Variables

variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
}

variable "versioning_enabled" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "encryption_algorithm" {
  description = "Server-side encryption algorithm"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_algorithm)
    error_message = "Encryption algorithm must be either AES256 or aws:kms."
  }
}

variable "bucket_key_enabled" {
  description = "Enable bucket key for S3 Bucket SSE-KMS encryption"
  type        = bool
  default     = false
}

variable "lifecycle_enabled" {
  description = "Enable lifecycle configuration for the bucket"
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days after which non-current versions expire"
  type        = number
  default     = 30
}

variable "abort_incomplete_multipart_upload_days" {
  description = "Number of days after which incomplete multipart uploads are aborted"
  type        = number
  default     = 7
}

variable "notification_enabled" {
  description = "Enable S3 bucket notifications"
  type        = bool
  default     = false
}

variable "eventbridge_enabled" {
  description = "Enable EventBridge notifications"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the bucket"
  type        = map(string)
  default     = {}
}
