variable "openid_provider_arn" {
  description = "IAM Openid Connect Provider ARN"
  type        = string
}

variable "aws_load_balancer_controller_helm_version" {
  description = "AWS Load Balancer Controller Helm version"
  type        = string
}

variable "eks_name" {
  description = "The name of the EKS cluster"
  type = string 
}

variable "aws_eks_node_group" {
  description = "The EKS node group"
  type = any  
}

variable "vpcId" {
  description = "The VPC ID"
  type = string
}