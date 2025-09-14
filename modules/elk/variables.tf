# ELK Stack Module Variables

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "namespace_name" {
  description = "Kubernetes namespace for ELK stack"
  type        = string
  default     = "elk"
}

# Elasticsearch Configuration
variable "create_elasticsearch" {
  description = "Whether to create Elasticsearch cluster"
  type        = bool
  default     = true
}

variable "elasticsearch_image" {
  description = "Elasticsearch Docker image"
  type        = string
  default     = "docker.elastic.co/elasticsearch/elasticsearch:8.11.0"
}

variable "elasticsearch_replicas" {
  description = "Number of Elasticsearch replicas"
  type        = number
  default     = 1
}

variable "elasticsearch_cluster_name" {
  description = "Elasticsearch cluster name"
  type        = string
  default     = "elk-cluster"
}

variable "elasticsearch_heap_size" {
  description = "Elasticsearch heap size"
  type        = string
  default     = "1g"
}

variable "elasticsearch_cpu_request" {
  description = "CPU request for Elasticsearch"
  type        = string
  default     = "500m"
}

variable "elasticsearch_memory_request" {
  description = "Memory request for Elasticsearch"
  type        = string
  default     = "2Gi"
}

variable "elasticsearch_cpu_limit" {
  description = "CPU limit for Elasticsearch"
  type        = string
  default     = "2"
}

variable "elasticsearch_memory_limit" {
  description = "Memory limit for Elasticsearch"
  type        = string
  default     = "4Gi"
}

variable "elasticsearch_storage_size" {
  description = "Storage size for Elasticsearch data"
  type        = string
  default     = "10Gi"
}

# Logstash Configuration
variable "create_logstash" {
  description = "Whether to create Logstash"
  type        = bool
  default     = true
}

variable "logstash_image" {
  description = "Logstash Docker image"
  type        = string
  default     = "docker.elastic.co/logstash/logstash:8.11.0"
}

variable "logstash_replicas" {
  description = "Number of Logstash replicas"
  type        = number
  default     = 1
}

variable "logstash_heap_size" {
  description = "Logstash heap size"
  type        = string
  default     = "512m"
}

variable "logstash_cpu_request" {
  description = "CPU request for Logstash"
  type        = string
  default     = "200m"
}

variable "logstash_memory_request" {
  description = "Memory request for Logstash"
  type        = string
  default     = "1Gi"
}

variable "logstash_cpu_limit" {
  description = "CPU limit for Logstash"
  type        = string
  default     = "1"
}

variable "logstash_memory_limit" {
  description = "Memory limit for Logstash"
  type        = string
  default     = "2Gi"
}

# Kibana Configuration
variable "create_kibana" {
  description = "Whether to create Kibana"
  type        = bool
  default     = true
}

variable "kibana_image" {
  description = "Kibana Docker image"
  type        = string
  default     = "docker.elastic.co/kibana/kibana:8.11.0"
}

variable "kibana_replicas" {
  description = "Number of Kibana replicas"
  type        = number
  default     = 1
}

variable "kibana_cpu_request" {
  description = "CPU request for Kibana"
  type        = string
  default     = "200m"
}

variable "kibana_memory_request" {
  description = "Memory request for Kibana"
  type        = string
  default     = "1Gi"
}

variable "kibana_cpu_limit" {
  description = "CPU limit for Kibana"
  type        = string
  default     = "1"
}

variable "kibana_memory_limit" {
  description = "Memory limit for Kibana"
  type        = string
  default     = "2Gi"
}

# Filebeat Configuration
variable "create_filebeat" {
  description = "Whether to create Filebeat"
  type        = bool
  default     = false
}

variable "filebeat_image" {
  description = "Filebeat Docker image"
  type        = string
  default     = "docker.elastic.co/beats/filebeat:8.11.0"
}

variable "filebeat_cpu_request" {
  description = "CPU request for Filebeat"
  type        = string
  default     = "100m"
}

variable "filebeat_memory_request" {
  description = "Memory request for Filebeat"
  type        = string
  default     = "256Mi"
}

variable "filebeat_cpu_limit" {
  description = "CPU limit for Filebeat"
  type        = string
  default     = "200m"
}

variable "filebeat_memory_limit" {
  description = "Memory limit for Filebeat"
  type        = string
  default     = "512Mi"
}
