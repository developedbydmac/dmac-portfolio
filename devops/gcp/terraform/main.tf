# D Mac Portfolio - GCP Infrastructure
# This configuration creates GCP resources for hosting a static portfolio website

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Random string for unique resource naming
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Cloud Storage bucket for static website hosting
resource "google_storage_bucket" "portfolio_bucket" {
  name          = "${var.project_name}-${var.environment}-${random_string.bucket_suffix.result}"
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

  labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
    owner       = "d-mac"
    cloud       = "gcp"
  }
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
