data "aws_cloudfront_origin_request_policy" "this" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_cache_policy" "this" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "distribution" {
  #origin {
    #domain_name = "${var.api_id}.execute-api.ap-southeast-2.amazonaws.com"
    #origin_id   = "${var.api_id}.execute-api.ap-southeast-2.amazonaws.com"
  #  domain_name = replace(var.api_endpoint, "/^https?://([^/]*).*/", "$1")
  #  origin_id   = "rk5rw6lgu0"
  #  custom_origin_config {
  #    https_port = 443
  #    http_port = 80
  #    origin_protocol_policy = "https-only"
  #    origin_ssl_protocols = ["TLSv1.2"]
  #  }
  #}

  provisioner "local-exec" {
    command = "echo ${var.api_endpoint} >> debug.txt ;"
  }
  origin {
    domain_name = replace(var.api_endpoint, "/^https?://([^/]*).*/", "$1")
    origin_id   = replace(var.api_endpoint, "/^https?://([^/]*).*/", "$1")
    origin_path = ""

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
   }

   origin {
    domain_name = aws_s3_bucket.www_bucket.website_endpoint
    origin_id = "S3-www.test123456789"

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  enabled = true
  #aliases   = ["${var.demo_dns_name}.${data.aws_route53_zone.public.name}"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id     = replace(var.api_endpoint, "/^https?://([^/]*).*/", "$1")

    forwarded_values {
      query_string = true
      headers        = ["All"]

      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

  }

  ordered_cache_behavior {
    path_pattern     = "/index.html"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-www.test123456789"
    #forwarded_values {
    #  query_string = false
    #  headers      = ["Origin"]
    #  cookies {
    #    forward = "none"
    #  }
    #}
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.this.id
    cache_policy_id          = data.aws_cloudfront_cache_policy.this.id
  }
# Cache behavior with precedence 1
#  ordered_cache_behavior {
#    path_pattern     = "/test1"
#    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#    cached_methods   = ["GET", "HEAD"]
#    target_origin_id = replace(var.api_endpoint, "/^https?://([^/]*).*/", "$1")
#    forwarded_values {
#      query_string = false
#      cookies {
#        forward = "none"
#      }
#    }
#    min_ttl                = 0
#    default_ttl            = 3600
#    max_ttl                = 86400
#    compress               = true
#    viewer_protocol_policy = "redirect-to-https"
#  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  #  ssl_support_method = "sni-only"
  #  acm_certificate_arn = "${aws_acm_certificate.myapp.arn}"
  #  minimum_protocol_version = "TLSv1.2_2018"
  }

  #web_acl_id = "${aws_wafv2_web_acl.my_web_acl.arn}"
}


resource "aws_s3_bucket" "www_bucket" {
  bucket = "www.test123456789"
  acl = "public-read"
  #policy = templatefile("templates/s3-policy.json", { bucket = "www.${var.bucket_name}" })

  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET", "POST"]
    allowed_origins = ["https://www.test123456789"]
    max_age_seconds = 3000
  }

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

}
