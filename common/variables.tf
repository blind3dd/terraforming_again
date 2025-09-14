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
    condition = contains(["dev", "test", "sandbox", "shared"], var.environment)
    error_message = "Environment must be one of: dev, test, sandbox, shared"
  }
}

# Terraform Backend Configuration Variables
variable "create_backend" {
  type = bool
  default = false
  description = "Whether to create the Terraform backend infrastructure (S3 bucket and DynamoDB table)"
}

variable "state_bucket_name" {
  type = string
  default = "terraform-state-bucket-database-ci"
  description = "Name of the S3 bucket for Terraform state"
}

variable "state_table_name" {
  type = string
  default = "terraform-state-lock"
  description = "Name of the DynamoDB table for state locking"
}

variable "main_vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
  description = "The CIDR block for the main VPC"
}

variable "private_subnet_range_a" {
  type = string
  default = "10.0.1.0/24"
  description = "The CIDR block for the private subnet A"
}

variable "private_subnet_range_b" {
  type = string
  default = "10.0.2.0/24"
  description = "The CIDR block for the private subnet B"
}

variable "public_subnet_range" {
  type = string
  default = "10.0.3.0/24"
  description = "The CIDR block for the public subnet A"
}

variable "service_name" {
  type = string
  default = "go-mysql-api"
  description = "The name of the service"
}

variable "instance_os" {
  type = string
  default = "Amazon Linux 1.5"
  description = "The OS of the instance"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
  description = "The type of the instance"
}

variable "instance_ami" {
  type = string
  default = "ami-58d7e821"
  description = "The AMI of the instance"
}

variable "aws_key_pair_name" {
  type = string
  default = "ec2_key_pair"
  description = "The name of the key pair"
}

variable "key_algorithm" {
  type = string
  default = "RSA"
  description = "The algorithm of the key pair"
}

variable "key_bits_size" {
  type = number
  default = 4096
  description = "The size of the key pair"
}

variable "db_password_param" {
  type = string
  default = "/opt/go-mysql-api/db/password"
  description = "The parameter name of the db password"
}

variable "associate_public_ip_address" {
  type = bool
  default = true
  description = "Whether to associate a public IP address with the instance"
}

variable "db_name" {
  type = string
  default = "mock_user"
  description = "The name of the database"
}

variable "rds_engine_version" {
  type = string
  default = "8.0.32"
  description = "The version of the RDS engine"
}

variable "infra_builder" {
  type = string
  default = "iacrunner"
  description = "The name of the person who created the infrastructure"
}

variable "ec2_instance_role_name" {
  type = string
  default = "ec2-instance-role"
  description = "The name of the instance role"
}

variable "ec2_instance_profile_name" {
  type = string
  default = "ec2-instance-profile"
  description = "The name of the instance profile"
}

variable "db_password" {
  type = string
  default = "password"
  description = "The password of the database"
}

variable "db_username" {
  type = string
  default = "username"
  description = "The username of the database"
}

variable "db_port" {
  type = number
  default = 3306
  description = "The port of the database"
}

variable "db_engine" {
  type = string
  default = "mysql"
  description = "The engine of the database"
}

variable "db_engine_version" {
  type = string
  default = "8.0.32" // # 9?
  description = "The version of the database engine"
}

variable "db_instance_class" {
  type = string
  default = "db.t2.micro"
}

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

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS01 challenge"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for the Kubernetes API and certificates"
  type        = string
  default     = "example.com"
}

# =============================================================================
# KUBERNETES OPERATORS VARIABLES
# =============================================================================

variable "create_kubernetes_operators" {
  description = "Whether to create Kubernetes operators for Terraform and Ansible"
  type        = bool
  default     = true
}

variable "create_operators_namespace" {
  description = "Whether to create a namespace for operators"
  type        = bool
  default     = true
}

variable "operators_namespace_name" {
  description = "Name of the namespace for operators"
  type        = string
  default     = "operators"
}

# Terraform Operator Variables
variable "create_terraform_operator" {
  description = "Whether to create the Terraform operator"
  type        = bool
  default     = true
}

variable "terraform_operator_image" {
  description = "Docker image for Terraform operator"
  type        = string
  default     = "ubuntu:22.04"
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
  default     = "1Gi"
}

# Ansible Operator Variables
variable "create_ansible_operator" {
  description = "Whether to create the Ansible operator"
  type        = bool
  default     = true
}

variable "ansible_operator_image" {
  description = "Docker image for Ansible operator"
  type        = string
  default     = "ubuntu:22.04"
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
  default     = "1Gi"
}

variable "ansible_vault_password" {
  description = "Ansible vault password"
  type        = string
  default     = "foobar123"
  sensitive   = true
}

# =============================================================================
# ELK STACK VARIABLES
# =============================================================================

variable "create_elk_stack" {
  description = "Whether to create ELK stack"
  type        = bool
  default     = true
}

variable "elk_namespace_name" {
  description = "Kubernetes namespace for ELK stack"
  type        = string
  default     = "elk"
}

# Elasticsearch Variables
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
  description = "Elasticsearch cluster name"
  type        = string
  default     = "elk-cluster"
}

variable "elasticsearch_heap_size" {
  description = "Elasticsearch heap size"
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
  default     = "2"
}

variable "elasticsearch_memory_limit" {
  description = "Memory limit for Elasticsearch"
  type        = string
  default     = "4Gi"
}

variable "elasticsearch_storage_size" {
  description = "Storage size for Elasticsearch data"
  type        = string
  default     = "10Gi"
}

# Logstash Variables
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
  description = "Logstash heap size"
  type        = string
  default     = "512m"
}

variable "logstash_cpu_request" {
  description = "CPU request for Logstash"
  type        = string
  default     = "200m"
}

variable "logstash_memory_request" {
  description = "Memory request for Logstash"
  type        = string
  default     = "1Gi"
}

variable "logstash_cpu_limit" {
  description = "CPU limit for Logstash"
  type        = string
  default     = "1"
}

variable "logstash_memory_limit" {
  description = "Memory limit for Logstash"
  type        = string
  default     = "2Gi"
}

# Kibana Variables
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
  default     = "200m"
}

variable "kibana_memory_request" {
  description = "Memory request for Kibana"
  type        = string
  default     = "1Gi"
}

variable "kibana_cpu_limit" {
  description = "CPU limit for Kibana"
  type        = string
  default     = "1"
}

variable "kibana_memory_limit" {
  description = "Memory limit for Kibana"
  type        = string
  default     = "2Gi"
}

# Filebeat Variables
variable "create_filebeat" {
  description = "Whether to create Filebeat"
  type        = bool
  default     = false
}

# =============================================================================
# ANSIBLE VAULT VARIABLES
# =============================================================================

variable "create_ansible_vault_password" {
  description = "Whether to create Ansible Vault password in SSM"
  type        = bool
  default     = true
}

variable "ansible_vault_password_parameter_name" {
  description = "SSM parameter name for Ansible Vault password"
  type        = string
  default     = "/ansible/vault/password"
}

variable "ansible_vault_password_value" {
  description = "Explicit Ansible vault password value"
  type        = string
  default     = null
  sensitive   = true
}

variable "ansible_vault_kms_key_id" {
  description = "KMS key ID for encrypting Ansible vault password"
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
  default     = "./ansible"
}

variable "ansible_rds_password_placeholder" {
  description = "Placeholder value for RDS password in vault template"
  type        = string
  default     = "CHANGE_ME_TO_ACTUAL_PASSWORD"
}

# =============================================================================
# AWS CREDENTIALS FOR VAULT INJECTION
# =============================================================================

variable "aws_access_key_id" {
  description = "AWS Access Key ID to inject into Ansible vault"
  type        = string
  default     = "foobar_aws_access_key_123"
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key to inject into Ansible vault"
  type        = string
  default     = "foobar_aws_secret_key_123"
  sensitive   = true
}

variable "aws_session_token" {
  description = "AWS Session Token to inject into Ansible vault (for temporary credentials)"
  type        = string
  default     = "foobar_aws_session_token_123"
  sensitive   = true
}