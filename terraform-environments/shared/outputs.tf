# Shared Environment Outputs
# Common outputs used across all environments

output "vpc_id" {
  description = "ID of the VPC"
  value       = var.create_vpc ? aws_vpc.main[0].id : null
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = var.create_vpc ? aws_vpc.main[0].cidr_block : null
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = var.create_vpc ? aws_vpc.main[0].id : null
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = var.create_vpc ? aws_subnet.public[*].id : []
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = var.create_vpc ? aws_subnet.private[*].id : []
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = var.create_vpc ? aws_route_table.public[0].id : null
}

output "common_security_group_id" {
  description = "ID of the common security group"
  value       = var.create_vpc ? aws_security_group.common[0].id : null
}

output "availability_zones" {
  description = "List of availability zones"
  value       = var.availability_zones
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}

output "internal_domain" {
  description = "Internal domain name"
  value       = var.internal_domain
}
