variable "enable_argocd" {
  description = "Enable ArgoCD"
  type        = bool
  default     = false
}

variable "argocd_helm_version" {
  description = "The version of the ArgoCD Helm chart to install"
  type        = string
  default     = "8.0.9"

}

variable "nginx_ingress_controller" {
  description = "The Nginx Ingress Controller Helm chart to install"
  type        = string
  default     = "helm_release.external_nginx"

}

variable "cert_manager" {
  description = "The Cert Manager Helm chart to install"
  type        = string
  default     = "helm_release.cert_manager"
}
