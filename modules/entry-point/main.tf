terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [aws, aws.acm]
    }
  }
}

resource "aws_acm_certificate" "this" {
  provider = aws.acm
  domain_name       = var.domain_name
  validation_method = "DNS"
}

data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "this" {
  provider = aws.acm

  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  provider = aws.acm
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.this : record.fqdn]
}

module "cdn" {
  source = "cloudposse/cloudfront-cdn/aws"
  version     = "0.26.0"
  context = module.this.context
  aliases = [var.domain_name]
  origin_domain_name = var.ec2_public_dns
  parent_zone_name = var.domain_name
  acm_certificate_arn = aws_acm_certificate.this.arn
  logging_enabled = false
  origin_protocol_policy = "http-only"
  origin_http_port = 5000
  forward_query_string = true
  min_ttl = 0
  default_ttl = 0
  max_ttl = 0
  response_headers_policy_id = "eaab4381-ed33-4a86-88ca-d9558dc6cd63"  # CORS with Preflight + Security Headers
}
