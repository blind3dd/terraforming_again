# CloudWatch Module Outputs

# Log Group Outputs
output "application_log_group_name" {
  description = "Name of the application log group"
  value       = var.create_application_log_group ? aws_cloudwatch_log_group.application[0].name : null
}

output "application_log_group_arn" {
  description = "ARN of the application log group"
  value       = var.create_application_log_group ? aws_cloudwatch_log_group.application[0].arn : null
}

output "system_log_group_name" {
  description = "Name of the system log group"
  value       = var.create_system_log_group ? aws_cloudwatch_log_group.system[0].name : null
}

output "system_log_group_arn" {
  description = "ARN of the system log group"
  value       = var.create_system_log_group ? aws_cloudwatch_log_group.system[0].arn : null
}

output "kubernetes_log_group_name" {
  description = "Name of the Kubernetes log group"
  value       = var.create_kubernetes_log_group ? aws_cloudwatch_log_group.kubernetes[0].name : null
}

output "kubernetes_log_group_arn" {
  description = "ARN of the Kubernetes log group"
  value       = var.create_kubernetes_log_group ? aws_cloudwatch_log_group.kubernetes[0].arn : null
}

output "rds_log_group_name" {
  description = "Name of the RDS log group"
  value       = var.create_rds_log_group ? aws_cloudwatch_log_group.rds[0].name : null
}

output "rds_log_group_arn" {
  description = "ARN of the RDS log group"
  value       = var.create_rds_log_group ? aws_cloudwatch_log_group.rds[0].arn : null
}

# Dashboard Outputs
output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = var.create_dashboard ? "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main[0].dashboard_name}" : null
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = var.create_dashboard ? aws_cloudwatch_dashboard.main[0].dashboard_name : null
}

# Alarm Outputs
output "cpu_alarm_arn" {
  description = "ARN of the CPU utilization alarm"
  value       = var.create_cpu_alarm ? aws_cloudwatch_metric_alarm.high_cpu[0].arn : null
}

output "memory_alarm_arn" {
  description = "ARN of the memory utilization alarm"
  value       = var.create_memory_alarm ? aws_cloudwatch_metric_alarm.high_memory[0].arn : null
}

output "disk_alarm_arn" {
  description = "ARN of the disk space alarm"
  value       = var.create_disk_alarm ? aws_cloudwatch_metric_alarm.disk_space[0].arn : null
}

output "rds_cpu_alarm_arn" {
  description = "ARN of the RDS CPU alarm"
  value       = var.create_rds_cpu_alarm ? aws_cloudwatch_metric_alarm.rds_cpu[0].arn : null
}

output "rds_connections_alarm_arn" {
  description = "ARN of the RDS connections alarm"
  value       = var.create_rds_connections_alarm ? aws_cloudwatch_metric_alarm.rds_connections[0].arn : null
}

# Metric Filter Outputs
output "error_filter_name" {
  description = "Name of the error log metric filter"
  value       = var.create_error_filter ? aws_cloudwatch_log_metric_filter.error_logs[0].name : null
}

output "warning_filter_name" {
  description = "Name of the warning log metric filter"
  value       = var.create_warning_filter ? aws_cloudwatch_log_metric_filter.warning_logs[0].name : null
}

# SNS Outputs
output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = var.create_sns_topic ? aws_sns_topic.alerts[0].arn : null
}

output "sns_topic_name" {
  description = "Name of the SNS topic for alerts"
  value       = var.create_sns_topic ? aws_sns_topic.alerts[0].name : null
}

# CloudWatch Insights Outputs
output "error_analysis_query_id" {
  description = "ID of the error analysis CloudWatch Insights query"
  value       = var.create_insights_queries ? aws_cloudwatch_query_definition.error_analysis[0].query_definition_id : null
}

output "performance_analysis_query_id" {
  description = "ID of the performance analysis CloudWatch Insights query"
  value       = var.create_insights_queries ? aws_cloudwatch_query_definition.performance_analysis[0].query_definition_id : null
}

# All Alarm ARNs
output "all_alarm_arns" {
  description = "List of all alarm ARNs"
  value = compact([
    var.create_cpu_alarm ? aws_cloudwatch_metric_alarm.high_cpu[0].arn : "",
    var.create_memory_alarm ? aws_cloudwatch_metric_alarm.high_memory[0].arn : "",
    var.create_disk_alarm ? aws_cloudwatch_metric_alarm.disk_space[0].arn : "",
    var.create_rds_cpu_alarm ? aws_cloudwatch_metric_alarm.rds_cpu[0].arn : "",
    var.create_rds_connections_alarm ? aws_cloudwatch_metric_alarm.rds_connections[0].arn : ""
  ])
}

# All Log Group ARNs
output "all_log_group_arns" {
  description = "List of all log group ARNs"
  value = compact([
    var.create_application_log_group ? aws_cloudwatch_log_group.application[0].arn : "",
    var.create_system_log_group ? aws_cloudwatch_log_group.system[0].arn : "",
    var.create_kubernetes_log_group ? aws_cloudwatch_log_group.kubernetes[0].arn : "",
    var.create_rds_log_group ? aws_cloudwatch_log_group.rds[0].arn : ""
  ])
}
