# Development Environment Configuration
environment = "dev"
region = "us-east-1"
main_vpc_cidr = "10.1.0.0/16"
private_subnet_range_a = "10.1.1.0/24"
private_subnet_range_b = "10.1.2.0/24"
public_subnet_range = "10.1.0.0/24"

# Database Configuration
db_name = "dev_database"
db_username = "dev_admin"
db_password = "dev_password_123"
db_instance_class = "db.t3.micro"

# EC2 Configuration
instance_type = "t3.micro"
key_name = "dev-key"

# SSM Parameters
db_password_param = "/dev/database/password"
db_host_param = "/dev/database/host"
db_port_param = "/dev/database/port"
db_name_param = "/dev/database/name"
db_username_param = "/dev/database/username"
db_engine_param = "/dev/database/engine"
db_engine_version_param = "/dev/database/engine_version"
db_instance_class_param = "/dev/database/instance_class"

# KMS Configuration
kms_key_alias = "dev-database-key"
kms_key_description = "KMS key for dev database encryption"

# RDS Configuration
db_allocated_storage = 20
db_max_allocated_storage = 100
db_backup_retention_period = 7
db_skip_final_snapshot = true
db_deletion_protection = false
db_performance_insights_enabled = true
db_multi_az = false
