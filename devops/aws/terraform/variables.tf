# Variables for D Mac Portfolio Infrastructure

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "dmac-portfolio"
}

variable "domain_name" {
  description = "Domain name for the portfolio (optional)"
  type        = string
  default     = ""
  # Example: "dmac.dev"
}

variable "enable_logging" {
  description = "Enable CloudFront logging"
  type        = bool
  default     = false
}

variable "cache_default_ttl" {
  description = "Default TTL for CloudFront cache"
  type        = number
  default     = 3600
}

variable "cache_max_ttl" {
  description = "Maximum TTL for CloudFront cache"
  type        = number
  default     = 86400
}

variable "enable_ipv6" {
  description = "Enable IPv6 for CloudFront distribution"
  type        = bool
  default     = true
}

variable "price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_100"
  validation {
    condition = contains([
      "PriceClass_All",
      "PriceClass_200",
      "PriceClass_100"
    ], var.price_class)
    error_message = "Price class must be PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
