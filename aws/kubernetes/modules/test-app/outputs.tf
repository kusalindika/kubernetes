output "namespace" {
  description = "Namespace where the test application is deployed."
  value       = kubernetes_namespace.this.metadata[0].name
}

output "frontend_service" {
  description = "Frontend service name."
  value       = kubernetes_service.frontend.metadata[0].name
}

output "backend_service" {
  description = "Backend service name."
  value       = kubernetes_service.backend.metadata[0].name
}
