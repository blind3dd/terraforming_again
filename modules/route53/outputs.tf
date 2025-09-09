# Route53 Module Outputs

output "public_zone_id" {
  description = "ID of the public hosted zone"
  value       = data.aws_route53_zone.main.zone_id
}

output "public_zone_name_servers" {
  description = "Name servers of the public hosted zone"
  value       = data.aws_route53_zone.main.name_servers
}

output "private_zone_id" {
  description = "ID of the private hosted zone"
  value       = var.create_private_zone ? aws_route53_zone.private[0].zone_id : null
}

output "private_zone_name_servers" {
  description = "Name servers of the private hosted zone"
  value       = var.create_private_zone ? aws_route53_zone.private[0].name_servers : null
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = var.create_certificate ? aws_acm_certificate.main[0].arn : null
}

output "certificate_validation_arn" {
  description = "ARN of the validated ACM certificate"
  value       = var.create_certificate ? aws_acm_certificate_validation.main[0].id : null
}

output "record_fqdns" {
  description = "FQDNs of the created records"
  value = {
    for k, v in aws_route53_record.records : k => v.fqdn
  }
}
