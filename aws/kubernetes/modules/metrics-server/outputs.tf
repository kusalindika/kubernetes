output "metrics_server_chart_version" {
  description = "Installed metrics-server Helm chart version."
  value       = helm_release.metrics_server.version
}

output "metrics_server_namespace" {
  description = "Namespace where metrics-server is installed."
  value       = helm_release.metrics_server.namespace
}

output "metrics_server_release_name" {
  description = "Helm release name for metrics-server."
  value       = helm_release.metrics_server.name
}
