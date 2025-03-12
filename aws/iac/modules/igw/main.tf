variable "name" {
  default = "igw"
}

variable "vpc_id" {
}

variable "env" {
}

variable "project_name" {
  default = "personal"
}

resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id

  tags = {
    Name        = "${var.env}-${var.project_name}-${var.name}"
    Environment = var.env
    Tf          = 1
  }
}

output "id" {
  value = aws_internet_gateway.this.id
}