# Self-Managed Kubernetes Module Variables

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
}

variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "go-mysql-api"
}

variable "vpc_id" {
  description = "VPC ID where Kubernetes cluster will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "key_pair_name" {
  description = "Name of the key pair for instances"
  type        = string
}

variable "domain_name" {
  description = "Domain name for private FQDN resolution"
  type        = string
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# etcd Configuration
variable "etcd_ami" {
  description = "AMI ID for etcd instances (use Bottlerocket AMI for best results)"
  type        = string
  default     = null
}

variable "etcd_instance_type" {
  description = "Instance type for etcd instances"
  type        = string
  default     = "t3.small"
}

variable "etcd_volume_size" {
  description = "Volume size for etcd instances"
  type        = number
  default     = 20
}

variable "etcd_volume_type" {
  description = "Volume type for etcd instances"
  type        = string
  default     = "gp3"
}

# Control Plane Configuration
variable "control_plane_ami" {
  description = "AMI ID for control plane instances (use Bottlerocket AMI for best results)"
  type        = string
  default     = null
}

variable "control_plane_instance_type" {
  description = "Instance type for control plane instances"
  type        = string
  default     = "t3.medium"
}

variable "control_plane_volume_size" {
  description = "Volume size for control plane instances"
  type        = number
  default     = 20
}

variable "control_plane_volume_type" {
  description = "Volume type for control plane instances"
  type        = string
  default     = "gp3"
}

# Worker Configuration
variable "worker_ami" {
  description = "AMI ID for worker instances (use Bottlerocket AMI for best results)"
  type        = string
  default     = null
}

variable "worker_instance_type" {
  description = "Instance type for worker instances"
  type        = string
  default     = "t3.medium"
}

variable "worker_volume_size" {
  description = "Volume size for worker instances"
  type        = number
  default     = 20
}

variable "worker_volume_type" {
  description = "Volume type for worker instances"
  type        = string
  default     = "gp3"
}

# Kubernetes Configuration
variable "pod_cidr" {
  description = "CIDR block for Kubernetes pods"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "CIDR block for Kubernetes services"
  type        = string
  default     = "10.96.0.0/12"
}

variable "use_bottlerocket" {
  description = "Whether to use Bottlerocket AMIs (automatically selects latest Bottlerocket AMI)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
