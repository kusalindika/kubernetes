variable "namespace" {
  description = "Kubernetes namespace for the test application."
  type        = string
  default     = "test-app"
}

variable "frontend_replicas" {
  description = "Number of frontend pod replicas."
  type        = number
  default     = 2
}

variable "backend_replicas" {
  description = "Number of backend pod replicas."
  type        = number
  default     = 2
}

variable "frontend_image" {
  description = "Container image for the frontend service."
  type        = string
  default     = "nginx:1.27-alpine"
}

variable "backend_image" {
  description = "Container image for the backend service."
  type        = string
  default     = "hashicorp/http-echo:0.2.3"
}

variable "backend_message" {
  description = "Message returned by the backend http-echo service."
  type        = string
  default     = "hello from backend"
}

variable "istio_ingress_gateway_namespace" {
  description = "Namespace where the Istio Ingress Gateway is deployed."
  type        = string
  default     = "istio-ingress"
}

variable "app_hostname" {
  description = "Hostname for the Istio VirtualService. Use '*' to match any host."
  type        = string
  default     = "*"
}
