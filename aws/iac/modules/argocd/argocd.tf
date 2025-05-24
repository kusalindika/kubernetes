resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_helm_version
  create_namespace = true
  name             = "argocd"
  namespace        = "argocd"

  depends_on = [
    var.nginx_ingress_controller,
    var.cert_manager
  ]

  values = [
    file("${path.module}/values/argocd.yaml")
  ]
}

output "argocd_id" {
  value = helm_release.argocd.*.id
}
