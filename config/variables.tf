variable "addr" {
  type    = string
  default = "https://127.0.0.1:9200"
}

variable "auth_method_id" {
  type    = string
  default = "ampw_1234567890"
}

variable "auth_method_login_name" {
  type    = string
  default = "admin"
}

variable "auth_method_password" {
  type    = string
  default = "password"
}

variable "users" {
  type = set(string)
  default = [
    "Jan",
    "Andrei",
  ]
}

variable "linux_server_ips" {
  type = set(string)
  default = [
    "10.0.1.37",
    "10.0.2.196",
  ]
}

variable "windows_server_ips" {
  type = set(string)
  default = [
    "10.0.1.231",
  ]
}

variable "vault_lb" {
  type    = string
  default = "https://127.0.0.1:8200"
}

variable "vault_address" {
  type    = string
  default = "https://127.0.0.1:8200"
}

variable "vault_token" {
  type = string
}

variable "linux_private_key" {
  description = "SSH private key to access the Linux instances."
}

variable "aws-auth-arn" {
  type = string
}