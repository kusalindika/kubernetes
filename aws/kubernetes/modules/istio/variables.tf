variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, stage, prod)."
  type        = string
}

variable "cluster_security_group_id" {
  description = "ID of the additional cluster security group (node SG where ingress rules are added)."
  type        = string
}

variable "cluster_primary_security_group_id" {
  description = "EKS-managed primary cluster security group ID (source for SG rules)."
  type        = string
}

variable "istio_version" {
  description = "Istio Helm chart version."
  type        = string
  default     = "1.26.0"
}

variable "enable_ingress_gateway" {
  description = "Whether to deploy the Istio Ingress Gateway."
  type        = bool
  default     = true
}

variable "ingress_gateway_lb_scheme" {
  description = "ALB scheme for the ingress gateway (internet-facing or internal)."
  type        = string
  default     = "internet-facing"

  validation {
    condition     = contains(["internet-facing", "internal"], var.ingress_gateway_lb_scheme)
    error_message = "Must be 'internet-facing' or 'internal'."
  }
}

variable "enable_egress_gateway" {
  description = "Whether to deploy the Istio Egress Gateway."
  type        = bool
  default     = true
}

variable "mtls_mode" {
  description = "Istio mesh-wide mTLS mode (STRICT, PERMISSIVE, DISABLE)."
  type        = string
  default     = "STRICT"

  validation {
    condition     = contains(["STRICT", "PERMISSIVE", "DISABLE"], var.mtls_mode)
    error_message = "Must be 'STRICT', 'PERMISSIVE', or 'DISABLE'."
  }
}

variable "enable_access_log" {
  description = "Whether to enable Envoy access logging to stdout."
  type        = bool
  default     = true
}

variable "istiod_resources" {
  description = "Resource requests and limits for the Istiod control plane."
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
  })
  default = {
    requests_cpu    = "250m"
    requests_memory = "256Mi"
    limits_cpu      = "500m"
    limits_memory   = "512Mi"
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block. Used to allow ALB health checks and traffic to reach Istio gateway pods."
  type        = string
}

# ---------- ALB configuration ----------

variable "alb_certificate_arn" {
  description = "ACM certificate ARN for HTTPS on the ALB. Leave empty to use HTTP only."
  type        = string
  default     = ""
}

variable "alb_ssl_policy" {
  description = "SSL negotiation policy for the ALB HTTPS listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "alb_waf_acl_arn" {
  description = "WAFv2 Web ACL ARN to associate with the ALB. Leave empty to skip."
  type        = string
  default     = ""
}

variable "alb_extra_annotations" {
  description = "Additional annotations to merge into the ALB Ingress resource."
  type        = map(string)
  default     = {}
}
