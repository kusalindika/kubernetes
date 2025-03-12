variable "name" {
  default = "public"
}

variable "cidrs" {
  default = []
}

variable "azs" {
  description = "A list of availability zones"
  default     = []
}

variable "vpc_id" {
}

variable "map_public_ip_on_launch" {
  default = true
}

variable "env" {
}

resource "aws_subnet" "public" {
  vpc_id                  = var.vpc_id
  cidr_block              = element(var.cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  count                   = length(var.cidrs)
  map_public_ip_on_launch = var.map_public_ip_on_launch

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name         = "${var.env}-${var.name}-${element(var.azs, count.index)}"
    Environment  = var.env
    Tf           = 1
    Subnet_Class = var.name
  }
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}
