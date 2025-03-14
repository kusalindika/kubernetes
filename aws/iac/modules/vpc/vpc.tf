resource "aws_vpc" "this" {
  cidr_block                       = var.vpc_cidr
  assign_generated_ipv6_cidr_block = false
  enable_dns_support               = true
  enable_dns_hostnames             = true

  tags = {
    Name        = "${var.env}-${var.project_name}-vpc"
    Environment = var.env
  }
}

output "vpc_id" {
  value = aws_vpc.this.id
}
