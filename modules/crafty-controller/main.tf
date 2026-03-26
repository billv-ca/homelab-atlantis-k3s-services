resource "kubernetes_namespace_v1" "namespace" {
  metadata {
    name = "crafty-controller"
  }
}

resource "kubernetes_stateful_set_v1" "craftycontroller" {
    metadata {
      name = "crafty-controller"
      namespace = kubernetes_namespace_v1.namespace.metadata[0].name
    }
    spec {
      service_name = "crafty-controller"
      volume_claim_template {
        metadata {
          name = "crafty-controller-servers"
        }
        spec {
            access_modes = ["ReadWriteOnce"]
            storage_class_name = "longhorn"
            resources {
            requests = {
                storage = "10Gi"
            }
          }
        }
      }
            volume_claim_template {
        metadata {
          name = "crafty-controller-backups"
        }
        spec {
            access_modes = ["ReadWriteOnce"]
            storage_class_name = "longhorn"
            resources {
            requests = {
                storage = "10Gi"
            }
          }
        }
      }
      volume_claim_template {
        metadata {
          name = "crafty-controller-config"
        }
        spec {
            access_modes = ["ReadWriteOnce"]
            storage_class_name = "longhorn"
            resources {
            requests = {
                storage = "1Gi"
            }
          }
        }
      }
      template {
        metadata {
          labels = {
            app = "crafty-controller"
          }
        }
        spec {
                    init_container {
          name = "init-chown"
          command = ["/bin/sh", "-c", "chown -R 1000:1000 /servers && chown -R 1000:1000 /config && chown -R 1000:1000 /backups"]
          image = "busybox:stable"
          image_pull_policy = "IfNotPresent"
          security_context {
            run_as_non_root = false
            run_as_user = 0
          }
          volume_mount {
            name = "crafty-controller-servers"
            mount_path = "/servers"
          }
          volume_mount {
            name = "crafty-controller-backups"
            mount_path = "/backups"
          }
          volume_mount {
            name = "crafty-controller-config"
            mount_path = "/config"
          }
        }
            container {
                security_context {
            run_as_group = 1000
            run_as_user = 1000
            run_as_non_root = true
          }
                name = "crafty-controller"
                image = "registry.gitlab.com/crafty-controller/crafty-4:4.10.2"
                image_pull_policy = "Always"
                resources {
                  requests = {
                    "cpu" = "1000m"
                    "memory" = "6144Mi"
                  }
                } 
                volume_mount {
                    name = "crafty-controller-servers"
                    mount_path = "/crafty/servers"
                }
                volume_mount {
                    name = "crafty-controller-backups"
                    mount_path = "/crafty/backups"
                }
                volume_mount {
                    name = "crafty-controller-config"
                    mount_path = "/crafty/app/config"
                }
            }
        }
      }
      selector {
        match_labels = {
            app = "crafty-controller"
        }
      }
    }
}

resource "kubernetes_service_v1" "craftycontroller" {
    metadata {
      name = "crafty-controller"
      namespace = kubernetes_namespace_v1.namespace.metadata.0.name
      annotations = {
        "metallb.universe.tf/loadBalancerIPs": "10.206.102.1"
      }
    }
    spec {
      type = "LoadBalancer"
      selector = {
        app = "crafty-controller"
      }
      port {
        name = "https"
        port = 443
        target_port = 8443
        protocol = "TCP"
      }
      port {
        name = "mc1"
        port = 25565
        target_port = 25565
        protocol = "TCP"
      }
      port {
        name = "mc2"
        port = 25566
        target_port = 25566
        protocol = "TCP"
      }
    } 
}

resource "kubernetes_manifest" "certificate" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "mc-billv-ca"
      "namespace" = kubernetes_namespace_v1.namespace.metadata.0.name
    }
    "spec" = {
      "dnsNames" = [
        "mc.billv.ca",
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt"
      }
      "secretName" = "mc-billv-ca"
    }
  }
}

resource "kubernetes_manifest" "ingressroute" {
  manifest = {
    "apiVersion" = "traefik.io/v1alpha1"
    "kind" = "IngressRoute"
    "metadata" = {
      "name" = "crafty-controller"
      "namespace" = kubernetes_namespace_v1.namespace.metadata.0.name
    }
    "spec" = {
      "entryPoints" = ["websecure"]
      "routes" = [{
        "kind" = "Rule"
        "match" = "Host(`mc.billv.ca`)"
        "services" = [{
          "kind" = "Service"
          "name" = "crafty-controller"
          "port" = 443
          "serversTransport" = "crafty-controller"
          "scheme" = "https"
        }]
      }]
      "tls" = {
        "secretName" = "mc-billv-ca"
      }
    }
  }
}

resource "kubernetes_manifest" "servers_transport" {
  manifest = {
    "apiVersion" = "traefik.io/v1alpha1"
    "kind" = "ServersTransport"
    "metadata" = {
      "name" = "crafty-controller"
      "namespace" = kubernetes_namespace_v1.namespace.metadata.0.name
    }
    "spec" = {
      "serverName" = "crafty-controller.${kubernetes_namespace_v1.namespace.metadata.0.name}.svc.cluster.local"
      "insecureSkipVerify" = "true"
    }
  }
}
