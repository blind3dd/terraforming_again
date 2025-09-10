# Minimal Dev Environment Terraform Configuration
# This file orchestrates basic modules for testing

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    # AWS Provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    
    # Utility Providers
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
    
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
    
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }

  # S3 Backend Configuration (commented out for local development)
  # backend "s3" {
  #   bucket         = "terraform-state-bucket-dev"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock-dev"
  #   encrypt        = true
  # }
}

# AWS Provider Configuration
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != null ? var.aws_profile : null
  
  default_tags {
    tags = {
      Environment = var.environment
      Service     = var.service_name
      ManagedBy   = "Terraform"
      Project     = var.project_name != null ? var.project_name : "database-ci"
    }
  }
}

# =============================================================================
# VPC INFRASTRUCTURE
# =============================================================================

# Create VPC with networking components
module "vpc" {
  source = "../../modules/vpc"

  environment = var.environment
  vpc_cidr    = var.vpc_cidr

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones

  # DHCP Options for private FQDN resolution
  create_dhcp_options = var.create_dhcp_options
  domain_name        = var.domain_name
  dhcp_domain_name_servers = var.dhcp_domain_name_servers
  dhcp_ntp_servers         = var.dhcp_ntp_servers
  dhcp_netbios_name_servers = var.dhcp_netbios_name_servers
  dhcp_netbios_node_type   = var.dhcp_netbios_node_type

  # Security Group Rules
  ssh_cidr_blocks   = var.ssh_cidr_blocks
  http_cidr_blocks  = var.http_cidr_blocks
  https_cidr_blocks = var.https_cidr_blocks
  custom_ingress_rules = var.custom_ingress_rules

  tags = var.tags
}

# =============================================================================
# EC2 INFRASTRUCTURE
# =============================================================================

# Create EC2 instances
module "ec2" {
  source = "../../modules/ec2"

  environment = var.environment
  service_name = var.service_name
  aws_region = var.aws_region

  # VPC Configuration
  vpc_id              = module.vpc.vpc_id
  public_subnet_id    = module.vpc.private_subnet_ids[0]
  security_group_id   = module.vpc.security_group_id

  # Instance Configuration
  ami_id              = var.ec2_ami_id
  instance_type       = var.ec2_instance_type
  associate_public_ip = var.ec2_associate_public_ip
  root_volume_size    = var.ec2_root_volume_size
  root_volume_type    = var.ec2_root_volume_type
  encrypt_root_volume = var.ec2_encrypt_root_volume
  user_data           = var.ec2_user_data

  # CloudInit Configuration
  create_cloudinit_config = var.ec2_create_cloudinit_config
  create_ec2_user_password = var.ec2_create_ec2_user_password

  # Database connection for cloudinit
  db_host = module.rds.db_instance_endpoint
  db_port = module.rds.db_instance_port
  db_name = module.rds.db_instance_name
  db_user = module.rds.db_instance_username
  db_password_param = var.rds_master_password_param
  ecr_repository_url = var.ecr_repository_url

  tags = var.tags
}

# =============================================================================
# RDS INFRASTRUCTURE
# =============================================================================

# Create RDS database
module "rds" {
  source = "../../modules/RDS"

  environment = var.environment
  service_name = var.service_name

  # VPC Configuration
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ec2_security_group_id = module.vpc.security_group_id

  # Database Configuration
  engine_version        = var.rds_engine_version
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  storage_type          = var.rds_storage_type
  storage_encrypted     = var.rds_storage_encrypted

  database_name  = var.rds_database_name
  master_username = var.rds_master_username
  master_password = var.rds_master_password

  backup_retention_period = var.rds_backup_retention_period
  backup_window          = var.rds_backup_window
  maintenance_window     = var.rds_maintenance_window
  multi_az              = var.rds_multi_az
  monitoring_interval   = var.rds_monitoring_interval
  deletion_protection   = var.rds_deletion_protection
  skip_final_snapshot   = var.rds_skip_final_snapshot

  mysql_cidr_blocks = var.rds_mysql_cidr_blocks

  tags = var.tags
}
