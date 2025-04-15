# Enable the SSH secrets engine
resource "vault_mount" "ssh_client_signer" {
  path        = "ssh-client-signer"
  type        = "ssh"
  description = "SSH client signing secrets engine"
}

# Configure the role for SSH client signing
resource "vault_ssh_secret_backend_role" "boundary_client_role" {
  backend = vault_mount.ssh_client_signer.path
  name    = "boundary-client"

  key_type                = "ca"
  allow_user_certificates = true
  default_user            = "admin"

  default_extensions = {
    permit-pty = ""
  }

  allowed_users      = "*"
  allowed_extensions = "*"
}

# Create a credential library for Vault
resource "boundary_credential_library_vault_ssh_certificate" "dynamic_credential_library" {
  name                = "vault-dynamic-library"
  description         = "Credential library for Vault SSH certificates"
  credential_store_id = boundary_credential_store_vault.vault_credential_store.id
  path                = "ssh-client-signer/sign/boundary-client"
  username            = "rocky"
  key_type            = "ecdsa"
  key_bits            = 521

  extensions = {
    permit-pty = ""
  }
}

# Configure the CA for the SSH secrets engine
resource "vault_ssh_secret_backend_ca" "ssh_ca_config" {
  backend              = vault_mount.ssh_client_signer.path
  generate_signing_key = true
}

# Output the public key to a local file
resource "local_file" "ca_public_key" {
  content  = vault_ssh_secret_backend_ca.ssh_ca_config.public_key
  filename = "./ca-key.pub"
}