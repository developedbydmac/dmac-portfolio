# AWS Infrastructure Outputs# Comprehensive outputs matching Azure setup# Static Website Hostingoutput "s3_bucket_name" {  description = "Name of the S3 bucket for static website hosting"  value       = aws_s3_bucket.portfolio_bucket.id}output "s3_bucket_domain_name" {  description = "Domain name of the S3 bucket"  value       = aws_s3_bucket.portfolio_bucket.bucket_domain_name}output "s3_website_endpoint" {  description = "Website endpoint for the S3 bucket"  value       = aws_s3_bucket_website_configuration.portfolio_website.website_endpoint}# CloudFront CDNoutput "cloudfront_distribution_id" {  description = "ID of the CloudFront distribution"  value       = aws_cloudfront_distribution.portfolio_distribution.id}output "cloudfront_domain_name" {  description = "Domain name of the CloudFront distribution"  value       = aws_cloudfront_distribution.portfolio_distribution.domain_name}output "cloudfront_hosted_zone_id" {  description = "CloudFront distribution hosted zone ID"  value       = aws_cloudfront_distribution.portfolio_distribution.hosted_zone_id}output "website_url" {  description = "Main website URL via CloudFront"  value       = "https://${aws_cloudfront_distribution.portfolio_distribution.domain_name}"}# API Gatewayoutput "api_gateway_url" {  description = "Base URL for the API Gateway"  value       = aws_api_gateway_deployment.portfolio_deployment.invoke_url}output "api_gateway_id" {  description = "ID of the API Gateway"  value       = aws_api_gateway_rest_api.portfolio_api.id}# Lambda Functionsoutput "visits_function_name" {  description = "Name of the visits Lambda function"  value       = aws_lambda_function.visits_function.function_name}output "visits_function_arn" {  description = "ARN of the visits Lambda function"  value       = aws_lambda_function.visits_function.arn}output "contact_function_name" {  description = "Name of the contact Lambda function"  value       = aws_lambda_function.contact_function.function_name}output "contact_function_arn" {  description = "ARN of the contact Lambda function"  value       = aws_lambda_function.contact_function.arn}# DynamoDB Databaseoutput "dynamodb_table_name" {  description = "Name of the DynamoDB table"  value       = aws_dynamodb_table.portfolio_db.name}output "dynamodb_table_arn" {  description = "ARN of the DynamoDB table"  value       = aws_dynamodb_table.portfolio_db.arn}# Secrets Manageroutput "secrets_manager_secret_name" {  description = "Name of the Secrets Manager secret"  value       = aws_secretsmanager_secret.portfolio_secrets.name}output "secrets_manager_secret_arn" {  description = "ARN of the Secrets Manager secret"  value       = aws_secretsmanager_secret.portfolio_secrets.arn}
# CloudWatch
output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.portfolio_dashboard.dashboard_name}"
}

# Resource Information
output "resource_group_name" {
  description = "AWS resource group equivalent (using tags)"
  value       = "Project:dmac-portfolio,Environment:${var.environment}"
}

output "deployment_region" {
  description = "AWS region where resources are deployed"
  value       = data.aws_region.current.name
}

output "resource_token" {
  description = "Unique resource token for naming"
  value       = local.resource_token
}
