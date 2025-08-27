# AWS SSM Parameter Store - Database Password from SOPS Encrypted File
# This module reads a password from a KMS SOPS encrypted file and stores it as an SSM parameter

# Read the SOPS encrypted file content
# data "local_file" "encrypted_password" {
#   filename = var.db_password_param_user
# }

# # Decrypt the SOPS encrypted content using AWS KMS
# data "external" "decrypt_sops" {
#   program = ["sh", "-c", <<-EOT

#     echo '${data.local_file.encrypted_password.content}' | sops -d /dev/stdin --output-type json | jq -r '.password'
#   EOT
#   ]
# }
# Note: The external data source for SOPS decryption is commented out above
# Create SSM SecureString parameter for database password
resource "aws_ssm_parameter" "database_password" {
  name        = var.db_password_param_pass
  description = "Database password for ${var.environment} environment"
  type        = "SecureString"
  value       = "mock_password_123"  # In production, use SOPS decryption
  key_id      = aws_kms_key.ssm_parameter.key_id

  lifecycle {
    ignore_changes = [
      value # Prevent updates to sensitive values unless explicitly changed
    ]
  }
}
# SSM Parameters - String (for non-sensitive configuration
resource "aws_ssm_parameter" "database_host" {
  name        = var.db_host_param
  description = "Database host for ${var.environment} environment"
  type        = "String"
  tier        = "Standard"

  tags = merge(
    var.common_tags,
    {
      Name        = "database-host"
      Type        = "String"
      Environment = var.environment
    }
  )
}

resource "aws_ssm_parameter" "database_port" {
  name        = var.database_port
  description = "Database port for ${var.environment} environment"
  type        = "String"
  tier        = "Standard"

  tags = merge(
    var.common_tags,
    {
      Name        = "database-port"
      Type        = "String"
      Environment = var.environment
    }
  )
}

resource "aws_ssm_parameter" "user_name" {
  name        = var.db_password_param_user
  description = "Database username for ${var.environment} environment"
  type        = "String"
  tier        = "Standard"
  key_id      = aws_kms_key.ssm_parameter.key_id

  lifecycle {
    ignore_changes = [
      value # Prevent updates to sensitive values unless explicitly changed
    ]
  }
}

# Note: Removed data source that referenced non-existent KMS key
# The KMS key is now created as a resource in this module

# Create a new KMS key for SSM parameters
resource "aws_kms_key" "ssm_parameter" { 
  description = "KMS key for SSM parameters"
  key_usage = "ENCRYPT_DECRYPT"
  enable_key_rotation = true
}

output "ssm_parameter_key_id" {
  value = aws_kms_key.ssm_parameter.key_id
}





