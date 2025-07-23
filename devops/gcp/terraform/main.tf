# D Mac Portfolio - GCP Infrastructure
# Comprehensive GCP resources equivalent to Azure setup:
# Cloud Storage (Static Web Apps) + Cloud Functions (Azure Functions) + Firestore (Cosmos DB) + Cloud Monitoring (App Insights)

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
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
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Configure the Google Cloud Beta Provider (for some advanced features)
provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Random string for unique resource naming
resource "random_string" "resource_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Local variables for resource naming
locals {
  resource_token      = random_string.resource_suffix.result
  storage_bucket_name = "${var.project_name}-static-${local.resource_token}"
  function_prefix     = "${var.project_name}-functions-${local.resource_token}"
  firestore_db_name   = "${var.project_name}-portfolio-db-${local.resource_token}"
  secret_name         = "${var.project_name}-secrets-${local.resource_token}"
  
  common_labels = {
    project     = "dmac-portfolio"
    environment = var.environment
    managed-by  = "terraform"
    owner       = "d-mac"
    azd-env-name = var.environment
  }
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "storage.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "firestore.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_dependent_services = false
  disable_on_destroy        = false
}

# =============================================================================
# CLOUD STORAGE FOR STATIC WEBSITE (equivalent to Azure Static Web Apps)
# =============================================================================

# Cloud Storage bucket for static website hosting
resource "google_storage_bucket" "portfolio_bucket" {
  name          = local.storage_bucket_name
  location      = var.bucket_location
  force_destroy = true
  
  uniform_bucket_level_access = true
  
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
  
  versioning {
    enabled = true
  }
  
  labels = local.common_labels
  
  depends_on = [google_project_service.required_apis]
}

# Make bucket publicly readable
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.portfolio_bucket.name
  role   = "roles/storage.legacyObjectReader"
  member = "allUsers"
}

# =============================================================================
# CLOUD CDN (equivalent to CloudFront/Azure CDN)
# =============================================================================

# Global IP address for load balancer
resource "google_compute_global_address" "portfolio_ip" {
  name = "${var.project_name}-ip-${local.resource_token}"
}

# Backend bucket for Cloud CDN
resource "google_compute_backend_bucket" "portfolio_backend" {
  name        = "${var.project_name}-backend-${local.resource_token}"
  bucket_name = google_storage_bucket.portfolio_bucket.name
  enable_cdn  = true
  
  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                  = 3600
    max_ttl                      = 86400
    negative_caching             = true
    serve_while_stale            = 86400
    signed_url_cache_max_age_sec = 7200
  }
}

# URL map for load balancer
resource "google_compute_url_map" "portfolio_url_map" {
  name            = "${var.project_name}-url-map-${local.resource_token}"
  default_service = google_compute_backend_bucket.portfolio_backend.id
  
  # API routes to Cloud Functions
  path_matcher {
    name            = "api-routes"
    default_service = google_compute_backend_bucket.portfolio_backend.id
    
    path_rule {
      paths   = ["/api/visits"]
      service = google_compute_backend_service.visits_backend.id
    }
    
    path_rule {
      paths   = ["/api/contact"]
      service = google_compute_backend_service.contact_backend.id
    }
  }
  
  host_rule {
    hosts        = ["*"]
    path_matcher = "api-routes"
  }
}

# HTTPS proxy
resource "google_compute_target_https_proxy" "portfolio_https_proxy" {
  name   = "${var.project_name}-https-proxy-${local.resource_token}"
  url_map = google_compute_url_map.portfolio_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.portfolio_ssl.name]
}

# Global forwarding rule
resource "google_compute_global_forwarding_rule" "portfolio_forwarding_rule" {
  name       = "${var.project_name}-forwarding-rule-${local.resource_token}"
  target     = google_compute_target_https_proxy.portfolio_https_proxy.id
  port_range = "443"
  ip_address = google_compute_global_address.portfolio_ip.id
}

# Managed SSL certificate
resource "google_compute_managed_ssl_certificate" "portfolio_ssl" {
  name = "${var.project_name}-ssl-${local.resource_token}"
  
  managed {
    domains = [google_compute_global_address.portfolio_ip.address]
  }
}

# =============================================================================
# CLOUD FUNCTIONS (equivalent to Azure Functions/AWS Lambda)
# =============================================================================

# Service account for Cloud Functions
resource "google_service_account" "functions_sa" {
  account_id   = "${var.project_name}-functions-sa-${local.resource_token}"
  display_name = "Portfolio Cloud Functions Service Account"
  description  = "Service account for portfolio Cloud Functions"
}

# IAM binding for Firestore access
resource "google_project_iam_member" "functions_firestore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.functions_sa.email}"
}

# IAM binding for Secret Manager access
resource "google_project_iam_member" "functions_secrets" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.functions_sa.email}"
}

# Storage bucket for Cloud Functions source code
resource "google_storage_bucket" "functions_bucket" {
  name          = "${var.project_name}-functions-${local.resource_token}"
  location      = var.region
  force_destroy = true
  
  uniform_bucket_level_access = true
}

# Archive source code for visits function
data "archive_file" "visits_function_zip" {
  type        = "zip"
  output_path = "visits_function.zip"
  source_dir  = "${path.module}/../functions/visits"
}

# Archive source code for contact function
data "archive_file" "contact_function_zip" {
  type        = "zip"
  output_path = "contact_function.zip"
  source_dir  = "${path.module}/../functions/contact"
}

# Upload visits function source to bucket
resource "google_storage_bucket_object" "visits_function_source" {
  name   = "visits-function-${data.archive_file.visits_function_zip.output_md5}.zip"
  bucket = google_storage_bucket.functions_bucket.name
  source = data.archive_file.visits_function_zip.output_path
}

# Upload contact function source to bucket
resource "google_storage_bucket_object" "contact_function_source" {
  name   = "contact-function-${data.archive_file.contact_function_zip.output_md5}.zip"
  bucket = google_storage_bucket.functions_bucket.name
  source = data.archive_file.contact_function_zip.output_path
}

# Visits Cloud Function
resource "google_cloudfunctions_function" "visits_function" {
  name        = "${local.function_prefix}-visits"
  description = "Portfolio visitor count function"
  runtime     = "nodejs18"
  region      = var.region
  
  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.functions_bucket.name
  source_archive_object = google_storage_bucket_object.visits_function_source.name
  
  https_trigger_security_level = "SECURE_ALWAYS"
  
  entry_point = "visitsHandler"
  
  environment_variables = {
    FIRESTORE_DATABASE_ID = google_firestore_database.portfolio_db.name
    SECRET_NAME          = google_secret_manager_secret.portfolio_secrets.secret_id
    GCP_PROJECT          = var.project_id
  }
  
  service_account_email = google_service_account.functions_sa.email
  
  depends_on = [google_project_service.required_apis]
}

# Contact Cloud Function
resource "google_cloudfunctions_function" "contact_function" {
  name        = "${local.function_prefix}-contact"
  description = "Portfolio contact form function"
  runtime     = "nodejs18"
  region      = var.region
  
  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.functions_bucket.name
  source_archive_object = google_storage_bucket_object.contact_function_source.name
  
  https_trigger_security_level = "SECURE_ALWAYS"
  
  entry_point = "contactHandler"
  
  environment_variables = {
    FIRESTORE_DATABASE_ID = google_firestore_database.portfolio_db.name
    SECRET_NAME          = google_secret_manager_secret.portfolio_secrets.secret_id
    GCP_PROJECT          = var.project_id
  }
  
  service_account_email = google_service_account.functions_sa.email
  
  depends_on = [google_project_service.required_apis]
}

# IAM bindings to allow unauthenticated invocation
resource "google_cloudfunctions_function_iam_member" "visits_invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.visits_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}

resource "google_cloudfunctions_function_iam_member" "contact_invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.contact_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}

# Backend services for Cloud Functions
resource "google_compute_backend_service" "visits_backend" {
  name        = "${var.project_name}-visits-backend-${local.resource_token}"
  protocol    = "HTTPS"
  timeout_sec = 30
  
  backend {
    group = google_compute_region_network_endpoint_group.visits_neg.id
  }
}

resource "google_compute_backend_service" "contact_backend" {
  name        = "${var.project_name}-contact-backend-${local.resource_token}"
  protocol    = "HTTPS"
  timeout_sec = 30
  
  backend {
    group = google_compute_region_network_endpoint_group.contact_neg.id
  }
}

# Network endpoint groups for Cloud Functions
resource "google_compute_region_network_endpoint_group" "visits_neg" {
  name         = "${var.project_name}-visits-neg-${local.resource_token}"
  network_endpoint_type = "SERVERLESS"
  region       = var.region
  
  cloud_function {
    function = google_cloudfunctions_function.visits_function.name
  }
}

resource "google_compute_region_network_endpoint_group" "contact_neg" {
  name         = "${var.project_name}-contact-neg-${local.resource_token}"
  network_endpoint_type = "SERVERLESS"
  region       = var.region
  
  cloud_function {
    function = google_cloudfunctions_function.contact_function.name
  }
}

# =============================================================================
# FIRESTORE DATABASE (equivalent to Cosmos DB/DynamoDB)
# =============================================================================

# Firestore database
resource "google_firestore_database" "portfolio_db" {
  project                           = var.project_id
  name                             = "(default)"
  location_id                      = var.firestore_location
  type                             = "FIRESTORE_NATIVE"
  concurrency_mode                 = "OPTIMISTIC"
  app_engine_integration_mode      = "DISABLED"
  point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_ENABLED"
  delete_protection_state          = "DELETE_PROTECTION_DISABLED"
  
  depends_on = [google_project_service.required_apis]
}

# =============================================================================
# SECRET MANAGER (equivalent to Azure Key Vault/AWS Secrets Manager)
# =============================================================================

# Secret Manager secret
resource "google_secret_manager_secret" "portfolio_secrets" {
  secret_id = local.secret_name
  
  replication {
    auto {}
  }
  
  depends_on = [google_project_service.required_apis]
}

# =============================================================================
# CLOUD MONITORING & LOGGING (equivalent to Application Insights/CloudWatch)
# =============================================================================

# Custom dashboard for monitoring
resource "google_monitoring_dashboard" "portfolio_dashboard" {
  dashboard_json = jsonencode({
    displayName = "D Mac Portfolio Dashboard"
    mosaicLayout = {
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Cloud Function Executions"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=~\"${local.function_prefix}-.*\""
                      aggregation = {
                        alignmentPeriod  = "60s"
                        perSeriesAligner = "ALIGN_RATE"
                      }
                    }
                  }
                  plotType = "LINE"
                }
              ]
            }
          }
        },
        {
          width  = 6
          height = 4
          xPos   = 6
          widget = {
            title = "Cloud Function Errors"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=~\"${local.function_prefix}-.*\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.labels.status!=\"ok\""
                      aggregation = {
                        alignmentPeriod  = "60s"
                        perSeriesAligner = "ALIGN_RATE"
                      }
                    }
                  }
                  plotType = "LINE"
                }
              ]
            }
          }
        }
      ]
    }
  })
  
  depends_on = [google_project_service.required_apis]
}

# Make bucket publicly readable
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.portfolio_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Backend bucket for load balancer
resource "google_compute_backend_bucket" "portfolio_backend" {
  name        = "${var.project_name}-${var.environment}-backend"
  bucket_name = google_storage_bucket.portfolio_bucket.name
  enable_cdn  = true

  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    default_ttl       = 3600
    max_ttl           = 86400
    negative_caching  = true
    serve_while_stale = 86400

    negative_caching_policy {
      code = 404
      ttl  = 120
    }
  }
}

# Global static IP address
resource "google_compute_global_address" "portfolio_ip" {
  name = "${var.project_name}-${var.environment}-ip"
}

# URL map for load balancer
resource "google_compute_url_map" "portfolio_url_map" {
  name            = "${var.project_name}-${var.environment}-url-map"
  default_service = google_compute_backend_bucket.portfolio_backend.id

  # Custom rules for different file types
  path_matcher {
    name            = "path-matcher-1"
    default_service = google_compute_backend_bucket.portfolio_backend.id

    # Cache assets longer
    path_rule {
      paths   = ["/assets/*", "/styles/*", "/scripts/*"]
      service = google_compute_backend_bucket.portfolio_backend.id
    }

    # Cache HTML files for shorter duration
    path_rule {
      paths   = ["/*.html", "/"]
      service = google_compute_backend_bucket.portfolio_backend.id
    }
  }

  host_rule {
    hosts        = var.domain_name != "" ? [var.domain_name] : ["*"]
    path_matcher = "path-matcher-1"
  }
}

# HTTP to HTTPS redirect
resource "google_compute_url_map" "portfolio_https_redirect" {
  name = "${var.project_name}-${var.environment}-https-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

# SSL certificate (managed by Google)
resource "google_compute_managed_ssl_certificate" "portfolio_ssl" {
  count = var.domain_name != "" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-ssl"

  managed {
    domains = [var.domain_name, "www.${var.domain_name}"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# HTTPS target proxy
resource "google_compute_target_https_proxy" "portfolio_https_proxy" {
  name             = "${var.project_name}-${var.environment}-https-proxy"
  url_map          = google_compute_url_map.portfolio_url_map.id
  ssl_certificates = var.domain_name != "" ? [google_compute_managed_ssl_certificate.portfolio_ssl[0].id] : []
}

# HTTP target proxy (for redirect)
resource "google_compute_target_http_proxy" "portfolio_http_proxy" {
  name    = "${var.project_name}-${var.environment}-http-proxy"
  url_map = google_compute_url_map.portfolio_https_redirect.id
}

# Global forwarding rule for HTTPS
resource "google_compute_global_forwarding_rule" "portfolio_https_forwarding_rule" {
  name       = "${var.project_name}-${var.environment}-https-forwarding-rule"
  target     = google_compute_target_https_proxy.portfolio_https_proxy.id
  port_range = "443"
  ip_address = google_compute_global_address.portfolio_ip.address
}

# Global forwarding rule for HTTP (redirect)
resource "google_compute_global_forwarding_rule" "portfolio_http_forwarding_rule" {
  name       = "${var.project_name}-${var.environment}-http-forwarding-rule"
  target     = google_compute_target_http_proxy.portfolio_http_proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.portfolio_ip.address
}

# Cloud DNS managed zone (optional)
resource "google_dns_managed_zone" "portfolio_zone" {
  count       = var.domain_name != "" ? 1 : 0
  name        = "${replace(var.project_name, "-", "")}${var.environment}zone"
  dns_name    = "${var.domain_name}."
  description = "DNS zone for D Mac Portfolio"

  labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# DNS A record pointing to load balancer
resource "google_dns_record_set" "portfolio_a" {
  count        = var.domain_name != "" ? 1 : 0
  name         = "${var.domain_name}."
  managed_zone = google_dns_managed_zone.portfolio_zone[0].name
  type         = "A"
  ttl          = 300

  rrdatas = [google_compute_global_address.portfolio_ip.address]
}

# DNS A record for www subdomain
resource "google_dns_record_set" "portfolio_www" {
  count        = var.domain_name != "" ? 1 : 0
  name         = "www.${var.domain_name}."
  managed_zone = google_dns_managed_zone.portfolio_zone[0].name
  type         = "A"
  ttl          = 300

  rrdatas = [google_compute_global_address.portfolio_ip.address]
}

# Service account for GitHub Actions
resource "google_service_account" "github_actions" {
  account_id   = "${var.project_name}-${var.environment}-github"
  display_name = "GitHub Actions Service Account for D Mac Portfolio"
  description  = "Service account for GitHub Actions to deploy to GCP"
}

# IAM binding for storage admin (to upload files)
resource "google_project_iam_member" "github_actions_storage" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# IAM binding for CDN cache invalidation
resource "google_project_iam_member" "github_actions_compute" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Service account key for GitHub Actions
resource "google_service_account_key" "github_actions_key" {
  service_account_id = google_service_account.github_actions.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}
