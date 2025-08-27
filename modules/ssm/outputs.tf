# AWS SSM Parameter Store - Outputs
# This file defines outputs from the SOPS encrypted file SSM module

output "database_password_parameter" {
  description = "Database password SSM parameter details"
  value = {
    name        = aws_ssm_parameter.database_password.name
    arn         = aws_ssm_parameter.database_password.arn
    version     = aws_ssm_parameter.database_password.version
    description = aws_ssm_parameter.database_password.description
    type        = aws_ssm_parameter.database_password.type
  }
}

output "database_password_parameter_name" {
  description = "Name of the database password parameter"
  value       = aws_ssm_parameter.database_password.name
}

output "database_password_parameter_arn" {
  description = "ARN of the database password parameter"
  value       = aws_ssm_parameter.database_password.arn
}

output "database_host_parameter_name" {
  description = "Name of the database host parameter"
  value       = aws_ssm_parameter.database_host.name
}

output "database_port_parameter_name" {
  description = "Name of the database port parameter"
  value       = aws_ssm_parameter.database_port.name
}

output "database_name_parameter_name" {
  description = "Name of the database name parameter"
  value       = aws_ssm_parameter.database_name.name
}

output "database_username_parameter_name" {
  description = "Name of the database username parameter"
  value       = aws_ssm_parameter.database_username.name
}

output "all_database_parameters" {
  description = "All database connection parameters"
  value = {
    password = aws_ssm_parameter.database_password.name
    host     = aws_ssm_parameter.database_host.name
    port     = aws_ssm_parameter.database_port.name
    name     = aws_ssm_parameter.database_name.name
    username = aws_ssm_parameter.database_username.name
  }
}
