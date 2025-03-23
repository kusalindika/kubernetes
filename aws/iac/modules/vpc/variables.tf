variable "env" {
}

variable "vpc_cidr" {
}

variable "project_name" {
  default = "personal"
}

variable "private_cidrs" {
  type = list(string)
}

variable "public_cidrs" {
  type = list(string)
}

variable "azs" {
  description = "A list of availability zones"
  type        = list(string)
}
