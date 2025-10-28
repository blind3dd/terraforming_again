# Tailscale Module Outputs

output "router_instance_id" {
  description = "ID of the Tailscale subnet router instance"
  value       = aws_instance.tailscale_subnet_router.id
}

output "router_private_ip" {
  description = "Private IP of the Tailscale subnet router"
  value       = aws_instance.tailscale_subnet_router.private_ip
}

output "router_security_group_id" {
  description = "ID of the Tailscale security group"
  value       = aws_security_group.tailscale.id
}

output "acl_parameter_name" {
  description = "SSM parameter name for Tailscale ACL"
  value       = aws_ssm_parameter.tailscale_acl.name
}

output "auth_key_parameter_name" {
  description = "SSM parameter name for Tailscale auth key"
  value       = aws_ssm_parameter.tailscale_auth_key.name
}

output "router_dns_name" {
  description = "DNS name of the Tailscale router"
  value       = var.route53_zone_id != "" ? aws_route53_record.tailscale_router[0].fqdn : null
}



