variable "users" {
  type = set(string)
  default = [
    "Jan",
    "Marc",
  ]
}

variable "linux_server_ips" {
  type = set(string)
  default = [
    "10.0.1.183",
    "10.0.2.24",
  ]
}

variable "windows_server_ips" {
  type = set(string)
  default = [
    "10.0.1.130",
  ]
}