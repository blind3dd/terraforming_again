# CloudInit configuration for EC2 instances
data "cloudinit_config" "ec2_user_data" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/cloudinit.yml", {
      environment = var.environment
      region = var.region
      service_name = var.service_name
      ssh_public_key = tls_private_key.ec2_ssh_key.public_key_openssh
      ec2_user_password = random_password.ec2_user_password.result
    })
  }

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/cloudinit_script.sh", {
      environment = var.environment
      service_name = var.service_name
      db_host = aws_db_instance.aws_rds_mysql_8.address
      db_port = aws_db_instance.aws_rds_mysql_8.port
      db_name = aws_db_instance.aws_rds_mysql_8.db_name
      db_user = aws_db_instance.aws_rds_mysql_8.username
      db_password_param = aws_ssm_parameter.db_password.name
      ecr_repository_url = aws_ecr_repository.go_mysql_api.repository_url
    })
  }
}

# RSA SSH Key Pair for EC2 instances
resource "tls_private_key" "ec2_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# AWS Key Pair
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.environment}-${var.service_name}-key"
  public_key = tls_private_key.ec2_ssh_key.public_key_openssh

  tags = {
    Name        = "${var.environment}-${var.service_name}-keypair"
    Environment = var.environment
    Service     = var.service_name
    CreatedBy   = var.infra_builder
  }
}

# Random password for ec2-user
resource "random_password" "ec2_user_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Store SSH private key in SSM Parameter Store
resource "aws_ssm_parameter" "ssh_private_key" {
  name        = "/${var.environment}/${var.service_name}/ssh/private_key"
  description = "SSH private key for EC2 instances"
  type        = "SecureString"
  value       = tls_private_key.ec2_ssh_key.private_key_pem

  tags = {
    Name        = "${var.environment}-${var.service_name}-ssh-private-key"
    Environment = var.environment
    Service     = var.service_name
    CreatedBy   = var.infra_builder
  }
}

# Store SSH public key in SSM Parameter Store
resource "aws_ssm_parameter" "ssh_public_key" {
  name        = "/${var.environment}/${var.service_name}/ssh/public_key"
  description = "SSH public key for EC2 instances"
  type        = "String"
  value       = tls_private_key.ec2_ssh_key.public_key_openssh

  tags = {
    Name        = "${var.environment}-${var.service_name}-ssh-public-key"
    Environment = var.environment
    Service     = var.service_name
    CreatedBy   = var.infra_builder
  }
}

# Store ec2-user password in SSM Parameter Store
resource "aws_ssm_parameter" "ec2_user_password" {
  name        = "/${var.environment}/${var.service_name}/ec2-user/password"
  description = "Password for ec2-user"
  type        = "SecureString"
  value       = random_password.ec2_user_password.result

  tags = {
    Name        = "${var.environment}-${var.service_name}-ec2-user-password"
    Environment = var.environment
    Service     = var.service_name
    CreatedBy   = var.infra_builder
  }
}

# Local file for SSH private key (for local access)
resource "local_file" "ssh_private_key" {
  content  = tls_private_key.ec2_ssh_key.private_key_pem
  filename = "${path.module}/ssh_keys/${var.environment}-${var.service_name}.pem"

  file_permission = "0600"
}

# Local file for SSH public key
resource "local_file" "ssh_public_key" {
  content  = tls_private_key.ec2_ssh_key.public_key_openssh
  filename = "${path.module}/ssh_keys/${var.environment}-${var.service_name}.pub"

  file_permission = "0644"
}

# Create SSH keys directory
resource "null_resource" "create_ssh_keys_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/ssh_keys"
  }
}

# Update EC2 instance to use CloudInit
resource "aws_instance" "go_mysql_api" {
  ami                         = var.instance_ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet[0].id
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = aws_key_pair.ec2_key_pair.key_name
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  
  vpc_security_group_ids = [
    aws_security_group.main_vpc_sg.id
  ]
  
  root_block_device {
    delete_on_termination = true
    volume_size = 10
    volume_type = "gp3"
  }

  user_data = data.cloudinit_config.ec2_user_data.rendered

  tags = {
    Name = "${var.environment}-${var.service_name}-instance"
    Instance_OS   = var.instance_os
    Environment = var.environment
    Service = var.service_name
    CreatedBy = var.infra_builder
  }
  
  depends_on = [
    aws_security_group.main_vpc_sg, 
    aws_key_pair.ec2_key_pair,
    null_resource.create_ssh_keys_dir
  ]
}

# Outputs
output "ssh_private_key_path" {
  description = "Path to the SSH private key file"
  value       = local_file.ssh_private_key.filename
}

output "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  value       = local_file.ssh_public_key.filename
}

output "ec2_user_password" {
  description = "Password for ec2-user (stored in SSM)"
  value       = "Password stored in SSM Parameter: /${var.environment}/${var.service_name}/ec2-user/password"
  sensitive   = true
}

output "ssh_connection_command" {
  description = "SSH connection command for EC2 instance"
  value       = "ssh -i ${local_file.ssh_private_key.filename} ec2-user@${aws_instance.go_mysql_api.public_ip}"
}
