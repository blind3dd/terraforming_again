# Load Balancer Configuration for Route53 Integration
# This file creates Application Load Balancer (ALB) and Network Load Balancer (NLB)
# for the RDS application with Route53 integration

# =============================================================================
# APPLICATION LOAD BALANCER (ALB) - Layer 7 Load Balancing
# =============================================================================

# ALB Security Group
resource "aws_security_group" "alb" {
  name_prefix = "alb-rds-app-"
  vpc_id      = data.aws_vpc.main.id

  # Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from anywhere"
  }

  # Allow HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from anywhere"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "alb-rds-app-sg"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Application Load Balancer for RDS App"
  }
}

# Application Load Balancer
resource "aws_lb" "rds_app_alb" {
  name               = "rds-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_2.id]

  enable_deletion_protection = false

  tags = {
    Name        = "rds-app-alb"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Application Load Balancer"
  }
}

# ALB Target Group for RDS App
resource "aws_lb_target_group" "rds_app_alb" {
  name     = "rds-app-alb-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "rds-app-alb-tg"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "ALB Target Group"
  }
}

# ALB Target Group Attachment (for EC2 instances)
resource "aws_lb_target_group_attachment" "rds_app_alb" {
  count            = length(aws_instance.kubernetes_worker)
  target_group_arn = aws_lb_target_group.rds_app_alb.arn
  target_id        = aws_instance.kubernetes_worker[count.index].id
  port             = 8080
}

# ALB HTTP Listener
resource "aws_lb_listener" "rds_app_alb_http" {
  load_balancer_arn = aws_lb.rds_app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Name        = "rds-app-alb-http-listener"
    Environment = var.environment
    Service     = "go-mysql-api"
  }
}

# ALB HTTPS Listener
resource "aws_lb_listener" "rds_app_alb_https" {
  load_balancer_arn = aws_lb.rds_app_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.rds_app.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rds_app_alb.arn
  }

  tags = {
    Name        = "rds-app-alb-https-listener"
    Environment = var.environment
    Service     = "go-mysql-api"
  }
}

# =============================================================================
# NETWORK LOAD BALANCER (NLB) - Layer 4 Load Balancing
# =============================================================================

# NLB Security Group
resource "aws_security_group" "nlb" {
  name_prefix = "nlb-rds-app-"
  vpc_id      = data.aws_vpc.main.id

  # Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from anywhere"
  }

  # Allow HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from anywhere"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "nlb-rds-app-sg"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Network Load Balancer for RDS App"
  }
}

# Network Load Balancer
resource "aws_lb" "rds_app_nlb" {
  name               = "rds-app-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public.id, aws_subnet.public_2.id]

  enable_deletion_protection = false

  tags = {
    Name        = "rds-app-nlb"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Network Load Balancer"
  }
}

# NLB Target Group for RDS App
resource "aws_lb_target_group" "rds_app_nlb" {
  name     = "rds-app-nlb-tg"
  port     = 8080
  protocol = "TCP"
  vpc_id   = data.aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
    protocol            = "TCP"
    port                = "traffic-port"
  }

  tags = {
    Name        = "rds-app-nlb-tg"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "NLB Target Group"
  }
}

# NLB Target Group Attachment
resource "aws_lb_target_group_attachment" "rds_app_nlb" {
  count            = length(aws_instance.kubernetes_worker)
  target_group_arn = aws_lb_target_group.rds_app_nlb.arn
  target_id        = aws_instance.kubernetes_worker[count.index].id
  port             = 8080
}

# NLB TCP Listener
resource "aws_lb_listener" "rds_app_nlb" {
  load_balancer_arn = aws_lb.rds_app_nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rds_app_nlb.arn
  }

  tags = {
    Name        = "rds-app-nlb-listener"
    Environment = var.environment
    Service     = "go-mysql-api"
  }
}

# =============================================================================
# SSL/TLS CERTIFICATE
# =============================================================================

# ACM Certificate for HTTPS
resource "aws_acm_certificate" "rds_app" {
  domain_name       = "rds-app.${var.domain_name}"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.rds-app.${var.domain_name}",
    "rds-app-api.${var.domain_name}",
    "rds-app-admin.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "rds-app-certificate"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "SSL Certificate for RDS App"
  }
}

# ACM Certificate Validation
resource "aws_acm_certificate_validation" "rds_app" {
  certificate_arn         = aws_acm_certificate.rds_app.arn
  validation_record_fqdns = [for record in aws_route53_record.rds_app_cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

# =============================================================================
# ROUTE53 CONFIGURATION
# =============================================================================

# Route53 Record for ALB
resource "aws_route53_record" "rds_app_alb" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "rds-app.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.rds_app_alb.dns_name
    zone_id                = aws_lb.rds_app_alb.zone_id
    evaluate_target_health = true
  }

  tags = {
    Name        = "rds-app-alb-record"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "ALB Route53 Record"
  }
}

# Route53 Record for NLB
resource "aws_route53_record" "rds_app_nlb" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "rds-app-nlb.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.rds_app_nlb.dns_name
    zone_id                = aws_lb.rds_app_nlb.zone_id
    evaluate_target_health = true
  }

  tags = {
    Name        = "rds-app-nlb-record"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "NLB Route53 Record"
  }
}

# Route53 Record for API endpoint
resource "aws_route53_record" "rds_app_api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "rds-app-api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.rds_app_alb.dns_name
    zone_id                = aws_lb.rds_app_alb.zone_id
    evaluate_target_health = true
  }

  tags = {
    Name        = "rds-app-api-record"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "API Route53 Record"
  }
}

# Route53 Record for Admin endpoint
resource "aws_route53_record" "rds_app_admin" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "rds-app-admin.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.rds_app_alb.dns_name
    zone_id                = aws_lb.rds_app_alb.zone_id
    evaluate_target_health = true
  }

  tags = {
    Name        = "rds-app-admin-record"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Admin Route53 Record"
  }
}

# Route53 Records for Certificate Validation
resource "aws_route53_record" "rds_app_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.rds_app.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id

  tags = {
    Name        = "rds-app-cert-validation-${each.key}"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Certificate Validation"
  }
}

# =============================================================================
# WAF (Web Application Firewall) - Optional but Recommended
# =============================================================================

# WAF Web ACL
resource "aws_wafv2_web_acl" "rds_app" {
  name  = "rds-app-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 1

    override_action {
      none {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # SQL Injection Protection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "rds-app-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "rds-app-waf"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Web Application Firewall"
  }
}

# WAF Association with ALB
resource "aws_wafv2_web_acl_association" "rds_app_alb" {
  resource_arn = aws_lb.rds_app_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.rds_app.arn
}

# =============================================================================
# CLOUDWATCH MONITORING
# =============================================================================

# CloudWatch Log Group for ALB
resource "aws_cloudwatch_log_group" "rds_app_alb" {
  name              = "/aws/applicationloadbalancer/rds-app-alb"
  retention_in_days = 30

  tags = {
    Name        = "rds-app-alb-logs"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "ALB Access Logs"
  }
}

# CloudWatch Log Group for NLB
resource "aws_cloudwatch_log_group" "rds_app_nlb" {
  name              = "/aws/networkloadbalancer/rds-app-nlb"
  retention_in_days = 30

  tags = {
    Name        = "rds-app-nlb-logs"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "NLB Access Logs"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "rds_app" {
  dashboard_name = "rds-app-load-balancer"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.rds_app_alb.arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS App ALB Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/NetworkELB", "ActiveFlowCount", "LoadBalancer", aws_lb.rds_app_nlb.arn_suffix],
            [".", "NewFlowCount", ".", "."],
            [".", "ProcessedBytes", ".", "."],
            [".", "TCP_Target_Reset_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS App NLB Metrics"
          period  = 300
        }
      }
    ]
  })

  tags = {
    Name        = "rds-app-dashboard"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Load Balancer Monitoring"
  }
}
