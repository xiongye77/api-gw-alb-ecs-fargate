resource "aws_apigatewayv2_api" "main" {
  name = "${var.name}-${var.env}"
  protocol_type = "HTTP"
  description = "Proxy entry point to ALB Backend"
  tags = var.tags
}

resource "aws_apigatewayv2_route" "main" {
  api_id = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"
  target = "integrations/${aws_apigatewayv2_integration.main.id}"
#  authorization_type = "JWT"
#  authorizer_id = aws_apigatewayv2_authorizer.main.id
}

resource "aws_apigatewayv2_integration" "main" {
  api_id = aws_apigatewayv2_api.main.id
  integration_type = "HTTP_PROXY"
  connection_id = aws_apigatewayv2_vpc_link.main.id
  connection_type = "VPC_LINK"
  integration_method = "ANY"
  integration_uri = var.alb_lister_arn
}

resource "aws_apigatewayv2_stage" "main" {
  api_id = aws_apigatewayv2_api.main.id
  name   = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.main.arn
    format = "$context.requestId $context.apiId $context.authorizer.error $context.authorizer.latency $context.authorizer.status $context.domainName $context.error.message $context.httpMethod"
  }

}

resource "aws_apigatewayv2_api_mapping" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  domain_name = aws_apigatewayv2_domain_name.main.id
  stage       = aws_apigatewayv2_stage.main.id
}



# This data source looks up the public DNS zone
data "aws_route53_zone" "public" {
  name         = "poc.csnglobal.net"
  private_zone = false
#  provider     = aws.account_route53
}



# This creates an SSL certificate
resource "aws_acm_certificate" "myapp" {
  domain_name       = "api.poc.csnglobal.net"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  provisioner "local-exec" {
    command = "sleep 120;"
  }
}

# This is a DNS record for the ACM certificate validation to prove we own the domain
#
# This example, we make an assumption that the certificate is for a single domain name so can just use the first value of the
# domain_validation_options.  It allows the terraform to apply without having to be targeted.
# This is somewhat less complex than the example at https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
# - that above example, won't apply without targeting

resource "aws_route53_record" "cert_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.myapp.domain_validation_options)[0].resource_record_name
  records         = [ tolist(aws_acm_certificate.myapp.domain_validation_options)[0].resource_record_value ]
  type            = tolist(aws_acm_certificate.myapp.domain_validation_options)[0].resource_record_type
  zone_id  = data.aws_route53_zone.public.id
  ttl      = 60
#  provider = aws.account_route53
}

# This tells terraform to cause the route53 validation to happen
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.myapp.arn
  validation_record_fqdns = [ aws_route53_record.cert_validation.fqdn ]

  provisioner "local-exec" {
    command = "sleep 120;"
  }

}





#resource "aws_apigatewayv2_authorizer" "main" {
#  api_id           = aws_apigatewayv2_api.main.id
#  authorizer_type  = "JWT"
#  identity_sources = ["$request.header.Authorization"]
#  name = "cognito-authorizer-${var.env}"
#
#  jwt_configuration {
#    audience = [var.client_id]
#    issuer   = "https://cognito-idp.ap-southeast-2.amazonaws.com/${var.user_pool_id}"
#  }
#}



resource "aws_apigatewayv2_domain_name" "main" {
   provisioner "local-exec" {
    command = "sleep 120;"
  }

  domain_name = "api.${var.route53_domain}"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.myapp.arn
    #certificate_arn = data.aws_acm_certificate.issued.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
  depends_on = [aws_acm_certificate_validation.cert]
}

resource "aws_route53_record" "main" {
  name    = aws_apigatewayv2_domain_name.main.domain_name
  #type    = "A"
  type = "CNAME"
  ttl=  300
  zone_id = data.aws_route53_zone.wamly-hosted-zone.id

  records = [aws_apigatewayv2_domain_name.main.domain_name_configuration[0].target_domain_name]
  #alias {
  #  name                   = aws_apigatewayv2_domain_name.main.domain_name_configuration[0].target_domain_name
  #  zone_id                = aws_apigatewayv2_domain_name.main.domain_name_configuration[0].hosted_zone_id
  #  evaluate_target_health = false
  #}
}

