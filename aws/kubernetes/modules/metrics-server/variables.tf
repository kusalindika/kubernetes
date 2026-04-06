variable "cluster_name" {
  description = "Name of the EKS cluster (used for labels)."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, stage, prod)."
  type        = string
}

variable "metrics_server_chart_version" {
  description = "metrics-server Helm chart version (https://artifacthub.io/packages/helm/metrics-server/metrics-server)."
  type        = string
  default     = "3.13.0"
}

variable "metrics_server_namespace" {
  description = "Kubernetes namespace for metrics-server (typically kube-system)."
  type        = string
  default     = "kube-system"
}

variable "metrics_server_replicas" {
  description = "Number of metrics-server replicas."
  type        = number
  default     = 1
}
