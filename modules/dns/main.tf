resource "aws_route53_zone" "this" {
  name = var.zone_name
  dynamic "vpc" {
    for_each = var.vpc_ids
    content {
      vpc_id = vpc.value
    }
  }
}


resource "aws_route53_record" "backend" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "${var.record_name}.${var.zone_name}"
  type    = "CNAME"
  ttl     = 60
  records = [var.backend_alb_dns]
}

output "backend_fqdn" {
  value = aws_route53_record.backend.fqdn
}

