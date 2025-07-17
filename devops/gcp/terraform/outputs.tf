# Outputs for D Mac Portfolio GCP Infrastructure

output "bucket_name" {
  description = "Name of the Cloud Storage bucket"
  value       = google_storage_bucket.portfolio_bucket.name
}

output "bucket_url" {
  description = "URL of the Cloud Storage bucket website"
  value       = "https://storage.googleapis.com/${google_storage_bucket.portfolio_bucket.name}/index.html"
}

output "load_balancer_ip" {
  description = "External IP address of the load balancer"
  value       = google_compute_global_address.portfolio_ip.address
}

output "website_url" {
  description = "Website URL"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${google_compute_global_address.portfolio_ip.address}"
}

output "cdn_enabled" {
  description = "Whether CDN is enabled"
  value       = var.enable_cdn
}

output "dns_name_servers" {
  description = "DNS name servers (if custom domain is configured)"
  value       = var.domain_name != "" ? google_dns_managed_zone.portfolio_zone[0].name_servers : null
}

output "ssl_certificate_status" {
  description = "Status of the managed SSL certificate"
  value       = var.domain_name != "" ? google_compute_managed_ssl_certificate.portfolio_ssl[0].managed[0].status : "No custom domain configured"
}

output "service_account_email" {
  description = "Email of the GitHub Actions service account"
  value       = google_service_account.github_actions.email
}

output "service_account_key" {
  description = "Private key for GitHub Actions service account (base64 encoded)"
  value       = google_service_account_key.github_actions_key.private_key
  sensitive   = true
}

output "backend_bucket_name" {
  description = "Name of the backend bucket for load balancer"
  value       = google_compute_backend_bucket.portfolio_backend.name
}

output "deployment_instructions" {
  description = "Instructions for setting up GitHub Actions secrets"
  value = <<-EOT
    
    🚀 D Mac Portfolio GCP Deployment Setup Complete!
    
    Next Steps:
    1. Add these secrets to your GitHub repository:
       - GCP_PROJECT_ID: ${var.project_id}
       - GCP_SA_KEY: (base64 encoded service account key - check terraform output)
       - GCP_BUCKET_NAME: ${google_storage_bucket.portfolio_bucket.name}
       - GCP_BACKEND_BUCKET: ${google_compute_backend_bucket.portfolio_backend.name}
    
    2. Your website will be available at:
       ${var.domain_name != "" ? "https://${var.domain_name}" : "https://${google_compute_global_address.portfolio_ip.address}"}
    
    3. If using a custom domain, update your domain's nameservers to:
       ${var.domain_name != "" ? join(", ", google_dns_managed_zone.portfolio_zone[0].name_servers) : "N/A - No custom domain configured"}
    
    4. SSL certificate status: ${var.domain_name != "" ? "Managed by Google (may take 10-15 minutes to provision)" : "N/A"}
    
    5. Push to your main branch to trigger the deployment pipeline!
    
    💰 Estimated monthly cost: $1-8 (depending on traffic)
    
  EOT
}
