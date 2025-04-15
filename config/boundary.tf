resource "boundary_scope" "global" {
  global_scope = true
  description  = "My first global scope!"
  scope_id     = "global"
}

resource "boundary_scope" "corp" {
  name                     = "HashiCorp, Inc."
  description              = "Infrastructure enables innovation"
  scope_id                 = boundary_scope.global.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

# Use password auth method
resource "boundary_auth_method" "password" {
  name     = "Corp Password"
  scope_id = boundary_scope.corp.id
  type     = "password"
}

# Create user accounts with password: password
resource "boundary_account_password" "users_acct" {
  for_each       = var.users
  name           = each.key
  description    = "User account for ${each.key}"
  login_name     = lower(each.key)
  password       = "password"
  auth_method_id = boundary_auth_method.password.id
}

resource "boundary_user" "users" {
  for_each    = var.users
  name        = each.key
  description = "User resource for ${each.key}"
  account_ids = [boundary_account_password.users_acct[each.value].id]
  scope_id    = boundary_scope.corp.id
}

resource "boundary_role" "organization_admin" {
  name        = "Organization Admin"
  description = "Organization administrator role"
  principal_ids = concat(
    [for user in boundary_user.users : user.id]
  )
  grant_strings = [
    "type=scope;actions=list",
    "ids=*;type=auth-method;actions=authenticate,list",
    "ids={{account.id}};actions=read,change-password",
    "ids=*;type=*;actions=*", # admin
  ]
  scope_id = boundary_scope.corp.id
}

# Create project
resource "boundary_scope" "sa_infra" {
  name                   = "SA Infrastructure"
  description            = "Solutions Architecture"
  scope_id               = boundary_scope.corp.id
  auto_create_admin_role = true
}

resource "boundary_role" "project_admin" {
  name        = "Project Admin"
  description = "Project administrator role"
  principal_ids = concat(
    [for user in boundary_user.users : user.id]
  )
  grant_strings = [
    "type=scope;actions=list",
    "ids=*;type=auth-method;actions=authenticate,list",
    "ids={{account.id}};actions=read,change-password",
    "ids=*;type=*;actions=*", # admin
  ]
  scope_id = boundary_scope.sa_infra.id
}

# Create host catalog
resource "boundary_host_catalog_static" "linux_servers" {
  name        = "linux_servers"
  description = "Linux servers host catalog"
  scope_id    = boundary_scope.sa_infra.id
}

# Create hosts
resource "boundary_host_static" "linux_servers" {
  for_each        = var.linux_server_ips
  type            = "static"
  name            = "linux_server_service_${each.value}"
  description     = "Linux server host"
  address         = each.key
  host_catalog_id = boundary_host_catalog_static.linux_servers.id
}

# Create host set
resource "boundary_host_set_static" "linux_servers_ssh" {
  type            = "static"
  name            = "linux_servers_ssh"
  description     = "Host set for Linux servers"
  host_catalog_id = boundary_host_catalog_static.linux_servers.id
  host_ids        = [for host in boundary_host_static.linux_servers : host.id]
}

# create target for accessing linux servers on port :22
resource "boundary_target" "linux_servers_ssh" {
  type         = "ssh"
  name         = "Linux servers"
  description  = "Linux SSH target"
  scope_id     = boundary_scope.sa_infra.id
  default_port = "22"

  host_source_ids = [
    boundary_host_set_static.linux_servers_ssh.id
  ]

  injected_application_credential_source_ids = [
    # boundary_credential_library_vault_ssh_certificate.dynamic_credential_library.id,
    boundary_credential_library_vault.static_linux_library.id,
  ]
}

resource "boundary_alias_target" "linux_servers_ssh" {
  # for_each                  = boundary_host_static.linux_servers
  name           = "linux_alias_target"
  description    = "Linux SSH alias"
  scope_id       = "global"
  value          = "linux.boundary"
  destination_id = boundary_target.linux_servers_ssh.id
  # authorize_session_host_id = boundary_host_static.linux_servers[each.key].id
}

# Create host catalog
resource "boundary_host_catalog_static" "windows_servers" {
  name        = "windows_servers"
  description = "Windows servers host catalog"
  scope_id    = boundary_scope.sa_infra.id
}

# Create hosts
resource "boundary_host_static" "windows_servers" {
  for_each        = var.windows_server_ips
  type            = "static"
  name            = "windows_server_service_${each.value}"
  description     = "Windows server host"
  address         = each.key
  host_catalog_id = boundary_host_catalog_static.windows_servers.id
}

# Create host set
resource "boundary_host_set_static" "windows_servers_rdp" {
  type            = "static"
  name            = "windows_servers_rdp"
  description     = "Host set for Windows servers"
  host_catalog_id = boundary_host_catalog_static.windows_servers.id
  host_ids        = [for host in boundary_host_static.windows_servers : host.id]
}

# create target for accessing windows servers on port :3389
resource "boundary_target" "windows_servers_rdp" {
  type         = "tcp"
  name         = "Windows servers"
  description  = "Windows RDP target"
  scope_id     = boundary_scope.sa_infra.id
  default_port = "3389"

  host_source_ids = [
    boundary_host_set_static.windows_servers_rdp.id
  ]

  brokered_credential_source_ids = [
    boundary_credential_library_vault.static_windows_library.id,
  ]
}

resource "boundary_alias_target" "windows_servers_rdp" {
  # for_each                  = boundary_host_static.windows_servers
  name           = "windows_alias_target"
  description    = "Windows RDP alias"
  scope_id       = "global"
  value          = "windows.boundary"
  destination_id = boundary_target.windows_servers_rdp.id
  # authorize_session_host_id = boundary_host_static.windows_servers[each.key].id
}