# Dev Environment Terraform Configuration
# This file orchestrates all modules to create the complete infrastructure for dev environment

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
    
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
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
# TERRAFORM BACKEND INFRASTRUCTURE (Optional)
# =============================================================================

# Create Terraform backend infrastructure (S3 + DynamoDB) if requested
module "terraform_backend" {
  count  = var.create_backend ? 1 : 0
  source = "../../modules/terraform-backend"

  state_bucket_name = var.state_bucket_name
  state_table_name  = var.state_table_name
  region           = var.aws_region
  environment      = var.environment
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

# =============================================================================
# ROUTE53 DNS INFRASTRUCTURE
# =============================================================================

# Create Route53 DNS records and certificates
module "route53" {
  source = "../../modules/route53"

  environment = var.environment
  domain_name = var.domain_name
  vpc_id      = module.vpc.vpc_id

  # Private Zone
  create_private_zone = var.create_private_zone

  # DNS Records
  records = var.route53_records

  # SSL Certificate
  create_certificate        = var.create_certificate
  certificate_domain_name   = var.certificate_domain_name
  certificate_san_domains   = var.certificate_san_domains

  tags = var.tags
}

# =============================================================================
# KUBERNETES INFRASTRUCTURE
# =============================================================================

# Create EKS cluster (managed Kubernetes)
module "kubernetes_eks" {
  count = var.kubernetes_cluster_type == "eks" ? 1 : 0
  source = "../../modules/kubernetes-eks"

  environment = var.environment
  service_name = var.service_name

  # VPC Configuration
  vpc_id       = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  # EKS Configuration
  kubernetes_version = var.kubernetes_version
  eks_endpoint_private_access = var.eks_endpoint_private_access
  eks_endpoint_public_access  = var.eks_endpoint_public_access
  eks_public_access_cidrs     = var.eks_public_access_cidrs
  eks_enabled_log_types       = var.eks_enabled_log_types
  eks_capacity_type           = var.eks_capacity_type
  eks_instance_types          = var.eks_instance_types
  eks_ami_type                = var.eks_ami_type
  eks_disk_size              = var.eks_disk_size
  eks_desired_size           = var.eks_desired_size
  eks_max_size               = var.eks_max_size
  eks_min_size               = var.eks_min_size
  eks_max_unavailable_percentage = var.eks_max_unavailable_percentage

  tags = var.tags
}

# Create self-managed Kubernetes cluster (3 etcd, 3 control planes, 3 workers)
module "kubernetes_self_managed" {
  count = var.kubernetes_cluster_type == "self-managed" ? 1 : 0
  source = "../../modules/kubernetes-self-managed"

  environment = var.environment
  service_name = var.service_name

  # VPC Configuration
  vpc_id       = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  # Instance Configuration
  key_pair_name = module.ec2.key_pair_name
  domain_name   = var.domain_name

  # etcd Configuration
  etcd_ami                 = var.etcd_ami
  etcd_instance_type       = var.etcd_instance_type
  etcd_volume_size         = var.etcd_volume_size
  etcd_volume_type         = var.etcd_volume_type

  # Control Plane Configuration
  control_plane_ami         = var.control_plane_ami
  control_plane_instance_type = var.control_plane_instance_type
  control_plane_volume_size  = var.control_plane_volume_size
  control_plane_volume_type  = var.control_plane_volume_type

  # Worker Configuration
  worker_ami           = var.worker_ami
  worker_instance_type = var.worker_instance_type
  worker_volume_size   = var.worker_volume_size
  worker_volume_type   = var.worker_volume_type

  # Kubernetes Configuration
  pod_cidr     = var.pod_cidr
  service_cidr = var.service_cidr
  use_bottlerocket = var.use_bottlerocket

  ssh_cidr_blocks = var.ssh_cidr_blocks

  tags = var.tags
}

# =============================================================================
# CLOUDWATCH MONITORING
# =============================================================================

# Create CloudWatch monitoring and alerting
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  environment = var.environment
  service_name = var.service_name
  aws_region   = var.aws_region

  # Log Groups
  create_application_log_group = var.create_application_log_group
  application_log_group_name   = var.application_log_group_name
  create_system_log_group      = var.create_system_log_group
  system_log_group_name        = var.system_log_group_name
  create_kubernetes_log_group  = var.create_kubernetes_log_group
  kubernetes_log_group_name    = var.kubernetes_log_group_name
  create_rds_log_group         = var.create_rds_log_group
  rds_log_group_name           = var.rds_log_group_name
  log_retention_days           = var.log_retention_days
  log_group_kms_key_id         = var.log_group_kms_key_id

  # Dashboard
  create_dashboard = var.create_dashboard
  dashboard_metrics = var.dashboard_metrics

  # Alarms
  create_cpu_alarm    = var.create_cpu_alarm
  instance_id         = module.ec2.instance_id
  cpu_threshold       = var.cpu_threshold
  create_memory_alarm = var.create_memory_alarm
  memory_threshold    = var.memory_threshold
  create_disk_alarm   = var.create_disk_alarm
  disk_threshold      = var.disk_threshold
  disk_device         = var.disk_device
  disk_fstype         = var.disk_fstype

  # RDS Alarms
  create_rds_cpu_alarm         = var.create_rds_cpu_alarm
  rds_instance_id              = module.rds.db_instance_id
  rds_cpu_threshold            = var.rds_cpu_threshold
  create_rds_connections_alarm = var.create_rds_connections_alarm
  rds_connections_threshold    = var.rds_connections_threshold

  # Alarm Actions
  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  # Metric Filters
  create_error_filter   = var.create_error_filter
  create_warning_filter = var.create_warning_filter

  # SNS
  create_sns_topic = var.create_sns_topic
  email_endpoint   = var.email_endpoint

  # CloudWatch Insights
  create_insights_queries = var.create_insights_queries

  tags = var.tags
}

# =============================================================================
# KUBERNETES OPERATORS
# =============================================================================

# Create Kubernetes operators for Terraform and Ansible
module "kubernetes_operators" {
  count = var.create_kubernetes_operators ? 1 : 0
  source = "../../modules/kubernetes-operators"

  environment = var.environment
  aws_region  = var.aws_region

  # Namespace Configuration
  create_namespace = var.create_operators_namespace
  namespace_name   = var.operators_namespace_name

  # Terraform Operator
  create_terraform_operator = var.create_terraform_operator
  terraform_operator_image  = var.terraform_operator_image
  terraform_operator_replicas = var.terraform_operator_replicas
  terraform_operator_cpu_request = var.terraform_operator_cpu_request
  terraform_operator_memory_request = var.terraform_operator_memory_request
  terraform_operator_cpu_limit = var.terraform_operator_cpu_limit
  terraform_operator_memory_limit = var.terraform_operator_memory_limit
  terraform_state_bucket = var.state_bucket_name
  terraform_state_table  = var.state_table_name

  # Ansible Operator
  create_ansible_operator = var.create_ansible_operator
  ansible_operator_image  = var.ansible_operator_image
  ansible_operator_replicas = var.ansible_operator_replicas
  ansible_operator_cpu_request = var.ansible_operator_cpu_request
  ansible_operator_memory_request = var.ansible_operator_memory_request
  ansible_operator_cpu_limit = var.ansible_operator_cpu_limit
  ansible_operator_memory_limit = var.ansible_operator_memory_limit
  ansible_vault_password = var.ansible_vault_password

  common_labels = var.tags
}

# =============================================================================
# ELK STACK
# =============================================================================

# Create ELK stack for logging
module "elk" {
  count = var.create_elk_stack ? 1 : 0
  source = "../../modules/elk"

  environment = var.environment
  namespace_name = var.elk_namespace_name

  # Elasticsearch Configuration
  create_elasticsearch = var.create_elasticsearch
  elasticsearch_replicas = var.elasticsearch_replicas
  elasticsearch_cluster_name = var.elasticsearch_cluster_name
  elasticsearch_heap_size = var.elasticsearch_heap_size
  elasticsearch_cpu_request = var.elasticsearch_cpu_request
  elasticsearch_memory_request = var.elasticsearch_memory_request
  elasticsearch_cpu_limit = var.elasticsearch_cpu_limit
  elasticsearch_memory_limit = var.elasticsearch_memory_limit
  elasticsearch_storage_size = var.elasticsearch_storage_size

  # Logstash Configuration
  create_logstash = var.create_logstash
  logstash_replicas = var.logstash_replicas
  logstash_heap_size = var.logstash_heap_size
  logstash_cpu_request = var.logstash_cpu_request
  logstash_memory_request = var.logstash_memory_request
  logstash_cpu_limit = var.logstash_cpu_limit
  logstash_memory_limit = var.logstash_memory_limit

  # Kibana Configuration
  create_kibana = var.create_kibana
  kibana_replicas = var.kibana_replicas
  kibana_cpu_request = var.kibana_cpu_request
  kibana_memory_request = var.kibana_memory_request
  kibana_cpu_limit = var.kibana_cpu_limit
  kibana_memory_limit = var.kibana_memory_limit

  # Filebeat Configuration
  create_filebeat = var.create_filebeat

  common_labels = var.tags
}

# =============================================================================
# ANSIBLE VAULT SETUP
# =============================================================================

# Create Ansible Vault configuration with SSM integration
module "ansible_vault" {
  source = "../../modules/ansible-vault"

  environment = var.environment
  aws_region  = var.aws_region

  # Vault Configuration
  create_vault_password = var.create_ansible_vault_password
  vault_password_parameter_name = var.ansible_vault_password_parameter_name
  vault_password_value = var.ansible_vault_password_value
  kms_key_id = var.ansible_vault_kms_key_id

  # File Generation
  create_ansible_config = var.create_ansible_config
  create_group_vars = var.create_group_vars
  create_vault_template = var.create_vault_template
  create_documentation = var.create_documentation
  ansible_directory = var.ansible_directory

  # Database Configuration for group_vars
  db_host = module.rds.db_instance_endpoint
  db_port = module.rds.db_instance_port
  db_name = module.rds.db_instance_name
  db_user = module.rds.db_instance_username
  rds_password_placeholder = var.ansible_rds_password_placeholder

  # AWS Credentials for vault injection
  aws_access_key_id = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_session_token = var.aws_session_token

  common_tags = var.tags
}

# =============================================================================
# WEBHOOK SERVICE
# =============================================================================

# Deploy API compatibility webhook service
module "webhook" {
  count = var.create_webhook_service ? 1 : 0
  source = "../../modules/webhook"

  environment = var.environment

  # Namespace Configuration
  create_namespace = var.create_webhook_namespace
  namespace_name   = var.webhook_namespace_name

  # Webhook Configuration
  webhook_image = var.webhook_image
  replicas      = var.webhook_replicas
  port          = var.webhook_port
  service_type  = var.webhook_service_type

  # Resource Configuration
  cpu_request    = var.webhook_cpu_request
  memory_request = var.webhook_memory_request
  cpu_limit      = var.webhook_cpu_limit
  memory_limit   = var.webhook_memory_limit

  # Security Configuration
  encryption_key        = var.webhook_encryption_key
  github_webhook_secret = var.github_webhook_secret
  working_dir          = var.webhook_working_dir
  log_level            = var.webhook_log_level

  # Ingress Configuration
  create_ingress         = var.create_webhook_ingress
  ingress_host          = var.webhook_ingress_host
  ingress_path          = var.webhook_ingress_path
  ingress_class_name    = var.webhook_ingress_class_name
  ingress_annotations   = var.webhook_ingress_annotations
  ingress_tls_secret_name = var.webhook_ingress_tls_secret_name

  common_labels = var.tags
}
