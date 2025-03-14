
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${var.env}-${var.project_name}-igw"
    Environment = var.env
    Tf          = 1
  }
}

output "igw_id" {
  value = aws_internet_gateway.igw.id
}