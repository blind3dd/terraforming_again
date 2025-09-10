# Webhook Module Outputs

output "namespace_name" {
  description = "Name of the webhook namespace"
  value       = var.create_namespace ? kubernetes_namespace.webhook[0].metadata[0].name : var.namespace_name
}

output "deployment_name" {
  description = "Name of the webhook deployment"
  value       = kubernetes_deployment.webhook.metadata[0].name
}

output "service_name" {
  description = "Name of the webhook service"
  value       = kubernetes_service.webhook.metadata[0].name
}

output "service_endpoint" {
  description = "Endpoint of the webhook service"
  value       = "${kubernetes_service.webhook.metadata[0].name}.${var.create_namespace ? kubernetes_namespace.webhook[0].metadata[0].name : var.namespace_name}.svc.cluster.local:${var.port}"
}

output "ingress_host" {
  description = "Host of the webhook ingress"
  value       = var.create_ingress ? kubernetes_ingress_v1.webhook[0].spec[0].rule[0].host : null
}

output "ingress_url" {
  description = "URL of the webhook ingress"
  value       = var.create_ingress ? "https://${kubernetes_ingress_v1.webhook[0].spec[0].rule[0].host}${var.ingress_path}" : null
}

output "webhook_endpoints" {
  description = "Available webhook endpoints"
  value = {
    health = "/health"
    ready  = "/ready"
    webhook = "/webhook"
    api_compatibility = "/api/compatibility/check"
  }
}
