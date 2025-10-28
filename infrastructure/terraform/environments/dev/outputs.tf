# Dev Environment Outputs

# Networking Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

# Compute Outputs
output "ec2_instance_ids" {
  description = "IDs of the EC2 instances"
  value       = module.compute.instance_ids
}

output "ec2_private_ips" {
  description = "Private IPs of the EC2 instances"
  value       = module.compute.private_ips
}

# Database Outputs
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.database.endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS port"
  value       = module.database.port
}

# Tailscale Outputs
output "tailscale_router_ip" {
  description = "Tailscale subnet router IP"
  value       = var.enable_tailscale ? module.tailscale[0].router_ip : null
}

# Security Group Outputs
output "web_security_group_id" {
  description = "ID of the web security group"
  value       = module.networking.web_security_group_id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = module.networking.database_security_group_id
}


