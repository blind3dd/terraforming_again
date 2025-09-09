# Self-Managed Kubernetes Module
# Creates a highly available cluster with 3 etcd, 3 control planes, and 3 workers

# Data sources for existing resources
data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnet" "public" {
  count = length(var.public_subnet_ids)
  id    = var.public_subnet_ids[count.index]
}

data "aws_subnet" "private" {
  count = length(var.private_subnet_ids)
  id    = var.private_subnet_ids[count.index]
}

# =============================================================================
# ETCD INSTANCES (3 instances for HA)
# =============================================================================

# etcd instances
resource "aws_instance" "etcd" {
  count = 3

  ami                    = var.etcd_ami
  instance_type          = var.etcd_instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.kubernetes.id]
  key_name               = var.key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.kubernetes_etcd.name

  associate_public_ip_address = false

  root_block_device {
    delete_on_termination = true
    volume_size          = var.etcd_volume_size
    volume_type          = var.etcd_volume_type
    encrypted            = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data_etcd.sh", {
    cluster_name = "${var.environment}-${var.service_name}-cluster"
    etcd_name    = "etcd-${count.index + 1}"
    etcd_ips     = join(",", [for i in range(3) : "etcd-${i + 1}.internal.${var.domain_name}"])
    pod_cidr     = var.pod_cidr
    service_cidr = var.service_cidr
  }))

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-etcd-${count.index + 1}"
    Environment = var.environment
    Service     = var.service_name
    Role        = "etcd"
  })
}

# =============================================================================
# CONTROL PLANE INSTANCES (3 instances for HA)
# =============================================================================

# Control plane instances
resource "aws_instance" "control_plane" {
  count = 3

  ami                    = var.control_plane_ami
  instance_type          = var.control_plane_instance_type
  subnet_id              = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.kubernetes.id]
  key_name               = var.key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.kubernetes_control_plane.name

  associate_public_ip_address = true

  root_block_device {
    delete_on_termination = true
    volume_size          = var.control_plane_volume_size
    volume_type          = var.control_plane_volume_type
    encrypted            = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data_control_plane.sh", {
    cluster_name = "${var.environment}-${var.service_name}-cluster"
    control_plane_name = "control-plane-${count.index + 1}"
    etcd_ips     = join(",", [for i in range(3) : "etcd-${i + 1}.internal.${var.domain_name}"])
    control_plane_ips = join(",", [for i in range(3) : "control-plane-${i + 1}.internal.${var.domain_name}"])
    pod_cidr     = var.pod_cidr
    service_cidr = var.service_cidr
    is_first_control_plane = count.index == 0
  }))

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-control-plane-${count.index + 1}"
    Environment = var.environment
    Service     = var.service_name
    Role        = "control-plane"
  })
}

# =============================================================================
# WORKER INSTANCES (3 instances for HA)
# =============================================================================

# Worker instances
resource "aws_instance" "workers" {
  count = 3

  ami                    = var.worker_ami
  instance_type          = var.worker_instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.kubernetes.id]
  key_name               = var.key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.kubernetes_worker.name

  associate_public_ip_address = false

  root_block_device {
    delete_on_termination = true
    volume_size          = var.worker_volume_size
    volume_type          = var.worker_volume_type
    encrypted            = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data_worker.sh", {
    cluster_name = "${var.environment}-${var.service_name}-cluster"
    worker_name = "worker-${count.index + 1}"
    control_plane_ip = aws_instance.control_plane[0].private_ip
    control_plane_ips = join(",", [for i in range(3) : "control-plane-${i + 1}.internal.${var.domain_name}"])
  }))

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-worker-${count.index + 1}"
    Environment = var.environment
    Service     = var.service_name
    Role        = "worker"
  })
}

# =============================================================================
# IAM ROLES AND POLICIES
# =============================================================================

# etcd IAM Role
resource "aws_iam_role" "kubernetes_etcd" {
  name = "${var.environment}-${var.service_name}-k8s-etcd"

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

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-k8s-etcd"
    Environment = var.environment
    Service     = var.service_name
  })
}

# Control Plane IAM Role
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

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-k8s-control-plane"
    Environment = var.environment
    Service     = var.service_name
  })
}

# Worker IAM Role
resource "aws_iam_role" "kubernetes_worker" {
  name = "${var.environment}-${var.service_name}-worker"

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

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-worker"
    Environment = var.environment
    Service     = var.service_name
  })
}

# IAM Instance Profiles
resource "aws_iam_instance_profile" "kubernetes_etcd" {
  name = "${var.environment}-${var.service_name}-k8s-etcd-profile"
  role = aws_iam_role.kubernetes_etcd.name

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-k8s-etcd-profile"
    Environment = var.environment
    Service     = var.service_name
  })
}

resource "aws_iam_instance_profile" "kubernetes_control_plane" {
  name = "${var.environment}-${var.service_name}-k8s-control-plane-profile"
  role = aws_iam_role.kubernetes_control_plane.name

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-k8s-control-plane-profile"
    Environment = var.environment
    Service     = var.service_name
  })
}

resource "aws_iam_instance_profile" "kubernetes_worker" {
  name = "${var.environment}-${var.service_name}-worker-profile"
  role = aws_iam_role.kubernetes_worker.name

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-worker-profile"
    Environment = var.environment
    Service     = var.service_name
  })
}

# =============================================================================
# IAM POLICY ATTACHMENTS
# =============================================================================

# etcd Policy Attachments
resource "aws_iam_role_policy_attachment" "kubernetes_etcd_ec2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  role       = aws_iam_role.kubernetes_etcd.name
}

# Control Plane Policy Attachments
resource "aws_iam_role_policy_attachment" "kubernetes_control_plane_ec2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.kubernetes_control_plane.name
}

resource "aws_iam_role_policy_attachment" "kubernetes_control_plane_elb" {
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  role       = aws_iam_role.kubernetes_control_plane.name
}

resource "aws_iam_role_policy_attachment" "kubernetes_control_plane_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.kubernetes_control_plane.name
}

# Worker Policy Attachments
resource "aws_iam_role_policy_attachment" "kubernetes_worker_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.kubernetes_worker.name
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

# Kubernetes Security Group
resource "aws_security_group" "kubernetes" {
  name_prefix = "${var.environment}-kubernetes-sg-"
  vpc_id      = var.vpc_id

  # etcd client API
  ingress {
    description = "etcd client API"
    from_port   = 2379
    to_port     = 2379
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # etcd peer API
  ingress {
    description = "etcd peer API"
    from_port   = 2380
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # Kubernetes API Server
  ingress {
    description = "Kubernetes API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # Kubelet API
  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # kube-scheduler
  ingress {
    description = "kube-scheduler"
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # kube-controller-manager
  ingress {
    description = "kube-controller-manager"
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # NodePort Services
  ingress {
    description = "NodePort Services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-kubernetes-sg"
    Environment = var.environment
    Service     = var.service_name
  })
}
