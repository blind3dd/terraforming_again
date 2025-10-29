# Tailscale Module
# This module creates Tailscale subnet router for hybrid cloud networking

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Tailscale subnet router for AWS VPC
resource "aws_instance" "tailscale_subnet_router" {
  ami                    = "ami-0c02fb55956c7d316"  # Amazon Linux 2023
  instance_type          = "t3.micro"
  key_name              = "${var.name_prefix}-key"
  vpc_security_group_ids = [aws_security_group.tailscale.id]
  subnet_id              = var.private_subnet_ids[0]
  private_ip             = cidrhost(var.private_subnet_cidrs[0], 10)

  associate_public_ip_address = false  # Private subnet only

  user_data = base64encode(templatefile("${path.module}/../../templates/tailscale-subnet-router.yml", {
    tailscale_auth_key = var.tailscale_auth_key
    subnet_routes = join(",", [
      var.vpc_cidr,
      join(",", var.public_subnet_cidrs),
      join(",", var.private_subnet_cidrs)
    ])
    environment = var.environment
    service_name = var.service_name
  }))

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens                 = "required"  # IMDSv2 required
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-tailscale-router"
    Role        = "tailscale-subnet-router"
    Purpose     = "Hybrid Cloud Networking"
    Security    = "high"
  })
}

# Security Group for Tailscale
resource "aws_security_group" "tailscale" {
  name_prefix = "${var.name_prefix}-tailscale-"
  vpc_id      = var.vpc_id

  # Tailscale WireGuard port
  ingress {
    description = "Tailscale WireGuard"
    from_port   = 41641
    to_port     = 41641
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]  # Tailscale manages this
  }

  # SSH access from Tailscale network
  ingress {
    description = "SSH from Tailscale"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["100.64.0.0/10"]  # Tailscale network range
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-tailscale-sg"
  })
}

# Tailscale ACL configuration
resource "aws_ssm_parameter" "tailscale_acl" {
  name  = "/${var.name_prefix}/tailscale/acl"
  type  = "String"
  value = jsonencode({
    "acls" = [
      {
        "action" = "accept"
        "src"    = ["group:developers"]
        "dst"    = ["*:22", "*:80", "*:443", "*:6443"]
      },
      {
        "action" = "accept"
        "src"    = ["group:admins"]
        "dst"    = ["*:*"]
      }
    ],
    "groups" = {
      "developers" = ["blind3dd@gmail.com"]
      "admins"     = ["blind3dd@gmail.com"]
    },
    "hosts" = {
      "azure-jumphost" = "100.64.0.1"
      "aws-subnet-router" = "100.64.0.2"
    },
    "subnet_routes" = {
      "${var.vpc_cidr}" = "aws-subnet-router"
    }
  })

  tags = var.common_tags
}

# Tailscale auth key (stored securely)
resource "aws_ssm_parameter" "tailscale_auth_key" {
  name  = "/${var.name_prefix}/tailscale/auth_key"
  type  = "SecureString"
  value = var.tailscale_auth_key

  tags = var.common_tags
}

# Route53 record for Tailscale hostname
resource "aws_route53_record" "tailscale_router" {
  count = var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = "router.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.tailscale_subnet_router.private_ip]
}



