# ---------- Prometheus (scrapes Istio metrics from Envoy sidecars) ----------

resource "helm_release" "prometheus" {
  name       = "prometheus"
  namespace  = var.namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = var.prometheus_version
  wait       = true
  timeout    = 600

  values = [
    yamlencode({
      alertmanager = {
        enabled = false
      }
      kube-state-metrics = {
        enabled = false
      }
      prometheus-node-exporter = {
        enabled = false
      }
      prometheus-pushgateway = {
        enabled = false
      }
      server = {
        global = {
          scrape_interval     = "15s"
          evaluation_interval = "15s"
        }
        retention = var.prometheus_retention
        persistentVolume = {
          enabled = var.prometheus_storage_enabled
          size    = var.prometheus_storage_size
        }
        tolerations = [{
          key      = "CriticalAddonsOnly"
          operator = "Exists"
          effect   = "NoSchedule"
        }]
        resources = {
          requests = {
            cpu    = "250m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
      serverFiles = {
        "prometheus.yml" = {
          scrape_configs = [
            {
              job_name     = "kubernetes-pods-istio"
              metrics_path = "/stats/prometheus"
              kubernetes_sd_configs = [{
                role = "pod"
              }]
              relabel_configs = [
                {
                  source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
                  action        = "keep"
                  regex         = "true"
                },
                {
                  source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
                  action        = "replace"
                  target_label  = "__metrics_path__"
                  regex         = "(.+)"
                },
                {
                  source_labels = ["__address__", "__meta_kubernetes_pod_annotation_prometheus_io_port"]
                  action        = "replace"
                  regex         = "([^:]+)(?::\\d+)?;(\\d+)"
                  replacement   = "$1:$2"
                  target_label  = "__address__"
                },
                {
                  source_labels = ["__meta_kubernetes_namespace"]
                  action        = "replace"
                  target_label  = "namespace"
                },
                {
                  source_labels = ["__meta_kubernetes_pod_name"]
                  action        = "replace"
                  target_label  = "pod"
                },
              ]
            },
            {
              job_name = "istiod"
              kubernetes_sd_configs = [{
                role = "endpoints"
                namespaces = {
                  names = [var.namespace]
                }
              }]
              relabel_configs = [
                {
                  source_labels = ["__meta_kubernetes_service_name", "__meta_kubernetes_endpoint_port_name"]
                  action        = "keep"
                  regex         = "istiod;http-monitoring"
                },
              ]
            },
            {
              job_name     = "envoy-stats"
              metrics_path = "/stats/prometheus"
              kubernetes_sd_configs = [{
                role = "pod"
              }]
              relabel_configs = [
                {
                  source_labels = ["__meta_kubernetes_pod_container_port_name"]
                  action        = "keep"
                  regex         = ".*-envoy-prom"
                },
                {
                  source_labels = ["__address__", "__meta_kubernetes_pod_annotation_prometheus_io_port"]
                  action        = "replace"
                  regex         = "([^:]+)(?::\\d+)?;(\\d+)"
                  replacement   = "$1:15090"
                  target_label  = "__address__"
                },
                {
                  source_labels = ["__meta_kubernetes_namespace"]
                  action        = "replace"
                  target_label  = "namespace"
                },
                {
                  source_labels = ["__meta_kubernetes_pod_name"]
                  action        = "replace"
                  target_label  = "pod"
                },
              ]
            },
          ]
        }
      }
    })
  ]
}

# ---------- Kiali (service mesh dashboard) ----------

resource "helm_release" "kiali" {
  name       = "kiali-server"
  namespace  = var.namespace
  repository = "https://kiali.org/helm-charts"
  chart      = "kiali-server"
  version    = var.kiali_version
  wait       = true
  timeout    = 600

  values = [
    yamlencode({
      auth = {
        strategy = var.kiali_auth_strategy
      }
      deployment = {
        accessible_namespaces = ["**"]
        tolerations = [{
          key      = "CriticalAddonsOnly"
          operator = "Exists"
          effect   = "NoSchedule"
        }]
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
      }
      external_services = {
        prometheus = {
          url = "http://prometheus-server.${var.namespace}.svc.cluster.local:80"
        }
        istio = {
          root_namespace = var.namespace
          component_status = {
            enabled = true
            components = [
              { app_label = "istiod", is_core = true, namespace = var.namespace },
            ]
          }
        }
      }
      server = {
        web_fqdn = ""
      }
    })
  ]

  depends_on = [helm_release.prometheus]
}
