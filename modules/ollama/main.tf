locals {
 pull_models = ["qwen3:8b", "gemma3:12b"]
}

resource "helm_release" "ollama" {
 repository = "https://otwld.github.io/ollama-helm"
 chart = "ollama"
 version = "1.19.0"
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

 dynamic "set" {
   for_each = local.pull_models
   content {
     name = "ollama.models.pull[${set.key}]"
     value = set.value
   }
 }


}

resource "helm_release" "openwebui" {
  repository = "https://helm.openwebui.com/"
  chart = "open-webui"
  name = "open-webui"
  version = "6.21.0"
  create_namespace = true
  namespace = "open-webui"

  set {
    name = "ollama.enabled"
    value = false
  }

  set {
    name = "ollamaUrls[0]"
    value = "http://ollama.ollama.svc.cluster.local:11434"
  }

  set {
    name = "sso.oidc.clientId"
    value = var.OIDC_CLIENT_ID
  }

  set_sensitive {
    name = "sso.oidc.clientSecret"
    value = var.OIDC_CLIENT_SECRET
  }

  set {
    name = "sso.oidc.enabled"
    value = true
  }

  set {
    name = "sso.oidc.providerName"
    value = var.OIDC_PROVIDER_NAME
  }

  set {
    name = "sso.oidc.providerUrl"
    value = var.OIDC_CONFIGURATION_URL
  }

  set {
    name = "sso.roleManagement.adminRoles"
    value = var.OIDC_ADMIN_GROUP
  }
  
  set {
    name = "sso.roleManagement.allowedRoles"
    value = var.OIDC_USER_GROUP
  }

  set {
    name = "sso.roleManagement.rolesClaim"
    value = "groups"
  }

  set {
    name = "sso.enabled"
    value = true
  }

  set {
    name = "sso.enableRoleManagement"
    value = true
  }

  set {
    name = "sso.enableSignup"
    value = true
  }

  set {
    name = "enableOpenaiApi"
    value = false
  }

  set {
    name = "extraEnvVars[0].name"
    value = "ENABLE_LOGIN_FORM"
  }

  set {
    name = "extraEnvVars[0].value"
    value = "\"false\""
  }

  set {
    name = "extraEnvVars[1].name"
    value = "DEFAULT_USER_ROLE"
  }

  set {
    name = "extraEnvVars[1].value"
    value = "user"
  }
  
  set {
    name = "extraEnvVars[2].name"
    value = "ENABLE_PERSISTENT_CONFIG"
  }

  set {
    name = "extraEnvVars[2].value"
    value = "\"false\""
  }

  set {
    name = "extraEnvVars[3].name"
    value = "WEBUI_URL"
  }

  set {
    name = "extraEnvVars[3].value"
    value = "https://ollama.billv.ca"
  }
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
