terraform {
  required_providers {
    boundary = {
      source  = "hashicorp/boundary"
      version = "0.1.0"
    }
  }
}

provider "boundary" {
  addr                            = "http://127.0.0.1:9200"
  auth_method_id                  = "ampw_1234567890"
  password_auth_method_login_name = "admin"
  password_auth_method_password   = "password"
}

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
resource "boundary_account" "users_acct" {
  for_each       = var.users
  name           = each.key
  description    = "User account for ${each.key}"
  type           = "password"
  login_name     = lower(each.key)
  password       = "password"
  auth_method_id = boundary_auth_method.password.id
}

resource "boundary_user" "users" {
  for_each    = var.users
  name        = each.key
  description = "User resource for ${each.key}"
  account_ids = [boundary_account.users_acct[each.value].id]
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
    "id=*;type=auth-method;actions=authenticate,list",
    "id={{account.id}};actions=read,change-password",
    "id=*;type=*;actions=*", # admin
  ]
  scope_id = boundary_scope.corp.id
}

# Create project
resource "boundary_scope" "tam_infra" {
  name                   = "TAM Infrastructure"
  description            = "Technical Account Management"
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
    "id=*;type=auth-method;actions=authenticate,list",
    "id={{account.id}};actions=read,change-password",
    "id=*;type=*;actions=*", # admin
  ]
  scope_id = boundary_scope.tam_infra.id
}

# Create host catalog
resource "boundary_host_catalog" "backend_servers" {
  name        = "backend_servers"
  description = "Backend servers host catalog"
  type        = "static"
  scope_id    = boundary_scope.tam_infra.id
}

# Create hosts
resource "boundary_host" "backend_servers" {
  for_each        = var.backend_server_ips
  type            = "static"
  name            = "backend_server_service_${each.value}"
  description     = "Backend server host"
  address         = each.key
  host_catalog_id = boundary_host_catalog.backend_servers.id
}

# Create host set
resource "boundary_host_set" "backend_servers_ssh" {
  type            = "static"
  name            = "backend_servers_ssh"
  description     = "Host set for backend servers"
  host_catalog_id = boundary_host_catalog.backend_servers.id
  host_ids        = [for host in boundary_host.backend_servers : host.id]
}

# create target for accessing backend servers on port :22
resource "boundary_target" "backend_servers_ssh" {
  type         = "tcp"
  name         = "Backend servers"
  description  = "Backend SSH target"
  scope_id     = boundary_scope.tam_infra.id
  default_port = "22"

  host_set_ids = [
    boundary_host_set.backend_servers_ssh.id
  ]
}