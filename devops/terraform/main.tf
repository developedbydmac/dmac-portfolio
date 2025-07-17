# D Mac Portfolio - AWS Infrastructure
# This configuration creates AWS resources for hosting a static portfolio website

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Uncomment and configure for remote state management
  # backend "s3" {
  #   bucket = "dmac-portfolio-terraform-state"
  #   key    = "portfolio/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "dmac-portfolio"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "D Mac"
    }
  }
}

# Data source for current AWS caller identity
data "aws_caller_identity" "current" {}

# Data source for AWS region
data "aws_region" "current" {}

# Random string for unique resource naming
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 bucket for static website hosting
resource "aws_s3_bucket" "portfolio_bucket" {
  bucket = "${var.project_name}-${var.environment}-${random_string.bucket_suffix.result}"
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "portfolio_versioning" {
  bucket = aws_s3_bucket.portfolio_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "portfolio_encryption" {
  bucket = aws_s3_bucket.portfolio_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "portfolio_pab" {
  bucket = aws_s3_bucket.portfolio_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 bucket website configuration
resource "aws_s3_bucket_website_configuration" "portfolio_website" {
  bucket = aws_s3_bucket.portfolio_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

# S3 bucket policy for public read access
resource "aws_s3_bucket_policy" "portfolio_policy" {
  bucket = aws_s3_bucket.portfolio_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.portfolio_bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.portfolio_pab]
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "portfolio_oac" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC for D Mac Portfolio"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "portfolio_distribution" {
  origin {
    domain_name              = aws_s3_bucket.portfolio_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.portfolio_oac.id
    origin_id                = "S3-${aws_s3_bucket.portfolio_bucket.bucket}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "D Mac Portfolio Distribution"
  default_root_object = "index.html"

  # Configure logging if needed
  # logging_config {
  #   include_cookies = false
  #   bucket          = aws_s3_bucket.logs.bucket_domain_name
  # }

  aliases = var.domain_name != "" ? [var.domain_name] : []

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.portfolio_bucket.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Cache behavior for static assets
  ordered_cache_behavior {
    path_pattern     = "/assets/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-${aws_s3_bucket.portfolio_bucket.bucket}"
    compress         = true

    forwarded_values {
      query_string = false
      headers      = ["Origin"]
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-distribution"
  }

  viewer_certificate {
    cloudfront_default_certificate = var.domain_name == "" ? true : false
    acm_certificate_arn            = var.domain_name != "" ? aws_acm_certificate.portfolio_cert[0].arn : null
    ssl_support_method             = var.domain_name != "" ? "sni-only" : null
    minimum_protocol_version       = var.domain_name != "" ? "TLSv1.2_2021" : null
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }
}

# Route53 hosted zone (optional - only if domain is provided)
resource "aws_route53_zone" "portfolio_zone" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name

  tags = {
    Name = "${var.project_name}-${var.environment}-zone"
  }
}

# ACM certificate (optional - only if domain is provided)
resource "aws_acm_certificate" "portfolio_cert" {
  count           = var.domain_name != "" ? 1 : 0
  domain_name     = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = ["www.${var.domain_name}"]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cert"
  }
}

# Route53 certificate validation records
resource "aws_route53_record" "portfolio_cert_validation" {
  for_each = var.domain_name != "" ? {
    for dvo in aws_acm_certificate.portfolio_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.portfolio_zone[0].zone_id
}

# ACM certificate validation
resource "aws_acm_certificate_validation" "portfolio_cert_validation" {
  count           = var.domain_name != "" ? 1 : 0
  certificate_arn = aws_acm_certificate.portfolio_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.portfolio_cert_validation : record.fqdn]
}

# Route53 A record for the domain
resource "aws_route53_record" "portfolio_a" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = aws_route53_zone.portfolio_zone[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.portfolio_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.portfolio_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route53 A record for www subdomain
resource "aws_route53_record" "portfolio_www" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = aws_route53_zone.portfolio_zone[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.portfolio_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.portfolio_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# IAM user for GitHub Actions deployment
resource "aws_iam_user" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions"
  path = "/"

  tags = {
    Name = "${var.project_name}-${var.environment}-github-actions"
  }
}

# IAM policy for GitHub Actions
resource "aws_iam_policy" "github_actions_policy" {
  name        = "${var.project_name}-${var.environment}-github-actions-policy"
  description = "Policy for GitHub Actions to deploy to S3 and invalidate CloudFront"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.portfolio_bucket.arn,
          "${aws_s3_bucket.portfolio_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = aws_cloudfront_distribution.portfolio_distribution.arn
      }
    ]
  })
}

# Attach policy to GitHub Actions user
resource "aws_iam_user_policy_attachment" "github_actions_policy_attachment" {
  user       = aws_iam_user.github_actions.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}

# Access keys for GitHub Actions (Note: Store these securely)
resource "aws_iam_access_key" "github_actions_key" {
  user = aws_iam_user.github_actions.name
}
