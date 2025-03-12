variable "name" {
  default = "vpc"
}

variable "env" {
}

variable "vpc_cidr" {
}

variable "project_name" {
  default = "personal"
}

resource "aws_vpc" "this" {
  cidr_block                       = var.vpc_cidr
  assign_generated_ipv6_cidr_block = false
  enable_dns_support               = true
  enable_dns_hostnames             = true

  tags = {
    Name        = "${var.env}-${var.project_name}-${var.name}"
    Environment = var.env
  }
}

output "id" {
  value = aws_vpc.this.id
}