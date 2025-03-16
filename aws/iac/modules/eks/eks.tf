resource "aws_eks_cluster" "this" {
  name     = "${var.env}-${var.eks_name}"
  version  = var.eks_version
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    # Enable the connection if you have vpn or direct connect
    endpoint_private_access = false
    # Enable the connection over the public internet
    endpoint_public_access  = true

    # Subnet ids of private
    subnet_ids = var.subnet_ids
  }

  depends_on = [aws_iam_role_policy_attachment.eks]
}

output "eks_name" {
  value = aws_eks_cluster.this.name
}