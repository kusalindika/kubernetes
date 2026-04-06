locals {
  metrics_server_chart_repository = "https://kubernetes-sigs.github.io/metrics-server/"
  critical_addons_toleration = {
    key      = "CriticalAddonsOnly"
    operator = "Exists"
    effect   = "NoSchedule"
  }
}

resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  namespace        = var.metrics_server_namespace
  create_namespace = false
  repository       = local.metrics_server_chart_repository
  chart            = "metrics-server"
  version          = var.metrics_server_chart_version
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      priorityClassName = "system-cluster-critical"
      commonLabels = {
        environment    = var.environment
        "cluster-name" = var.cluster_name
      }
      # EKS kubelets often use certs the API server does not trust; this matches common EKS guidance.
      args = [
        "--kubelet-insecure-tls",
      ]
      tolerations = [local.critical_addons_toleration]
      replicas    = var.metrics_server_replicas
    })
  ]
}
