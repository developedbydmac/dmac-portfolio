#!/bin/bash

# D Mac Portfolio - Local Development & Deployment Script
# This script helps with local development and deployment tasks

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}"
    echo "=================================="
    echo "  D Mac Portfolio DevOps Script"
    echo "=================================="
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if required tools are installed
check_dependencies() {
    print_info "Checking dependencies..."
    
    # Check for AWS CLI
    if ! command -v aws &> /dev/null; then
        print_warning "AWS CLI not found. Install it from: https://aws.amazon.com/cli/"
        return 1
    fi
    
    # Check for Terraform
    if ! command -v terraform &> /dev/null; then
        print_warning "Terraform not found. Install it from: https://terraform.io/downloads"
        return 1
    fi
    
    # Check for Git
    if ! command -v git &> /dev/null; then
        print_error "Git is required but not installed"
        return 1
    fi
    
    print_success "All dependencies are available"
    return 0
}

# Setup local development environment
setup_dev() {
    print_info "Setting up local development environment..."
    
    # Create necessary directories if they don't exist
    mkdir -p components assets/images styles scripts
    
    # Check if main files exist
    if [ ! -f "index.html" ]; then
        print_warning "index.html not found in current directory"
    fi
    
    # Start a simple HTTP server if Python is available
    if command -v python3 &> /dev/null; then
        print_info "Starting local development server..."
        print_info "Your portfolio will be available at: http://localhost:8000"
        print_info "Press Ctrl+C to stop the server"
        python3 -m http.server 8000
    elif command -v python &> /dev/null; then
        print_info "Starting local development server..."
        print_info "Your portfolio will be available at: http://localhost:8000"
        print_info "Press Ctrl+C to stop the server"
        python -m SimpleHTTPServer 8000
    else
        print_warning "Python not found. Cannot start local server."
        print_info "You can use any other HTTP server to serve the files locally"
    fi
}

# Initialize Terraform
init_terraform() {
    print_info "Initializing Terraform..."
    
    cd devops/terraform
    
    # Copy example variables if terraform.tfvars doesn't exist
    if [ ! -f "terraform.tfvars" ]; then
        print_info "Creating terraform.tfvars from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your specific values"
        return 1
    fi
    
    # Initialize Terraform
    terraform init
    
    print_success "Terraform initialized successfully"
    cd - > /dev/null
}

# Plan Terraform deployment
plan_terraform() {
    print_info "Planning Terraform deployment..."
    
    cd devops/terraform
    
    if [ ! -f "terraform.tfvars" ]; then
        print_error "terraform.tfvars not found. Run 'init' first."
        cd - > /dev/null
        return 1
    fi
    
    terraform plan
    
    cd - > /dev/null
}

# Apply Terraform deployment
deploy_infrastructure() {
    print_info "Deploying infrastructure to AWS..."
    
    cd devops/terraform
    
    if [ ! -f "terraform.tfvars" ]; then
        print_error "terraform.tfvars not found. Run 'init' first."
        cd - > /dev/null
        return 1
    fi
    
    print_warning "This will create AWS resources which may incur costs."
    read -p "Do you want to continue? (y/N): " confirm
    
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        terraform apply
        
        print_success "Infrastructure deployed successfully!"
        print_info "Don't forget to add the output values to your GitHub repository secrets"
        
        # Show important outputs
        echo ""
        print_info "Important values for GitHub Actions:"
        terraform output github_actions_access_key_id
        echo "AWS_SECRET_ACCESS_KEY: (sensitive - check terraform output)"
        terraform output -raw s3_bucket_name
        terraform output -raw cloudfront_distribution_id
        
    else
        print_info "Deployment cancelled"
    fi
    
    cd - > /dev/null
}

# Deploy website content to S3
deploy_content() {
    print_info "Deploying website content to S3..."
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI not configured. Run 'aws configure' first."
        return 1
    fi
    
    # Get S3 bucket name from Terraform output
    cd devops/terraform
    if [ ! -f "terraform.tfstate" ]; then
        print_error "No Terraform state found. Deploy infrastructure first."
        cd - > /dev/null
        return 1
    fi
    
    S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null)
    DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null)
    
    if [ -z "$S3_BUCKET" ]; then
        print_error "Could not get S3 bucket name from Terraform output"
        cd - > /dev/null
        return 1
    fi
    
    cd - > /dev/null
    
    print_info "Uploading to S3 bucket: $S3_BUCKET"
    
    # Sync files to S3
    aws s3 sync . s3://$S3_BUCKET/ \
        --exclude ".git/*" \
        --exclude "devops/*" \
        --exclude ".github/*" \
        --exclude "*.sh" \
        --exclude "README.md" \
        --exclude "LICENSE" \
        --cache-control "public, max-age=3600"
    
    # Set longer cache for assets
    if [ -d "assets" ]; then
        aws s3 sync assets/ s3://$S3_BUCKET/assets/ \
            --cache-control "public, max-age=31536000"
    fi
    
    # Invalidate CloudFront cache if distribution ID is available
    if [ -n "$DISTRIBUTION_ID" ]; then
        print_info "Invalidating CloudFront cache..."
        aws cloudfront create-invalidation \
            --distribution-id $DISTRIBUTION_ID \
            --paths "/*" > /dev/null
        print_success "CloudFront cache invalidated"
    fi
    
    print_success "Content deployed successfully!"
}

# Destroy infrastructure
destroy_infrastructure() {
    print_warning "This will DESTROY all AWS resources created by Terraform!"
    print_warning "This action cannot be undone."
    read -p "Are you absolutely sure? Type 'yes' to confirm: " confirm
    
    if [[ $confirm == "yes" ]]; then
        cd devops/terraform
        terraform destroy
        cd - > /dev/null
        print_success "Infrastructure destroyed"
    else
        print_info "Destruction cancelled"
    fi
}

# Show help
show_help() {
    print_header
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  check       Check if required tools are installed"
    echo "  dev         Start local development server"
    echo "  init        Initialize Terraform configuration"
    echo "  plan        Plan Terraform deployment"
    echo "  deploy-infra Deploy infrastructure to AWS"
    echo "  deploy      Deploy website content to S3"
    echo "  destroy     Destroy AWS infrastructure"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 check            # Check dependencies"
    echo "  $0 dev              # Start local development"
    echo "  $0 init             # Initialize Terraform"
    echo "  $0 deploy-infra     # Deploy AWS infrastructure"
    echo "  $0 deploy           # Deploy website content"
    echo ""
}

# Main script logic
main() {
    case "${1:-help}" in
        "check")
            print_header
            check_dependencies
            ;;
        "dev")
            print_header
            setup_dev
            ;;
        "init")
            print_header
            init_terraform
            ;;
        "plan")
            print_header
            plan_terraform
            ;;
        "deploy-infra")
            print_header
            deploy_infrastructure
            ;;
        "deploy")
            print_header
            deploy_content
            ;;
        "destroy")
            print_header
            destroy_infrastructure
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run the main function with all arguments
main "$@"
