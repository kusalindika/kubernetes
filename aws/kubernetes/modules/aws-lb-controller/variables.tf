variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, stage, prod)."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA."
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL without https:// prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster is deployed."
  type        = string
}

variable "aws_lb_controller_version" {
  description = "AWS Load Balancer Controller Helm chart version."
  type        = string
  default     = "1.12.0"
}

variable "aws_lb_controller_namespace" {
  description = "Kubernetes namespace for the AWS Load Balancer Controller."
  type        = string
  default     = "kube-system"
}

variable "aws_lb_controller_replicas" {
  description = "Number of controller replicas."
  type        = number
  default     = 2
}
