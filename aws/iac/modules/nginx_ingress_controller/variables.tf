variable "eks_name" {
  description = "The name of the EKS cluster"
  type        = string
  
}
variable "enable_nginx_ingress_controller" {
  description = "Enable the Nginx Ingress Controller"
  type        = bool
  default     = false
}

variable "ingress_nginx_helm_verion" {
  description = "The version of the Nginx Ingress Controller Helm chart to install"
  type        = string
  default     = "4.12.0"
  
}

variable "aws_load_balancer_controller" {
  description = "The AWS Load Balancer Controller Helm chart to install"
  type        = string
  default     = "helm_release.aws_load_balancer_controller"
  
}