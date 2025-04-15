# Adds K/V v2
resource "vault_mount" "kv" {
  path = "secret"
  type = "kv"
  options = {
    version = "2"
  }
}

# Adds private SSH key
resource "vault_kv_secret_v2" "linux_secret" {
  mount = vault_mount.kv.path
  name  = "linux"

  data_json = jsonencode({
    username    = "rocky",
    private_key = var.linux_private_key
  })
}

# Create a credential library for Vault
resource "boundary_credential_library_vault" "static_linux_library" {
  name                = "vault-linux-library"
  description         = "vault ssh private key credential with mapping overrides"
  credential_store_id = boundary_credential_store_vault.vault_credential_store.id
  path                = "secret/data/linux"
  credential_type     = "ssh_private_key"
}

# Adds Windows credentials
resource "vault_kv_secret_v2" "windows_secret" {
  mount = vault_mount.kv.path
  name  = "windows"

  data_json = jsonencode({
    username = var.win_instance_username,
    password = var.win_instance_password,
  })
}

resource "boundary_credential_library_vault" "static_windows_library" {
  name                = "vault-windows-library"
  description         = "vault username password credential"
  credential_store_id = boundary_credential_store_vault.vault_credential_store.id
  path                = "secret/data/windows"
  credential_type     = "username_password"
}