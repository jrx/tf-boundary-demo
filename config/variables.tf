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
