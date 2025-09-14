# Kubernetes Operators Module
# This module creates Kubernetes operators for Terraform and Ansible

# =============================================================================
# NAMESPACE
# =============================================================================

resource "kubernetes_namespace" "operators" {
  count = var.create_namespace ? 1 : 0
  
  metadata {
    name = var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "operators"
        "app.kubernetes.io/instance" = var.environment
        "app.kubernetes.io/version"  = "v1.0.0"
      }
    )
  }
}

# =============================================================================
# TERRAFORM OPERATOR
# =============================================================================

# ServiceAccount for Terraform Operator
resource "kubernetes_service_account" "terraform_operator" {
  count = var.create_terraform_operator ? 1 : 0
  
  metadata {
    name      = "terraform-operator"
    namespace = var.create_namespace ? kubernetes_namespace.operators[0].metadata[0].name : var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "terraform-operator"
        "app.kubernetes.io/component" = "operator"
      }
    )
  }
}

# ClusterRole for Terraform Operator
resource "kubernetes_cluster_role" "terraform_operator" {
  count = var.create_terraform_operator ? 1 : 0
  
  metadata {
    name = "terraform-operator"
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "terraform-operator"
        "app.kubernetes.io/component" = "operator"
      }
    )
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "persistentvolumeclaims", "events", "configmaps", "secrets"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "replicasets", "statefulsets"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["monitoring.coreos.com"]
    resources  = ["servicemonitors"]
    verbs      = ["get", "create"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["list", "watch"]
  }
}

# ClusterRoleBinding for Terraform Operator
resource "kubernetes_cluster_role_binding" "terraform_operator" {
  count = var.create_terraform_operator ? 1 : 0
  
  metadata {
    name = "terraform-operator"
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "terraform-operator"
        "app.kubernetes.io/component" = "operator"
      }
    )
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.terraform_operator[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.terraform_operator[0].metadata[0].name
    namespace = var.create_namespace ? kubernetes_namespace.operators[0].metadata[0].name : var.namespace_name
  }
}

# ConfigMap for Terraform Operator configuration
resource "kubernetes_config_map" "terraform_operator_config" {
  count = var.create_terraform_operator ? 1 : 0
  
  metadata {
    name      = "terraform-operator-config"
    namespace = var.create_namespace ? kubernetes_namespace.operators[0].metadata[0].name : var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "terraform-operator"
        "app.kubernetes.io/component" = "config"
      }
    )
  }

  data = {
    "terraform.tf" = templatefile("${path.module}/templates/terraform-operator.tf.tpl", {
      aws_region = var.aws_region
      environment = var.environment
      state_bucket = var.terraform_state_bucket
      state_table = var.terraform_state_table
    })
    
    "terraform.tfvars" = templatefile("${path.module}/templates/terraform-operator.tfvars.tpl", {
      environment = var.environment
      aws_region = var.aws_region
    })
  }
}

# Deployment for Terraform Operator
resource "kubernetes_deployment" "terraform_operator" {
  count = var.create_terraform_operator ? 1 : 0
  
  metadata {
    name      = "terraform-operator"
    namespace = var.create_namespace ? kubernetes_namespace.operators[0].metadata[0].name : var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "terraform-operator"
        "app.kubernetes.io/component" = "operator"
      }
    )
  }

  spec {
    replicas = var.terraform_operator_replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "terraform-operator"
        "app.kubernetes.io/component" = "operator"
      }
    }

    template {
      metadata {
        labels = merge(
          var.common_labels,
          {
            "app.kubernetes.io/name"     = "terraform-operator"
            "app.kubernetes.io/component" = "operator"
          }
        )
      }

      spec {
        service_account_name = kubernetes_service_account.terraform_operator[0].metadata[0].name

        container {
          name  = "terraform-operator"
          image = var.terraform_operator_image
          image_pull_policy = "IfNotPresent"

          command = ["/bin/bash"]
          args = ["-c", <<-EOT
            # Install Terraform
            wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
            apt-get update && apt-get install -y terraform

            # Install AWS CLI
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            ./aws/install

            # Setup working directory
            mkdir -p /workspace
            cd /workspace

            # Copy configuration
            cp /config/terraform.tf .
            cp /config/terraform.tfvars .

            # Initialize Terraform
            terraform init

            # Keep container running
            tail -f /dev/null
          EOT
          ]

          volume_mount {
            name       = "config"
            mount_path = "/config"
            read_only  = true
          }

          volume_mount {
            name       = "workspace"
            mount_path = "/workspace"
          }

          env {
            name  = "AWS_REGION"
            value = var.aws_region
          }

          env {
            name  = "ENVIRONMENT"
            value = var.environment
          }

          resources {
            requests = {
              cpu    = var.terraform_operator_cpu_request
              memory = var.terraform_operator_memory_request
            }
            limits = {
              cpu    = var.terraform_operator_cpu_limit
              memory = var.terraform_operator_memory_limit
            }
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.terraform_operator_config[0].metadata[0].name
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

# =============================================================================
# ANSIBLE OPERATOR
# =============================================================================

# ServiceAccount for Ansible Operator
resource "kubernetes_service_account" "ansible_operator" {
  count = var.create_ansible_operator ? 1 : 0
  
  metadata {
    name      = "ansible-operator"
    namespace = var.create_namespace ? kubernetes_namespace.operators[0].metadata[0].name : var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "ansible-operator"
        "app.kubernetes.io/component" = "operator"
      }
    )
  }
}

# ClusterRole for Ansible Operator
resource "kubernetes_cluster_role" "ansible_operator" {
  count = var.create_ansible_operator ? 1 : 0
  
  metadata {
    name = "ansible-operator"
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "ansible-operator"
        "app.kubernetes.io/component" = "operator"
      }
    )
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "persistentvolumeclaims", "events", "configmaps", "secrets"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "replicasets", "statefulsets"]
    verbs      = ["*"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["list", "watch"]
  }
}

# ClusterRoleBinding for Ansible Operator
resource "kubernetes_cluster_role_binding" "ansible_operator" {
  count = var.create_ansible_operator ? 1 : 0
  
  metadata {
    name = "ansible-operator"
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "ansible-operator"
        "app.kubernetes.io/component" = "operator"
      }
    )
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.ansible_operator[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.ansible_operator[0].metadata[0].name
    namespace = var.create_namespace ? kubernetes_namespace.operators[0].metadata[0].name : var.namespace_name
  }
}

# ConfigMap for Ansible Operator configuration
resource "kubernetes_config_map" "ansible_operator_config" {
  count = var.create_ansible_operator ? 1 : 0
  
  metadata {
    name      = "ansible-operator-config"
    namespace = var.create_namespace ? kubernetes_namespace.operators[0].metadata[0].name : var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "ansible-operator"
        "app.kubernetes.io/component" = "config"
      }
    )
  }

  data = {
    "ansible.cfg" = templatefile("${path.module}/templates/ansible-operator.cfg.tpl", {
      vault_password_file = "/vault/get-vault-password.sh"
    })
    
    "inventory.yml" = templatefile("${path.module}/templates/ansible-inventory.yml.tpl", {
      environment = var.environment
    })
  }
}

# Secret for Ansible Vault password
resource "kubernetes_secret" "ansible_vault_password" {
  count = var.create_ansible_operator ? 1 : 0
  
  metadata {
    name      = "ansible-vault-password"
    namespace = var.create_namespace ? kubernetes_namespace.operators[0].metadata[0].name : var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "ansible-operator"
        "app.kubernetes.io/component" = "vault"
      }
    )
  }

  data = {
    "vault-password" = var.ansible_vault_password
  }

  type = "Opaque"
}

# Deployment for Ansible Operator
resource "kubernetes_deployment" "ansible_operator" {
  count = var.create_ansible_operator ? 1 : 0
  
  metadata {
    name      = "ansible-operator"
    namespace = var.create_namespace ? kubernetes_namespace.operators[0].metadata[0].name : var.namespace_name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"     = "ansible-operator"
        "app.kubernetes.io/component" = "operator"
      }
    )
  }

  spec {
    replicas = var.ansible_operator_replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "ansible-operator"
        "app.kubernetes.io/component" = "operator"
      }
    }

    template {
      metadata {
        labels = merge(
          var.common_labels,
          {
            "app.kubernetes.io/name"     = "ansible-operator"
            "app.kubernetes.io/component" = "operator"
          }
        )
      }

      spec {
        service_account_name = kubernetes_service_account.ansible_operator[0].metadata[0].name

        container {
          name  = "ansible-operator"
          image = var.ansible_operator_image
          image_pull_policy = "IfNotPresent"

          command = ["/bin/bash"]
          args = ["-c", <<-EOT
            # Install Ansible and dependencies
            apt-get update && apt-get install -y python3 python3-pip git
            pip3 install ansible boto3

            # Install AWS CLI
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            ./aws/install

            # Setup working directory
            mkdir -p /workspace
            cd /workspace

            # Copy configuration
            cp /config/ansible.cfg .
            cp /config/inventory.yml .

            # Create vault password script
            mkdir -p /vault
            echo '#!/bin/bash' > /vault/get-vault-password.sh
            echo 'cat /secrets/vault-password' >> /vault/get-vault-password.sh
            chmod +x /vault/get-vault-password.sh

            # Keep container running
            tail -f /dev/null
          EOT
          ]

          volume_mount {
            name       = "config"
            mount_path = "/config"
            read_only  = true
          }

          volume_mount {
            name       = "workspace"
            mount_path = "/workspace"
          }

          volume_mount {
            name       = "vault-secret"
            mount_path = "/secrets"
            read_only  = true
          }

          env {
            name  = "AWS_REGION"
            value = var.aws_region
          }

          env {
            name  = "ENVIRONMENT"
            value = var.environment
          }

          resources {
            requests = {
              cpu    = var.ansible_operator_cpu_request
              memory = var.ansible_operator_memory_request
            }
            limits = {
              cpu    = var.ansible_operator_cpu_limit
              memory = var.ansible_operator_memory_limit
            }
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.ansible_operator_config[0].metadata[0].name
          }
        }

        volume {
          name = "workspace"
          empty_dir {}
        }

        volume {
          name = "vault-secret"
          secret {
            secret_name = kubernetes_secret.ansible_vault_password[0].metadata[0].name
          }
        }
      }
    }
  }
}
