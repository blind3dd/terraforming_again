# Database Module Outputs

output "endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "username" {
  description = "Database username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "password_parameter_name" {
  description = "SSM parameter name for database password"
  value       = aws_ssm_parameter.db_password.name
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}

output "parameter_group_name" {
  description = "Name of the DB parameter group"
  value       = aws_db_parameter_group.main.name
}

output "rds_dns_name" {
  description = "RDS DNS name"
  value       = aws_db_instance.main.endpoint
}



