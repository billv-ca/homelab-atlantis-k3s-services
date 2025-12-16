resource "kubernetes_namespace_v1" "namespace" {
  metadata {
    name = "trilium"
  }
}

resource "kubernetes_persistent_volume_claim_v1" "pvc" {
  metadata {
    name = "trilium-pvc"
    namespace = kubernetes_namespace_v1.namespace.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    storage_class_name = "longhorn"
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

resource "helm_release" "trilium" {
  repository = "https://triliumnext.github.io/helm-charts"
  chart = "trilium"
  name = "trilium"
  version = "1.3.0"
  create_namespace = true
  namespace = kubernetes_namespace_v1.namespace.metadata.0.name
  set_sensitive = [ {
    name = "persistence.data.enabled"
    value = true
  },
  {
    name = "persistence.data.type"
    value = "persistentVolumeClaim"
  },
  {
    name = "persistence.data.existingClaim"
    value = "trilium-pvc"
  },
  {
    name = "controllers.main.containers.trilium.image.tag"
    value = "v0.95.0"
  },
  {
    name = "controllers.main.containers.trilium.env.TRILIUM_OAUTH_ISSUER_BASE_URL"
    value = var.OIDC_CONFIGURATION_URL
  },
  {
    name = "controllers.main.containers.trilium.env.TRILIUM_OAUTH_ISSUER_NAME"
    value = "Authentik"
  },
  {
    name = "controllers.main.containers.trilium.env.TRILIUM_OAUTH_ISSUER_ICON"
    value = "https://auth.billv.ca/static/dist/assets/icons/icon.svg"
  },
  {
    name = "controllers.main.containers.trilium.env.TRILIUM_OAUTH_BASE_URL"
    value = "https://notes.billv.ca"
  },
  {
    name = "controllers.main.containers.trilium.env.TRILIUM_OAUTH_CLIENT_SECRET"
    value = var.OIDC_CLIENT_SECRET
  },
  {
    name = "controllers.main.containers.trilium.env.TRILIUM_OAUTH_CLIENT_ID"
    value = var.OIDC_CLIENT_ID
  }]
}

resource "kubernetes_manifest" "certificate_ollama_billv_ca" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "notes-billv-ca"
      "namespace" = kubernetes_namespace_v1.namespace.metadata.0.name
    }
    "spec" = {
      "dnsNames" = [
        "notes.billv.ca",
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt"
      }
      "secretName" = "notes-billv-ca"
    }
  }
}

resource "kubernetes_manifest" "ingressroute" {
  manifest = {
    "apiVersion" = "traefik.io/v1alpha1"
    "kind" = "IngressRoute"
    "metadata" = {
      "name" = "trilium"
      "namespace" = kubernetes_namespace_v1.namespace.metadata.0.name
    }
    "spec" = {
      "entryPoints" = ["websecure"]
      "routes" = [{
        "kind" = "Rule"
        "match" = "Host(`notes.billv.ca`)"
        "services" = [{
          "kind" = "Service"
          "name" = "trilium"
          "port" = 8080
        }]
      }]
      "tls" = {
        "secretName" = "notes-billv-ca"
      }
    }
  }
}
