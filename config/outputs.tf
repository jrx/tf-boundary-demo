output "auth_method_id" {
  value = boundary_auth_method.password.id
}


output "scope_id" {
  value = boundary_scope.sa_infra.id
}
