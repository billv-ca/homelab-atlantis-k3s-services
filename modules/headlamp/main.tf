resource "helm_release" "headlamp" {
 repository = "https://kubernetes-sigs.github.io/headlamp/"
 chart = "headlamp"
 version = "0.40.0"
 name = "headlamp"
 create_namespace = true
 namespace = "headlamp"
}

resource "kubernetes_manifest" "certificate_kube_billv_ca" {
  depends_on = [helm_release.headlamp]
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "kube-billv-ca"
      "namespace" = "headlamp"
    }
    "spec" = {
      "dnsNames" = [
        "kube.billv.ca",
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt"
      }
      "secretName" = "kube-billv-ca"
    }
  }
}

resource "kubernetes_manifest" "ingressroute" {
  depends_on = [helm_release.headlamp]
  manifest = {
    "apiVersion" = "traefik.io/v1alpha1"
    "kind" = "IngressRoute"
    "metadata" = {
      "name" = "headlamp"
      "namespace" = "headlamp"
    }
    "spec" = {
      "entryPoints" = ["websecure"]
      "routes" = [{
        "kind" = "Rule"
        "match" = "Host(`kube.billv.ca`)"
        "middlewares" = [{
          "name" = "authentik"
          "namespace" = "headlamp"
        }]
        "services" = [{
          "kind" = "Service"
          "name" = "headlamp"
          "port" = 80
        }]
      }]
      "tls" = {
        "secretName" = "kube-billv-ca"
      }
    }
  }
}
