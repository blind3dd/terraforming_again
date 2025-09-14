# Test Environment Outputs
# This file defines all outputs for the test environment

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
  value       = module.route53.private_zone_id
}

output "route53_name_servers" {
  description = "Name servers of the Route53 zone"
  value       = module.route53.private_zone_name_servers
}

output "certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = module.route53.certificate_arn
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
    domain_name = var.domain_name
    endpoints = {
      api = "https://${var.domain_name}/${var.environment}/api"
      web = "https://${var.domain_name}/${var.environment}/web"
      rds = "https://${var.domain_name}/${var.environment}/rds"
    }
  }
}
