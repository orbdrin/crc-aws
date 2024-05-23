#====================
# ACM Certificate / Route 53 (Zone) Setup
#====================

resource "aws_acm_certificate" "ssl" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_record" "domain_validation" {
  for_each = {
    for dvo in aws_acm_certificate.ssl.domain_validation_options : dvo.domain_name => {
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
  zone_id         = aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.ssl.arn
  validation_record_fqdns = [for record in aws_route53_record.domain_validation : record.fqdn]
}

#====================
# S3 Bucket Setup
#====================

resource "aws_s3_bucket" "crc_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_ownership_controls" "crc_bucket_ownership" {
  bucket = aws_s3_bucket.crc_bucket.id
  
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "crc_public_access" {
  bucket = aws_s3_bucket.crc_bucket.id
  
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "crc_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.crc_bucket_ownership,
	aws_s3_bucket_public_access_block.crc_public_access
  ]
  
  bucket = aws_s3_bucket.crc_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "crc_bucket_policy" {
  bucket = aws_s3_bucket.crc_bucket.id
  
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
	  Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject"]
      Resource  = ["arn:aws:s3:::${var.bucket_name}/*"]
      }
    ]
  })
}

resource "aws_s3_bucket_website_configuration" "crc_bucket_website" {
  bucket = aws_s3_bucket.crc_bucket.id
  
  index_document {
    suffix = "index.html"
  }
  
  error_document {
    key = "index.html"
  }
}

resource "aws_s3_object" "upload_site_html" {
  for_each     = fileset("${path.module}/site/", "*.html")
  bucket       = aws_s3_bucket.crc_bucket.id
  key          = each.value
  content_type = "text/html"
  source       = "${path.module}/site/${each.value}"
  etag         = filemd5("${path.module}/site/${each.value}")
}

resource "aws_s3_object" "upload_site_css" {
  for_each     = fileset("${path.module}/site/", "*.css")
  bucket       = aws_s3_bucket.crc_bucket.id
  key          = each.value
  content_type = "text/css"
  source       = "${path.module}/site/${each.value}"
  etag         = filemd5("${path.module}/site/${each.value}")
}

resource "aws_s3_object" "upload_site_js" {
  for_each     = fileset("${path.module}/site/", "*.js")
  bucket       = aws_s3_bucket.crc_bucket.id
  key          = each.value
  content_type = "text/js"
  source       = "${path.module}/site/${each.value}"
  etag         = filemd5("${path.module}/site/${each.value}")
}

resource "aws_s3_object" "upload_site_png" {
  for_each     = fileset("${path.module}/site/", "*.png")
  bucket       = aws_s3_bucket.crc_bucket.id
  key          = each.value
  content_type = "image/png"
  source       = "${path.module}/site/${each.value}"
  etag         = filemd5("${path.module}/site/${each.value}")
}

#====================
# CloudFront Distribution Setup
#====================

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.crc_bucket.bucket_regional_domain_name
    origin_id                = var.cloudfront_origin_id
	
	custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Distribution for Cloud Resume Challenge Static Site"
  default_root_object = "index.html"
  aliases             = ["${var.domain_name}", "www.${var.domain_name}"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.cloudfront_origin_id

    forwarded_values {
      query_string = false
	  
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1"
  }
}

#====================
# Route 53 (DNS Records) Setup
#====================

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = 60
  records = ["${aws_cloudfront_distribution.s3_distribution.domain_name}"]
}

resource "aws_route53_record" "domain" {
  zone_id = aws_route53_zone.main.zone_id
  name    = aws_route53_zone.main.name
  type    = "A"
  
  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}