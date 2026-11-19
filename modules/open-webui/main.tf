data "aws_ssm_parameter" "homeassistant_token" {
  name = "/homeassistant/token"
}

data "aws_ssm_parameter" "triliumnotes_token" {
  name = "/triliumnotes/token"
}

resource "helm_release" "openwebui" {
  repository = "https://helm.openwebui.com/"
  chart = "open-webui"
  name = "open-webui"
  version = "18.4.0"
  create_namespace = true
  namespace = "open-webui"

  set = [
  {
    name = "podAnnotations.config_hash"
    value = sha256(jsonencode(kubernetes_secret_v1.tool_server_connections.data))
  },
  {
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
    value = "https://ai.billv.ca"
  },
  {
    name = "extraEnvVars[4].name"
    value = "WEB_SEARCH_ENGINE"
  },
  {
    name = "extraEnvVars[4].value"
    value = "duckduckgo"
  },
  {
    name = "extraEnvVars[5].name"
    value = "ENABLE_WEB_SEARCH"
  },
  {
    name = "extraEnvVars[5].value"
    value = "true"
    type = "string"
  },
  {
    name = "extraEnvVars[6].name"
    value = "TOOL_SERVER_CONNECTIONS"
  },
  {
    name = "extraEnvVars[6].valueFrom.secretKeyRef.name"
    value = "open-webui-tool-server-connections"
  },
  {
    name = "extraEnvVars[6].valueFrom.secretKeyRef.key"
    value = "TOOL_SERVER_CONNECTIONS"
  }]

  set_sensitive = [{
    name = "sso.oidc.clientSecret"
    value = var.OIDC_CLIENT_SECRET
  }]
}

resource "kubernetes_secret_v1" "tool_server_connections" {
  metadata {
    namespace = "open-webui"
    name = "open-webui-tool-server-connections"
  }
  data = {
    TOOL_SERVER_CONNECTIONS = jsonencode([
      {
        type = "mcp"
        url = "https://assistant.home.billv.ca/api/mcp"
        spec_type = "url"
        spec = ""
        path = "openapi.json"
        auth_type = "bearer"
        config = {
          enabled = "true"
          access_grants = [
              {
                principal_type = "user"
                principal_id   = "*"
                permission     = "read"
              }
          ]
        }
        key = data.aws_ssm_parameter.homeassistant_token.value
        info = {
          id = "homeassistant"
          name = "HomeAssistant"
          description = ""
        }
      },
      {
        type = "mcp"
        url = "http://trilium.trilium.svc.cluster.local:8080/mcp"
        spec_type = "url"
        spec = ""
        path = "openapi.json"
        auth_type = "bearer"
        config = {
          enabled = "true"
          access_grants = [
              {
                principal_type = "user"
                principal_id   = "*"
                permission     = "read"
              }
          ]
        }
        key = data.aws_ssm_parameter.triliumnotes_token.value
        info = {
          id = "trilium-notes"
          name = "Trilium Notes"
          description = ""
        }
      }
    ])
  }

  type = "Opaque"
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
        "ai.billv.ca",
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt"
      }
      "secretName" = "ai-billv-ca"
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
        "match" = "Host(`ai.billv.ca`)"
        "services" = [{
          "kind" = "Service"
          "name" = "open-webui"
          "port" = 80
        }]
      }]
      "tls" = {
        "secretName" = "ai-billv-ca"
      }
    }
  }
}
