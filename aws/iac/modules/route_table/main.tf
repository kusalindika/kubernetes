variable "env" {
  default = ""
}

variable "vpc_id" {
  default = vpc.id
}

variable "igw_id" {
  default = igw.id
}

variable "ngw_id" {
  default = ngw.id
}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = {
    Name        = "${var.env}-rt-public"
    Environment = var.env
    Tf          = 1
  }
}

resource "aws_route_table_association" "public" {
  count          = length(public_subnet.public_subnet_ids)
  subnet_id      = element(flatten(module.public_subnet.subnet_ids), count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.ngw_id
  }

  tags = {
    Name        = "${var.env}-rt-private"
    Environment = var.env
    Tf          = 1
  }
}

resource "aws_route_table_association" "private" {
  count          = length(private_subnet.private_subnet_ids)
  subnet_id      = element(flatten(module.private_subnet.subnet_ids), count.index)
  route_table_id = aws_route_table.private.id
}
