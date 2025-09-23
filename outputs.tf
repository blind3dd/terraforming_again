# Outputs for terraforming_again infrastructure

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

# Security Group Outputs
output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

# Key Pair Output
output "key_pair_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.main.key_name
}

# Database Outputs
output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = try(aws_db_instance.main[0].endpoint, "")
  sensitive   = true
}

output "database_port" {
  description = "RDS instance port"
  value       = try(aws_db_instance.main[0].port, 3306)
}

output "database_name" {
  description = "Database name"
  value       = try(aws_db_instance.main[0].db_name, "")
}

output "database_username" {
  description = "Database username"
  value       = try(aws_db_instance.main[0].username, "")
  sensitive   = true
}

# Kubernetes Outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = try(aws_eks_cluster.main[0].id, "")
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = try(aws_eks_cluster.main[0].arn, "")
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = try(aws_eks_cluster.main[0].endpoint, "")
}

output "eks_cluster_version" {
  description = "EKS cluster version"
  value       = try(aws_eks_cluster.main[0].version, "")
}

output "eks_node_group_arn" {
  description = "EKS node group ARN"
  value       = try(aws_eks_node_group.main[0].arn, "")
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = try(aws_lb.main[0].dns_name, "")
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = try(aws_lb.main[0].zone_id, "")
}

# ECR Outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = try(aws_ecr_repository.main[0].repository_url, "")
}

output "ecr_registry_id" {
  description = "Registry ID of the ECR repository"
  value       = try(aws_ecr_repository.main[0].registry_id, "")
}

# SSM Parameter Outputs
output "database_password_parameter_name" {
  description = "Name of the SSM parameter storing the database password"
  value       = aws_ssm_parameter.db_password.name
}

# General Outputs
output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "availability_zones" {
  description = "List of availability zones"
  value       = data.aws_availability_zones.available.names
}

# Environment-specific outputs
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

# Connection Information
output "ssh_connection_command" {
  description = "SSH connection command for EC2 instances"
  value       = "ssh -i ~/.ssh/${aws_key_pair.main.key_name}.pem ec2-user@<instance-ip>"
}

output "kubectl_config_command" {
  description = "Command to configure kubectl for EKS cluster"
  value       = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${try(aws_eks_cluster.main[0].name, "")}"
}

# Security Information
output "security_groups" {
  description = "Security group information"
  value = {
    web = {
      id   = aws_security_group.web.id
      name = aws_security_group.web.name
    }
    database = {
      id   = aws_security_group.database.id
      name = aws_security_group.database.name
    }
  }
}

# Network Information
output "network_info" {
  description = "Network configuration information"
  value = {
    vpc_id     = aws_vpc.main.id
    vpc_cidr   = aws_vpc.main.cidr_block
    public_subnets = {
      ids  = aws_subnet.public[*].id
      cidrs = aws_subnet.public[*].cidr_block
    }
    private_subnets = {
      ids   = aws_subnet.private[*].id
      cidrs = aws_subnet.private[*].cidr_block
    }
  }
}
