# CloudWatch Module - Monitoring, Logging, and Alarms

# =============================================================================
# CLOUDWATCH LOG GROUPS
# =============================================================================

# Application Log Group
resource "aws_cloudwatch_log_group" "application" {
  count = var.create_application_log_group ? 1 : 0

  name              = var.application_log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_group_kms_key_id

  tags = merge(var.tags, {
    Name        = var.application_log_group_name
    Environment = var.environment
    Service     = var.service_name
    Purpose     = "Application Logs"
  })
}

# System Log Group
resource "aws_cloudwatch_log_group" "system" {
  count = var.create_system_log_group ? 1 : 0

  name              = var.system_log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_group_kms_key_id

  tags = merge(var.tags, {
    Name        = var.system_log_group_name
    Environment = var.environment
    Service     = var.service_name
    Purpose     = "System Logs"
  })
}

# Kubernetes Log Group
resource "aws_cloudwatch_log_group" "kubernetes" {
  count = var.create_kubernetes_log_group ? 1 : 0

  name              = var.kubernetes_log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_group_kms_key_id

  tags = merge(var.tags, {
    Name        = var.kubernetes_log_group_name
    Environment = var.environment
    Service     = var.service_name
    Purpose     = "Kubernetes Logs"
  })
}

# RDS Log Group
resource "aws_cloudwatch_log_group" "rds" {
  count = var.create_rds_log_group ? 1 : 0

  name              = var.rds_log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_group_kms_key_id

  tags = merge(var.tags, {
    Name        = var.rds_log_group_name
    Environment = var.environment
    Service     = var.service_name
    Purpose     = "RDS Logs"
  })
}

# =============================================================================
# CLOUDWATCH DASHBOARDS
# =============================================================================

# Main Application Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  count = var.create_dashboard ? 1 : 0

  dashboard_name = "${var.environment}-${var.service_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = var.dashboard_metrics
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "${var.environment} - ${var.service_name} Metrics"
          period  = 300
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-dashboard"
    Environment = var.environment
    Service     = var.service_name
    Purpose     = "Monitoring Dashboard"
  })
}

# =============================================================================
# CLOUDWATCH ALARMS
# =============================================================================

# High CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.create_cpu_alarm ? 1 : 0

  alarm_name          = "${var.environment}-${var.service_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-high-cpu"
    Environment = var.environment
    Service     = var.service_name
    Purpose     = "CPU Monitoring"
  })
}

# High Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  count = var.create_memory_alarm ? 1 : 0

  alarm_name          = "${var.environment}-${var.service_name}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = var.memory_threshold
  alarm_description   = "This metric monitors memory utilization"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-high-memory"
    Environment = var.environment
    Service     = var.service_name
    Purpose     = "Memory Monitoring"
  })
}

# Disk Space Alarm
resource "aws_cloudwatch_metric_alarm" "disk_space" {
  count = var.create_disk_alarm ? 1 : 0

  alarm_name          = "${var.environment}-${var.service_name}-disk-space"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "disk_free_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = var.disk_threshold
  alarm_description   = "This metric monitors disk space"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    InstanceId = var.instance_id
    device     = var.disk_device
    fstype     = var.disk_fstype
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-disk-space"
    Environment = var.environment
    Service     = var.service_name
    Purpose     = "Disk Monitoring"
  })
}

# RDS CPU Alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  count = var.create_rds_cpu_alarm ? 1 : 0

  alarm_name          = "${var.environment}-${var.service_name}-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.rds_cpu_threshold
  alarm_description   = "This metric monitors RDS cpu utilization"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-rds-cpu"
    Environment = var.environment
    Service     = var.service_name
    Purpose     = "RDS CPU Monitoring"
  })
}

# RDS Connection Count Alarm
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  count = var.create_rds_connections_alarm ? 1 : 0

  alarm_name          = "${var.environment}-${var.service_name}-rds-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.rds_connections_threshold
  alarm_description   = "This metric monitors RDS connection count"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-rds-connections"
    Environment = var.environment
    Service     = var.service_name
    Purpose     = "RDS Connections Monitoring"
  })
}

# =============================================================================
# CLOUDWATCH METRIC FILTERS
# =============================================================================

# Error Log Filter
resource "aws_cloudwatch_log_metric_filter" "error_logs" {
  count = var.create_error_filter ? 1 : 0

  name           = "${var.environment}-${var.service_name}-error-logs"
  log_group_name = var.application_log_group_name
  pattern        = "[timestamp, request_id, level=\"ERROR\", ...]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "${var.environment}/${var.service_name}"
    value     = "1"
  }
}

# Warning Log Filter
resource "aws_cloudwatch_log_metric_filter" "warning_logs" {
  count = var.create_warning_filter ? 1 : 0

  name           = "${var.environment}-${var.service_name}-warning-logs"
  log_group_name = var.application_log_group_name
  pattern        = "[timestamp, request_id, level=\"WARN\", ...]"

  metric_transformation {
    name      = "WarningCount"
    namespace = "${var.environment}/${var.service_name}"
    value     = "1"
  }
}

# =============================================================================
# SNS TOPICS FOR ALERTS
# =============================================================================

# SNS Topic for Alarms
resource "aws_sns_topic" "alerts" {
  count = var.create_sns_topic ? 1 : 0

  name = "${var.environment}-${var.service_name}-alerts"

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-alerts"
    Environment = var.environment
    Service     = var.service_name
    Purpose     = "Alert Notifications"
  })
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "email" {
  count = var.create_sns_topic && var.email_endpoint != null ? 1 : 0

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.email_endpoint
}

# =============================================================================
# CLOUDWATCH INSIGHTS QUERIES
# =============================================================================

# CloudWatch Insights Query for Error Analysis
resource "aws_cloudwatch_query_definition" "error_analysis" {
  count = var.create_insights_queries ? 1 : 0

  name = "${var.environment}-${var.service_name}-error-analysis"

  log_group_names = [var.application_log_group_name]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
EOF
}

# CloudWatch Insights Query for Performance Analysis
resource "aws_cloudwatch_query_definition" "performance_analysis" {
  count = var.create_insights_queries ? 1 : 0

  name = "${var.environment}-${var.service_name}-performance-analysis"

  log_group_names = [var.application_log_group_name]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /duration/
| sort @timestamp desc
| limit 100
EOF
}
