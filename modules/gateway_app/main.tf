
resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_deployment" "this" {
  metadata {
    name      = "gateway-proxy"
    namespace = var.namespace
    labels    = { app = "gateway-proxy" }
  }

  spec {
    replicas = 2
    selector {
      match_labels = { app = "gateway-proxy" }
    }
    template {
      metadata {
        labels = { app = "gateway-proxy" }
      }
      spec {
        container {
          name  = "nginx"
          image = "nginx:1.25"

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/conf.d"
          }

          port {
            container_port = 80
          }
        }

        volume {
          name = "nginx-config"

          config_map {
            name = kubernetes_config_map.nginx.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map" "nginx" {
  metadata {
    name      = "nginx-config"
    namespace = var.namespace
  }

  data = {
    "default.conf" = <<-EOT
      server {
        listen 80;
        location / {
          proxy_pass http://${var.backend_dns};
        }
      }
    EOT
  }
}

resource "kubernetes_service" "this" {
  metadata {
    name      = "gateway-proxy"
    namespace = var.namespace
  }

  spec {
    selector = { app = "gateway-proxy" }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}


resource "kubernetes_ingress_v1" "this" {
  metadata {
    name      = "gateway-proxy-ingress"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class"           = "alb"
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"  # or "internal"
      "alb.ingress.kubernetes.io/target-type" = "ip"                # or "instance"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.this.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

/*
data "external" "alb_dns" {
  program = [
    "bash",
    "-c",
    <<-EOT
      LB_DNS_NAME=$(aws elbv2 describe-load-balancers \
        --query "LoadBalancers[?Scheme=='internet-facing'].DNSName" \
        --region eu-west-2 \
        --output text)
      
      # Check if a DNS name was returned
      if [ -z "$LB_DNS_NAME" ]; then
        echo '{"url": ""}'
      else
        echo '{"url": "'"$LB_DNS_NAME"'"}'
      fi
    EOT
  ]
}

output "gateway_lb_dns" {
  description = "The DNS name of the internet-facing Application Load Balancer."
  value       = data.external.alb_dns.result.url
}
*/
/*
output "gateway_lb_dns" {
  #  value = kubernetes_ingress_v1.this.status[0].load_balancer[0].ingress[0].hostname
  value = try(kubernetes_ingress_v1.this.status[0].load_balancer[0].ingress[0].hostname,"pending")
}
*/
