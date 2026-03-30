output "prometheus_service" {
  description = "Prometheus server service endpoint within the cluster."
  value       = "http://prometheus-server.${var.namespace}.svc.cluster.local:80"
}

output "kiali_service" {
  description = "Kiali dashboard service endpoint within the cluster."
  value       = "http://kiali-server.${var.namespace}.svc.cluster.local:20001"
}
