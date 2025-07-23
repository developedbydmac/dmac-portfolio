# GCP Infrastructure Outputs
# Comprehensive outputs matching Azure setup

# Static Website Hosting
output "storage_bucket_name" {
  description = "Name of the Cloud Storage bucket for static website hosting"
  value       = google_storage_bucket.portfolio_bucket.name
}

output "storage_bucket_url" {
  description = "URL of the Cloud Storage bucket"
  value       = google_storage_bucket.portfolio_bucket.url
}

output "storage_website_url" {
  description = "Website URL for the Cloud Storage bucket"
  value       = "https://storage.googleapis.com/${google_storage_bucket.portfolio_bucket.name}/index.html"
}

# Cloud CDN & Load Balancer
output "global_ip_address" {
  description = "Global IP address for the load balancer"
  value       = google_compute_global_address.portfolio_ip.address
}

output "load_balancer_url" {
  description = "Main website URL via Global Load Balancer"
  value       = "https://${google_compute_global_address.portfolio_ip.address}"
}

output "backend_bucket_name" {
  description = "Name of the backend bucket for CDN"
  value       = google_compute_backend_bucket.portfolio_backend.name
}

# Cloud Functions
output "visits_function_name" {
  description = "Name of the visits Cloud Function"
  value       = google_cloudfunctions_function.visits_function.name
}

output "visits_function_url" {
  description = "HTTP trigger URL for the visits Cloud Function"
  value       = google_cloudfunctions_function.visits_function.https_trigger_url
}

output "contact_function_name" {
  description = "Name of the contact Cloud Function"
  value       = google_cloudfunctions_function.contact_function.name
}

output "contact_function_url" {
  description = "HTTP trigger URL for the contact Cloud Function"
  value       = google_cloudfunctions_function.contact_function.https_trigger_url
}

# API Endpoints
output "api_visits_endpoint" {
  description = "API endpoint for visitor count"
  value       = "${google_cloudfunctions_function.visits_function.https_trigger_url}"
}

output "api_contact_endpoint" {
  description = "API endpoint for contact form"
  value       = "${google_cloudfunctions_function.contact_function.https_trigger_url}"
}

# Firestore Database
output "firestore_database_name" {
  description = "Name of the Firestore database"
  value       = google_firestore_database.portfolio_db.name
}

output "firestore_location" {
  description = "Location of the Firestore database"
  value       = google_firestore_database.portfolio_db.location_id
}

# Secret Manager
output "secret_manager_secret_name" {
  description = "Name of the Secret Manager secret"
  value       = google_secret_manager_secret.portfolio_secrets.secret_id
}

output "secret_manager_secret_id" {
  description = "Full resource ID of the Secret Manager secret"
  value       = google_secret_manager_secret.portfolio_secrets.id
}

# Service Account
output "functions_service_account_email" {
  description = "Email of the Cloud Functions service account"
  value       = google_service_account.functions_sa.email
}

output "functions_service_account_id" {
  description = "ID of the Cloud Functions service account"
  value       = google_service_account.functions_sa.account_id
}

# Monitoring
output "monitoring_dashboard_url" {
  description = "URL to the Cloud Monitoring dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.portfolio_dashboard.id}?project=${var.project_id}"
}

# Project Information
output "project_id" {
  description = "GCP project ID where resources are deployed"
  value       = var.project_id
}

output "deployment_region" {
  description = "GCP region where resources are deployed"
  value       = var.region
}

output "resource_token" {
  description = "Unique resource token for naming"
  value       = local.resource_token
}

# Website URLs Summary
output "website_urls" {
  description = "All available website URLs"
  value = {
    storage_direct  = "https://storage.googleapis.com/${google_storage_bucket.portfolio_bucket.name}/index.html"
    load_balancer   = "https://${google_compute_global_address.portfolio_ip.address}"
    functions_visits = google_cloudfunctions_function.visits_function.https_trigger_url
    functions_contact = google_cloudfunctions_function.contact_function.https_trigger_url
  }
}
