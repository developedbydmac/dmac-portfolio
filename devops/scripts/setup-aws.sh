#!/bin/bash

# AWS Profile and Region Setup Script
# Helps configure AWS CLI for the D Mac Portfolio project

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

echo -e "${BLUE}🔧 AWS Configuration Setup for D Mac Portfolio${NC}"
echo "================================================"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_warning "AWS CLI is not installed. Please install it first:"
    echo "  macOS: brew install awscli"
    echo "  Linux: sudo apt-get install awscli"
    echo "  Windows: Download from AWS website"
    exit 1
fi

print_info "AWS CLI version:"
aws --version

echo ""
print_info "Current AWS configuration:"
if aws sts get-caller-identity &> /dev/null; then
    aws sts get-caller-identity
    print_success "AWS CLI is already configured"
    
    read -p "Do you want to reconfigure? (y/N): " reconfigure
    if [[ ! $reconfigure =~ ^[Yy]$ ]]; then
        print_info "Keeping existing configuration"
        exit 0
    fi
else
    print_warning "AWS CLI is not configured"
fi

echo ""
print_info "Please enter your AWS credentials:"
print_info "(You can find these in AWS Console → IAM → Users → Security credentials)"

echo ""
read -p "AWS Access Key ID: " access_key
read -s -p "AWS Secret Access Key: " secret_key
echo ""
read -p "Default region [us-east-1]: " region
region=${region:-us-east-1}
read -p "Default output format [json]: " output
output=${output:-json}

# Configure AWS CLI
aws configure set aws_access_key_id "$access_key"
aws configure set aws_secret_access_key "$secret_key"
aws configure set default.region "$region"
aws configure set default.output "$output"

echo ""
print_info "Testing AWS configuration..."

if aws sts get-caller-identity &> /dev/null; then
    print_success "AWS configuration successful!"
    
    echo ""
    print_info "Your AWS identity:"
    aws sts get-caller-identity
    
    echo ""
    print_success "You're ready to deploy your portfolio to AWS!"
    print_info "Next steps:"
    echo "  1. cd to your project directory"
    echo "  2. Run: ./devops/scripts/deploy.sh init"
    echo "  3. Edit: devops/terraform/terraform.tfvars"
    echo "  4. Run: ./devops/scripts/deploy.sh deploy-infra"
    
else
    print_warning "AWS configuration failed. Please check your credentials."
    exit 1
fi
