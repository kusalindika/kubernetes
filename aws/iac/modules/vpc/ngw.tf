resource "aws_eip" "nat_gateway_public_ip" {
  domain = "vpc"

  tags = {
    Name        = "${var.env}-${var.project_name}-ngw-eip"
    Environment = var.env
    Tf          = 1
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat_gateway_public_ip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "${var.env}-${var.project_name}-ngw"
    Environment = var.env
    Tf          = 1
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

output "ngw_id" {
  value = aws_nat_gateway.this.id
}