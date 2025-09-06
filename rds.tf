# RDS MySQL Database with VPC Association Authorization
# This file creates a secure RDS instance with proper Route53 integration

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = [
    aws_subnet.private.id,
    aws_subnet.private_2.id
  ]

  tags = {
    Name        = "main-db-subnet-group"
    Environment = var.environment
    Service     = "go-mysql-api"
  }
}

# RDS Parameter Group for enhanced security
resource "aws_db_parameter_group" "main" {
  family = "mysql8.0"
  name   = "main-db-parameter-group"

  # Security parameters
  parameter {
    name  = "require_secure_transport"
    value = "ON"
  }

  parameter {
    name  = "ssl_ca"
    value = "rds-ca-2019-root"
  }

  parameter {
    name  = "ssl_cert"
    value = "rds-ca-2019-root"
  }

  parameter {
    name  = "ssl_key"
    value = "rds-ca-2019-root"
  }

  # Connection security
  parameter {
    name  = "max_connections"
    value = "100"
  }

  parameter {
    name  = "connect_timeout"
    value = "30"
  }

  parameter {
    name  = "wait_timeout"
    value = "28800"
  }

  parameter {
    name  = "interactive_timeout"
    value = "28800"
  }

  # Logging and monitoring
  parameter {
    name  = "general_log"
    value = "1"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name  = "log_queries_not_using_indexes"
    value = "1"
  }

  # Performance and security
  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "innodb_log_file_size"
    value = "268435456"
  }

  parameter {
    name  = "innodb_flush_log_at_trx_commit"
    value = "1"
  }

  tags = {
    Name        = "main-db-parameter-group"
    Environment = var.environment
    Service     = "go-mysql-api"
  }
}

# KMS Key for RDS encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "rds-encryption-key"
    Environment = var.environment
    Service     = "go-mysql-api"
  }
}

# KMS Key Alias
resource "aws_kms_alias" "rds" {
  name          = "alias/rds-encryption-key"
  target_key_id = aws_kms_key.rds.key_id
}

# RDS Option Group for additional security features
resource "aws_db_option_group" "main" {
  name                     = "main-db-option-group"
  option_group_description = "Option group for MySQL security features"
  engine_name              = "mysql"
  major_engine_version     = "8.0"

  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
  }

  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
    option_settings {
      name  = "SERVER_AUDIT_EVENTS"
      value = "CONNECT,QUERY,TABLE"
    }
    option_settings {
      name  = "SERVER_AUDIT_FILE_ROTATIONS"
      value = "10"
    }
    option_settings {
      name  = "SERVER_AUDIT_FILE_ROTATE_SIZE"
      value = "1000000"
    }
  }

  tags = {
    Name        = "main-db-option-group"
    Environment = var.environment
    Service     = "go-mysql-api"
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name_prefix = "rds-mysql-"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.kubernetes_control_plane.id]
    description     = "MySQL from Kubernetes control plane"
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.kubernetes_worker.id]
    description     = "MySQL from Kubernetes workers"
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.jump_host.id]
    description     = "MySQL from jump host"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "rds-mysql-sg"
    Environment = var.environment
    Service     = "go-mysql-api"
  }
}

# RDS Parameter Group for MySQL 8.0
resource "aws_db_parameter_group" "mysql" {
  family = "mysql8.0"
  name   = "mysql8-secure-params"

  parameter {
    name  = "log_bin_trust_function_creators"
    value = "1"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name  = "log_queries_not_using_indexes"
    value = "1"
  }

  tags = {
    Name        = "mysql8-secure-params"
    Environment = var.environment
    Service     = "go-mysql-api"
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "mysql" {
  identifier = "go-mysql-api-db"

  # Engine configuration
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.micro"

  # Parameter group for security
  parameter_group_name = aws_db_parameter_group.main.name

  # Storage configuration
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true
  kms_key_id           = aws_kms_key.rds.arn

  # Database configuration
  db_name  = "goapp_users"
  username = "admin"
  password = var.rds_password

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.main.name
  option_group_name      = aws_db_option_group.main.name

  # Backup configuration
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  copy_tags_to_snapshot  = true
  delete_automated_backups = false

  # Security configuration
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "go-mysql-api-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  publicly_accessible = false
  apply_immediately   = false

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  performance_insights_kms_key_id = aws_kms_key.rds.arn

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn
  enabled_cloudwatch_logs_exports = ["error", "general", "slow-query"]

  # Multi-AZ for high availability
  multi_az = true

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  tags = {
    Name        = "go-mysql-api-db"
    Environment = var.environment
    Service     = "go-mysql-api"
  }
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "rds-enhanced-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "rds-enhanced-monitoring-role"
    Environment = var.environment
    Service     = "go-mysql-api"
  }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Route53 Record for RDS FQDN
resource "aws_route53_record" "mysql_database" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "mysql.${var.domain_name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_db_instance.mysql.endpoint]
}

# VPC Association Authorization for Route53 to resolve RDS FQDNs
# This is the critical piece for RDS FQDN connectivity
resource "aws_route53_zone_association" "rds_vpc_association" {
  zone_id = aws_route53_zone.private.zone_id
  vpc_id  = data.aws_vpc.main.id
}

# Alternative: If you need to associate with multiple VPCs
# resource "aws_route53_zone_association" "rds_vpc_association_2" {
#   zone_id = aws_route53_zone.private.zone_id
#   vpc_id  = aws_vpc.other_vpc.id
# }
