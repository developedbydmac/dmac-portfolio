# Variables for D Mac Portfolio GCP Infrastructure

variable "project_id" {
  description = "GCP Project ID"
  type        = string
  # Example: "dmac-portfolio-12345"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "dmac-portfolio"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for resources"
  type        = string
  default     = "us-central1-a"
}

variable "bucket_location" {
  description = "Location for Cloud Storage bucket"
  type        = string
  default     = "US"
  # Options: US, EU, ASIA, or specific regions like us-central1
}

variable "domain_name" {
  description = "Custom domain name (optional)"
  type        = string
  default     = ""
  # Example: "dmac.dev"
}

variable "enable_cdn" {
  description = "Enable Cloud CDN"
  type        = bool
  default     = true
}

variable "firestore_location" {
  description = "Location for Firestore database"
  type        = string
  default     = "nam5"
  # Options: nam5 (North America), eur3 (Europe), asia-southeast1, etc.
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS load balancer"
  type        = string
  default     = "MODERN"
  validation {
    condition = contains([
      "COMPATIBLE",
      "MODERN", 
      "RESTRICTED",
      "CUSTOM"
    ], var.ssl_policy)
    error_message = "SSL policy must be COMPATIBLE, MODERN, RESTRICTED, or CUSTOM."
  }
}

variable "cache_max_age" {
  description = "Maximum cache age in seconds"
  type        = number
  default     = 86400
}

variable "enable_compression" {
  description = "Enable gzip compression"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional labels to apply to resources"
  type        = map(string)
  default     = {}
}
