# ---------- Namespace (Istio sidecar injection enabled) ----------

resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace

    labels = {
      "istio-injection" = "enabled"
    }
  }
}

# ---------- Backend: http-echo service ----------

resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.this.metadata[0].name

    labels = {
      app     = "backend"
      version = "v1"
    }
  }

  spec {
    replicas = var.backend_replicas

    selector {
      match_labels = {
        app = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app     = "backend"
          version = "v1"
        }
      }

      spec {
        container {
          name  = "backend"
          image = var.backend_image

          args = ["-text=${var.backend_message}", "-listen=:8080"]

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "32Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "64Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 15
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.this.metadata[0].name

    labels = {
      app = "backend"
    }
  }

  spec {
    selector = {
      app = "backend"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
  }
}

# ---------- Frontend: nginx reverse-proxying to backend ----------

resource "kubernetes_config_map" "frontend_nginx" {
  metadata {
    name      = "frontend-nginx-config"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    "default.conf" = <<-NGINX
      server {
          listen 80;
          server_name _;

          location / {
              root   /usr/share/nginx/html;
              index  index.html;
          }

          location /api {
              proxy_pass http://backend.${var.namespace}.svc.cluster.local;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          }

          location /health {
              access_log off;
              return 200 'ok';
              add_header Content-Type text/plain;
          }
      }
    NGINX
  }
}

resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.this.metadata[0].name

    labels = {
      app     = "frontend"
      version = "v1"
    }
  }

  spec {
    replicas = var.frontend_replicas

    selector {
      match_labels = {
        app = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app     = "frontend"
          version = "v1"
        }
      }

      spec {
        container {
          name  = "frontend"
          image = var.frontend_image

          port {
            name           = "http"
            container_port = 80
            protocol       = "TCP"
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "32Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "64Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 15
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/conf.d"
            read_only  = true
          }
        }

        volume {
          name = "nginx-config"

          config_map {
            name = kubernetes_config_map.frontend_nginx.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.this.metadata[0].name

    labels = {
      app = "frontend"
    }
  }

  spec {
    selector = {
      app = "frontend"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
  }
}
