# Route53 Module - DNS management

# Data source for existing hosted zone
data "aws_route53_zone" "main" {
  name = var.domain_name
}

# Private Hosted Zone for internal FQDN resolution
resource "aws_route53_zone" "private" {
  count = var.create_private_zone ? 1 : 0

  name = "internal.${var.domain_name}"

  vpc {
    vpc_id = var.vpc_id
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-private-hosted-zone"
    Environment = var.environment
    Purpose     = "Private FQDN Resolution"
  })
}

# Route53 Records
resource "aws_route53_record" "records" {
  for_each = var.records

  zone_id = each.value.zone_type == "public" ? data.aws_route53_zone.main.zone_id : aws_route53_zone.private[0].zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records

  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  # Note: Route53 records don't support tags
}

# ACM Certificate for HTTPS
resource "aws_acm_certificate" "main" {
  count = var.create_certificate ? 1 : 0

  domain_name       = var.certificate_domain_name
  validation_method = "DNS"

  subject_alternative_names = var.certificate_san_domains

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-certificate"
    Environment = var.environment
    Purpose     = "SSL Certificate"
  })
}

# ACM Certificate Validation Records
resource "aws_route53_record" "cert_validation" {
  for_each = var.create_certificate ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id

  # Note: Route53 records don't support tags
}

# ACM Certificate Validation
resource "aws_acm_certificate_validation" "main" {
  count = var.create_certificate ? 1 : 0

  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}
