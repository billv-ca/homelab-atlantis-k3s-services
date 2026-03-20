resource "helm_release" "headlamp" {
 repository = "https://kubernetes-sigs.github.io/headlamp/"
 chart = "headlamp"
 version = "0.40.0"
 name = "headlamp"
 create_namespace = true
 namespace = "headlamp"
 set_sensitive = [{
  name = "config.oidc.clientSecret"
  value = var.OIDC_CLIENT_SECRET
 }]
 values = [<<-EOF
service:
  type: LoadBalancer
  annotations:
    metallb.universe.tf/loadBalancerIPs: 10.206.101.11
config:
  oidc:
    clientID: ${var.OIDC_CLIENT_ID}
    issuerURL: ${var.OIDC_CONFIGURATION_URL}
 EOF
]
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
