# ---------- Istio Gateway ----------
# Binds to the Istio Ingress Gateway workload in the istio-ingress namespace.
# The ALB routes traffic to the gateway pods, which then use this
# Gateway resource to accept traffic on port 80.

resource "kubectl_manifest" "gateway" {
  yaml_body = yamlencode({
    apiVersion = "networking.istio.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "test-app-gateway"
      namespace = kubernetes_namespace.this.metadata[0].name
    }
    spec = {
      selector = {
        istio = "ingressgateway"
      }
      servers = [{
        port = {
          number   = 80
          name     = "http"
          protocol = "HTTP"
        }
        hosts = [var.app_hostname]
      }]
    }
  })

  depends_on = [
    kubernetes_namespace.this,
  ]
}

# ---------- VirtualService ----------
# Routes incoming HTTP traffic through the Istio Gateway:
#   /api/* -> backend service
#   /*     -> frontend service

resource "kubectl_manifest" "virtualservice" {
  yaml_body = yamlencode({
    apiVersion = "networking.istio.io/v1"
    kind       = "VirtualService"
    metadata = {
      name      = "test-app-routes"
      namespace = kubernetes_namespace.this.metadata[0].name
    }
    spec = {
      hosts    = [var.app_hostname]
      gateways = ["test-app-gateway"]
      http = [
        {
          name = "backend-api"
          match = [{
            uri = {
              prefix = "/api"
            }
          }]
          rewrite = {
            uri = "/"
          }
          route = [{
            destination = {
              host = "backend.${var.namespace}.svc.cluster.local"
              port = {
                number = 80
              }
            }
          }]
          timeout = "10s"
          retries = {
            attempts      = 3
            perTryTimeout = "3s"
            retryOn       = "5xx,reset,connect-failure"
          }
        },
        {
          name = "frontend-default"
          route = [{
            destination = {
              host = "frontend.${var.namespace}.svc.cluster.local"
              port = {
                number = 80
              }
            }
          }]
        },
      ]
    }
  })

  depends_on = [kubectl_manifest.gateway]
}

# ---------- DestinationRule: backend ----------
# Connection pool limits and outlier detection for the backend service.

resource "kubectl_manifest" "destination_rule_backend" {
  yaml_body = yamlencode({
    apiVersion = "networking.istio.io/v1"
    kind       = "DestinationRule"
    metadata = {
      name      = "backend"
      namespace = kubernetes_namespace.this.metadata[0].name
    }
    spec = {
      host = "backend.${var.namespace}.svc.cluster.local"
      trafficPolicy = {
        connectionPool = {
          tcp = {
            maxConnections = 100
          }
          http = {
            h2UpgradePolicy         = "DEFAULT"
            http1MaxPendingRequests = 100
            http2MaxRequests        = 1000
          }
        }
        outlierDetection = {
          consecutive5xxErrors = 5
          interval             = "30s"
          baseEjectionTime     = "30s"
          maxEjectionPercent   = 50
        }
      }
    }
  })

  depends_on = [kubernetes_service.backend]
}

# ---------- DestinationRule: frontend ----------

resource "kubectl_manifest" "destination_rule_frontend" {
  yaml_body = yamlencode({
    apiVersion = "networking.istio.io/v1"
    kind       = "DestinationRule"
    metadata = {
      name      = "frontend"
      namespace = kubernetes_namespace.this.metadata[0].name
    }
    spec = {
      host = "frontend.${var.namespace}.svc.cluster.local"
      trafficPolicy = {
        connectionPool = {
          tcp = {
            maxConnections = 100
          }
          http = {
            h2UpgradePolicy         = "DEFAULT"
            http1MaxPendingRequests = 100
            http2MaxRequests        = 1000
          }
        }
        outlierDetection = {
          consecutive5xxErrors = 5
          interval             = "30s"
          baseEjectionTime     = "30s"
          maxEjectionPercent   = 50
        }
      }
    }
  })

  depends_on = [kubernetes_service.frontend]
}

# ---------- PeerAuthentication: STRICT mTLS for the namespace ----------
# All pod-to-pod traffic within the test-app namespace must use mTLS.

resource "kubectl_manifest" "peer_authentication" {
  yaml_body = yamlencode({
    apiVersion = "security.istio.io/v1"
    kind       = "PeerAuthentication"
    metadata = {
      name      = "default"
      namespace = kubernetes_namespace.this.metadata[0].name
    }
    spec = {
      mtls = {
        mode = "STRICT"
      }
    }
  })

  depends_on = [kubernetes_namespace.this]
}

# ---------- AuthorizationPolicy: backend access ----------
# Only allow the frontend service account to call the backend.
# The Istio ingress gateway is also allowed (for the /api path routing).

resource "kubectl_manifest" "authz_backend" {
  yaml_body = yamlencode({
    apiVersion = "security.istio.io/v1"
    kind       = "AuthorizationPolicy"
    metadata = {
      name      = "backend-allow-frontend-only"
      namespace = kubernetes_namespace.this.metadata[0].name
    }
    spec = {
      selector = {
        matchLabels = {
          app = "backend"
        }
      }
      action = "ALLOW"
      rules = [{
        from = [{
          source = {
            principals = [
              "cluster.local/ns/${var.namespace}/sa/default",
              "cluster.local/ns/${var.istio_ingress_gateway_namespace}/sa/istio-ingress",
            ]
          }
        }]
        to = [{
          operation = {
            methods = ["GET", "POST", "HEAD", "OPTIONS"]
          }
        }]
      }]
    }
  })

  depends_on = [kubernetes_namespace.this]
}

# ---------- ServiceEntry: controlled egress ----------
# Allow pods in the mesh to reach httpbin.org (for testing external access).
# Without this, STRICT mesh mode + REGISTRY_ONLY would block external traffic.

resource "kubectl_manifest" "service_entry_httpbin" {
  yaml_body = yamlencode({
    apiVersion = "networking.istio.io/v1"
    kind       = "ServiceEntry"
    metadata = {
      name      = "allow-httpbin"
      namespace = kubernetes_namespace.this.metadata[0].name
    }
    spec = {
      hosts    = ["httpbin.org"]
      location = "MESH_EXTERNAL"
      ports = [{
        number   = 443
        name     = "https"
        protocol = "TLS"
      }]
      resolution = "DNS"
    }
  })

  depends_on = [kubernetes_namespace.this]
}
