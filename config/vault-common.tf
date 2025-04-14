# Create K/V policy
resource "vault_policy" "controller" {
  name   = "boundary-controller"
  policy = <<EOT
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
path "auth/token/renew-self" {
  capabilities = ["update"]
}
path "auth/token/revoke-self" {
  capabilities = ["update"]
}
path "sys/leases/renew" {
  capabilities = ["update"]
}
path "sys/leases/revoke" {
  capabilities = ["update"]
}
path "sys/capabilities-self" {
  capabilities = ["update"]
}
EOT
}

# Create K/V policy
resource "vault_policy" "boundary_kv" {
  name   = "boundary-kv"
  policy = <<EOT
path "secret/*" {
  capabilities = ["read"]
}
EOT
}

# Create SSH policy
resource "vault_policy" "boundary_ssh" {
  name   = "boundary-ssh"
  policy = <<EOT
path "ssh-client-signer/issue/boundary-client" {
  capabilities = ["create", "update"]
}
path "ssh-client-signer/sign/boundary-client" {
  capabilities = ["create", "update"]
}
EOT
}

# # Enable AWS auth method
# resource "vault_auth_backend" "aws" {
#   type = "aws"
# }

# # Configure AWS auth client
# resource "vault_aws_auth_backend_client" "config" {
#   backend = vault_auth_backend.aws.path
# }

# # Create AWS auth role
# resource "vault_aws_auth_backend_role" "boundary-controller" {
#   backend                  = vault_auth_backend.aws.path
#   role                     = "boundary-controller"
#   auth_type                = "iam"
#   token_ttl                = 86400 # 24 hours in seconds
#   token_policies           = [vault_policy.boundary_kv.name]
#   bound_iam_principal_arns = [var.aws-auth-arn]
# }


# Create a periodic token
resource "vault_token" "boundary_token" {
  no_default_policy = true
  no_parent         = true
  renewable         = true
  period            = "20m"

  policies = [
    "boundary-controller",
    "boundary-kv",
    "boundary-ssh",
  ]
}

# Create a credential store for Vault 
resource "boundary_credential_store_vault" "vault_credential_store" {
  name            = "Vault Credential Store"
  description     = "Credential store for Vault integration"
  scope_id        = boundary_scope.sa_infra.id
  address         = var.vault_lb
  token           = vault_token.boundary_token.client_token
  tls_skip_verify = true
  worker_filter   = "\"vault\" in \"/tags/type\""
}
