#Repo: https://prometheus-community.github.io/helm-charts
#Chart: kube-prometheus-stack
resource "helm_release" "community-prometheus" {
  repository = "https://prometheus-community.github.io/helm-charts"
  chart = "kube-prometheus-stack"
  name = "kube-prometheus-stack"
  version = "80.6.0"
  create_namespace = true
  namespace = "monitoring"

  set = [
    {
        name = "grafana.env.GF_AUTH_BASIC_ENABLED"
        value = "false"
    },
    {
        name = "grafana.env.GF_AUTH_DISABLE_LOGIN_FORM"
        value = "true"
    },
    {
        name = "grafana.env.GF_AUTH_GENERIC_OAUTH_ENABLED"
        value = "true"
    },
    {
        name = "grafana.env.GF_AUTH_GENERIC_OAUTH_ALLOW_SIGN_UP"
        value = "true"
    },
    {
        name = "grafana.env.GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH"
        value = "contains(groups[*]\\, 'Grafana_Admins') && 'GrafanaAdmin' || 'Viewer'"
    },
    {
        name = "grafana.env.GF_AUTH_GENERIC_OAUTH_NAME"
        value = "Authentik"
    },
    {
        name = "grafana.env.GF_AUTH_GENERIC_OAUTH_CLIENT_ID"
        value = var.OIDC_CLIENT_ID
    },
    {
        name = "grafana.env.GF_AUTH_GENERIC_OAUTH_SCOPES"
        value = "openid profile email"
    },
    {
        name = "grafana.env.GF_AUTH_GENERIC_OAUTH_AUTH_URL"
        value = "https://auth.billv.ca/application/o/authorize/"
    },
    {
        name = "grafana.env.GF_AUTH_GENERIC_OAUTH_TOKEN_URL"
        value = "https://auth.billv.ca/application/o/token/"
    },
    {
        name = "grafana.env.GF_AUTH_GENERIC_OAUTH_API_URL"
        value = "https://auth.billv.ca/application/o/userinfo/"
    },
    {
        name = "grafana.env.GF_AUTH_GENERIC_OAUTH_ALLOW_ASSIGN_GRAFANA_ADMIN",
        value = "true"
    },
    {
        name = "grafana.env.GF_SERVER_ROOT_URL"
        value = "https://grafana.billv.ca/"
    },
  ]

  set_sensitive = [ 
    {
        name = "grafana.env.GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET"
        value = var.OIDC_CLIENT_SECRET
    }
  ]
}

# auth_url = https://auth.billv.ca/application/o/authorize/
# token_url = https://auth.billv.ca/application/o/token/
# api_url = https://auth.billv.ca/application/o/userinfo/
# use_pkce = true
# use_refresh_token = true

resource "kubernetes_manifest" "cert" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "grafana"
      "namespace" = "monitoring"
    }
    "spec" = {
      "dnsNames" = [
        "grafana.billv.ca",
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt"
      }
      "secretName" = "grafana-billv-ca"
    }
  }
}

resource "kubernetes_manifest" "ingressroute" {
  manifest = {
    "apiVersion" = "traefik.io/v1alpha1"
    "kind" = "IngressRoute"
    "metadata" = {
      "name" = "grafana"
      "namespace" = "monitoring"
    }
    "spec" = {
      "entryPoints" = ["websecure"]
      "routes" = [{
        "kind" = "Rule"
        "match" = "Host(`grafana.billv.ca`)"
        "services" = [{
          "kind" = "Service"
          "name" = "kube-prometheus-stack-grafana"
          "port" = 80
        }]
      }]
      "tls" = {
        "secretName" = "grafana-billv-ca"
      }
    }
  }
}
