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
    "10.0.1.247",
    "10.0.2.196",
  ]
}

variable "windows_server_ips" {
  type = set(string)
  default = [
    "10.0.1.231",
  ]
}