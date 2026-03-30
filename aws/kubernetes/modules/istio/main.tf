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

# ---------- Security group rules for ALB -> Istio Gateway pods ----------
# The ALB (in public subnets) sends traffic directly to pod IPs (in private
# subnets) because target-type is "ip". The EKS primary security group must
# allow inbound from the VPC CIDR on the gateway's data port and health check
# port, otherwise health checks time out.

resource "aws_security_group_rule" "alb_to_gateway_traffic" {
  count = var.enable_ingress_gateway ? 1 : 0

  description       = "ALB to Istio gateway traffic (port 80)"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = var.cluster_primary_security_group_id
}

resource "aws_security_group_rule" "alb_to_gateway_healthcheck" {
  count = var.enable_ingress_gateway ? 1 : 0

  description       = "ALB health check to Istio gateway (port 15021)"
  type              = "ingress"
  from_port         = 15021
  to_port           = 15021
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = var.cluster_primary_security_group_id
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
        accessLogFile         = var.enable_access_log ? "/dev/stdout" : ""
        enableAutoMtls        = var.mtls_mode != "DISABLE"
        enablePrometheusMerge = true
        defaultConfig = {
          holdApplicationUntilProxyStarts = true
          gatewayTopology = {
            numTrustedProxies = 1
          }
          proxyStatsMatcher = {
            inclusionRegexps = [
              ".*circuit_breakers.*",
              ".*upstream_rq_retry.*",
              ".*upstream_cx_.*",
            ]
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

# ---------- Istio Ingress Gateway (ClusterIP — fronted by ALB) ----------

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
        type = "ClusterIP"
      }
    })
  ]

  depends_on = [helm_release.istiod]
}

# ---------- ALB Ingress for Istio Gateway ----------
# The AWS Load Balancer Controller watches this Ingress resource
# and provisions an Application Load Balancer that routes to
# the Istio Ingress Gateway pods via IP-mode target groups.

resource "kubernetes_ingress_v1" "istio_alb" {
  count = var.enable_ingress_gateway ? 1 : 0

  metadata {
    name      = "istio-ingress-alb"
    namespace = helm_release.istio_ingress[0].namespace

    annotations = merge(
      {
        "alb.ingress.kubernetes.io/scheme"           = var.ingress_gateway_lb_scheme
        "alb.ingress.kubernetes.io/target-type"      = "ip"
        "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
        "alb.ingress.kubernetes.io/healthcheck-path" = "/healthz/ready"
        "alb.ingress.kubernetes.io/healthcheck-port" = "15021"
      },
      var.alb_certificate_arn != "" ? {
        "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\":80},{\"HTTPS\":443}]"
        "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
        "alb.ingress.kubernetes.io/certificate-arn" = var.alb_certificate_arn
        "alb.ingress.kubernetes.io/ssl-policy"      = var.alb_ssl_policy
        } : {
        "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\":80}]"
      },
      var.alb_waf_acl_arn != "" ? {
        "alb.ingress.kubernetes.io/wafv2-acl-arn" = var.alb_waf_acl_arn
      } : {},
      var.alb_extra_annotations,
    )
  }

  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "istio-ingress"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.istio_ingress]
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
