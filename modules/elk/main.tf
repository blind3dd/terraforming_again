# ELK Stack Module
# This module creates an ELK (Elasticsearch, Logstash, Kibana) stack for logging

# =============================================================================
# ELASTICSEARCH CLUSTER
# =============================================================================

# Elasticsearch Service
resource "kubernetes_service" "elasticsearch" {
  count = var.create_elasticsearch ? 1 : 0
  
  metadata {
    name      = "elasticsearch"
    namespace = var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "elasticsearch"
        "app.kubernetes.io/component" = "search"
      }
    )
  }

  spec {
    selector = {
      "app.kubernetes.io/name"     = "elasticsearch"
      "app.kubernetes.io/component" = "search"
    }

    port {
      name        = "http"
      port        = 9200
      target_port = 9200
    }

    port {
      name        = "transport"
      port        = 9300
      target_port = 9300
    }

    type = "ClusterIP"
  }
}

# Elasticsearch StatefulSet
resource "kubernetes_stateful_set" "elasticsearch" {
  count = var.create_elasticsearch ? 1 : 0
  
  metadata {
    name      = "elasticsearch"
    namespace = var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "elasticsearch"
        "app.kubernetes.io/component" = "search"
      }
    )
  }

  spec {
    service_name = kubernetes_service.elasticsearch[0].metadata[0].name
    replicas     = var.elasticsearch_replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "elasticsearch"
        "app.kubernetes.io/component" = "search"
      }
    }

    template {
      metadata {
        labels = merge(
          var.common_labels,
          {
            "app.kubernetes.io/name"     = "elasticsearch"
            "app.kubernetes.io/component" = "search"
          }
        )
      }

      spec {
        container {
          name  = "elasticsearch"
          image = var.elasticsearch_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 9200
            name          = "http"
          }

          port {
            container_port = 9300
            name          = "transport"
          }

          env {
            name  = "node.name"
            value = "$(POD_NAME)"
          }

          env {
            name  = "cluster.name"
            value = var.elasticsearch_cluster_name
          }

          env {
            name  = "discovery.seed_hosts"
            value = "elasticsearch-0.elasticsearch.${var.namespace_name}.svc.cluster.local"
          }

          env {
            name  = "cluster.initial_master_nodes"
            value = "elasticsearch-0"
          }

          env {
            name  = "ES_JAVA_OPTS"
            value = "-Xms${var.elasticsearch_heap_size} -Xmx${var.elasticsearch_heap_size}"
          }

          env {
            name  = "bootstrap.memory_lock"
            value = "true"
          }

          env {
            name = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }

          resources {
            requests = {
              cpu    = var.elasticsearch_cpu_request
              memory = var.elasticsearch_memory_request
            }
            limits = {
              cpu    = var.elasticsearch_cpu_limit
              memory = var.elasticsearch_memory_limit
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/usr/share/elasticsearch/data"
          }

          volume_mount {
            name       = "config"
            mount_path = "/usr/share/elasticsearch/config/elasticsearch.yml"
            sub_path   = "elasticsearch.yml"
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.elasticsearch_config[0].metadata[0].name
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = var.elasticsearch_storage_size
          }
        }
      }
    }
  }
}

# Elasticsearch ConfigMap
resource "kubernetes_config_map" "elasticsearch_config" {
  count = var.create_elasticsearch ? 1 : 0
  
  metadata {
    name      = "elasticsearch-config"
    namespace = var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "elasticsearch"
        "app.kubernetes.io/component" = "config"
      }
    )
  }

  data = {
    "elasticsearch.yml" = templatefile("${path.module}/templates/elasticsearch.yml.tpl", {
      cluster_name = var.elasticsearch_cluster_name
      node_name    = "$(POD_NAME)"
    })
  }
}

# =============================================================================
# LOGSTASH
# =============================================================================

# Logstash Service
resource "kubernetes_service" "logstash" {
  count = var.create_logstash ? 1 : 0
  
  metadata {
    name      = "logstash"
    namespace = var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "logstash"
        "app.kubernetes.io/component" = "log-processor"
      }
    )
  }

  spec {
    selector = {
      "app.kubernetes.io/name"     = "logstash"
      "app.kubernetes.io/component" = "log-processor"
    }

    port {
      name        = "beats"
      port        = 5044
      target_port = 5044
    }

    port {
      name        = "http"
      port        = 9600
      target_port = 9600
    }

    type = "ClusterIP"
  }
}

# Logstash Deployment
resource "kubernetes_deployment" "logstash" {
  count = var.create_logstash ? 1 : 0
  
  metadata {
    name      = "logstash"
    namespace = var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "logstash"
        "app.kubernetes.io/component" = "log-processor"
      }
    )
  }

  spec {
    replicas = var.logstash_replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "logstash"
        "app.kubernetes.io/component" = "log-processor"
      }
    }

    template {
      metadata {
        labels = merge(
          var.common_labels,
          {
            "app.kubernetes.io/name"     = "logstash"
            "app.kubernetes.io/component" = "log-processor"
          }
        )
      }

      spec {
        container {
          name  = "logstash"
          image = var.logstash_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 5044
            name          = "beats"
          }

          port {
            container_port = 9600
            name          = "http"
          }

          env {
            name  = "LS_JAVA_OPTS"
            value = "-Xms${var.logstash_heap_size} -Xmx${var.logstash_heap_size}"
          }

          resources {
            requests = {
              cpu    = var.logstash_cpu_request
              memory = var.logstash_memory_request
            }
            limits = {
              cpu    = var.logstash_cpu_limit
              memory = var.logstash_memory_limit
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/usr/share/logstash/config/logstash.yml"
            sub_path   = "logstash.yml"
          }

          volume_mount {
            name       = "pipeline"
            mount_path = "/usr/share/logstash/pipeline"
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.logstash_config[0].metadata[0].name
          }
        }

        volume {
          name = "pipeline"
          config_map {
            name = kubernetes_config_map.logstash_pipeline[0].metadata[0].name
          }
        }
      }
    }
  }
}

# Logstash ConfigMap
resource "kubernetes_config_map" "logstash_config" {
  count = var.create_logstash ? 1 : 0
  
  metadata {
    name      = "logstash-config"
    namespace = var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "logstash"
        "app.kubernetes.io/component" = "config"
      }
    )
  }

  data = {
    "logstash.yml" = templatefile("${path.module}/templates/logstash.yml.tpl", {
      elasticsearch_host = "elasticsearch.${var.namespace_name}.svc.cluster.local:9200"
    })
  }
}

# Logstash Pipeline ConfigMap
resource "kubernetes_config_map" "logstash_pipeline" {
  count = var.create_logstash ? 1 : 0
  
  metadata {
    name      = "logstash-pipeline"
    namespace = var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "logstash"
        "app.kubernetes.io/component" = "pipeline"
      }
    )
  }

  data = {
    "main.conf" = templatefile("${path.module}/templates/logstash-pipeline.conf.tpl", {
      elasticsearch_host = "elasticsearch.${var.namespace_name}.svc.cluster.local:9200"
    })
  }
}

# =============================================================================
# KIBANA
# =============================================================================

# Kibana Service
resource "kubernetes_service" "kibana" {
  count = var.create_kibana ? 1 : 0
  
  metadata {
    name      = "kibana"
    namespace = var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "kibana"
        "app.kubernetes.io/component" = "dashboard"
      }
    )
  }

  spec {
    selector = {
      "app.kubernetes.io/name"     = "kibana"
      "app.kubernetes.io/component" = "dashboard"
    }

    port {
      name        = "http"
      port        = 5601
      target_port = 5601
    }

    type = "ClusterIP"
  }
}

# Kibana Deployment
resource "kubernetes_deployment" "kibana" {
  count = var.create_kibana ? 1 : 0
  
  metadata {
    name      = "kibana"
    namespace = var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "kibana"
        "app.kubernetes.io/component" = "dashboard"
      }
    )
  }

  spec {
    replicas = var.kibana_replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "kibana"
        "app.kubernetes.io/component" = "dashboard"
      }
    }

    template {
      metadata {
        labels = merge(
          var.common_labels,
          {
            "app.kubernetes.io/name"     = "kibana"
            "app.kubernetes.io/component" = "dashboard"
          }
        )
      }

      spec {
        container {
          name  = "kibana"
          image = var.kibana_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 5601
            name          = "http"
          }

          env {
            name  = "ELASTICSEARCH_HOSTS"
            value = "http://elasticsearch.${var.namespace_name}.svc.cluster.local:9200"
          }

          env {
            name  = "SERVER_NAME"
            value = "kibana.${var.namespace_name}.svc.cluster.local"
          }

          resources {
            requests = {
              cpu    = var.kibana_cpu_request
              memory = var.kibana_memory_request
            }
            limits = {
              cpu    = var.kibana_cpu_limit
              memory = var.kibana_memory_limit
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/usr/share/kibana/config/kibana.yml"
            sub_path   = "kibana.yml"
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.kibana_config[0].metadata[0].name
          }
        }
      }
    }
  }
}

# Kibana ConfigMap
resource "kubernetes_config_map" "kibana_config" {
  count = var.create_kibana ? 1 : 0
  
  metadata {
    name      = "kibana-config"
    namespace = var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "kibana"
        "app.kubernetes.io/component" = "config"
      }
    )
  }

  data = {
    "kibana.yml" = templatefile("${path.module}/templates/kibana.yml.tpl", {
      elasticsearch_host = "elasticsearch.${var.namespace_name}.svc.cluster.local:9200"
    })
  }
}

# =============================================================================
# FILEBEAT (Optional)
# =============================================================================

# Filebeat DaemonSet
resource "kubernetes_daemon_set" "filebeat" {
  count = var.create_filebeat ? 1 : 0
  
  metadata {
    name      = "filebeat"
    namespace = var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "filebeat"
        "app.kubernetes.io/component" = "log-shipper"
      }
    )
  }

  spec {
    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "filebeat"
        "app.kubernetes.io/component" = "log-shipper"
      }
    }

    template {
      metadata {
        labels = merge(
          var.common_labels,
          {
            "app.kubernetes.io/name"     = "filebeat"
            "app.kubernetes.io/component" = "log-shipper"
          }
        )
      }

      spec {
        container {
          name  = "filebeat"
          image = var.filebeat_image
          image_pull_policy = "IfNotPresent"

          env {
            name  = "ELASTICSEARCH_HOST"
            value = "elasticsearch.${var.namespace_name}.svc.cluster.local:9200"
          }

          resources {
            requests = {
              cpu    = var.filebeat_cpu_request
              memory = var.filebeat_memory_request
            }
            limits = {
              cpu    = var.filebeat_cpu_limit
              memory = var.filebeat_memory_limit
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/usr/share/filebeat/filebeat.yml"
            sub_path   = "filebeat.yml"
          }

          volume_mount {
            name       = "varlog"
            mount_path = "/var/log"
            read_only  = true
          }

          volume_mount {
            name       = "varlibdockercontainers"
            mount_path = "/var/lib/docker/containers"
            read_only  = true
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.filebeat_config[0].metadata[0].name
          }
        }

        volume {
          name = "varlog"
          host_path {
            path = "/var/log"
          }
        }

        volume {
          name = "varlibdockercontainers"
          host_path {
            path = "/var/lib/docker/containers"
          }
        }
      }
    }
  }
}

# Filebeat ConfigMap
resource "kubernetes_config_map" "filebeat_config" {
  count = var.create_filebeat ? 1 : 0
  
  metadata {
    name      = "filebeat-config"
    namespace = var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "filebeat"
        "app.kubernetes.io/component" = "config"
      }
    )
  }

  data = {
    "filebeat.yml" = templatefile("${path.module}/templates/filebeat.yml.tpl", {
      logstash_host = "logstash.${var.namespace_name}.svc.cluster.local:5044"
    })
  }
}
