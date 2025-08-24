variable "OIDC_CONFIGURATION_URL" {
  default = "https://auth.billv.ca/application/o/trilium"
  type = string
}

variable "OIDC_CLIENT_ID" {
  type = string
}

variable "OIDC_CLIENT_SECRET" {
  type = string
  sensitive = true
}

variable "OIDC_PROVIDER_NAME" {
  default = "Authentik"
  type = string
}

variable "OIDC_ADMIN_GROUP" {
  default = "trilium_Admins"
  type = string
}

variable "OIDC_USER_GROUP" {
  default = "trilium_Users"
  type = string
}

