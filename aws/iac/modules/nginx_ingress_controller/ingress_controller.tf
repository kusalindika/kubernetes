resource "helm_release" "external_nginx" {
  count = var.enable_nginx_ingress_controller ? 1 : 0

  name = "external-nginx"

  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  version          = var.ingress_nginx_helm_verion
  create_namespace = true

  values = [file("${path.module}/values/nginx-ingress.yaml")]

  depends_on = [var.aws_load_balancer_controller]
}

output "external_nginx_id" {
  value = helm_release.external_nginx.*.id
}