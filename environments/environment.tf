# Environment Configuration Template
# This file sources the appropriate modules based on environment variables

# Terraform Backend Infrastructure (optional)
module "terraform_backend" {
  count  = var.create_backend ? 1 : 0
  source = "../../modules/terraform-backend"

  state_bucket_name = var.state_bucket_name
  state_table_name  = var.state_table_name
  region           = var.region
  environment      = var.environment
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  
  region                    = var.region
  environment              = var.environment
  main_vpc_cidr           = var.main_vpc_cidr
  private_subnet_range_a  = var.private_subnet_range_a
  private_subnet_range_b  = var.private_subnet_range_b
  public_subnet_range_a   = var.public_subnet_range
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  db_port                 = var.db_port
  db_engine               = var.db_engine
  db_engine_version       = var.db_engine_version
  db_instance_class       = var.db_instance_class
  db_password_param       = var.db_password_param
  db_host_param           = var.db_host_param
  db_port_param           = var.db_port_param
  db_name_param           = var.db_name_param
  db_username_param       = var.db_username_param
  db_engine_param         = var.db_engine_param
  db_engine_version_param = var.db_engine_version_param
  db_instance_class_param = var.db_instance_class_param
  kms_key_id              = var.kms_key_id
  kms_key_alias           = var.kms_key_alias
  kms_key_description     = var.kms_key_description
  kms_key_usage           = var.kms_key_usage
  kms_key_deletion_window = var.kms_key_deletion_window
  kms_key_enable_key_rotation = var.kms_key_enable_key_rotation
  kms_key_policy          = var.kms_key_policy
  kms_key_tags            = var.kms_key_tags
}

# RDS Module
module "rds" {
  source = "../../modules/RDS"
  
  region                    = var.region
  environment              = var.environment
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  db_port                 = var.db_port
  db_engine               = var.db_engine
  db_engine_version       = var.db_engine_version
  db_instance_class       = var.db_instance_class
  db_allocated_storage    = var.db_allocated_storage
  db_max_allocated_storage = var.db_max_allocated_storage
  db_storage_encrypted    = var.db_storage_encrypted
  db_backup_retention_period = var.db_backup_retention_period
  db_backup_window        = var.db_backup_window
  db_maintenance_window   = var.db_maintenance_window
  db_multi_az             = var.db_multi_az
  db_publicly_accessible  = var.db_publicly_accessible
  db_skip_final_snapshot  = var.db_skip_final_snapshot
  db_final_snapshot_identifier = var.db_final_snapshot_identifier
  db_deletion_protection  = var.db_deletion_protection
  db_performance_insights_enabled = var.db_performance_insights_enabled
  db_performance_insights_retention_period = var.db_performance_insights_retention_period
  db_monitoring_interval  = var.db_monitoring_interval
  db_monitoring_role_arn  = var.db_monitoring_role_arn
  db_enabled_cloudwatch_logs_exports = var.db_enabled_cloudwatch_logs_exports
  db_parameter_group_name = var.db_parameter_group_name
  db_option_group_name    = var.db_option_group_name
  db_license_model        = var.db_license_model
  db_auto_minor_version_upgrade = var.db_auto_minor_version_upgrade
  db_apply_immediately    = var.db_apply_immediately
  db_copy_tags_to_snapshot = var.db_copy_tags_to_snapshot
  db_delete_automated_backups = var.db_delete_automated_backups
  db_iam_database_authentication_enabled = var.db_iam_database_authentication_enabled
  db_manage_master_user_password = var.db_manage_master_user_password
  db_master_user_secret_kms_key_id = var.db_master_user_secret_kms_key_id
  db_network_type         = var.db_network_type
  db_storage_throughput   = var.db_storage_throughput
  db_storage_type         = var.db_storage_type
  db_tags                 = var.db_tags
  db_vpc_security_group_ids = [module.vpc.rds_security_group_id]
  db_subnet_group_name    = module.vpc.rds_subnet_group_name
  db_password_param       = var.db_password_param
  db_host_param           = var.db_host_param
  db_port_param           = var.db_port_param
  db_name_param           = var.db_name_param
  db_username_param       = var.db_username_param
  db_engine_param         = var.db_engine_param
  db_engine_version_param = var.db_engine_version_param
  db_instance_class_param = var.db_instance_class_param
  kms_key_id              = var.kms_key_id
  kms_key_alias           = var.kms_key_alias
  kms_key_description     = var.kms_key_description
  kms_key_usage           = var.kms_key_usage
  kms_key_deletion_window = var.kms_key_deletion_window
  kms_key_enable_key_rotation = var.kms_key_enable_key_rotation
  kms_key_policy          = var.kms_key_policy
  kms_key_tags            = var.kms_key_tags
}

# EC2 Module
module "ec2" {
  source = "../../modules/ec2"
  
  region                    = var.region
  environment              = var.environment
  instance_type            = var.instance_type
  ami_id                   = var.ami_id
  key_name                 = var.key_name
  vpc_security_group_ids   = [module.vpc.ec2_security_group_id]
  subnet_id                = module.vpc.public_subnet_ids[0]
  user_data                = var.user_data
  iam_instance_profile     = var.iam_instance_profile
  associate_public_ip_address = var.associate_public_ip_address
  monitoring               = var.monitoring
  ebs_optimized            = var.ebs_optimized
  root_block_device        = var.root_block_device
  ebs_block_device         = var.ebs_block_device
  ephemeral_block_device   = var.ephemeral_block_device
  tags                     = var.tags
}

# SSM Module
module "ssm" {
  source = "../../modules/ssm"
  
  region                    = var.region
  environment              = var.environment
  db_password_param        = var.db_password_param
  db_host_param            = var.db_host_param
  db_port_param            = var.db_port_param
  db_name_param            = var.db_name_param
  db_username_param        = var.db_username_param
  db_engine_param          = var.db_engine_param
  db_engine_version_param  = var.db_engine_version_param
  db_instance_class_param  = var.db_instance_class_param
  kms_key_id               = var.kms_key_id
  kms_key_alias            = var.kms_key_alias
  kms_key_description      = var.kms_key_description
  kms_key_usage            = var.kms_key_usage
  kms_key_deletion_window  = var.kms_key_deletion_window
  kms_key_enable_key_rotation = var.kms_key_enable_key_rotation
  kms_key_policy           = var.kms_key_policy
  kms_key_tags             = var.kms_key_tags
}
