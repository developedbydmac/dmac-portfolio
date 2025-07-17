# Outputs for D Mac Portfolio Infrastructure

output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting the website"
  value       = aws_s3_bucket.portfolio_bucket.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.portfolio_bucket.arn
}

output "s3_website_endpoint" {
  description = "S3 website endpoint"
  value       = aws_s3_bucket_website_configuration.portfolio_website.website_endpoint
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.portfolio_distribution.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.portfolio_distribution.domain_name
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.portfolio_distribution.arn
}

output "website_url" {
  description = "Website URL"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.portfolio_distribution.domain_name}"
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = var.domain_name != "" ? aws_route53_zone.portfolio_zone[0].zone_id : null
}

output "route53_name_servers" {
  description = "Route53 name servers"
  value       = var.domain_name != "" ? aws_route53_zone.portfolio_zone[0].name_servers : null
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = var.domain_name != "" ? aws_acm_certificate.portfolio_cert[0].arn : null
}

output "github_actions_user_arn" {
  description = "GitHub Actions IAM user ARN"
  value       = aws_iam_user.github_actions.arn
}

output "github_actions_access_key_id" {
  description = "GitHub Actions access key ID"
  value       = aws_iam_access_key.github_actions_key.id
  sensitive   = true
}

output "github_actions_secret_access_key" {
  description = "GitHub Actions secret access key"
  value       = aws_iam_access_key.github_actions_key.secret
  sensitive   = true
}

output "deployment_instructions" {
  description = "Instructions for setting up GitHub Actions secrets"
  value = <<-EOT
    
    🚀 D Mac Portfolio Deployment Setup Complete!
    
    Next Steps:
    1. Add these secrets to your GitHub repository:
       - AWS_ACCESS_KEY_ID: ${aws_iam_access_key.github_actions_key.id}
       - AWS_SECRET_ACCESS_KEY: ${aws_iam_access_key.github_actions_key.secret}
       - AWS_REGION: ${var.aws_region}
       - S3_BUCKET: ${aws_s3_bucket.portfolio_bucket.bucket}
       - CLOUDFRONT_DISTRIBUTION_ID: ${aws_cloudfront_distribution.portfolio_distribution.id}
    
    2. Your website will be available at:
       ${var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.portfolio_distribution.domain_name}"}
    
    3. If using a custom domain, update your domain's nameservers to:
       ${var.domain_name != "" ? join(", ", aws_route53_zone.portfolio_zone[0].name_servers) : "N/A - No custom domain configured"}
    
    4. Push to your main branch to trigger the deployment pipeline!
    
  EOT
}
