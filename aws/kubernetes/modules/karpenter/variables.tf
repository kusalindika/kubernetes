variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster API endpoint."
  type        = string
}

variable "cluster_ca_data" {
  description = "Base64-encoded CA data for the EKS cluster."
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

variable "node_role_arn" {
  description = "ARN of the existing EKS node IAM role. Karpenter-launched nodes use this role."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where Karpenter can launch nodes."
  type        = list(string)
}

variable "cluster_primary_security_group_id" {
  description = "EKS-managed primary cluster security group ID."
  type        = string
}

variable "karpenter_version" {
  description = "Karpenter Helm chart version."
  type        = string
  default     = "1.10.0"
}

variable "karpenter_namespace" {
  description = "Kubernetes namespace for Karpenter."
  type        = string
  default     = "kube-system"
}

variable "node_pool_instance_categories" {
  description = "EC2 instance categories allowed for the general on-demand NodePool."
  type        = list(string)
  default     = ["c", "m", "r"]
}

variable "node_pool_instance_categories_spot" {
  description = "EC2 instance categories allowed for the general spot NodePool."
  type        = list(string)
  default     = ["c", "m", "r"]
}

variable "node_pool_cpu_limit" {
  description = "Maximum total vCPUs Karpenter can provision across all on-demand NodePools."
  type        = number
  default     = 100
}

variable "node_pool_cpu_limit_spot" {
  description = "Maximum total vCPUs Karpenter can provision across spot NodePools."
  type        = number
  default     = 100
}

variable "consolidation_policy" {
  description = "Karpenter disruption consolidation policy."
  type        = string
  default     = "WhenEmptyOrUnderutilized"
}

variable "consolidate_after" {
  description = "Duration after which Karpenter consolidates nodes."
  type        = string
  default     = "1m"
}

variable "node_expire_after" {
  description = "Duration after which nodes are expired (recycled)."
  type        = string
  default     = "720h"
}

variable "enable_spot_pool" {
  description = "Whether to create the spot NodePool."
  type        = bool
  default     = true
}
