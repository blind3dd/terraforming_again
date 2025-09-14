# Self-Managed Kubernetes Control Plane with Calico CNI
# This creates a highly available control plane in public subnets with Calico networking

# Data sources are defined in ecr.tf

# IAM Role for Kubernetes Control Plane
resource "aws_iam_role" "kubernetes_control_plane" {
  name = "${var.environment}-${var.service_name}-k8s-control-plane"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-${var.service_name}-k8s-control-plane"
    Environment = var.environment
    Service     = var.service_name
    CreatedBy   = var.infra_builder
  }
}

# IAM Policy for Kubernetes Control Plane
resource "aws_iam_policy" "kubernetes_control_plane" {
  name        = "${var.environment}-${var.service_name}-k8s-control-plane"
  description = "Policy for Kubernetes control plane instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecs:*",
          "iam:PassRole"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}-${var.service_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "kubernetes_control_plane" {
  role       = aws_iam_role.kubernetes_control_plane.name
  policy_arn = aws_iam_policy.kubernetes_control_plane.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "kubernetes_control_plane" {
  name = "${var.environment}-${var.service_name}-k8s-control-plane"
  role = aws_iam_role.kubernetes_control_plane.name
}

# Security Group for Kubernetes Control Plane
resource "aws_security_group" "kubernetes_control_plane" {
  name_prefix = "${var.environment}-${var.service_name}-k8s-control-plane-"
  vpc_id      = aws_vpc.main.id

  # Allow all traffic within the security group
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # Kubernetes API Server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubernetes API Server"
  }

  # etcd client communication
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "etcd client communication"
  }

  # Kubelet API
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Kubelet API"
  }

  # kube-scheduler
  ingress {
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "kube-scheduler"
  }

  # kube-controller-manager
  ingress {
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "kube-controller-manager"
  }

  # Calico BGP
  ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Calico BGP"
  }

  # Calico Typha
  ingress {
    from_port   = 5473
    to_port     = 5473
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Calico Typha"
  }

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP/HTTPS for package installation
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.service_name}-k8s-control-plane"
    Environment = var.environment
    Service     = var.service_name
    CreatedBy   = var.infra_builder
  }
}

# Security Group for Kubernetes Worker Nodes
resource "aws_security_group" "kubernetes_workers" {
  name_prefix = "${var.environment}-${var.service_name}-workers-"
  vpc_id      = aws_vpc.main.id

  # Allow all traffic within the security group
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # Kubelet API
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Kubelet API"
  }

  # NodePort Services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NodePort Services"
  }

  # Calico BGP
  ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Calico BGP"
  }

  # Calico Typha
  ingress {
    from_port   = 5473
    to_port     = 5473
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Calico Typha"
  }

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.service_name}-workers"
    Environment = var.environment
    Service     = var.service_name
    CreatedBy   = var.infra_builder
  }
}

# Security Group Rule: Kubernetes to RDS
resource "aws_security_group_rule" "kubernetes_to_rds" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.kubernetes_workers.id
  security_group_id        = aws_security_group.rds.id
  description              = "Kubernetes workers to RDS MySQL"
}

# Security Group Rule: RDS to Kubernetes
resource "aws_security_group_rule" "rds_to_kubernetes" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.kubernetes_workers.id
  security_group_id        = aws_security_group.rds.id
  description              = "RDS MySQL to Kubernetes workers"
}

# CloudInit configuration for Kubernetes control plane
data "cloudinit_config" "kubernetes_control_plane" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/templates/kubernetes-control-plane-cloudinit.yml", {
      environment = var.environment
      service_name = var.service_name
      cluster_name = "${var.environment}-${var.service_name}-cluster"
      pod_cidr     = "10.244.0.0/16"
      service_cidr = "10.96.0.0/12"
      calico_version = "3.26.1"
      kubernetes_version = "1.28.0"
      aws_region = data.aws_region.current.name
      aws_account_id = data.aws_caller_identity.current.account_id
      rds_endpoint = aws_db_instance.aws_rds_mysql_8.endpoint
      rds_port = aws_db_instance.aws_rds_mysql_8.port
      rds_database = aws_db_instance.aws_rds_mysql_8.db_name
      rds_username = aws_db_instance.aws_rds_mysql_8.username
      rds_password_parameter = aws_ssm_parameter.db_password.name
    })
  }

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/templates/kubernetes-control-plane-setup.sh", {
      environment = var.environment
      service_name = var.service_name
      cluster_name = "${var.environment}-${var.service_name}-cluster"
      pod_cidr     = "10.244.0.0/16"
      service_cidr = "10.96.0.0/12"
      calico_version = "3.26.1"
      kubernetes_version = "1.28.0"
      aws_region = data.aws_region.current.name
      aws_account_id = data.aws_caller_identity.current.account_id
      rds_endpoint = aws_db_instance.aws_rds_mysql_8.endpoint
      rds_port = aws_db_instance.aws_rds_mysql_8.port
      rds_database = aws_db_instance.aws_rds_mysql_8.db_name
      rds_username = aws_db_instance.aws_rds_mysql_8.username
      rds_password_parameter = aws_ssm_parameter.db_password.name
      aws_access_key_id = var.aws_access_key_id
      aws_secret_access_key = var.aws_secret_access_key
      route53_zone_id = var.route53_zone_id
    })
  }
}

# Launch Template for Kubernetes Control Plane
resource "aws_launch_template" "kubernetes_control_plane" {
  name_prefix   = "${var.environment}-${var.service_name}-k8s-control-plane-"
  image_id      = "ami-0c7217cdde317cfec" # Amazon Linux 2023 with kernel 6.1
  instance_type = "t3.medium"

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    device_index                = 0
    security_groups             = [aws_security_group.kubernetes_control_plane.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.kubernetes_control_plane.name
  }

  user_data = data.cloudinit_config.kubernetes_control_plane.rendered

  key_name = aws_key_pair.main.key_name

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-${var.service_name}-k8s-control-plane"
      Environment = var.environment
      Service     = var.service_name
      Role        = "kubernetes-control-plane"
      CreatedBy   = var.infra_builder
    }
  }

  tags = {
    Name        = "${var.environment}-${var.service_name}-k8s-control-plane"
    Environment = var.environment
    Service     = var.service_name
    CreatedBy   = var.infra_builder
  }
}

# Auto Scaling Group for Kubernetes Control Plane
resource "aws_autoscaling_group" "kubernetes_control_plane" {
  name                = "${var.environment}-${var.service_name}-k8s-control-plane"
  desired_capacity    = 3
  max_size           = 5
  min_size           = 3
  target_group_arns  = [aws_lb_target_group.kubernetes_api.arn]
  vpc_zone_identifier = aws_subnet.public[*].id
  health_check_type  = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.kubernetes_control_plane.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value              = "${var.environment}-${var.service_name}-k8s-control-plane"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value              = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Service"
    value              = var.service_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value              = "kubernetes-control-plane"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.environment}-${var.service_name}-cluster"
    value              = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/role/control-plane"
    value              = "1"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/role/control-plane"
    value              = "1"
    propagate_at_launch = true
  }
}

# Application Load Balancer for Kubernetes API
resource "aws_lb" "kubernetes_api" {
  name               = "${var.environment}-${var.service_name}-k8s-api"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.kubernetes_control_plane.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name        = "${var.environment}-${var.service_name}-k8s-api"
    Environment = var.environment
    Service     = var.service_name
    CreatedBy   = var.infra_builder
  }
}

# Target Group for Kubernetes API
resource "aws_lb_target_group" "kubernetes_api" {
  name     = "${var.environment}-${var.service_name}-k8s-api"
  port     = 6443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/healthz"
    port                = "traffic-port"
    protocol            = "HTTPS"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.environment}-${var.service_name}-k8s-api"
    Environment = var.environment
    Service     = var.service_name
    CreatedBy   = var.infra_builder
  }
}

# Listener for Kubernetes API
resource "aws_lb_listener" "kubernetes_api" {
  load_balancer_arn = aws_lb.kubernetes_api.arn
  port              = "6443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.kubernetes_api.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kubernetes_api.arn
  }
}

# ACM Certificate for Kubernetes API
resource "aws_acm_certificate" "kubernetes_api" {
  domain_name       = "k8s.${var.environment}-${var.service_name}.${var.domain_name}"
  validation_method = "DNS"

  tags = {
    Name        = "${var.environment}-${var.service_name}-k8s-api"
    Environment = var.environment
    Service     = var.service_name
    CreatedBy   = var.infra_builder
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 Record for Kubernetes API
resource "aws_route53_record" "kubernetes_api" {
  zone_id = var.route53_zone_id
  name    = "k8s.${var.environment}-${var.service_name}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.kubernetes_api.dns_name
    zone_id                = aws_lb.kubernetes_api.zone_id
    evaluate_target_health = true
  }
}

# IAM Role for Kubernetes Worker Nodes
resource "aws_iam_role" "kubernetes_workers" {
  name = "${var.environment}-${var.service_name}-workers"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-${var.service_name}-workers"
    Environment = var.environment
    Service     = var.service_name
    CreatedBy   = var.infra_builder
  }
}

# IAM Policy for Kubernetes Worker Nodes
resource "aws_iam_policy" "kubernetes_workers" {
  name        = "${var.environment}-${var.service_name}-workers"
  description = "Policy for Kubernetes worker nodes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecs:*",
          "iam:PassRole"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}-${var.service_name}/*"
        ]
      }
    ]
  })
}

# Attach policy to worker role
resource "aws_iam_role_policy_attachment" "kubernetes_workers" {
  role       = aws_iam_role.kubernetes_workers.name
  policy_arn = aws_iam_policy.kubernetes_workers.arn
}

# IAM Instance Profile for Workers
resource "aws_iam_instance_profile" "kubernetes_workers" {
  name = "${var.environment}-${var.service_name}-workers"
  role = aws_iam_role.kubernetes_workers.name
}

# CloudInit configuration for Kubernetes worker nodes
data "cloudinit_config" "kubernetes_workers" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/templates/kubernetes-worker-cloudinit.yml", {
      environment = var.environment
      service_name = var.service_name
      cluster_name = "${var.environment}-${var.service_name}-cluster"
      pod_cidr     = "10.244.0.0/16"
      service_cidr = "10.96.0.0/12"
      calico_version = "3.26.1"
      kubernetes_version = "1.28.0"
      aws_region = data.aws_region.current.name
      aws_account_id = data.aws_caller_identity.current.account_id
    })
  }

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/templates/kubernetes-worker-setup.sh", {
      environment = var.environment
      service_name = var.service_name
      cluster_name = "${var.environment}-${var.service_name}-cluster"
      pod_cidr     = "10.244.0.0/16"
      service_cidr = "10.96.0.0/12"
      calico_version = "3.26.1"
      kubernetes_version = "1.28.0"
      aws_region = data.aws_region.current.name
      aws_account_id = data.aws_caller_identity.current.account_id
    })
  }
}

# Launch Template for Kubernetes Worker Nodes
resource "aws_launch_template" "kubernetes_workers" {
  name_prefix   = "${var.environment}-${var.service_name}-workers-"
  image_id      = "ami-0c7217cdde317cfec" # Amazon Linux 2023 with kernel 6.1
  instance_type = "t3.medium"

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    device_index                = 0
    security_groups             = [aws_security_group.kubernetes_workers.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.kubernetes_workers.name
  }

  user_data = data.cloudinit_config.kubernetes_workers.rendered

  key_name = aws_key_pair.main.key_name

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-${var.service_name}-workers"
      Environment = var.environment
      Service     = var.service_name
      Role        = "kubernetes-workers"
      CreatedBy   = var.infra_builder
    }
  }

  tags = {
    Name        = "${var.environment}-${var.service_name}-workers"
    Environment = var.environment
    Service     = var.service_name
    CreatedBy   = var.infra_builder
  }
}

# Auto Scaling Group for Kubernetes Worker Nodes
resource "aws_autoscaling_group" "kubernetes_workers" {
  name                = "${var.environment}-${var.service_name}-workers"
  desired_capacity    = 2
  max_size           = 10
  min_size           = 1
  vpc_zone_identifier = aws_subnet.public[*].id
  health_check_type  = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.kubernetes_workers.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value              = "${var.environment}-${var.service_name}-workers"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value              = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Service"
    value              = var.service_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value              = "kubernetes-workers"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.environment}-${var.service_name}-cluster"
    value              = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/role/worker"
    value              = "1"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/role/worker"
    value              = "1"
    propagate_at_launch = true
  }
}

# Outputs
output "kubernetes_api_endpoint" {
  description = "Kubernetes API endpoint"
  value       = "https://${aws_route53_record.kubernetes_api.name}:6443"
}

output "kubernetes_cluster_name" {
  description = "Kubernetes cluster name"
  value       = "${var.environment}-${var.service_name}-cluster"
}

output "kubernetes_load_balancer_dns" {
  description = "Kubernetes load balancer DNS name"
  value       = aws_lb.kubernetes_api.dns_name
}

output "kubernetes_certificate_arn" {
  description = "Kubernetes API certificate ARN"
  value       = aws_acm_certificate.kubernetes_api.arn
}
