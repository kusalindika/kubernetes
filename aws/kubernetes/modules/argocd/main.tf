locals {
  argocd_chart_repository = "https://argoproj.github.io/argo-helm"
  critical_addons_toleration = {
    key      = "CriticalAddonsOnly"
    operator = "Exists"
  }
}

resource "kubectl_manifest" "argocd_namespace" {
  count = var.enable_istio_sidecar_injection ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = var.argocd_namespace
      labels = {
        istio-injection = "enabled"
      }
    }
  })
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = var.argocd_namespace
  create_namespace = true
  repository       = local.argocd_chart_repository
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  wait             = true
  timeout          = 900

  values = [
    yamlencode({
      crds = {
        install = true
      }
      configs = {
        params = {
          "server.insecure" = true
          "server.basehref" = var.argocd_base_path
          "server.rootpath" = var.argocd_base_path
        }
      }
      controller = {
        tolerations = [local.critical_addons_toleration]
      }
      repoServer = {
        tolerations = [local.critical_addons_toleration]
      }
      server = {
        tolerations = [local.critical_addons_toleration]
        service = {
          type = "ClusterIP"
        }
      }
      applicationSet = {
        tolerations = [local.critical_addons_toleration]
      }
      redis = {
        tolerations = [local.critical_addons_toleration]
      }
    })
  ]

  depends_on = [kubectl_manifest.argocd_namespace]
}

resource "kubectl_manifest" "test_app_application" {
  count = var.create_test_app_application ? 1 : 0
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.test_app_application_name
      namespace = var.argocd_namespace
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.test_app_repo_url
        targetRevision = var.test_app_target_revision
        path           = var.test_app_path
        helm = {
          valuesObject = {
            istio = {
              enabled = true
              gateway = {
                create    = var.test_app_create_gateway
                name      = var.test_app_gateway_name
                namespace = var.test_app_gateway_namespace
                servers = [{
                  port = {
                    number   = 80
                    name     = "http"
                    protocol = "HTTP"
                  }
                  hosts = [var.test_app_hostname]
                }]
              }
              virtualService = {
                hosts = [var.test_app_hostname]
                gateways = var.test_app_create_gateway ? [] : compact([
                  trimspace(var.test_app_gateway_namespace) != "" ? "${var.test_app_gateway_namespace}/${var.test_app_gateway_name}" : var.test_app_gateway_name
                ])
              }
            }
          }
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.test_app_namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  })

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_gateway" {
  count = var.enable_istio_ingress ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "networking.istio.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "argocd-gateway"
      namespace = var.argocd_namespace
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
        hosts = [var.argocd_hostname]
      }]
    }
  })

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_virtualservice" {
  count = var.enable_istio_ingress ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "networking.istio.io/v1"
    kind       = "VirtualService"
    metadata = {
      name      = "argocd-routes"
      namespace = var.argocd_namespace
    }
    spec = {
      hosts    = [var.argocd_hostname]
      gateways = ["argocd-gateway"]
      http = [{
        name = "argocd-server"
        match = [{
          uri = {
            prefix = var.argocd_base_path
          }
        }]
        route = [{
          destination = {
            host = "argocd-server.${var.argocd_namespace}.svc.cluster.local"
            port = {
              number = 80
            }
          }
        }]
      }]
    }
  })

  depends_on = [kubectl_manifest.argocd_gateway]
}
