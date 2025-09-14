# Outputs for Kubernetes IAM Authentication Module

output "oidc_provider_arn" {
  description = "ARN of the OIDC identity provider"
  value       = aws_iam_openid_connect_provider.kubernetes.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC identity provider"
  value       = aws_iam_openid_connect_provider.kubernetes.url
}

output "cluster_admin_role_arn" {
  description = "ARN of the cluster admin IAM role"
  value       = aws_iam_role.kubernetes_cluster_admin.arn
}

output "developer_role_arn" {
  description = "ARN of the developer IAM role"
  value       = aws_iam_role.kubernetes_developer.arn
}

output "readonly_role_arn" {
  description = "ARN of the read-only IAM role"
  value       = aws_iam_role.kubernetes_readonly.arn
}

output "service_account_role_arn" {
  description = "ARN of the service account IAM role"
  value       = aws_iam_role.kubernetes_service_account.arn
}

output "aws_auth_configmap_name" {
  description = "Name of the aws-auth ConfigMap"
  value       = kubernetes_config_map.aws_auth.metadata[0].name
}

output "service_account_name" {
  description = "Name of the Kubernetes service account"
  value       = kubernetes_service_account.aws_iam_authenticator.metadata[0].name
}

output "service_account_namespace" {
  description = "Namespace of the Kubernetes service account"
  value       = kubernetes_service_account.aws_iam_authenticator.metadata[0].namespace
}

output "cluster_roles" {
  description = "Map of cluster roles created"
  value = {
    cluster_admin = kubernetes_cluster_role.cluster_admin.metadata[0].name
    developer     = kubernetes_cluster_role.developer.metadata[0].name
    readonly      = kubernetes_cluster_role.readonly.metadata[0].name
  }
}

output "cluster_role_bindings" {
  description = "Map of cluster role bindings created"
  value = {
    cluster_admin = kubernetes_cluster_role_binding.cluster_admin.metadata[0].name
    developer     = kubernetes_cluster_role_binding.developer.metadata[0].name
    readonly      = kubernetes_cluster_role_binding.readonly.metadata[0].name
  }
}
