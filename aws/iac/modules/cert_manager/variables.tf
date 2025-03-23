variable "cert_manager_helm_version" {
  description = "The version of the cert-manager Helm chart to install"
  type        = string
}

variable "nginx_ingress_controller" {
  description = "The Helm release of the nginx ingress controller to depend on"
  type        = any

}

variable "enable_cert_manager" {
  description = "Whether to enable cert-manager"
  type        = bool

}

variable "eks_name" {
  description = "The name of the EKS cluster"
  type        = string
}