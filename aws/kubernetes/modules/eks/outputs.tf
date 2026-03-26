output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate data for the cluster CA."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_version" {
  description = "Kubernetes version running on the cluster."
  value       = aws_eks_cluster.this.version
}

output "cluster_security_group_id" {
  description = "ID of the additional cluster security group."
  value       = aws_security_group.cluster.id
}

output "cluster_primary_security_group_id" {
  description = "ID of the EKS-managed cluster security group."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider (without https://)."
  value       = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

output "cluster_role_arn" {
  description = "ARN of the IAM role used by the EKS cluster."
  value       = aws_iam_role.cluster.arn
}

output "node_role_arn" {
  description = "ARN of the IAM role used by the managed node group."
  value       = aws_iam_role.node.arn
}

output "node_role_name" {
  description = "Name of the IAM role used by the managed node group."
  value       = aws_iam_role.node.name
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for EKS secrets encryption. Empty when encryption is disabled."
  value       = var.enable_secrets_encryption ? aws_kms_key.eks[0].arn : ""
}

output "ebs_csi_role_arn" {
  description = "ARN of the IRSA role used by the EBS CSI driver."
  value       = aws_iam_role.ebs_csi.arn
}

output "system_node_group_name" {
  description = "Name of the system managed node group."
  value       = aws_eks_node_group.system.node_group_name
}
