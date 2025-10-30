# Compute Module
# This module creates EC2 instances and related compute resources

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# SSH Key Pair
resource "aws_key_pair" "main" {
  key_name   = "${var.name_prefix}-key"
  public_key = var.ssh_public_key

  tags = var.common_tags
}

# EC2 Instance in Private Subnet
resource "aws_instance" "main" {
  count = length(var.private_subnet_ids)

  ami                    = var.instance_ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [var.web_security_group_id]
  subnet_id              = var.private_subnet_ids[count.index]
  private_ip             = cidrhost(var.private_subnet_cidrs[count.index], 10)

  associate_public_ip_address = var.associate_public_ip_address

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens                 = "required" # IMDSv2 required
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-instance-${count.index + 1}"
    Type = "compute"
  })
}

# EIP for instances that need public IPs
resource "aws_eip" "main" {
  count = var.associate_public_ip_address ? length(aws_instance.main) : 0

  domain   = "vpc"
  instance = aws_instance.main[count.index].id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-eip-${count.index + 1}"
  })
}

# ECR Repository for container images
resource "aws_ecr_repository" "main" {
  name                 = "${var.name_prefix}-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = var.common_tags
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
