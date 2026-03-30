locals {
  istio_chart_repository = "https://istio-release.storage.googleapis.com/charts"
}

# ---------- Security group rules for Istio ----------
# Allow the EKS control plane to reach Istiod webhook (sidecar injector)
# and xDS/CA endpoints on worker nodes.

resource "aws_security_group_rule" "istio_webhook" {
  description              = "Cluster API to Istio sidecar injector webhook"
  type                     = "ingress"
  from_port                = 15017
  to_port                  = 15017
  protocol                 = "tcp"
  source_security_group_id = var.cluster_primary_security_group_id
  security_group_id        = var.cluster_security_group_id
}

resource "aws_security_group_rule" "istio_xds" {
  description              = "Cluster API to Istiod xDS and CA"
  type                     = "ingress"
  from_port                = 15012
  to_port                  = 15012
  protocol                 = "tcp"
  source_security_group_id = var.cluster_primary_security_group_id
  security_group_id        = var.cluster_security_group_id
}

# ---------- Istio Base (CRDs) ----------

resource "helm_release" "istio_base" {
  name             = "istio-base"
  namespace        = "istio-system"
  create_namespace = true
  repository       = local.istio_chart_repository
  chart            = "base"
  version          = var.istio_version
  wait             = true
  timeout          = 300

  depends_on = [
    aws_security_group_rule.istio_webhook,
    aws_security_group_rule.istio_xds,
  ]
}

# ---------- Istiod (Control Plane) ----------

resource "helm_release" "istiod" {
  name       = "istiod"
  namespace  = helm_release.istio_base.namespace
  repository = local.istio_chart_repository
  chart      = "istiod"
  version    = var.istio_version
  wait       = true
  timeout    = 600

  values = [
    yamlencode({
      meshConfig = {
        accessLogFile = var.enable_access_log ? "/dev/stdout" : ""
        enableAutoMtls = var.mtls_mode != "DISABLE"
        defaultConfig = {
          holdApplicationUntilProxyStarts = true
          gatewayTopology = {
            numTrustedProxies = 1
          }
        }
      }
      pilot = {
        resources = {
          requests = {
            cpu    = var.istiod_resources.requests_cpu
            memory = var.istiod_resources.requests_memory
          }
          limits = {
            cpu    = var.istiod_resources.limits_cpu
            memory = var.istiod_resources.limits_memory
          }
        }
      }
      global = {
        proxy = {
          resources = {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    })
  ]

  depends_on = [helm_release.istio_base]
}

# ---------- Istio Ingress Gateway ----------

resource "helm_release" "istio_ingress" {
  count = var.enable_ingress_gateway ? 1 : 0

  name             = "istio-ingress"
  namespace        = "istio-ingress"
  create_namespace = true
  repository       = local.istio_chart_repository
  chart            = "gateway"
  version          = var.istio_version
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      labels = {
        istio = "ingressgateway"
      }
      service = {
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
          "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
          "service.beta.kubernetes.io/aws-load-balancer-scheme"          = var.ingress_gateway_lb_scheme
          "service.beta.kubernetes.io/aws-load-balancer-attributes"      = "load_balancing.cross_zone.enabled=true"
        }
      }
    })
  ]

  depends_on = [helm_release.istiod]
}

# ---------- Istio Egress Gateway ----------

resource "helm_release" "istio_egress" {
  count = var.enable_egress_gateway ? 1 : 0

  name             = "istio-egress"
  namespace        = "istio-egress"
  create_namespace = true
  repository       = local.istio_chart_repository
  chart            = "gateway"
  version          = var.istio_version
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      labels = {
        istio = "egressgateway"
      }
      service = {
        type = "ClusterIP"
      }
    })
  ]

  depends_on = [helm_release.istiod]
}
