# Dev Environment Outputs
# This file defines all outputs for the dev environment

# =============================================================================
# VPC OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.vpc.security_group_id
}

# =============================================================================
# EC2 OUTPUTS
# =============================================================================

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.instance_public_ip
}

output "ec2_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = module.ec2.instance_private_ip
}

output "ec2_key_pair_name" {
  description = "Name of the EC2 key pair"
  value       = module.ec2.key_pair_name
}

# =============================================================================
# RDS OUTPUTS
# =============================================================================

output "rds_instance_id" {
  description = "ID of the RDS instance"
  value       = module.rds.db_instance_id
}

output "rds_instance_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.rds.db_instance_endpoint
}

output "rds_instance_port" {
  description = "Port of the RDS instance"
  value       = module.rds.db_instance_port
}

output "rds_instance_name" {
  description = "Name of the RDS instance"
  value       = module.rds.db_instance_name
}

output "rds_instance_username" {
  description = "Username of the RDS instance"
  value       = module.rds.db_instance_username
}

# =============================================================================
# ROUTE53 OUTPUTS
# =============================================================================

output "route53_zone_id" {
  description = "ID of the Route53 zone"
  value       = module.route53.zone_id
}

output "route53_name_servers" {
  description = "Name servers of the Route53 zone"
  value       = module.route53.name_servers
}

output "certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = module.route53.certificate_arn
}

# =============================================================================
# KUBERNETES OUTPUTS
# =============================================================================

output "kubernetes_cluster_name" {
  description = "Name of the Kubernetes cluster"
  value = var.kubernetes_cluster_type == "eks" ? module.kubernetes_eks[0].cluster_name : module.kubernetes_self_managed[0].cluster_name
}

output "kubernetes_cluster_endpoint" {
  description = "Endpoint of the Kubernetes cluster"
  value = var.kubernetes_cluster_type == "eks" ? module.kubernetes_eks[0].cluster_endpoint : module.kubernetes_self_managed[0].cluster_endpoint
}

output "kubernetes_cluster_ca_certificate" {
  description = "CA certificate of the Kubernetes cluster"
  value = var.kubernetes_cluster_type == "eks" ? module.kubernetes_eks[0].cluster_ca_certificate : module.kubernetes_self_managed[0].cluster_ca_certificate
}

output "kubernetes_cluster_security_group_id" {
  description = "Security group ID of the Kubernetes cluster"
  value = var.kubernetes_cluster_type == "eks" ? module.kubernetes_eks[0].cluster_security_group_id : module.kubernetes_self_managed[0].cluster_security_group_id
}

# EKS specific outputs
output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = var.kubernetes_cluster_type == "eks" ? module.kubernetes_eks[0].cluster_arn : null
}

output "eks_node_group_arn" {
  description = "ARN of the EKS node group"
  value       = var.kubernetes_cluster_type == "eks" ? module.kubernetes_eks[0].node_group_arn : null
}

# Self-managed specific outputs
output "control_plane_instance_ids" {
  description = "IDs of the control plane instances"
  value       = var.kubernetes_cluster_type == "self-managed" ? module.kubernetes_self_managed[0].control_plane_instance_ids : null
}

output "worker_instance_ids" {
  description = "IDs of the worker instances"
  value       = var.kubernetes_cluster_type == "self-managed" ? module.kubernetes_self_managed[0].worker_instance_ids : null
}

output "etcd_instance_ids" {
  description = "IDs of the etcd instances"
  value       = var.kubernetes_cluster_type == "self-managed" ? module.kubernetes_self_managed[0].etcd_instance_ids : null
}

# =============================================================================
# CLOUDWATCH OUTPUTS
# =============================================================================

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = module.cloudwatch.dashboard_url
}

output "cloudwatch_log_groups" {
  description = "Names of the CloudWatch log groups"
  value       = module.cloudwatch.log_group_names
}

output "cloudwatch_alarm_arns" {
  description = "ARNs of the CloudWatch alarms"
  value       = module.cloudwatch.alarm_arns
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = module.cloudwatch.sns_topic_arn
}

# =============================================================================
# KUBERNETES OPERATORS OUTPUTS
# =============================================================================

output "operators_namespace" {
  description = "Name of the operators namespace"
  value       = var.create_kubernetes_operators ? module.kubernetes_operators[0].namespace_name : null
}

output "terraform_operator_deployment_name" {
  description = "Name of the Terraform operator deployment"
  value       = var.create_kubernetes_operators && var.create_terraform_operator ? module.kubernetes_operators[0].terraform_operator_deployment_name : null
}

output "ansible_operator_deployment_name" {
  description = "Name of the Ansible operator deployment"
  value       = var.create_kubernetes_operators && var.create_ansible_operator ? module.kubernetes_operators[0].ansible_operator_deployment_name : null
}

# =============================================================================
# ELK STACK OUTPUTS
# =============================================================================

output "elk_namespace" {
  description = "Name of the ELK namespace"
  value       = var.create_elk_stack ? module.elk[0].namespace_name : null
}

output "elasticsearch_service_name" {
  description = "Name of the Elasticsearch service"
  value       = var.create_elk_stack && var.create_elasticsearch ? module.elk[0].elasticsearch_service_name : null
}

output "kibana_service_name" {
  description = "Name of the Kibana service"
  value       = var.create_elk_stack && var.create_kibana ? module.elk[0].kibana_service_name : null
}

# =============================================================================
# ANSIBLE VAULT OUTPUTS
# =============================================================================

output "ansible_vault_password_parameter_name" {
  description = "SSM parameter name for Ansible vault password"
  value       = module.ansible_vault.vault_password_parameter_name
}

output "ansible_config_file_path" {
  description = "Path to the generated ansible.cfg file"
  value       = module.ansible_vault.ansible_config_file_path
}

output "group_vars_file_path" {
  description = "Path to the generated group_vars file"
  value       = module.ansible_vault.group_vars_file_path
}

output "vault_file_path" {
  description = "Path to the generated vault file"
  value       = module.ansible_vault.vault_file_path
}

# =============================================================================
# TERRAFORM BACKEND OUTPUTS
# =============================================================================

output "terraform_backend_bucket_name" {
  description = "Name of the Terraform backend S3 bucket"
  value       = var.create_backend ? module.terraform_backend[0].bucket_name : null
}

output "terraform_backend_table_name" {
  description = "Name of the Terraform backend DynamoDB table"
  value       = var.create_backend ? module.terraform_backend[0].table_name : null
}

# =============================================================================
# WEBHOOK OUTPUTS
# =============================================================================

output "webhook_namespace" {
  description = "Name of the webhook namespace"
  value       = var.create_webhook_service ? module.webhook[0].namespace_name : null
}

output "webhook_deployment_name" {
  description = "Name of the webhook deployment"
  value       = var.create_webhook_service ? module.webhook[0].deployment_name : null
}

output "webhook_service_endpoint" {
  description = "Endpoint of the webhook service"
  value       = var.create_webhook_service ? module.webhook[0].service_endpoint : null
}

output "webhook_ingress_url" {
  description = "URL of the webhook ingress"
  value       = var.create_webhook_service ? module.webhook[0].ingress_url : null
}

output "webhook_endpoints" {
  description = "Available webhook endpoints"
  value       = var.create_webhook_service ? module.webhook[0].webhook_endpoints : null
}

# =============================================================================
# ENVIRONMENT SUMMARY
# =============================================================================

output "environment_summary" {
  description = "Summary of the deployed environment"
  value = {
    environment = var.environment
    region      = var.aws_region
    vpc_id      = module.vpc.vpc_id
    ec2_instance_id = module.ec2.instance_id
    rds_instance_id = module.rds.db_instance_id
    kubernetes_cluster_name = var.kubernetes_cluster_type == "eks" ? module.kubernetes_eks[0].cluster_name : module.kubernetes_self_managed[0].cluster_name
    kubernetes_cluster_type = var.kubernetes_cluster_type
    operators_enabled = var.create_kubernetes_operators
    elk_enabled = var.create_elk_stack
    ansible_vault_enabled = var.create_ansible_vault_password
    webhook_enabled = var.create_webhook_service
    webhook_url = var.create_webhook_service ? module.webhook[0].ingress_url : null
    endpoints = {
      api = "https://${var.domain_name}/${var.environment}/api"
      web = "https://${var.domain_name}/${var.environment}/web"
      rds = "https://${var.domain_name}/${var.environment}/rds"
      webhook = var.create_webhook_service ? module.webhook[0].ingress_url : null
    }
  }
}
