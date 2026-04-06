output "argocd_namespace" {
  description = "Namespace where Argo CD is installed."
  value       = var.argocd_namespace
}

output "argocd_release_name" {
  description = "Helm release name of Argo CD."
  value       = helm_release.argocd.name
}

output "test_app_application_name" {
  description = "Name of the bootstrapped test-app Argo CD Application."
  value       = var.create_test_app_application ? var.test_app_application_name : ""
}

output "argocd_istio_host" {
  description = "Host name used for Argo CD Istio exposure."
  value       = var.enable_istio_ingress ? var.argocd_hostname : ""
}
