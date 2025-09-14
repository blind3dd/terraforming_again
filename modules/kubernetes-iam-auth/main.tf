# Kubernetes IAM Authentication Module
# This module sets up secure Kubernetes authentication tied to AWS IAM

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Create OIDC Identity Provider for Kubernetes
resource "aws_iam_openid_connect_provider" "kubernetes" {
  url = "https://kubernetes.${var.cluster_domain}"

  client_id_list = [
    "sts.amazonaws.com",
    "system:serviceaccount:${var.namespace}:${var.service_account_name}"
  ]

  thumbprint_list = [
    "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"  # Kubernetes OIDC thumbprint
  ]

  tags = {
    Name        = "${var.cluster_name}-oidc-provider"
    Environment = var.environment
    Purpose     = "Kubernetes IAM Authentication"
  }
}

# IAM Role for Kubernetes Cluster Admin
resource "aws_iam_role" "kubernetes_cluster_admin" {
  name = "${var.cluster_name}-cluster-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.kubernetes.arn
        }
        Condition = {
          StringEquals = {
            "kubernetes.${var.cluster_domain}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
            "kubernetes.${var.cluster_domain}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-cluster-admin"
    Environment = var.environment
    Purpose     = "Kubernetes Cluster Admin Access"
  }
}

# IAM Role for Kubernetes Developers
resource "aws_iam_role" "kubernetes_developer" {
  name = "${var.cluster_name}-developer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.kubernetes.arn
        }
        Condition = {
          StringEquals = {
            "kubernetes.${var.cluster_domain}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
            "kubernetes.${var.cluster_domain}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-developer"
    Environment = var.environment
    Purpose     = "Kubernetes Developer Access"
  }
}

# IAM Role for Kubernetes Read-Only Users
resource "aws_iam_role" "kubernetes_readonly" {
  name = "${var.cluster_name}-readonly"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.kubernetes.arn
        }
        Condition = {
          StringEquals = {
            "kubernetes.${var.cluster_domain}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
            "kubernetes.${var.cluster_domain}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-readonly"
    Environment = var.environment
    Purpose     = "Kubernetes Read-Only Access"
  }
}

# IAM Role for Kubernetes Service Accounts (for applications)
resource "aws_iam_role" "kubernetes_service_account" {
  name = "${var.cluster_name}-service-account"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.kubernetes.arn
        }
        Condition = {
          StringEquals = {
            "kubernetes.${var.cluster_domain}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
            "kubernetes.${var.cluster_domain}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-service-account"
    Environment = var.environment
    Purpose     = "Kubernetes Service Account Access"
  }
}

# IAM Policy for Cluster Admin
resource "aws_iam_role_policy" "kubernetes_cluster_admin" {
  name = "${var.cluster_name}-cluster-admin-policy"
  role = aws_iam_role.kubernetes_cluster_admin.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:*",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "iam:ListRoles",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for Developer
resource "aws_iam_role_policy" "kubernetes_developer" {
  name = "${var.cluster_name}-developer-policy"
  role = aws_iam_role.kubernetes_developer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for Service Account
resource "aws_iam_role_policy" "kubernetes_service_account" {
  name = "${var.cluster_name}-service-account-policy"
  role = aws_iam_role.kubernetes_service_account.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "secretsmanager:GetSecretValue",
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create Kubernetes Service Account
resource "kubernetes_service_account" "aws_iam_authenticator" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.kubernetes_service_account.arn
    }
  }

  automount_service_account_token = true
}

# Create ClusterRole for Cluster Admin
resource "kubernetes_cluster_role" "cluster_admin" {
  metadata {
    name = "aws-iam-cluster-admin"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    non_resource_urls = ["*"]
    verbs             = ["*"]
  }
}

# Create ClusterRole for Developer
resource "kubernetes_cluster_role" "developer" {
  metadata {
    name = "aws-iam-developer"
  }

  rule {
    api_groups = ["", "apps", "extensions"]
    resources  = ["pods", "services", "deployments", "replicasets", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

# Create ClusterRole for Read-Only
resource "kubernetes_cluster_role" "readonly" {
  metadata {
    name = "aws-iam-readonly"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

# Create ClusterRoleBinding for Cluster Admin
resource "kubernetes_cluster_role_binding" "cluster_admin" {
  metadata {
    name = "aws-iam-cluster-admin-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cluster_admin.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = "aws-iam-cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}

# Create ClusterRoleBinding for Developer
resource "kubernetes_cluster_role_binding" "developer" {
  metadata {
    name = "aws-iam-developer-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.developer.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = "aws-iam-developer"
    api_group = "rbac.authorization.k8s.io"
  }
}

# Create ClusterRoleBinding for Read-Only
resource "kubernetes_cluster_role_binding" "readonly" {
  metadata {
    name = "aws-iam-readonly-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.readonly.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = "aws-iam-readonly"
    api_group = "rbac.authorization.k8s.io"
  }
}

# Create aws-auth ConfigMap for IAM user/role mapping
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.kubernetes_cluster_admin.arn
        username = "aws-iam-cluster-admin"
        groups   = ["system:masters"]
      },
      {
        rolearn  = aws_iam_role.kubernetes_developer.arn
        username = "aws-iam-developer"
        groups   = ["aws-iam-developer"]
      },
      {
        rolearn  = aws_iam_role.kubernetes_readonly.arn
        username = "aws-iam-readonly"
        groups   = ["aws-iam-readonly"]
      },
      {
        rolearn  = aws_iam_role.kubernetes_service_account.arn
        username = "aws-iam-service-account"
        groups   = ["aws-iam-service-account"]
      }
    ])

    mapUsers = yamlencode([
      for user in var.iam_users : {
        userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${user.username}"
        username = user.username
        groups   = user.groups
      }
    ])
  }
}
