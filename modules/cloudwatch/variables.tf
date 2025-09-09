# CloudWatch Module Variables

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
}

variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "go-mysql-api"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Log Groups
variable "create_application_log_group" {
  description = "Whether to create application log group"
  type        = bool
  default     = true
}

variable "application_log_group_name" {
  description = "Name of the application log group"
  type        = string
  default     = "/aws/ec2/application"
}

variable "create_system_log_group" {
  description = "Whether to create system log group"
  type        = bool
  default     = true
}

variable "system_log_group_name" {
  description = "Name of the system log group"
  type        = string
  default     = "/aws/ec2/system"
}

variable "create_kubernetes_log_group" {
  description = "Whether to create Kubernetes log group"
  type        = bool
  default     = false
}

variable "kubernetes_log_group_name" {
  description = "Name of the Kubernetes log group"
  type        = string
  default     = "/aws/eks/kubernetes"
}

variable "create_rds_log_group" {
  description = "Whether to create RDS log group"
  type        = bool
  default     = false
}

variable "rds_log_group_name" {
  description = "Name of the RDS log group"
  type        = string
  default     = "/aws/rds/mysql"
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch log retention period."
  }
}

variable "log_group_kms_key_id" {
  description = "KMS key ID for log group encryption"
  type        = string
  default     = null
}

# Dashboard
variable "create_dashboard" {
  description = "Whether to create CloudWatch dashboard"
  type        = bool
  default     = true
}

variable "dashboard_metrics" {
  description = "List of metrics to display on dashboard"
  type = list(list(string))
  default = [
    ["AWS/EC2", "CPUUtilization", "InstanceId", "i-1234567890abcdef0"],
    ["AWS/EC2", "NetworkIn", "InstanceId", "i-1234567890abcdef0"],
    ["AWS/EC2", "NetworkOut", "InstanceId", "i-1234567890abcdef0"]
  ]
}

# Alarms - EC2
variable "create_cpu_alarm" {
  description = "Whether to create CPU utilization alarm"
  type        = bool
  default     = true
}

variable "instance_id" {
  description = "EC2 instance ID for monitoring"
  type        = string
  default     = null
}

variable "cpu_threshold" {
  description = "CPU utilization threshold for alarm"
  type        = number
  default     = 80
}

variable "create_memory_alarm" {
  description = "Whether to create memory utilization alarm"
  type        = bool
  default     = true
}

variable "memory_threshold" {
  description = "Memory utilization threshold for alarm"
  type        = number
  default     = 80
}

variable "create_disk_alarm" {
  description = "Whether to create disk space alarm"
  type        = bool
  default     = true
}

variable "disk_threshold" {
  description = "Disk space threshold for alarm (percentage)"
  type        = number
  default     = 20
}

variable "disk_device" {
  description = "Disk device for monitoring"
  type        = string
  default     = "/dev/xvda1"
}

variable "disk_fstype" {
  description = "File system type for monitoring"
  type        = string
  default     = "ext4"
}

# Alarms - RDS
variable "create_rds_cpu_alarm" {
  description = "Whether to create RDS CPU alarm"
  type        = bool
  default     = false
}

variable "rds_instance_id" {
  description = "RDS instance ID for monitoring"
  type        = string
  default     = null
}

variable "rds_cpu_threshold" {
  description = "RDS CPU utilization threshold for alarm"
  type        = number
  default     = 80
}

variable "create_rds_connections_alarm" {
  description = "Whether to create RDS connections alarm"
  type        = bool
  default     = false
}

variable "rds_connections_threshold" {
  description = "RDS connections threshold for alarm"
  type        = number
  default     = 100
}

# Alarm Actions
variable "alarm_actions" {
  description = "List of ARNs to notify when alarm is triggered"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "List of ARNs to notify when alarm is OK"
  type        = list(string)
  default     = []
}

# Metric Filters
variable "create_error_filter" {
  description = "Whether to create error log metric filter"
  type        = bool
  default     = true
}

variable "create_warning_filter" {
  description = "Whether to create warning log metric filter"
  type        = bool
  default     = true
}

# SNS
variable "create_sns_topic" {
  description = "Whether to create SNS topic for alerts"
  type        = bool
  default     = false
}

variable "email_endpoint" {
  description = "Email endpoint for SNS subscription"
  type        = string
  default     = null
}

# CloudWatch Insights
variable "create_insights_queries" {
  description = "Whether to create CloudWatch Insights queries"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
