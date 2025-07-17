#!/bin/bash

# GitHub Repository Setup Script
# Helps configure GitHub repository secrets for CI/CD

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
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

echo -e "${BLUE}🔧 GitHub Repository Setup for D Mac Portfolio${NC}"
echo "=============================================="

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    print_error "This is not a Git repository. Please run from your project root."
    exit 1
fi

# Check if GitHub CLI is installed
if command -v gh &> /dev/null; then
    print_info "GitHub CLI detected. You can use 'gh' commands to set secrets automatically."
    
    # Check if user is logged in
    if gh auth status &> /dev/null; then
        print_success "You're logged into GitHub CLI"
        use_gh_cli=true
    else
        print_warning "Not logged into GitHub CLI. Run 'gh auth login' first."
        use_gh_cli=false
    fi
else
    print_info "GitHub CLI not found. You'll need to set secrets manually."
    use_gh_cli=false
fi

echo ""
print_info "First, make sure your infrastructure is deployed:"
print_info "Run: ./devops/scripts/deploy.sh deploy-infra"

echo ""
print_info "Getting values from Terraform..."

cd devops/terraform

if [ ! -f "terraform.tfstate" ]; then
    print_error "Terraform state not found. Deploy infrastructure first."
    exit 1
fi

# Get values from Terraform outputs
ACCESS_KEY_ID=$(terraform output -raw github_actions_access_key_id 2>/dev/null)
SECRET_ACCESS_KEY=$(terraform output -raw github_actions_secret_access_key 2>/dev/null)
REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")
S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null)
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null)

cd - > /dev/null

if [ -z "$ACCESS_KEY_ID" ] || [ -z "$SECRET_ACCESS_KEY" ] || [ -z "$S3_BUCKET" ] || [ -z "$DISTRIBUTION_ID" ]; then
    print_error "Could not get all required values from Terraform. Make sure infrastructure is deployed."
    exit 1
fi

echo ""
print_success "Retrieved values from Terraform:"
echo "  AWS_ACCESS_KEY_ID: $ACCESS_KEY_ID"
echo "  AWS_SECRET_ACCESS_KEY: [HIDDEN]"
echo "  AWS_REGION: $REGION"
echo "  S3_BUCKET: $S3_BUCKET"
echo "  CLOUDFRONT_DISTRIBUTION_ID: $DISTRIBUTION_ID"

if [ "$use_gh_cli" = true ]; then
    echo ""
    print_info "Setting GitHub repository secrets using GitHub CLI..."
    
    # Set secrets using GitHub CLI
    echo "$ACCESS_KEY_ID" | gh secret set AWS_ACCESS_KEY_ID
    echo "$SECRET_ACCESS_KEY" | gh secret set AWS_SECRET_ACCESS_KEY
    echo "$REGION" | gh secret set AWS_REGION
    echo "$S3_BUCKET" | gh secret set S3_BUCKET
    echo "$DISTRIBUTION_ID" | gh secret set CLOUDFRONT_DISTRIBUTION_ID
    
    print_success "GitHub repository secrets set successfully!"
    
else
    echo ""
    print_warning "Manual setup required. Add these secrets to your GitHub repository:"
    print_info "Go to: GitHub Repository → Settings → Secrets and variables → Actions"
    
    echo ""
    echo "Add these secrets:"
    echo "  AWS_ACCESS_KEY_ID = $ACCESS_KEY_ID"
    echo "  AWS_SECRET_ACCESS_KEY = [Get from Terraform output]"
    echo "  AWS_REGION = $REGION"
    echo "  S3_BUCKET = $S3_BUCKET"
    echo "  CLOUDFRONT_DISTRIBUTION_ID = $DISTRIBUTION_ID"
    
    echo ""
    print_info "To get the secret access key, run:"
    echo "  cd devops/terraform && terraform output github_actions_secret_access_key"
fi

echo ""
print_success "Setup complete! Your CI/CD pipeline is ready."
print_info "Next steps:"
echo "  1. Push your code to the main branch"
echo "  2. Check GitHub Actions tab for deployment progress"
echo "  3. Your portfolio will be live shortly!"

# Show website URL
cd devops/terraform
WEBSITE_URL=$(terraform output -raw website_url 2>/dev/null)
if [ -n "$WEBSITE_URL" ]; then
    echo ""
    print_success "Your portfolio will be available at: $WEBSITE_URL"
fi
cd - > /dev/null
