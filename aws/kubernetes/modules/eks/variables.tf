variable "name_prefix" {
  description = "Prefix used for naming resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, stage, prod)."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.35"
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the cluster and node groups."
  type        = list(string)
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public Kubernetes API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_log_types" {
  description = "EKS control-plane log types to enable."
  type        = list(string)
  default     = ["api", "authenticator"]
}

variable "admin_principal_arns" {
  description = "IAM principal ARNs granted AmazonEKSClusterAdminPolicy via access entries."
  type        = list(string)
  default     = []
}

variable "system_node_instance_types" {
  description = "Instance types for the system managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "system_node_desired" {
  description = "Desired number of nodes in the system node group."
  type        = number
  default     = 2
}

variable "system_node_min" {
  description = "Minimum number of nodes in the system node group."
  type        = number
  default     = 1
}

variable "system_node_max" {
  description = "Maximum number of nodes in the system node group."
  type        = number
  default     = 3
}
