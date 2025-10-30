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

output "rds_database_name" {
  description = "RDS database name"
  value       = var.db_name
}

output "rds_username" {
  description = "RDS username"
  value       = var.db_username
  sensitive   = true
}

# Tailscale Outputs
output "tailscale_router_ip" {
  description = "Tailscale subnet router IP"
  value       = try(module.tailscale[0].router_private_ip, null)
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

# =============================================================================
# ANSIBLE INVENTORY GENERATION
# =============================================================================

resource "local_file" "ansible_inventory" {
  filename = "${path.root}/../../../../ansible/inventory/${var.environment}/hosts.yml"

  content = templatefile("${path.module}/templates/ansible-inventory.tpl", {
    environment         = var.environment
    timestamp           = timestamp()
    aws_region          = var.aws_region
    vpc_id              = module.networking.vpc_id
    vpc_cidr            = module.networking.vpc_cidr_block
    public_subnet_ids   = module.networking.public_subnet_ids
    private_subnet_ids  = module.networking.private_subnet_ids
    rds_endpoint        = module.database.endpoint
    rds_port            = module.database.port
    rds_database        = var.db_name
    rds_username        = var.db_username
    ec2_instance_ids    = module.compute.instance_ids
    ec2_private_ips     = module.compute.private_ips
    tailscale_router_ip = try(module.tailscale[0].router_private_ip, "none")
    web_sg_id           = module.networking.web_security_group_id
    db_sg_id            = module.networking.database_security_group_id
  })

  file_permission = "0644"
}

# Generate Ansible group vars from Terraform
resource "local_file" "ansible_group_vars" {
  filename = "${path.root}/../../../../ansible/group_vars/${var.environment}.yml"

  content = yamlencode({
    # Environment metadata
    environment   = var.environment
    k8s_namespace = var.environment

    # Terraform outputs
    terraform_managed      = true
    terraform_vpc_id       = module.networking.vpc_id
    terraform_rds_endpoint = module.database.endpoint
    terraform_rds_database = var.db_name

    # ArgoCD applications
    argocd_apps = [
      {
        name      = "go-mysql-api-${var.environment}"
        repo      = "https://github.com/blind3dd/terraforming_again"
        path      = "infrastructure/kubernetes/overlays/${var.environment}"
        namespace = var.environment
        auto_sync = var.environment == "dev" ? true : false
      }
    ]

    # Helm releases
    helm_releases = var.environment == "dev" ? [] : [
      {
        name        = "karpenter"
        chart       = "oci://public.ecr.aws/karpenter/karpenter"
        namespace   = "karpenter"
        values_file = "../helm-kustomize/karpenter/values.yaml"
      }
    ]
  })

  file_permission = "0644"
}


