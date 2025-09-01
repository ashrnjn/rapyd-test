
resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_deployment" "this" {
  metadata {
    name      = "hello-backend"
    namespace = var.namespace
    labels    = { app = "hello-backend" }
  }

  spec {
    replicas = 2

    selector {
      match_labels = { app = "hello-backend" }
    }

    template {
      metadata {
        labels = { app = "hello-backend" }
      }

      spec {
        container {
          name  = "app"
          image = var.app_image

          args = ["-text=${var.app_text}", "-listen=:8080"]

          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "this" {
  metadata {
    name      = "hello-backend"
    namespace = var.namespace
  }

  spec {
    selector = { app = "hello-backend" }

    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "this" {
  metadata {
    name      = "hello-backend"
    namespace = var.namespace
    annotations = {
      # "kubernetes.io/ingress.class"                 = "alb"
      "alb.ingress.kubernetes.io/scheme"            = "internal"
      "alb.ingress.kubernetes.io/target-type"       = "ip"
      #"alb.ingress.kubernetes.io/security-groups"   = var.alb_sg_id
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path     = "/"
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
  wait_for_load_balancer = true
}


/*resource "null_resource" "wait_for_ingress" {
  provisioner "local-exec" {
    command = "sleep 120"
  }

  depends_on = [kubernetes_ingress_v1.this]
}*/

data "external" "alb_dns" {
  program = [
    "bash",
    "-c",
    <<-EOT
      LB_DNS_NAME=$(aws elbv2 describe-load-balancers \
        --query "LoadBalancers[?Scheme=='internal'].DNSName" \
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

output "ingress_hostname" {  
  # depends_on = [null_resource.wait_for_ingress] 
  # depends_on = [kubernetes_ingress_v1.this]
   # value = try(kubernetes_ingress_v1.this.status[0].load_balancer[0].ingress[0].hostname,"pending")
  value = data.external.alb_dns.result.url
 }

