variable "OIDC_CONFIGURATION_URL" {
  default = "https://auth.billv.ca/application/o/trilium/"
  type    = string
}

variable "OIDC_CLIENT_ID" {
  type = string
}

variable "OIDC_CLIENT_SECRET" {
  type      = string
  sensitive = true
}

variable "trilium_tag" {
  type = string
  # renovate: datasource=docker depName=triliumnext/trilium
  default = "v0.105.0"
}
