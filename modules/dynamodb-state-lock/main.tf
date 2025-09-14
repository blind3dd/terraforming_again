# DynamoDB State Lock Module
# Creates a DynamoDB table for Terraform state locking

resource "aws_dynamodb_table" "state_lock" {
  name           = var.table_name
  billing_mode   = var.billing_mode
  hash_key       = var.hash_key

  attribute {
    name = var.hash_key
    type = "S"
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = var.point_in_time_recovery_enabled
  }

  # Server-side encryption
  server_side_encryption {
    enabled = var.server_side_encryption_enabled
  }

  # Tags
  tags = merge(var.tags, {
    Name        = "Terraform State Lock Table"
    Purpose     = "terraform-state-lock"
    Module      = "dynamodb-state-lock"
  })

  # Provisioned capacity (only used if billing_mode is PROVISIONED)
  dynamic "provisioned_throughput" {
    for_each = var.billing_mode == "PROVISIONED" ? [1] : []
    content {
      read_capacity_units  = var.read_capacity_units
      write_capacity_units = var.write_capacity_units
    }
  }

  # Auto-scaling (only used if billing_mode is PROVISIONED and auto_scaling is enabled)
  dynamic "autoscaling" {
    for_each = var.billing_mode == "PROVISIONED" && var.auto_scaling_enabled ? [1] : []
    content {
      target_tracking_scaling_policy_configuration {
        predefined_metric_specification {
          predefined_metric_type = "DynamoDBReadCapacityUtilization"
        }
        target_value = var.auto_scaling_target_value
      }
    }
  }

  # Global secondary indexes (if any)
  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = lookup(global_secondary_index.value, "range_key", null)
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = lookup(global_secondary_index.value, "non_key_attributes", null)

      dynamic "provisioned_throughput" {
        for_each = var.billing_mode == "PROVISIONED" ? [1] : []
        content {
          read_capacity_units  = lookup(global_secondary_index.value, "read_capacity_units", var.read_capacity_units)
          write_capacity_units = lookup(global_secondary_index.value, "write_capacity_units", var.write_capacity_units)
        }
      }
    }
  }
}
