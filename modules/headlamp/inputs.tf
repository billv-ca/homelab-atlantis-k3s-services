variable "OIDC_CONFIGURATION_URL" {
  default = "https://auth.billv.ca/application/o/headlamp/"
  type = string
}

variable "OIDC_CLIENT_ID" {
  type = string
}

variable "OIDC_CLIENT_SECRET" {
  type = string
  sensitive = true
}
