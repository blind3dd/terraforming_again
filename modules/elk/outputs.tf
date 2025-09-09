# ELK Stack Module Outputs

output "elasticsearch_service_name" {
  description = "Name of the Elasticsearch service"
  value       = var.create_elasticsearch ? kubernetes_service.elasticsearch[0].metadata[0].name : null
}

output "elasticsearch_service_endpoint" {
  description = "Elasticsearch service endpoint"
  value       = var.create_elasticsearch ? "http://${kubernetes_service.elasticsearch[0].metadata[0].name}.${var.namespace_name}.svc.cluster.local:9200" : null
}

output "logstash_service_name" {
  description = "Name of the Logstash service"
  value       = var.create_logstash ? kubernetes_service.logstash[0].metadata[0].name : null
}

output "logstash_service_endpoint" {
  description = "Logstash service endpoint"
  value       = var.create_logstash ? "${kubernetes_service.logstash[0].metadata[0].name}.${var.namespace_name}.svc.cluster.local:5044" : null
}

output "kibana_service_name" {
  description = "Name of the Kibana service"
  value       = var.create_kibana ? kubernetes_service.kibana[0].metadata[0].name : null
}

output "kibana_service_endpoint" {
  description = "Kibana service endpoint"
  value       = var.create_kibana ? "http://${kubernetes_service.kibana[0].metadata[0].name}.${var.namespace_name}.svc.cluster.local:5601" : null
}

output "elk_stack_info" {
  description = "Complete information about the ELK stack"
  value = {
    namespace = var.namespace_name
    elasticsearch = var.create_elasticsearch ? {
      service_name = kubernetes_service.elasticsearch[0].metadata[0].name
      endpoint     = "http://${kubernetes_service.elasticsearch[0].metadata[0].name}.${var.namespace_name}.svc.cluster.local:9200"
      statefulset  = kubernetes_stateful_set.elasticsearch[0].metadata[0].name
    } : null
    logstash = var.create_logstash ? {
      service_name = kubernetes_service.logstash[0].metadata[0].name
      endpoint     = "${kubernetes_service.logstash[0].metadata[0].name}.${var.namespace_name}.svc.cluster.local:5044"
      deployment   = kubernetes_deployment.logstash[0].metadata[0].name
    } : null
    kibana = var.create_kibana ? {
      service_name = kubernetes_service.kibana[0].metadata[0].name
      endpoint     = "http://${kubernetes_service.kibana[0].metadata[0].name}.${var.namespace_name}.svc.cluster.local:5601"
      deployment   = kubernetes_deployment.kibana[0].metadata[0].name
    } : null
    filebeat = var.create_filebeat ? {
      daemonset = kubernetes_daemon_set.filebeat[0].metadata[0].name
    } : null
  }
}
