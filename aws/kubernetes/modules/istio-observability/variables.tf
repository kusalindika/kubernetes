variable "namespace" {
  description = "Namespace for the observability stack."
  type        = string
  default     = "istio-system"
}

variable "prometheus_version" {
  description = "Prometheus Helm chart version."
  type        = string
  default     = "27.5.0"
}

variable "kiali_version" {
  description = "Kiali Server Helm chart version."
  type        = string
  default     = "2.7.0"
}

variable "prometheus_retention" {
  description = "Prometheus data retention period."
  type        = string
  default     = "6h"
}

variable "prometheus_storage_enabled" {
  description = "Enable persistent storage for Prometheus."
  type        = bool
  default     = false
}

variable "prometheus_storage_size" {
  description = "Persistent volume size for Prometheus (when storage is enabled)."
  type        = string
  default     = "10Gi"
}

variable "kiali_auth_strategy" {
  description = "Kiali authentication strategy. Use 'anonymous' for dev, 'token' for prod."
  type        = string
  default     = "anonymous"

  validation {
    condition     = contains(["anonymous", "token", "openid", "header"], var.kiali_auth_strategy)
    error_message = "Must be 'anonymous', 'token', 'openid', or 'header'."
  }
}
