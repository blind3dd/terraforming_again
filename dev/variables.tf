# Development Environment Variables
# Based on test environment but with dev-specific defaults

# Terraform Backend Configuration Variables
variable "create_backend" {
  type = bool
  default = false
  description = "Whether to create the Terraform backend infrastructure (S3 bucket and DynamoDB table)"
}

variable "state_bucket_name" {
  type = string
  default = "terraform-state-bucket-database-ci-dev"
  description = "Name of the S3 bucket for Terraform state"
}

variable "state_table_name" {
  type = string
  default = "terraform-state-lock-dev"
  description = "Name of the DynamoDB table for state locking"
}

variable region {
   type = string
   default = "us-east-1"
   description = "The region to deploy to"
   validation {
    condition = contains(["us-east-1", "us-west-2"], var.region)
    error_message = "Region must be either us-east-1 or us-west-2"
   }
}

variable "environment" {
  type = string
  default = "dev"
  description = "The environment to deploy to"
  validation {
    condition = contains(["dev", "dev-canary"], var.environment)
    error_message = "Environment must be either dev or dev-canary"
  }
}

variable "main_vpc_cidr" {
  type = string
  default = "10.1.0.0/16"
  description = "The CIDR block for the main VPC"
}

variable "private_subnet_range_a" {
  type = string
  default = "10.1.1.0/24"
  description = "The CIDR block for the private subnet A"
}

variable "private_subnet_range_b" {
  type = string
  default = "10.1.2.0/24"
  description = "The CIDR block for the private subnet B"
}

variable "public_subnet_range" {
  type = string
  default = "10.1.0.0/24"
  description = "The CIDR block for the public subnet"
}

# Database Configuration
variable "db_name" {
  type = string
  default = "dev_database"
  description = "The name of the database"
}

variable "db_username" {
  type = string
  default = "dev_admin"
  description = "The username for the database"
}

variable "db_password" {
  type = string
  default = "dev_password_123"
  description = "The password for the database"
  sensitive = true
}

variable "db_port" {
  type = number
  default = 3306
  description = "The port for the database"
}

variable "db_engine" {
  type = string
  default = "mysql"
  description = "The database engine"
}

variable "db_engine_version" {
  type = string
  default = "8.0"
  description = "The database engine version"
}

variable "db_instance_class" {
  type = string
  default = "db.t3.micro"
  description = "The database instance class"
}

# EC2 Configuration
variable "instance_type" {
  type = string
  default = "t3.micro"
  description = "The EC2 instance type"
}

variable "ami_id" {
  type = string
  default = ""
  description = "The AMI ID for the EC2 instance"
}

variable "key_name" {
  type = string
  default = "dev-key"
  description = "The key pair name for the EC2 instance"
}

# SSM Parameters
variable "db_password_param" {
  type = string
  default = "/dev/database/password"
  description = "SSM parameter for database password"
}

variable "db_host_param" {
  type = string
  default = "/dev/database/host"
  description = "SSM parameter for database host"
}

variable "db_port_param" {
  type = string
  default = "/dev/database/port"
  description = "SSM parameter for database port"
}

variable "db_name_param" {
  type = string
  default = "/dev/database/name"
  description = "SSM parameter for database name"
}

variable "db_username_param" {
  type = string
  default = "/dev/database/username"
  description = "SSM parameter for database username"
}

variable "db_engine_param" {
  type = string
  default = "/dev/database/engine"
  description = "SSM parameter for database engine"
}

variable "db_engine_version_param" {
  type = string
  default = "/dev/database/engine_version"
  description = "SSM parameter for database engine version"
}

variable "db_instance_class_param" {
  type = string
  default = "/dev/database/instance_class"
  description = "SSM parameter for database instance class"
}

# KMS Configuration
variable "kms_key_id" {
  type = string
  default = ""
  description = "The KMS key ID for encryption"
}

variable "kms_key_alias" {
  type = string
  default = "dev-database-key"
  description = "The KMS key alias"
}

variable "kms_key_description" {
  type = string
  default = "KMS key for dev database encryption"
  description = "The KMS key description"
}

variable "kms_key_usage" {
  type = string
  default = "ENCRYPT_DECRYPT"
  description = "The KMS key usage"
}

variable "kms_key_deletion_window" {
  type = number
  default = 7
  description = "The KMS key deletion window in days"
}

variable "kms_key_enable_key_rotation" {
  type = bool
  default = true
  description = "Enable automatic key rotation"
}

variable "kms_key_policy" {
  type = string
  default = ""
  description = "The KMS key policy"
}

variable "kms_key_tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Purpose = "database-encryption"
  }
  description = "Tags for the KMS key"
}

# Common Tags
variable "common_tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Project = "database-ci"
    ManagedBy = "terraform"
  }
  description = "Common tags for all resources"
}

variable "db_password_param_pass" {
  type = string
  default = "dev_password_123"
  description = "Password for SSM parameter"
  sensitive = true
}

# Additional variables for RDS
variable "db_allocated_storage" {
  type = number
  default = 20
  description = "The allocated storage for the database"
}

variable "db_max_allocated_storage" {
  type = number
  default = 100
  description = "The maximum allocated storage for the database"
}

variable "db_storage_encrypted" {
  type = bool
  default = true
  description = "Enable storage encryption for the database"
}

variable "db_backup_retention_period" {
  type = number
  default = 7
  description = "The backup retention period in days"
}

variable "db_backup_window" {
  type = string
  default = "03:00-04:00"
  description = "The backup window"
}

variable "db_maintenance_window" {
  type = string
  default = "sun:04:00-sun:05:00"
  description = "The maintenance window"
}

variable "db_multi_az" {
  type = bool
  default = false
  description = "Enable multi-AZ deployment"
}

variable "db_publicly_accessible" {
  type = bool
  default = false
  description = "Make the database publicly accessible"
}

variable "db_skip_final_snapshot" {
  type = bool
  default = true
  description = "Skip final snapshot when deleting"
}

variable "db_final_snapshot_identifier" {
  type = string
  default = "dev-database-final-snapshot"
  description = "The final snapshot identifier"
}

variable "db_deletion_protection" {
  type = bool
  default = false
  description = "Enable deletion protection"
}

variable "db_performance_insights_enabled" {
  type = bool
  default = true
  description = "Enable Performance Insights"
}

variable "db_performance_insights_retention_period" {
  type = number
  default = 7
  description = "Performance Insights retention period in days"
}

variable "db_monitoring_interval" {
  type = number
  default = 60
  description = "Enhanced monitoring interval in seconds"
}

variable "db_monitoring_role_arn" {
  type = string
  default = ""
  description = "The ARN of the monitoring role"
}

variable "db_enabled_cloudwatch_logs_exports" {
  type = list(string)
  default = ["error", "general", "slow_query"]
  description = "List of log types to export to CloudWatch"
}

variable "db_parameter_group_name" {
  type = string
  default = ""
  description = "The parameter group name"
}

variable "db_option_group_name" {
  type = string
  default = ""
  description = "The option group name"
}

variable "db_license_model" {
  type = string
  default = "general-public-license"
  description = "The license model"
}

variable "db_auto_minor_version_upgrade" {
  type = bool
  default = true
  description = "Enable automatic minor version upgrades"
}

variable "db_apply_immediately" {
  type = bool
  default = false
  description = "Apply changes immediately"
}

variable "db_copy_tags_to_snapshot" {
  type = bool
  default = true
  description = "Copy tags to snapshots"
}

variable "db_delete_automated_backups" {
  type = bool
  default = true
  description = "Delete automated backups when deleting the database"
}

variable "db_iam_database_authentication_enabled" {
  type = bool
  default = false
  description = "Enable IAM database authentication"
}

variable "db_manage_master_user_password" {
  type = bool
  default = false
  description = "Manage master user password with AWS Secrets Manager"
}

variable "db_master_user_secret_kms_key_id" {
  type = string
  default = ""
  description = "KMS key ID for master user secret"
}

variable "db_network_type" {
  type = string
  default = "IPV4"
  description = "The network type"
}

variable "db_storage_throughput" {
  type = number
  default = 0
  description = "The storage throughput"
}

variable "db_storage_type" {
  type = string
  default = "gp2"
  description = "The storage type"
}

variable "db_tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Purpose = "development-database"
  }
  description = "Tags for the database"
}

# EC2 Additional Variables
variable "user_data" {
  type = string
  default = ""
  description = "User data script for EC2 instance"
}

variable "iam_instance_profile" {
  type = string
  default = ""
  description = "IAM instance profile for EC2 instance"
}

variable "associate_public_ip_address" {
  type = bool
  default = true
  description = "Associate public IP address with EC2 instance"
}

variable "monitoring" {
  type = bool
  default = true
  description = "Enable detailed monitoring for EC2 instance"
}

variable "ebs_optimized" {
  type = bool
  default = false
  description = "Enable EBS optimization for EC2 instance"
}

variable "root_block_device" {
  type = list(object({
    volume_type = string
    volume_size = number
    encrypted = bool
    delete_on_termination = bool
  }))
  default = [{
    volume_type = "gp3"
    volume_size = 20
    encrypted = true
    delete_on_termination = true
  }]
  description = "Root block device configuration"
}

variable "ebs_block_device" {
  type = list(object({
    device_name = string
    volume_type = string
    volume_size = number
    encrypted = bool
    delete_on_termination = bool
  }))
  default = []
  description = "EBS block device configuration"
}

variable "ephemeral_block_device" {
  type = list(object({
    device_name = string
    virtual_name = string
  }))
  default = []
  description = "Ephemeral block device configuration"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Purpose = "development-instance"
  }
  description = "Tags for EC2 instance"
}
