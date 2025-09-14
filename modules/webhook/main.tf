# Webhook Module - API Compatibility Webhook Service
# This module deploys the API compatibility webhook service

# Kubernetes Namespace for webhook
resource "kubernetes_namespace" "webhook" {
  count = var.create_namespace ? 1 : 0
  
  metadata {
    name = var.namespace_name
    labels = merge(var.common_labels, {
      app = "api-compatibility-webhook"
    })
  }
}

# Kubernetes Secret for webhook configuration
resource "kubernetes_secret" "webhook_config" {
  metadata {
    name      = "webhook-config"
    namespace = var.create_namespace ? kubernetes_namespace.webhook[0].metadata[0].name : var.namespace_name
  }

  data = {
    "encryption-key" = var.encryption_key
    "github-webhook-secret" = var.github_webhook_secret
    "working-dir" = var.working_dir
  }

  type = "Opaque"
}

# Kubernetes ConfigMap for webhook configuration
resource "kubernetes_config_map" "webhook_config" {
  metadata {
    name      = "webhook-config"
    namespace = var.create_namespace ? kubernetes_namespace.webhook[0].metadata[0].name : var.namespace_name
  }

  data = {
    "PORT" = var.port
    "WORKING_DIR" = var.working_dir
    "ENCRYPTION_KEY" = var.encryption_key
    "GITHUB_WEBHOOK_SECRET" = var.github_webhook_secret
    "LOG_LEVEL" = var.log_level
    "ENVIRONMENT" = var.environment
  }
}

# Kubernetes Deployment for webhook service
resource "kubernetes_deployment" "webhook" {
  metadata {
    name      = "api-compatibility-webhook"
    namespace = var.create_namespace ? kubernetes_namespace.webhook[0].metadata[0].name : var.namespace_name
    labels = merge(var.common_labels, {
      app = "api-compatibility-webhook"
    })
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "api-compatibility-webhook"
      }
    }

    template {
      metadata {
        labels = merge(var.common_labels, {
          app = "api-compatibility-webhook"
        })
      }

      spec {
        service_account_name = kubernetes_service_account.webhook.metadata[0].name

        container {
          name  = "webhook"
          image = var.webhook_image
          port {
            container_port = var.port
            name          = "http"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.webhook_config.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.webhook_config.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = var.port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/ready"
              port = var.port
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }

          volume_mount {
            name       = "workspace"
            mount_path = var.working_dir
          }
        }

        volume {
          name = "workspace"
          empty_dir {}
        }
      }
    }
  }
}

# Kubernetes Service for webhook
resource "kubernetes_service" "webhook" {
  metadata {
    name      = "api-compatibility-webhook"
    namespace = var.create_namespace ? kubernetes_namespace.webhook[0].metadata[0].name : var.namespace_name
    labels = merge(var.common_labels, {
      app = "api-compatibility-webhook"
    })
  }

  spec {
    selector = {
      app = "api-compatibility-webhook"
    }

    port {
      port        = var.port
      target_port = var.port
      name        = "http"
    }

    type = var.service_type
  }
}

# Kubernetes ServiceAccount for webhook
resource "kubernetes_service_account" "webhook" {
  metadata {
    name      = "api-compatibility-webhook"
    namespace = var.create_namespace ? kubernetes_namespace.webhook[0].metadata[0].name : var.namespace_name
    labels = merge(var.common_labels, {
      app = "api-compatibility-webhook"
    })
  }
}

# Kubernetes ClusterRole for webhook
resource "kubernetes_cluster_role" "webhook" {
  metadata {
    name = "api-compatibility-webhook"
    labels = merge(var.common_labels, {
      app = "api-compatibility-webhook"
    })
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }
}

# Kubernetes ClusterRoleBinding for webhook
resource "kubernetes_cluster_role_binding" "webhook" {
  metadata {
    name = "api-compatibility-webhook"
    labels = merge(var.common_labels, {
      app = "api-compatibility-webhook"
    })
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.webhook.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.webhook.metadata[0].name
    namespace = var.create_namespace ? kubernetes_namespace.webhook[0].metadata[0].name : var.namespace_name
  }
}

# Kubernetes Ingress for webhook (if enabled)
resource "kubernetes_ingress_v1" "webhook" {
  count = var.create_ingress ? 1 : 0
  
  metadata {
    name      = "api-compatibility-webhook"
    namespace = var.create_namespace ? kubernetes_namespace.webhook[0].metadata[0].name : var.namespace_name
    labels = merge(var.common_labels, {
      app = "api-compatibility-webhook"
    })
    annotations = var.ingress_annotations
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.ingress_host
      http {
        path {
          path      = var.ingress_path
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.webhook.metadata[0].name
              port {
                number = var.port
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.ingress_host]
      secret_name = var.ingress_tls_secret_name
    }
  }
}
