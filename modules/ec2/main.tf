# EC2 Module - Creates EC2 instances and related resources
# This module assumes VPC, subnets, and security groups are created elsewhere

# Data sources for existing resources
data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnet" "public" {
  id = var.public_subnet_id
}

data "aws_security_group" "default" {
  id = var.security_group_id
}

# SSH Key Pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.environment}-${var.service_name}-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
  
  tags = {
    Name        = "${var.environment}-${var.service_name}-key"
    Environment = var.environment
    Service     = var.service_name
  }
}

# Random password for ec2-user
resource "random_password" "ec2_user_password" {
  count = var.create_ec2_user_password ? 1 : 0
  
  length  = 16
  special = true
}

# CloudInit configuration for EC2 instances
data "cloudinit_config" "ec2_user_data" {
  count = var.create_cloudinit_config ? 1 : 0
  
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/cloudinit.yml", {
      environment = var.environment
      service_name = var.service_name
      region = var.aws_region
      ssh_public_key = tls_private_key.ssh_key.public_key_openssh
      ec2_user_password = var.create_ec2_user_password ? random_password.ec2_user_password[0].result : null
    })
  }

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/cloudinit-script.sh", {
      environment = var.environment
      service_name = var.service_name
      db_host = var.db_host
      db_port = var.db_port
      db_name = var.db_name
      db_user = var.db_user
      db_password_param = var.db_password_param
      ecr_repository_url = var.ecr_repository_url
    })
  }
}

# Save private key locally
resource "local_sensitive_file" "private_key" {
  content              = tls_private_key.ssh_key.private_key_pem
  file_permission      = "0600"
  directory_permission = "0700"
  filename             = "${aws_key_pair.ec2_key_pair.key_name}.pem"
}

# IAM Role for EC2 instance
resource "aws_iam_role" "instance_role" {
  name = "${var.environment}-${var.service_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-${var.service_name}-ec2-role"
    Environment = var.environment
    Service     = var.service_name
  }
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.environment}-${var.service_name}-ec2-profile"
  role = aws_iam_role.instance_role.name

  tags = {
    Name        = "${var.environment}-${var.service_name}-ec2-profile"
    Environment = var.environment
    Service     = var.service_name
  }
}

# Attach policies to the role
resource "aws_iam_role_policy_attachment" "ssm_readonly" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# EC2 Instance
resource "aws_instance" "main" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.public.id
  vpc_security_group_ids = [data.aws_security_group.default.id]
  key_name               = aws_key_pair.ec2_key_pair.key_name
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name

  associate_public_ip_address = var.associate_public_ip

  root_block_device {
    delete_on_termination = true
    volume_size          = var.root_volume_size
    volume_type          = var.root_volume_type
    encrypted            = var.encrypt_root_volume
  }

  user_data = var.create_cloudinit_config ? data.cloudinit_config.ec2_user_data[0].rendered : (var.user_data != null ? var.user_data : null)

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-ec2"
    Environment = var.environment
    Service     = var.service_name
  })

  lifecycle {
    create_before_destroy = true
  }
}