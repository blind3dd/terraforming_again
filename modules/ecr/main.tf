# AWS ECR Repository Module
# This module creates an ECR repository with proper policies and lifecycle management

# ECR Repository
resource "aws_ecr_repository" "main" {
  name                 = "${var.environment}-${var.service_name}-api"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-ecr"
    Environment = var.environment
    Service     = var.service_name
    Purpose     = "ECR Repository"
  })
}

# ECR Repository Policy
resource "aws_ecr_repository_policy" "main" {
  count      = var.create_repository_policy ? 1 : 0
  repository = aws_ecr_repository.main.name

  policy = var.repository_policy != null ? var.repository_policy : jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECRAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "main" {
  count      = var.create_lifecycle_policy ? 1 : 0
  repository = aws_ecr_repository.main.name

  policy = var.lifecycle_policy != null ? var.lifecycle_policy : jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.keep_tagged_images} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = var.tag_prefix_list
          countType     = "imageCountMoreThan"
          countNumber   = var.keep_tagged_images
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images older than ${var.untagged_image_retention_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_retention_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
