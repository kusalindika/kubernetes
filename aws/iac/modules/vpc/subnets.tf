variable "private_subnet_tags" {
  description = "Private subnet tags"
  type        = map(any)
}

variable "public_subnet_tags" {
  description = "Private subnet tags"
  type        = map(any)
}

resource "aws_subnet" "private" {
  count                   = length(var.private_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false

  lifecycle {
    create_before_destroy = true
  }

  tags = merge({
    Name        = "${var.env}-private-${var.azs[count.index]}"
    Environment = var.env
    Tf = 1 }
  , var.private_subnet_tags)
}

resource "aws_subnet" "public" {
  count                   = length(var.public_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  lifecycle {
    create_before_destroy = true
  }

  tags = merge({
    Name        = "${var.env}-public-${var.azs[count.index]}"
    Environment = var.env
    Tf          = 1
  }, var.public_subnet_tags)

}

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

output "public_sunet_ids" {
  value = aws_subnet.public.*.id
}