terraform {
  backend "s3" {
    bucket = "tfstate.billv.ca"
    key = "k8s/terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    authentik = {
      source = "goauthentik/authentik"
    }
  }
}

provider "kubernetes" {
  ignore_annotations = [
    "metallb\\.universe\\.tf\\/ip-allocated-from-pool",
    "kubectl\\.kubernetes\\.io\\/restartedAt"
  ]
}

provider "authentik" {
  url = "https://auth.billv.ca"
  token = var.authentik_api_key
  insecure = true
}

module "metallb" {
  source = "./modules/metallb"
}

# module "ollama" {
#   source = "./modules/ollama"
# }

module "transformerlab" {
  source = "./modules/transformerlab"
}

module "orca" {
  source = "./modules/orca"
}

module "community-prometheus" {
  OIDC_CLIENT_ID = module.authentik.grafana_client_id
  OIDC_CLIENT_SECRET = module.authentik.grafana_client_secret
  source = "./modules/community-prometheus"
}

module "trilium" {
  OIDC_CLIENT_ID = module.authentik.trilium_client_id
  OIDC_CLIENT_SECRET = module.authentik.trilium_client_secret
  source = "./modules/trilium"
}

module "open-webui" {
  source = "./modules/open-webui"
  OIDC_CLIENT_ID = module.authentik.open-webui_client_id
  OIDC_CLIENT_SECRET = module.authentik.open-webui_client_secret
}

module "cert_manager" {
  source = "./modules/cert-manager"
}

module "authentik" {
  source = "./modules/authentik"
}

module "mealie-system" {
  source = "./modules/mealie-system"
  OIDC_CLIENT_ID = module.authentik.mealie_client_id
  OIDC_CLIENT_SECRET = module.authentik.mealie_client_secret
}

module "pfsense_route53_credentials" {
  source = "./modules/pfsense-route53-credentials"
}

module "dns" {
  source = "./modules/dns"
}

module "wireguard" {
  source = "./modules/wireguard"
}

module "ocis" {
  client_id = module.authentik.ocis_client_id
  source = "./modules/ocis"
}

module "meshcentral" {
  source = "./modules/meshcentral"
}
