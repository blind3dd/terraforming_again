# Dev Environment Variables
# This file defines all variables for the dev environment

# =============================================================================
# GENERAL CONFIGURATION
# =============================================================================

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "database-ci"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "database-ci"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile to use"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Service     = "database-ci"
    ManagedBy   = "Terraform"
    Project     = "database-ci"
  }
}

# =============================================================================
# TERRAFORM BACKEND CONFIGURATION
# =============================================================================

variable "create_backend" {
  description = "Whether to create Terraform backend infrastructure"
  type        = bool
  default     = false
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "terraform-state-bucket-dev"
}

variable "state_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  type        = string
  default     = "terraform-state-lock-dev"
}

# =============================================================================
# VPC CONFIGURATION
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# DHCP Options
variable "create_dhcp_options" {
  description = "Whether to create DHCP options set"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for DHCP options"
  type        = string
  default     = "dev.internal"
}

variable "dhcp_domain_name_servers" {
  description = "Domain name servers for DHCP options"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_ntp_servers" {
  description = "NTP servers for DHCP options"
  type        = list(string)
  default     = ["169.254.169.123"]
}

variable "dhcp_netbios_name_servers" {
  description = "NetBIOS name servers for DHCP options"
  type        = list(string)
  default     = []
}

variable "dhcp_netbios_node_type" {
  description = "NetBIOS node type for DHCP options"
  type        = number
  default     = 2
}

# Security Groups
variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "http_cidr_blocks" {
  description = "CIDR blocks allowed for HTTP access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_cidr_blocks" {
  description = "CIDR blocks allowed for HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "custom_ingress_rules" {
  description = "Custom ingress rules for security groups"
  type        = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

# =============================================================================
# EC2 CONFIGURATION
# =============================================================================

variable "ec2_ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0c02fb55956c7d316"  # Amazon Linux 2
}

variable "ec2_instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
  default     = "t3.medium"
}

variable "ec2_associate_public_ip" {
  description = "Whether to associate public IP with EC2 instances"
  type        = bool
  default     = true
}

variable "ec2_root_volume_size" {
  description = "Size of the root volume for EC2 instances"
  type        = number
  default     = 20
}

variable "ec2_root_volume_type" {
  description = "Type of the root volume for EC2 instances"
  type        = string
  default     = "gp3"
}

variable "ec2_encrypt_root_volume" {
  description = "Whether to encrypt the root volume"
  type        = bool
  default     = true
}

variable "ec2_user_data" {
  description = "User data script for EC2 instances"
  type        = string
  default     = ""
}

variable "ec2_create_cloudinit_config" {
  description = "Whether to create CloudInit configuration"
  type        = bool
  default     = true
}

variable "ec2_create_ec2_user_password" {
  description = "Whether to create EC2 user password"
  type        = bool
  default     = true
}

# =============================================================================
# RDS CONFIGURATION
# =============================================================================

variable "rds_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage for RDS instance"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Maximum allocated storage for RDS instance"
  type        = number
  default     = 100
}

variable "rds_storage_type" {
  description = "Storage type for RDS instance"
  type        = string
  default     = "gp2"
}

variable "rds_storage_encrypted" {
  description = "Whether to encrypt RDS storage"
  type        = bool
  default     = true
}

variable "rds_database_name" {
  description = "Name of the database"
  type        = string
  default     = "database_ci_dev"
}

variable "rds_master_username" {
  description = "Master username for RDS instance"
  type        = string
  default     = "admin"
}

variable "rds_master_password" {
  description = "Master password for RDS instance"
  type        = string
  default     = "ChangeMe123!"
  sensitive   = true
}

variable "rds_master_password_param" {
  description = "SSM parameter name for RDS master password"
  type        = string
  default     = "/rds/dev/master-password"
}

variable "rds_backup_retention_period" {
  description = "Backup retention period for RDS instance"
  type        = number
  default     = 7
}

variable "rds_backup_window" {
  description = "Backup window for RDS instance"
  type        = string
  default     = "03:00-04:00"
}

variable "rds_maintenance_window" {
  description = "Maintenance window for RDS instance"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "rds_multi_az" {
  description = "Whether to enable Multi-AZ for RDS instance"
  type        = bool
  default     = false
}

variable "rds_monitoring_interval" {
  description = "Monitoring interval for RDS instance"
  type        = number
  default     = 0
}

variable "rds_deletion_protection" {
  description = "Whether to enable deletion protection for RDS instance"
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Whether to skip final snapshot when deleting RDS instance"
  type        = bool
  default     = true
}

variable "rds_mysql_cidr_blocks" {
  description = "CIDR blocks allowed for MySQL access"
  type        = list(object({
    cidr_block = string
    description = string
  }))
  default = [{
    cidr_block = "10.0.0.0/16"
    description = "VPC CIDR for MySQL access"
  }]
}

# =============================================================================
# ROUTE53 CONFIGURATION
# =============================================================================

variable "create_private_zone" {
  description = "Whether to create private Route53 zone"
  type        = bool
  default     = true
}

variable "route53_records" {
  description = "Route53 records to create"
  type        = map(object({
    name    = string
    type    = string
    ttl     = optional(number)
    records = optional(list(string))
    zone_type = string
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = bool
    }))
  }))
  default = {}
}

variable "create_certificate" {
  description = "Whether to create SSL certificate"
  type        = bool
  default     = false
}

variable "certificate_domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = "*.dev.example.com"
}

variable "certificate_san_domains" {
  description = "Subject Alternative Names for SSL certificate"
  type        = list(string)
  default     = []
}

# =============================================================================
# KUBERNETES CONFIGURATION
# =============================================================================

variable "kubernetes_cluster_type" {
  description = "Type of Kubernetes cluster (eks or self-managed)"
  type        = string
  default     = "self-managed"
  validation {
    condition     = contains(["eks", "self-managed"], var.kubernetes_cluster_type)
    error_message = "Kubernetes cluster type must be either 'eks' or 'self-managed'."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

# EKS Configuration
variable "eks_endpoint_private_access" {
  description = "Whether to enable private access to EKS API server"
  type        = bool
  default     = true
}

variable "eks_endpoint_public_access" {
  description = "Whether to enable public access to EKS API server"
  type        = bool
  default     = true
}

variable "eks_public_access_cidrs" {
  description = "CIDR blocks allowed for public access to EKS API server"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_enabled_log_types" {
  description = "List of EKS log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "eks_capacity_type" {
  description = "Capacity type for EKS node group"
  type        = string
  default     = "ON_DEMAND"
}

variable "eks_instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_ami_type" {
  description = "AMI type for EKS node group"
  type        = string
  default     = "AL2_x86_64"
}

variable "eks_disk_size" {
  description = "Disk size for EKS node group"
  type        = number
  default     = 20
}

variable "eks_desired_size" {
  description = "Desired number of nodes in EKS node group"
  type        = number
  default     = 2
}

variable "eks_max_size" {
  description = "Maximum number of nodes in EKS node group"
  type        = number
  default     = 4
}

variable "eks_min_size" {
  description = "Minimum number of nodes in EKS node group"
  type        = number
  default     = 1
}

variable "eks_max_unavailable_percentage" {
  description = "Maximum unavailable percentage for EKS node group"
  type        = number
  default     = 25
}

# Self-managed Kubernetes Configuration
variable "etcd_ami" {
  description = "AMI for etcd instances"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

variable "etcd_instance_type" {
  description = "Instance type for etcd instances"
  type        = string
  default     = "t3.small"
}

variable "etcd_volume_size" {
  description = "Volume size for etcd instances"
  type        = number
  default     = 20
}

variable "etcd_volume_type" {
  description = "Volume type for etcd instances"
  type        = string
  default     = "gp3"
}

variable "control_plane_ami" {
  description = "AMI for control plane instances"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

variable "control_plane_instance_type" {
  description = "Instance type for control plane instances"
  type        = string
  default     = "t3.medium"
}

variable "control_plane_volume_size" {
  description = "Volume size for control plane instances"
  type        = number
  default     = 20
}

variable "control_plane_volume_type" {
  description = "Volume type for control plane instances"
  type        = string
  default     = "gp3"
}

variable "worker_ami" {
  description = "AMI for worker instances"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

variable "worker_instance_type" {
  description = "Instance type for worker instances"
  type        = string
  default     = "t3.medium"
}

variable "worker_volume_size" {
  description = "Volume size for worker instances"
  type        = number
  default     = 20
}

variable "worker_volume_type" {
  description = "Volume type for worker instances"
  type        = string
  default     = "gp3"
}

variable "pod_cidr" {
  description = "CIDR block for Kubernetes pods"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "CIDR block for Kubernetes services"
  type        = string
  default     = "10.96.0.0/12"
}

variable "use_bottlerocket" {
  description = "Whether to use Bottlerocket OS"
  type        = bool
  default     = false
}

# =============================================================================
# CLOUDWATCH CONFIGURATION
# =============================================================================

variable "create_application_log_group" {
  description = "Whether to create application log group"
  type        = bool
  default     = true
}

variable "application_log_group_name" {
  description = "Name of the application log group"
  type        = string
  default     = "/aws/ec2/database-ci-dev/application"
}

variable "create_system_log_group" {
  description = "Whether to create system log group"
  type        = bool
  default     = true
}

variable "system_log_group_name" {
  description = "Name of the system log group"
  type        = string
  default     = "/aws/ec2/database-ci-dev/system"
}

variable "create_kubernetes_log_group" {
  description = "Whether to create Kubernetes log group"
  type        = bool
  default     = true
}

variable "kubernetes_log_group_name" {
  description = "Name of the Kubernetes log group"
  type        = string
  default     = "/aws/kubernetes/database-ci-dev"
}

variable "create_rds_log_group" {
  description = "Whether to create RDS log group"
  type        = bool
  default     = true
}

variable "rds_log_group_name" {
  description = "Name of the RDS log group"
  type        = string
  default     = "/aws/rds/database-ci-dev"
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "log_group_kms_key_id" {
  description = "KMS key ID for log group encryption"
  type        = string
  default     = null
}

variable "create_dashboard" {
  description = "Whether to create CloudWatch dashboard"
  type        = bool
  default     = true
}

variable "dashboard_metrics" {
  description = "Metrics to include in dashboard"
  type        = list(list(string))
  default     = [["CPUUtilization"], ["NetworkIn"], ["NetworkOut"], ["DiskReadOps"], ["DiskWriteOps"]]
}

variable "create_cpu_alarm" {
  description = "Whether to create CPU alarm"
  type        = bool
  default     = true
}

variable "cpu_threshold" {
  description = "CPU threshold for alarm"
  type        = number
  default     = 80
}

variable "create_memory_alarm" {
  description = "Whether to create memory alarm"
  type        = bool
  default     = true
}

variable "memory_threshold" {
  description = "Memory threshold for alarm"
  type        = number
  default     = 80
}

variable "create_disk_alarm" {
  description = "Whether to create disk alarm"
  type        = bool
  default     = true
}

variable "disk_threshold" {
  description = "Disk threshold for alarm"
  type        = number
  default     = 80
}

variable "disk_device" {
  description = "Disk device to monitor"
  type        = string
  default     = "/dev/xvda1"
}

variable "disk_fstype" {
  description = "File system type"
  type        = string
  default     = "ext4"
}

variable "create_rds_cpu_alarm" {
  description = "Whether to create RDS CPU alarm"
  type        = bool
  default     = true
}

variable "rds_cpu_threshold" {
  description = "RDS CPU threshold for alarm"
  type        = number
  default     = 80
}

variable "create_rds_connections_alarm" {
  description = "Whether to create RDS connections alarm"
  type        = bool
  default     = true
}

variable "rds_connections_threshold" {
  description = "RDS connections threshold for alarm"
  type        = number
  default     = 80
}

variable "alarm_actions" {
  description = "Actions to take when alarm triggers"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "Actions to take when alarm recovers"
  type        = list(string)
  default     = []
}

variable "create_error_filter" {
  description = "Whether to create error metric filter"
  type        = bool
  default     = true
}

variable "create_warning_filter" {
  description = "Whether to create warning metric filter"
  type        = bool
  default     = true
}

variable "create_sns_topic" {
  description = "Whether to create SNS topic"
  type        = bool
  default     = true
}

variable "email_endpoint" {
  description = "Email endpoint for SNS notifications"
  type        = string
  default     = "admin@example.com"
}

variable "create_insights_queries" {
  description = "Whether to create CloudWatch Insights queries"
  type        = bool
  default     = true
}

# =============================================================================
# KUBERNETES OPERATORS CONFIGURATION
# =============================================================================

variable "create_kubernetes_operators" {
  description = "Whether to create Kubernetes operators"
  type        = bool
  default     = true
}

variable "create_operators_namespace" {
  description = "Whether to create operators namespace"
  type        = bool
  default     = true
}

variable "operators_namespace_name" {
  description = "Name of the operators namespace"
  type        = string
  default     = "operators"
}

# Terraform Operator
variable "create_terraform_operator" {
  description = "Whether to create Terraform operator"
  type        = bool
  default     = true
}

variable "terraform_operator_image" {
  description = "Docker image for Terraform operator"
  type        = string
  default     = "hashicorp/terraform-k8s:2.0.0"
}

variable "terraform_operator_replicas" {
  description = "Number of replicas for Terraform operator"
  type        = number
  default     = 1
}

variable "terraform_operator_cpu_request" {
  description = "CPU request for Terraform operator"
  type        = string
  default     = "100m"
}

variable "terraform_operator_memory_request" {
  description = "Memory request for Terraform operator"
  type        = string
  default     = "256Mi"
}

variable "terraform_operator_cpu_limit" {
  description = "CPU limit for Terraform operator"
  type        = string
  default     = "500m"
}

variable "terraform_operator_memory_limit" {
  description = "Memory limit for Terraform operator"
  type        = string
  default     = "512Mi"
}

# Ansible Operator
variable "create_ansible_operator" {
  description = "Whether to create Ansible operator"
  type        = bool
  default     = true
}

variable "ansible_operator_image" {
  description = "Docker image for Ansible operator"
  type        = string
  default     = "ansible/ansible-runner:latest"
}

variable "ansible_operator_replicas" {
  description = "Number of replicas for Ansible operator"
  type        = number
  default     = 1
}

variable "ansible_operator_cpu_request" {
  description = "CPU request for Ansible operator"
  type        = string
  default     = "100m"
}

variable "ansible_operator_memory_request" {
  description = "Memory request for Ansible operator"
  type        = string
  default     = "256Mi"
}

variable "ansible_operator_cpu_limit" {
  description = "CPU limit for Ansible operator"
  type        = string
  default     = "500m"
}

variable "ansible_operator_memory_limit" {
  description = "Memory limit for Ansible operator"
  type        = string
  default     = "512Mi"
}

variable "ansible_vault_password" {
  description = "Ansible vault password"
  type        = string
  default     = "dev-vault-password"
  sensitive   = true
}

# =============================================================================
# ELK STACK CONFIGURATION
# =============================================================================

variable "create_elk_stack" {
  description = "Whether to create ELK stack"
  type        = bool
  default     = true
}

variable "elk_namespace_name" {
  description = "Name of the ELK namespace"
  type        = string
  default     = "elk"
}

# Elasticsearch
variable "create_elasticsearch" {
  description = "Whether to create Elasticsearch"
  type        = bool
  default     = true
}

variable "elasticsearch_replicas" {
  description = "Number of Elasticsearch replicas"
  type        = number
  default     = 1
}

variable "elasticsearch_cluster_name" {
  description = "Name of the Elasticsearch cluster"
  type        = string
  default     = "database-ci-dev"
}

variable "elasticsearch_heap_size" {
  description = "Heap size for Elasticsearch"
  type        = string
  default     = "1g"
}

variable "elasticsearch_cpu_request" {
  description = "CPU request for Elasticsearch"
  type        = string
  default     = "500m"
}

variable "elasticsearch_memory_request" {
  description = "Memory request for Elasticsearch"
  type        = string
  default     = "2Gi"
}

variable "elasticsearch_cpu_limit" {
  description = "CPU limit for Elasticsearch"
  type        = string
  default     = "1000m"
}

variable "elasticsearch_memory_limit" {
  description = "Memory limit for Elasticsearch"
  type        = string
  default     = "4Gi"
}

variable "elasticsearch_storage_size" {
  description = "Storage size for Elasticsearch"
  type        = string
  default     = "10Gi"
}

# Logstash
variable "create_logstash" {
  description = "Whether to create Logstash"
  type        = bool
  default     = true
}

variable "logstash_replicas" {
  description = "Number of Logstash replicas"
  type        = number
  default     = 1
}

variable "logstash_heap_size" {
  description = "Heap size for Logstash"
  type        = string
  default     = "512m"
}

variable "logstash_cpu_request" {
  description = "CPU request for Logstash"
  type        = string
  default     = "250m"
}

variable "logstash_memory_request" {
  description = "Memory request for Logstash"
  type        = string
  default     = "1Gi"
}

variable "logstash_cpu_limit" {
  description = "CPU limit for Logstash"
  type        = string
  default     = "500m"
}

variable "logstash_memory_limit" {
  description = "Memory limit for Logstash"
  type        = string
  default     = "2Gi"
}

# Kibana
variable "create_kibana" {
  description = "Whether to create Kibana"
  type        = bool
  default     = true
}

variable "kibana_replicas" {
  description = "Number of Kibana replicas"
  type        = number
  default     = 1
}

variable "kibana_cpu_request" {
  description = "CPU request for Kibana"
  type        = string
  default     = "250m"
}

variable "kibana_memory_request" {
  description = "Memory request for Kibana"
  type        = string
  default     = "1Gi"
}

variable "kibana_cpu_limit" {
  description = "CPU limit for Kibana"
  type        = string
  default     = "500m"
}

variable "kibana_memory_limit" {
  description = "Memory limit for Kibana"
  type        = string
  default     = "2Gi"
}

# Filebeat
variable "create_filebeat" {
  description = "Whether to create Filebeat"
  type        = bool
  default     = true
}

# =============================================================================
# ANSIBLE VAULT CONFIGURATION
# =============================================================================

variable "create_ansible_vault_password" {
  description = "Whether to create Ansible vault password in SSM"
  type        = bool
  default     = true
}

variable "ansible_vault_password_parameter_name" {
  description = "SSM parameter name for Ansible vault password"
  type        = string
  default     = "/ansible/vault/password"
}

variable "ansible_vault_password_value" {
  description = "Ansible vault password value"
  type        = string
  default     = "dev-vault-password"
  sensitive   = true
}

variable "ansible_vault_kms_key_id" {
  description = "KMS key ID for Ansible vault password encryption"
  type        = string
  default     = null
}

variable "create_ansible_config" {
  description = "Whether to create ansible.cfg file"
  type        = bool
  default     = true
}

variable "create_group_vars" {
  description = "Whether to create group_vars files"
  type        = bool
  default     = true
}

variable "create_vault_template" {
  description = "Whether to create vault.yml template"
  type        = bool
  default     = true
}

variable "create_documentation" {
  description = "Whether to create setup documentation"
  type        = bool
  default     = true
}

variable "ansible_directory" {
  description = "Directory where Ansible files should be created"
  type        = string
  default     = "../../ansible"
}

variable "ansible_rds_password_placeholder" {
  description = "Placeholder value for RDS password in vault template"
  type        = string
  default     = "CHANGE_ME_TO_ACTUAL_PASSWORD"
}

# AWS Credentials for vault injection
variable "aws_access_key_id" {
  description = "AWS Access Key ID for cert-manager Route53 integration"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for cert-manager Route53 integration"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_session_token" {
  description = "AWS Session Token to inject into vault (for temporary credentials)"
  type        = string
  default     = "foobar_aws_session_token_123"
  sensitive   = true
}

# =============================================================================
# WEBHOOK SERVICE CONFIGURATION
# =============================================================================

variable "create_webhook_service" {
  description = "Whether to create webhook service"
  type        = bool
  default     = true
}

variable "create_webhook_namespace" {
  description = "Whether to create webhook namespace"
  type        = bool
  default     = true
}

variable "webhook_namespace_name" {
  description = "Name of the webhook namespace"
  type        = string
  default     = "webhook"
}

variable "webhook_image" {
  description = "Docker image for the webhook service"
  type        = string
  default     = "api-compatibility-webhook:latest"
}

variable "webhook_replicas" {
  description = "Number of webhook replicas"
  type        = number
  default     = 1
}

variable "webhook_port" {
  description = "Port for the webhook service"
  type        = number
  default     = 8080
}

variable "webhook_service_type" {
  description = "Type of Kubernetes service"
  type        = string
  default     = "ClusterIP"
}

variable "webhook_cpu_request" {
  description = "CPU request for webhook containers"
  type        = string
  default     = "100m"
}

variable "webhook_memory_request" {
  description = "Memory request for webhook containers"
  type        = string
  default     = "128Mi"
}

variable "webhook_cpu_limit" {
  description = "CPU limit for webhook containers"
  type        = string
  default     = "500m"
}

variable "webhook_memory_limit" {
  description = "Memory limit for webhook containers"
  type        = string
  default     = "512Mi"
}

variable "webhook_encryption_key" {
  description = "Encryption key for webhook secrets"
  type        = string
  default     = "dev-webhook-encryption-key"
  sensitive   = true
}

variable "github_webhook_secret" {
  description = "GitHub webhook secret"
  type        = string
  default     = "dev-github-webhook-secret"
  sensitive   = true
}

variable "webhook_working_dir" {
  description = "Working directory for webhook operations"
  type        = string
  default     = "/tmp/webhook-workspace"
}

variable "webhook_log_level" {
  description = "Log level for webhook service"
  type        = string
  default     = "info"
}

variable "create_webhook_ingress" {
  description = "Whether to create ingress for webhook"
  type        = bool
  default     = true
}

variable "webhook_ingress_host" {
  description = "Host for webhook ingress"
  type        = string
  default     = "webhook.internal.coderedalarmtech.com"
}

variable "webhook_ingress_path" {
  description = "Path for webhook ingress"
  type        = string
  default     = "/"
}

variable "webhook_ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "webhook_ingress_annotations" {
  description = "Annotations for webhook ingress"
  type        = map(string)
  default = {
    "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    "nginx.ingress.kubernetes.io/ssl-redirect"   = "true"
  }
}

variable "webhook_ingress_tls_secret_name" {
  description = "TLS secret name for ingress"
  type        = string
  default     = "webhook-tls"
}

# =============================================================================
# ECR CONFIGURATION
# =============================================================================

variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
  default     = ""
}
