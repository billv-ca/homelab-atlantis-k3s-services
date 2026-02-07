resource "kubernetes_namespace_v1" "namespace" {
  metadata{
    name = "transformerlab"
  }
}

resource "kubernetes_service_v1" "service" {
    metadata {
      name = "transformerlab"
      namespace = kubernetes_namespace_v1.namespace.metadata.0.name
    }
    spec {
        selector = {
            app = "transformerlab"
        }
        type = "ClusterIP"
        port {
            name = "http"
            port = 80
            target_port = 8338
            protocol = "TCP"
        }
    }
}

resource "kubernetes_stateful_set_v1" "transformerlab" {
    metadata {
      name = "transformerlab"
      namespace = kubernetes_namespace_v1.namespace.metadata.0.name
    }
    spec {
        selector {
            match_labels = {
              app = "transformerlab"
            }
        }
        service_name = "transformerlab"
        template {
            metadata {
              labels = {
                app = "transformerlab"
              }
            }
            spec {
                container {
                    name = "transformerlab"
                    image = "transformerlab/api:0.28.5-rocm"
                    resources {
                      limits = {
                        "amd.com/gpu" = 1
                      }
                      requests = {
                        "amd.com/gpu" = 1
                      }
                    }
                    port {
                        container_port = 8338
                        name = "http"
                        protocol = "TCP"
                    }
                    env {
                      name = "TL_API_URL"
                      value = "https://tl.billv.ca/"
                    }
                    env {
                        name = "MULTIUSER"
                        value = "true"
                    }
                    env {
                        name = "FRONTEND_URL"
                        value = "https://tl.billv.ca"
                    }
                }
            }
        }
    }
}

resource "kubernetes_manifest" "certificate_tl_billv_ca" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "tl-billv-ca"
      "namespace" = kubernetes_namespace_v1.namespace.metadata.0.name
    }
    "spec" = {
      "dnsNames" = [
        "tl.billv.ca",
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt"
      }
      "secretName" = "tl-billv-ca"
    }
  }
}

resource "kubernetes_manifest" "ingressroute" {
  manifest = {
    "apiVersion" = "traefik.io/v1alpha1"
    "kind" = "IngressRoute"
    "metadata" = {
      "name" = "transformerlab"
      "namespace" = kubernetes_namespace_v1.namespace.metadata.0.name
    }
    "spec" = {
      "entryPoints" = ["websecure"]
      "routes" = [{
        "kind" = "Rule"
        "match" = "Host(`tl.billv.ca`)"
        "services" = [{
          "kind" = "Service"
          "name" = "transformerlab"
          "port" = 80
        }]
      }]
      "tls" = {
        "secretName" = "tl-billv-ca"
      }
    }
  }
}