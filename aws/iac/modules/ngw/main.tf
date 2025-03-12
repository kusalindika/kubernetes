variable "name" {
  default = "ngw"
}

variable "env" {
}

variable "project_name" {
  default = "personal"
}

variable "subnet_id" {
  default = ""
}

resource "aws_eip" "nat_gateway_public_ip" {
  domain = "vpc"

  tags = {
    Name        = "${var.env}-${var.project_name}-${var.name}"
    Environment = var.env
    Tf          = 1
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat_gateway_public_ip.id
  subnet_id     = var.subnet_id

  tags = {
    Name        = "${var.env}-${var.project_name}-${var.name}"
    Environment = var.env
    Tf          = 1
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [igw.id]
}

output "id" {
  value = aws_nat_gateway.this.id
}