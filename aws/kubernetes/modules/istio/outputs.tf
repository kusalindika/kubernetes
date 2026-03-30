output "istiod_version" {
  description = "Installed Istio chart version."
  value       = helm_release.istiod.version
}

output "istio_namespace" {
  description = "Namespace where Istiod control plane is installed."
  value       = helm_release.istiod.namespace
}

output "ingress_gateway_namespace" {
  description = "Namespace of the Istio Ingress Gateway. Empty when disabled."
  value       = var.enable_ingress_gateway ? helm_release.istio_ingress[0].namespace : ""
}

output "egress_gateway_namespace" {
  description = "Namespace of the Istio Egress Gateway. Empty when disabled."
  value       = var.enable_egress_gateway ? helm_release.istio_egress[0].namespace : ""
}

output "alb_ingress_name" {
  description = "Name of the Kubernetes Ingress resource that provisions the ALB. Empty when disabled."
  value       = var.enable_ingress_gateway ? kubernetes_ingress_v1.istio_alb[0].metadata[0].name : ""
}
