# Test Environment Terraform Variables
# This file contains the actual values for the test environment

# =============================================================================
# GENERAL CONFIGURATION
# =============================================================================

environment = "test"
service_name = "database-ci"
project_name = "database-ci"
aws_region = "us-east-1"
aws_profile = null  # Use default profile

# =============================================================================
# VPC CONFIGURATION
# =============================================================================

vpc_cidr = "10.1.0.0/16"
public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.20.0/24"]
availability_zones = ["us-east-1a", "us-east-1b"]

# DHCP Options
create_dhcp_options = true
domain_name = "internal.coderedalarmtech.com"
dhcp_domain_name_servers = ["AmazonProvidedDNS"]
dhcp_ntp_servers = ["169.254.169.123"]
dhcp_netbios_name_servers = []
dhcp_netbios_node_type = 2

# Security Groups
ssh_cidr_blocks = ["10.1.0.0/16"]  # Only allow SSH from VPC
http_cidr_blocks = ["10.1.0.0/16"]  # Only allow HTTP from VPC
https_cidr_blocks = ["10.1.0.0/16"]  # Only allow HTTPS from VPC
custom_ingress_rules = []

# =============================================================================
# EC2 CONFIGURATION
# =============================================================================

ec2_ami_id = "ami-0c02fb55956c7d316"  # Amazon Linux 2
ec2_instance_type = "t3.medium"
ec2_associate_public_ip = false
ec2_root_volume_size = 20
ec2_root_volume_type = "gp3"
ec2_encrypt_root_volume = true
ec2_user_data = ""
ec2_create_cloudinit_config = true
ec2_create_ec2_user_password = true

# =============================================================================
# RDS CONFIGURATION
# =============================================================================

rds_engine_version = "8.0"
rds_instance_class = "db.t3.micro"
rds_allocated_storage = 20
rds_max_allocated_storage = 100
rds_storage_type = "gp2"
rds_storage_encrypted = true
rds_database_name = "database_ci_test"
rds_master_username = "admin"
rds_master_password = "TestPassword123!"
rds_master_password_param = "/rds/test/master-password"
rds_backup_retention_period = 7
rds_backup_window = "03:00-04:00"
rds_maintenance_window = "sun:04:00-sun:05:00"
rds_multi_az = false
rds_monitoring_interval = 0
rds_deletion_protection = false
rds_skip_final_snapshot = true
rds_mysql_cidr_blocks = [{
  cidr_block = "10.1.0.0/16"
  description = "VPC CIDR for MySQL access"
}]

# =============================================================================
# ROUTE53 CONFIGURATION
# =============================================================================

create_private_zone = true
route53_records = {
  "test-api" = {
    name = "test-api"
    type = "A"
    ttl = 300
    records = ["10.1.10.10"]  # Will be updated with actual EC2 private IP
    zone_type = "private"
  }
  "test-web" = {
    name = "test-web"
    type = "A"
    ttl = 300
    records = ["10.1.10.11"]  # Will be updated with actual EC2 private IP
    zone_type = "private"
  }
  "test-rds" = {
    name = "test-rds"
    type = "CNAME"
    ttl = 300
    records = ["database-ci-test-rds.internal.coderedalarmtech.com"]
    zone_type = "private"
  }
}
create_certificate = false
certificate_domain_name = "*.test.example.com"
certificate_san_domains = []

# =============================================================================
# ECR CONFIGURATION
# =============================================================================

ecr_repository_url = ""
