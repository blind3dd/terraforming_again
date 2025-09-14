# Dev Environment Terraform Variables
# This file contains the actual values for the dev environment

# =============================================================================
# GENERAL CONFIGURATION
# =============================================================================

environment = "dev"
service_name = "database-ci"
project_name = "database-ci"
aws_region = "us-east-1"
aws_profile = null  # Use default profile

# =============================================================================
# TERRAFORM BACKEND CONFIGURATION
# =============================================================================

create_backend = false  # Set to true when ready to use S3 backend
state_bucket_name = "terraform-state-bucket-dev"
state_table_name = "terraform-state-lock-dev"

# =============================================================================
# VPC CONFIGURATION
# =============================================================================

vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
availability_zones = ["us-east-1a", "us-east-1b"]

# DHCP Options
create_dhcp_options = true
domain_name = "internal.coderedalarmtech.com"
dhcp_domain_name_servers = ["AmazonProvidedDNS"]
dhcp_ntp_servers = ["169.254.169.123"]
dhcp_netbios_name_servers = []
dhcp_netbios_node_type = 2

# Security Groups
ssh_cidr_blocks = ["10.0.0.0/16"]  # Only allow SSH from VPC
http_cidr_blocks = ["10.0.0.0/16"]  # Only allow HTTP from VPC
https_cidr_blocks = ["10.0.0.0/16"]  # Only allow HTTPS from VPC
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
rds_database_name = "database_ci_dev"
rds_master_username = "admin"
rds_master_password = "DevPassword123!"
rds_master_password_param = "/rds/dev/master-password"
rds_backup_retention_period = 7
rds_backup_window = "03:00-04:00"
rds_maintenance_window = "sun:04:00-sun:05:00"
rds_multi_az = false
rds_monitoring_interval = 0
rds_deletion_protection = false
rds_skip_final_snapshot = true
rds_mysql_cidr_blocks = [{
  cidr_block = "10.0.0.0/16"
  description = "VPC CIDR for MySQL access"
}]

# =============================================================================
# ROUTE53 CONFIGURATION
# =============================================================================

create_private_zone = true
route53_records = {
  "dev-api" = {
    name = "dev-api"
    type = "A"
    ttl = 300
    records = ["10.0.10.10"]  # Will be updated with actual EC2 private IP
    zone_type = "private"
  }
  "dev-web" = {
    name = "dev-web"
    type = "A"
    ttl = 300
    records = ["10.0.10.11"]  # Will be updated with actual EC2 private IP
    zone_type = "private"
  }
  "dev-rds" = {
    name = "dev-rds"
    type = "CNAME"
    ttl = 300
    records = ["database-ci-dev-rds.internal.coderedalarmtech.com"]
    zone_type = "private"
  }
}
create_certificate = false
certificate_domain_name = "*.dev.example.com"
certificate_san_domains = []

# =============================================================================
# KUBERNETES CONFIGURATION
# =============================================================================

kubernetes_cluster_type = "self-managed"  # or "eks"
kubernetes_version = "1.28"

# EKS Configuration (if using EKS)
eks_endpoint_private_access = true
eks_endpoint_public_access = true
eks_public_access_cidrs = ["0.0.0.0/0"]
eks_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
eks_capacity_type = "ON_DEMAND"
eks_instance_types = ["t3.medium"]
eks_ami_type = "AL2_x86_64"
eks_disk_size = 20
eks_desired_size = 2
eks_max_size = 4
eks_min_size = 1
eks_max_unavailable_percentage = 25

# Self-managed Kubernetes Configuration
etcd_ami = "ami-0c02fb55956c7d316"
etcd_instance_type = "t3.small"
etcd_volume_size = 20
etcd_volume_type = "gp3"

control_plane_ami = "ami-0c02fb55956c7d316"
control_plane_instance_type = "t3.medium"
control_plane_volume_size = 20
control_plane_volume_type = "gp3"

worker_ami = "ami-0c02fb55956c7d316"
worker_instance_type = "t3.medium"
worker_volume_size = 20
worker_volume_type = "gp3"

pod_cidr = "10.244.0.0/16"
service_cidr = "10.96.0.0/12"
use_bottlerocket = false

# =============================================================================
# CLOUDWATCH CONFIGURATION
# =============================================================================

create_application_log_group = true
application_log_group_name = "/aws/ec2/database-ci-dev/application"
create_system_log_group = true
system_log_group_name = "/aws/ec2/database-ci-dev/system"
create_kubernetes_log_group = true
kubernetes_log_group_name = "/aws/kubernetes/database-ci-dev"
create_rds_log_group = true
rds_log_group_name = "/aws/rds/database-ci-dev"
log_retention_days = 30
log_group_kms_key_id = null

create_dashboard = true
dashboard_metrics = [["CPUUtilization"], ["NetworkIn"], ["NetworkOut"], ["DiskReadOps"], ["DiskWriteOps"]]

create_cpu_alarm = true
cpu_threshold = 80
create_memory_alarm = true
memory_threshold = 80
create_disk_alarm = true
disk_threshold = 80
disk_device = "/dev/xvda1"
disk_fstype = "ext4"

create_rds_cpu_alarm = true
rds_cpu_threshold = 80
create_rds_connections_alarm = true
rds_connections_threshold = 80

alarm_actions = []
ok_actions = []

create_error_filter = true
create_warning_filter = true
create_sns_topic = true
email_endpoint = "admin@example.com"
create_insights_queries = true

# =============================================================================
# KUBERNETES OPERATORS CONFIGURATION
# =============================================================================

create_kubernetes_operators = true
create_operators_namespace = true
operators_namespace_name = "operators"

# Terraform Operator
create_terraform_operator = true
terraform_operator_image = "hashicorp/terraform-k8s:2.0.0"
terraform_operator_replicas = 1
terraform_operator_cpu_request = "100m"
terraform_operator_memory_request = "256Mi"
terraform_operator_cpu_limit = "500m"
terraform_operator_memory_limit = "512Mi"

# Ansible Operator
create_ansible_operator = true
ansible_operator_image = "ansible/ansible-runner:latest"
ansible_operator_replicas = 1
ansible_operator_cpu_request = "100m"
ansible_operator_memory_request = "256Mi"
ansible_operator_cpu_limit = "500m"
ansible_operator_memory_limit = "512Mi"
ansible_vault_password = "dev-vault-password"

# =============================================================================
# ELK STACK CONFIGURATION
# =============================================================================

create_elk_stack = true
elk_namespace_name = "elk"

# Elasticsearch
create_elasticsearch = true
elasticsearch_replicas = 1
elasticsearch_cluster_name = "database-ci-dev"
elasticsearch_heap_size = "1g"
elasticsearch_cpu_request = "500m"
elasticsearch_memory_request = "2Gi"
elasticsearch_cpu_limit = "1000m"
elasticsearch_memory_limit = "4Gi"
elasticsearch_storage_size = "10Gi"

# Logstash
create_logstash = true
logstash_replicas = 1
logstash_heap_size = "512m"
logstash_cpu_request = "250m"
logstash_memory_request = "1Gi"
logstash_cpu_limit = "500m"
logstash_memory_limit = "2Gi"

# Kibana
create_kibana = true
kibana_replicas = 1
kibana_cpu_request = "250m"
kibana_memory_request = "1Gi"
kibana_cpu_limit = "500m"
kibana_memory_limit = "2Gi"

# Filebeat
create_filebeat = true

# =============================================================================
# ANSIBLE VAULT CONFIGURATION
# =============================================================================

create_ansible_vault_password = true
ansible_vault_password_parameter_name = "/ansible/vault/password"
ansible_vault_password_value = "dev-vault-password"
ansible_vault_kms_key_id = null

create_ansible_config = true
create_group_vars = true
create_vault_template = true
create_documentation = true
ansible_directory = "../../ansible"
ansible_rds_password_placeholder = "CHANGE_ME_TO_ACTUAL_PASSWORD"

# AWS Credentials (set these to actual values or use environment variables)
aws_access_key_id = ""
aws_secret_access_key = ""
aws_session_token = ""

# =============================================================================
# WEBHOOK SERVICE CONFIGURATION
# =============================================================================

create_webhook_service = true
create_webhook_namespace = true
webhook_namespace_name = "webhook"
webhook_image = "api-compatibility-webhook:latest"
webhook_replicas = 1
webhook_port = 8080
webhook_service_type = "ClusterIP"

webhook_cpu_request = "100m"
webhook_memory_request = "128Mi"
webhook_cpu_limit = "500m"
webhook_memory_limit = "512Mi"

webhook_encryption_key = "dev-webhook-encryption-key"
github_webhook_secret = "dev-github-webhook-secret"
webhook_working_dir = "/tmp/webhook-workspace"
webhook_log_level = "info"

create_webhook_ingress = true
webhook_ingress_host = "webhook.internal.coderedalarmtech.com"
webhook_ingress_path = "/"
webhook_ingress_class_name = "nginx"
webhook_ingress_annotations = {
  "nginx.ingress.kubernetes.io/rewrite-target" = "/"
  "nginx.ingress.kubernetes.io/ssl-redirect"   = "true"
}
webhook_ingress_tls_secret_name = "webhook-tls"

# =============================================================================
# ECR CONFIGURATION
# =============================================================================

ecr_repository_url = ""
