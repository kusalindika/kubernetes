variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, stage, prod)."
  type        = string
}

variable "argocd_namespace" {
  description = "Namespace where Argo CD is installed."
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version."
  type        = string
  default     = "7.7.16"
}

variable "create_test_app_application" {
  description = "Whether to bootstrap a test-app Argo CD Application."
  type        = bool
  default     = true
}

variable "test_app_application_name" {
  description = "Name of the Argo CD Application for test-app."
  type        = string
  default     = "test-app"
}

variable "test_app_namespace" {
  description = "Destination namespace for the test-app workload."
  type        = string
  default     = "test-app"
}

variable "test_app_repo_url" {
  description = "Git repository URL containing test-app manifests."
  type        = string
}

variable "test_app_target_revision" {
  description = "Git revision Argo CD tracks for test-app."
  type        = string
  default     = "main"
}

variable "test_app_path" {
  description = "Path in repository where test-app manifests live."
  type        = string
  default     = "aws/kubernetes/apps/test-app"
}

variable "test_app_hostname" {
  description = "Hostname used by the test-app Istio VirtualService."
  type        = string
  default     = "*"
}

variable "test_app_create_gateway" {
  description = "Whether the test-app Helm chart should create its own Istio Gateway."
  type        = bool
  default     = true
}

variable "test_app_gateway_name" {
  description = "Name of the Istio Gateway used by test-app."
  type        = string
  default     = "test-app-gateway"
}

variable "test_app_gateway_namespace" {
  description = "Namespace where the test-app Istio Gateway lives."
  type        = string
  default     = ""
}

variable "enable_istio_ingress" {
  description = "Whether to expose Argo CD through an Istio Gateway and VirtualService."
  type        = bool
  default     = false
}

variable "argocd_hostname" {
  description = "Host name used by Istio Gateway/VirtualService for Argo CD."
  type        = string
  default     = "argocd.dev.example.com"
}

variable "argocd_base_path" {
  description = "Base URI path used to expose Argo CD via Istio (for example: /argocd)."
  type        = string
  default     = "/argocd"
}

variable "enable_istio_sidecar_injection" {
  description = "Whether to label the Argo CD namespace for Istio sidecar injection."
  type        = bool
  default     = false
}
