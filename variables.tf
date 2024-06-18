variable "cluster_name" {
  description = "Name of the cluster."
  default     = "boundary-example"
}

variable "owner" {
  description = "Owner tag on all resources."
  default     = "myuser"
}

variable "key_name" {
  description = "Specify the AWS ssh key to use."
}

variable "private_key" {
  description = "SSH private key to provision the cluster instances."
}

variable "aws_region" {
  default = "eu-north-1"
}

variable "aws_azs" {
  type        = list
  description = "List of the availability zones to use."
  default     = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
}

variable "amis" {
  type = map(string)
  default = {
    # eu-central-1 = "ami-337be65c" # centos 7
    # eu-north-1 = "ami-026f0eb2e8006617d" # centos 7
    eu-north-1 = "ami-07c0f40b66e9893c4" # rocky linux 9
  }
}

variable "instance_username" {
  default = "rocky"
}

variable "num_boundary" {
  description = "Specify the amount of Boundary controllers. For redundancy you should have at least 3."
  default     = 1
}

variable "boundary_version" {
  default     = "0.16.1+ent"
  description = "Specifies which Boundary version instruction to use."
}

variable "boundary_instance_type" {
  description = "Boundary server instance type."
  default     = "t3.small"
}

variable "boundary_license" {
  default     = ""
  description = "Boundary license string."
}

variable "num_linux" {
  description = "Specify the amount of Linux machines."
  default     = 2
}

variable "linux_instance_type" {
  description = "Linux server instance type."
  default     = "t3.small"
}

variable "num_win" {
  description = "Specify the amount of Windows machines."
  default     = 1
}

variable "win_instance_type" {
  description = "Windows server instance type."
  default     = "t3.small"
}

variable "win_instance_username" {
  description = "Windows server username."
  default     = "Boundary"
}

variable "win_instance_password" {
  description = "Windows server password."
  default     = "S3CRET!123"
}