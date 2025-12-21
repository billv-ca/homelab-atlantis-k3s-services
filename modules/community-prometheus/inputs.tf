variable "OIDC_CLIENT_ID" {
  type = string
}

variable "OIDC_CLIENT_SECRET" {
  type = string
  sensitive = true
}