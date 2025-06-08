resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_helm_version
  namespace        = "cert-manager"
  create_namespace = true
  wait_for_jobs = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [var.nginx_ingress_controller]
}

# Below CRD is need to apply manually as the helm chart does not create it automatically.

# resource "null_resource" "wait_for_cert_manager_crds" {
#   depends_on = [helm_release.cert_manager]

#   provisioner "local-exec" {
#     command = "kubectl wait --for=condition=Established --timeout=120s crd/clusterissuers.cert-manager.io || true"
#   }
# }

# # ClusterIssuer using HTTP01 challenge
# resource "kubernetes_manifest" "cluster_issuer" {
#   manifest = yamldecode(file("${path.module}/cluster_issuer.yaml"))
#   depends_on = [
#     null_resource.wait_for_cert_manager_crds,
#     helm_release.cert_manager
#   ]
# }