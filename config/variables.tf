variable "users" {
  type = set(string)
  default = [
    "Jan",
    "Marc",
  ]
}

variable "backend_server_ips" {
  type = set(string)
  default = [
    "10.0.1.218",
    "10.0.2.125",
  ]
}