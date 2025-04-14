terraform {
  required_providers {
    boundary = {
      source = "hashicorp/boundary"
    }
  }
}

provider "boundary" {
  addr                   = var.addr
  tls_insecure           = true
  auth_method_id         = var.auth_method_id
  auth_method_login_name = var.auth_method_login_name
  auth_method_password   = var.auth_method_password
}

provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}