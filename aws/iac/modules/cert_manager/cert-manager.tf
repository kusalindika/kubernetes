resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_helm_version
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [var.nginx_ingress_controller]
}

# ClusterIssuer using HTTP01 challenge
resource "kubernetes_manifest" "cluster_issuer" {
  manifest = yamldecode(file("${path.module}/cluster_issuer.yaml"))

  depends_on = [helm_release.cert_manager]
}