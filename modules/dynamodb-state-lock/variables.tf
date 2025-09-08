# DynamoDB State Lock Module Variables

variable "table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
}

variable "hash_key" {
  description = "The attribute to use as the hash (partition) key"
  type        = string
  default     = "LockID"
}

variable "billing_mode" {
  description = "Controls how you are charged for read and write throughput and how you manage capacity"
  type        = string
  default     = "PAY_PER_REQUEST"
  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.billing_mode)
    error_message = "Billing mode must be either PROVISIONED or PAY_PER_REQUEST."
  }
}

variable "read_capacity_units" {
  description = "The number of read units for this table (only used with PROVISIONED billing mode)"
  type        = number
  default     = 5
}

variable "write_capacity_units" {
  description = "The number of write units for this table (only used with PROVISIONED billing mode)"
  type        = number
  default     = 5
}

variable "point_in_time_recovery_enabled" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "server_side_encryption_enabled" {
  description = "Enable server-side encryption"
  type        = bool
  default     = true
}

variable "auto_scaling_enabled" {
  description = "Enable auto-scaling for provisioned capacity"
  type        = bool
  default     = false
}

variable "auto_scaling_target_value" {
  description = "Target value for auto-scaling (percentage of capacity utilization)"
  type        = number
  default     = 70.0
}

variable "global_secondary_indexes" {
  description = "Describe a GSI for the table"
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = optional(string)
    projection_type    = string
    non_key_attributes = optional(list(string))
    read_capacity_units  = optional(number)
    write_capacity_units = optional(number)
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to assign to the table"
  type        = map(string)
  default     = {}
}
