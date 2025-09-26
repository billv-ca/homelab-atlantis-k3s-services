resource "kubernetes_namespace_v1" "namespace" {
  metadata {
    name = "octoeverywhere"
  }
}

resource "kubernetes_stateful_set_v1" "octoeverywhere" {
  metadata {
    name = "octoeverywhere"
    namespace = kubernetes_namespace_v1.namespace.metadata[0].name
  }
  spec {
    service_name = "octoeverywhere"
    selector {
      match_labels = {
        app = "octoeverywhere"
      }
    }
    volume_claim_template {
        metadata {
            name = "data"
        }
        spec {
            resources {
              requests = {
                storage = "5Gi"
              }
            }
            storage_class_name = "longhorn"
            access_modes = ["ReadWriteOnce"]
        }
    }
    template {
        metadata {
            labels = {
                app = "octoeverywhere"
            }
        }
        spec {
            container {
                name = "octoeverywhere"
                image = "octoeverywhere/octoeverywhere:latest"
                
                env {
                    name = "COMPANION_MODE"
                    value = "elegoo"
                }

                env {
                    name = "PRINTER_IP"
                    value = "10.202.0.22"
                }

                volume_mount {
                    name = "data"
                    mount_path = "/data"
                }
            }
        }
    }
  }
}