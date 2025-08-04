resource "helm_release" "ollama" {
 repository = "https://otwld.github.io/ollama-helm"
 chart = "ollama"
 version = "1.24.0"
 name = "ollama"
 create_namespace = true
 namespace = "ollama"
 values = [<<-EOF
persistentVolume:
  enabled: true
  size: 32Gi
  storageClass: local-path

service:
  type: LoadBalancer
  annotations:
    metallb.universe.tf/loadBalancerIPs: 10.206.101.10

resources:
  requests:
    memory: 4096Mi
  limits:
    cpu: 2000m
  
ollama:
  gpu:
    enabled: true
    type: amd
    number: 1
 EOF
]
}

resource "helm_release" "openwebui" {
  repository = "https://helm.openwebui.com/"
  chart = "open-webui"
  name = "open-webui"
  version = "6.29.0"
  create_namespace = true
  namespace = "open-webui"

  set = [{
    name = "ollama.enabled"
    value = false
  },
  {
    name = "ollamaUrls[0]"
    value = "http://ollama.ollama.svc.cluster.local:11434"
  },
  {
    name = "sso.oidc.clientId"
    value = var.OIDC_CLIENT_ID
  },
  {
    name = "sso.oidc.enabled"
    value = true
  },
  {
    name = "sso.oidc.providerName"
    value = var.OIDC_PROVIDER_NAME
  },
  {
    name = "sso.oidc.providerUrl"
    value = var.OIDC_CONFIGURATION_URL
  },
  {
    name = "sso.roleManagement.adminRoles"
    value = var.OIDC_ADMIN_GROUP
  },
  {
    name = "sso.roleManagement.allowedRoles"
    value = var.OIDC_USER_GROUP
  },
  {
    name = "sso.roleManagement.rolesClaim"
    value = "groups"
  },
  {
    name = "sso.enabled"
    value = true
  },
  {
    name = "sso.enableRoleManagement"
    value = true
  },
  {
    name = "sso.enableSignup"
    value = true
  },
  {
    name = "enableOpenaiApi"
    value = false
  },
  {
    name = "extraEnvVars[0].name"
    value = "ENABLE_LOGIN_FORM"
  },
  {
    name = "extraEnvVars[0].value"
    value = "\"false\""
  },
  {
    name = "extraEnvVars[1].name"
    value = "DEFAULT_USER_ROLE"
  },
  {
    name = "extraEnvVars[1].value"
    value = "user"
  },
  {
    name = "extraEnvVars[2].name"
    value = "ENABLE_PERSISTENT_CONFIG"
  },
  {
    name = "extraEnvVars[2].value"
    value = "\"false\""
  },
  {
    name = "extraEnvVars[3].name"
    value = "WEBUI_URL"
  },
  {
    name = "extraEnvVars[3].value"
    value = "https://ollama.billv.ca"
  }]

  set_sensitive = [{
    name = "sso.oidc.clientSecret"
    value = var.OIDC_CLIENT_SECRET
  }]
}

resource "kubernetes_manifest" "certificate_ollama_billv_ca" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "ollama-billv-ca"
      "namespace" = "open-webui"
    }
    "spec" = {
      "dnsNames" = [
        "ollama.billv.ca",
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt"
      }
      "secretName" = "ollama-billv-ca"
    }
  }
}

resource "kubernetes_manifest" "ingressroute" {
  manifest = {
    "apiVersion" = "traefik.io/v1alpha1"
    "kind" = "IngressRoute"
    "metadata" = {
      "name" = "open-webui"
      "namespace" = "open-webui"
    }
    "spec" = {
      "entryPoints" = ["websecure"]
      "routes" = [{
        "kind" = "Rule"
        "match" = "Host(`ollama.billv.ca`)"
        "services" = [{
          "kind" = "Service"
          "name" = "open-webui"
          "port" = 80
        }]
      }]
      "tls" = {
        "secretName" = "ollama-billv-ca"
      }
    }
  }
}
