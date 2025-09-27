resource "kubernetes_namespace_v1" "namespace" {
  metadata {
    name = "orca"
  }
}

resource "kubernetes_stateful_set_v1" "orca" {
  metadata {
    name = "orca"
    namespace = kubernetes_namespace_v1.namespace.metadata[0].name
  }
  spec {
    service_name = "orca"
    selector {
      match_labels = {
        app = "orca"
      }
    }
    volume_claim_template {
        metadata {
            name = "config"
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
                app = "orca"
            }
        }
        spec {
            container {
                name = "orca"
                image = "linuxserver/orcaslicer:2.3.1"

                port {
                  container_port = 3000
                  protocol = "TCP"
                  name = "http"
                }

                volume_mount {
                  mount_path = "/config"
                  name = "config"
                }
            }
        }
    }
  }
}

resource "kubernetes_service_v1" "orca" {
  metadata {
    name = "orca"
    namespace = kubernetes_namespace_v1.namespace.metadata.0.name
  }
  spec {
    type = "ClusterIP"
    selector = {
        "app" = "orca"
    }
    port {
      name = "http"
      port = 3000
      target_port = 3000
      protocol = "TCP"
    }
  }
}

resource "kubernetes_manifest" "certificate_orca_billv_ca" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "orca-billv-ca"
      "namespace" = kubernetes_namespace_v1.namespace.metadata.0.name
    }
    "spec" = {
      "dnsNames" = [
        "orca.billv.ca",
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt"
      }
      "secretName" = "orca-billv-ca"
    }
  }
}

resource "kubernetes_manifest" "ingressroute" {
  manifest = {
    "apiVersion" = "traefik.io/v1alpha1"
    "kind" = "IngressRoute"
    "metadata" = {
      "name" = "orca"
      "namespace" = kubernetes_namespace_v1.namespace.metadata.0.name
    }
    "spec" = {
      "entryPoints" = ["websecure"]
      "routes" = [{
        "kind" = "Rule"
        "match" = "Host(`orca.billv.ca`)"
        "middlewares" = [{
          "name" = "authentik"
          "namespace" = kubernetes_namespace_v1.namespace.metadata.0.name
        }]
        "services" = [{
          "kind" = "Service"
          "name" = "orca"
          "port" = 3000
          "scheme" = "http"
        }]
      }]
      "tls" = {
        "secretName" = "orca-billv-ca"
      }
    }
  }
}
