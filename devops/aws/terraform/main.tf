# D Mac Portfolio - AWS Infrastructure
# Comprehensive AWS resources equivalent to Azure setup:
# S3 (Static Web Apps) + Lambda (Azure Functions) + DynamoDB (Cosmos DB) + CloudWatch (App Insights)

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
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
      "azd-env-name" = var.environment
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Random string for unique resource naming
resource "random_string" "resource_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Variables for resource naming
locals {
  resource_token     = random_string.resource_suffix.result
  static_bucket_name = "${var.project_name}-static-${local.resource_token}"
  function_name      = "${var.project_name}-functions-${local.resource_token}"
  dynamo_table_name  = "${var.project_name}-portfolio-db-${local.resource_token}"
  secrets_name       = "${var.project_name}-secrets-${local.resource_token}"
  
  common_tags = {
    Project     = "dmac-portfolio"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "D Mac"
    "azd-env-name" = var.environment
  }
}

# =============================================================================
# S3 STATIC WEBSITE HOSTING (equivalent to Azure Static Web Apps)
# =============================================================================

# S3 bucket for static website hosting
resource "aws_s3_bucket" "portfolio_bucket" {
  bucket = local.static_bucket_name
  tags   = local.common_tags
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
resource "aws_s3_bucket_policy" "portfolio_bucket_policy" {
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
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.portfolio_pab]
}

# S3 bucket CORS configuration
resource "aws_s3_bucket_cors_configuration" "portfolio_cors" {
  bucket = aws_s3_bucket.portfolio_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

# =============================================================================
# CLOUDFRONT CDN (equivalent to Azure Static Web Apps CDN)
# =============================================================================

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "portfolio_oac" {
  name                              = "${var.project_name}-oac-${local.resource_token}"
  description                       = "OAC for ${var.project_name} portfolio"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "portfolio_distribution" {
  origin {
    domain_name              = aws_s3_bucket.portfolio_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.portfolio_oac.id
    origin_id                = "S3-${aws_s3_bucket.portfolio_bucket.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "D Mac Portfolio Distribution"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.portfolio_bucket.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # Cache behavior for API routes
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-${aws_s3_bucket.portfolio_bucket.id}"

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type"]
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  tags = local.common_tags
}

# =============================================================================
# LAMBDA FUNCTIONS (equivalent to Azure Functions)
# =============================================================================

# IAM role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role-${local.resource_token}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for Lambda functions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy-${local.resource_token}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.portfolio_db.arn,
          "${aws_dynamodb_table.portfolio_db.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.portfolio_secrets.arn
      }
    ]
  })
}

# Lambda function for visitor count
resource "aws_lambda_function" "visits_function" {
  filename         = "visits_function.zip"
  function_name    = "${local.function_name}-visits"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.visits_zip.output_base64sha256
  runtime         = "nodejs18.x"
  timeout         = 30

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.portfolio_db.name
      SECRETS_NAME        = aws_secretsmanager_secret.portfolio_secrets.name
    }
  }

  tags = local.common_tags
}

# Lambda function for contact form
resource "aws_lambda_function" "contact_function" {
  filename         = "contact_function.zip"
  function_name    = "${local.function_name}-contact"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.contact_zip.output_base64sha256
  runtime         = "nodejs18.x"
  timeout         = 30

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.portfolio_db.name
      SECRETS_NAME        = aws_secretsmanager_secret.portfolio_secrets.name
    }
  }

  tags = local.common_tags
}

# Lambda function zip files
data "archive_file" "visits_zip" {
  type        = "zip"
  output_path = "visits_function.zip"
  source {
    content  = file("${path.module}/../lambda/visits/index.js")
    filename = "index.js"
  }
}

data "archive_file" "contact_zip" {
  type        = "zip"
  output_path = "contact_function.zip"
  source {
    content  = file("${path.module}/../lambda/contact/index.js")
    filename = "index.js"
  }
}

# API Gateway for Lambda functions
resource "aws_api_gateway_rest_api" "portfolio_api" {
  name        = "${var.project_name}-api-${local.resource_token}"
  description = "Portfolio API Gateway"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.common_tags
}

# API Gateway resources and methods for visits
resource "aws_api_gateway_resource" "visits_resource" {
  rest_api_id = aws_api_gateway_rest_api.portfolio_api.id
  parent_id   = aws_api_gateway_rest_api.portfolio_api.root_resource_id
  path_part   = "visits"
}

resource "aws_api_gateway_method" "visits_method" {
  rest_api_id   = aws_api_gateway_rest_api.portfolio_api.id
  resource_id   = aws_api_gateway_resource.visits_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "visits_integration" {
  rest_api_id = aws_api_gateway_rest_api.portfolio_api.id
  resource_id = aws_api_gateway_resource.visits_resource.id
  http_method = aws_api_gateway_method.visits_method.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.visits_function.invoke_arn
}

# API Gateway resources and methods for contact
resource "aws_api_gateway_resource" "contact_resource" {
  rest_api_id = aws_api_gateway_rest_api.portfolio_api.id
  parent_id   = aws_api_gateway_rest_api.portfolio_api.root_resource_id
  path_part   = "contact"
}

resource "aws_api_gateway_method" "contact_method" {
  rest_api_id   = aws_api_gateway_rest_api.portfolio_api.id
  resource_id   = aws_api_gateway_resource.contact_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "contact_integration" {
  rest_api_id = aws_api_gateway_rest_api.portfolio_api.id
  resource_id = aws_api_gateway_resource.contact_resource.id
  http_method = aws_api_gateway_method.contact_method.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.contact_function.invoke_arn
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "portfolio_deployment" {
  depends_on = [
    aws_api_gateway_method.visits_method,
    aws_api_gateway_integration.visits_integration,
    aws_api_gateway_method.contact_method,
    aws_api_gateway_integration.contact_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.portfolio_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.visits_resource.id,
      aws_api_gateway_method.visits_method.id,
      aws_api_gateway_integration.visits_integration.id,
      aws_api_gateway_resource.contact_resource.id,
      aws_api_gateway_method.contact_method.id,
      aws_api_gateway_integration.contact_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "portfolio_stage" {
  deployment_id = aws_api_gateway_deployment.portfolio_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.portfolio_api.id
  stage_name    = var.environment
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "visits_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visits_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.portfolio_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "contact_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.portfolio_api.execution_arn}/*/*"
}

# =============================================================================
# DYNAMODB DATABASE (equivalent to Cosmos DB)
# =============================================================================

# DynamoDB table for portfolio data
resource "aws_dynamodb_table" "portfolio_db" {
  name           = local.dynamo_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key      = "type"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "type"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = local.common_tags
}

# =============================================================================
# SECRETS MANAGER (equivalent to Azure Key Vault)
# =============================================================================

# Secrets Manager secret for application secrets
resource "aws_secretsmanager_secret" "portfolio_secrets" {
  name        = local.secrets_name
  description = "Secrets for D Mac Portfolio application"

  tags = local.common_tags
}

# =============================================================================
# CLOUDWATCH MONITORING (equivalent to Application Insights)
# =============================================================================

# CloudWatch Log Groups for Lambda functions
resource "aws_cloudwatch_log_group" "visits_logs" {
  name              = "/aws/lambda/${aws_lambda_function.visits_function.function_name}"
  retention_in_days = 14

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "contact_logs" {
  name              = "/aws/lambda/${aws_lambda_function.contact_function.function_name}"
  retention_in_days = 14

  tags = local.common_tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "portfolio_dashboard" {
  dashboard_name = "${var.project_name}-dashboard-${local.resource_token}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.visits_function.function_name],
            [".", "Errors", ".", "."],
            [".", "Invocations", ".", "."],
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.contact_function.function_name],
            [".", "Errors", ".", "."],
            [".", "Invocations", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Lambda Function Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", aws_cloudfront_distribution.portfolio_distribution.id],
            [".", "BytesDownloaded", ".", "."],
            [".", "4xxErrorRate", ".", "."],
            [".", "5xxErrorRate", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"  # CloudFront metrics are always in us-east-1
          title   = "CloudFront Distribution Metrics"
          period  = 300
        }
      }
    ]
  })
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
