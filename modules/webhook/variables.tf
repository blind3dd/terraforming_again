# Webhook Module Variables

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "namespace_name" {
  description = "Name of the Kubernetes namespace"
  type        = string
  default     = "webhook"
}

variable "create_namespace" {
  description = "Whether to create the namespace"
  type        = bool
  default     = true
}

variable "webhook_image" {
  description = "Docker image for the webhook service"
  type        = string
  default     = "api-compatibility-webhook:latest"
}

variable "replicas" {
  description = "Number of webhook replicas"
  type        = number
  default     = 1
}

variable "port" {
  description = "Port for the webhook service"
  type        = number
  default     = 8080
}

variable "service_type" {
  description = "Type of Kubernetes service"
  type        = string
  default     = "ClusterIP"
}

variable "cpu_request" {
  description = "CPU request for webhook containers"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request for webhook containers"
  type        = string
  default     = "128Mi"
}

variable "cpu_limit" {
  description = "CPU limit for webhook containers"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit for webhook containers"
  type        = string
  default     = "512Mi"
}

variable "encryption_key" {
  description = "Encryption key for webhook secrets"
  type        = string
  default     = "default-webhook-encryption-key-change-in-production"
  sensitive   = true
}

variable "github_webhook_secret" {
  description = "GitHub webhook secret"
  type        = string
  default     = "default-github-webhook-secret"
  sensitive   = true
}

variable "working_dir" {
  description = "Working directory for webhook operations"
  type        = string
  default     = "/tmp/webhook-workspace"
}

variable "log_level" {
  description = "Log level for webhook service"
  type        = string
  default     = "info"
}

variable "create_ingress" {
  description = "Whether to create ingress for webhook"
  type        = bool
  default     = false
}

variable "ingress_host" {
  description = "Host for webhook ingress"
  type        = string
  default     = "webhook.internal.coderedalarmtech.com"
}

variable "ingress_path" {
  description = "Path for webhook ingress"
  type        = string
  default     = "/"
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "ingress_annotations" {
  description = "Annotations for webhook ingress"
  type        = map(string)
  default = {
    "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    "nginx.ingress.kubernetes.io/ssl-redirect"   = "true"
  }
}

variable "ingress_tls_secret_name" {
  description = "TLS secret name for ingress"
  type        = string
  default     = "webhook-tls"
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Service     = "webhook"
    ManagedBy   = "Terraform"
  }
}
