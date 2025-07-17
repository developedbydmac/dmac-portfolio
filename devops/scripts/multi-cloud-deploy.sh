#!/bin/bash

# D Mac Portfolio - Multi-Cloud Development & Deployment Script
# This script helps with local development and deployment to AWS, Azure, and GCP

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Cloud provider constants
CLOUD_AWS="aws"
CLOUD_AZURE="azure"
CLOUD_GCP="gcp"

# Functions
print_header() {
    echo -e "${BLUE}"
    echo "========================================"
    echo "  D Mac Portfolio Multi-Cloud DevOps"
    echo "========================================"
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

print_cloud_header() {
    local cloud=$1
    case $cloud in
        "aws")
            echo -e "${YELLOW}🔶 AWS Operations${NC}"
            ;;
        "azure")
            echo -e "${CYAN}🔷 Azure Operations${NC}"
            ;;
        "gcp")
            echo -e "${PURPLE}🟡 GCP Operations${NC}"
            ;;
        *)
            echo -e "${BLUE}☁️  Multi-Cloud Operations${NC}"
            ;;
    esac
}

# Validate cloud provider
validate_cloud() {
    local cloud=$1
    case $cloud in
        $CLOUD_AWS|$CLOUD_AZURE|$CLOUD_GCP)
            return 0
            ;;
        *)
            print_error "Invalid cloud provider: $cloud"
            print_info "Valid options: aws, azure, gcp"
            return 1
            ;;
    esac
}

# Check if required tools are installed
check_dependencies() {
    local cloud=${1:-"all"}
    
    print_info "Checking dependencies for: $cloud"
    
    local missing_tools=()
    
    # Common tools
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi
    
    # Cloud-specific tools
    case $cloud in
        $CLOUD_AWS|"all")
            if ! command -v aws &> /dev/null; then
                missing_tools+=("aws-cli")
            fi
            if ! command -v terraform &> /dev/null; then
                missing_tools+=("terraform")
            fi
            ;;
    esac
    
    case $cloud in
        $CLOUD_AZURE|"all")
            if ! command -v az &> /dev/null; then
                missing_tools+=("azure-cli")
            fi
            ;;
    esac
    
    case $cloud in
        $CLOUD_GCP|"all")
            if ! command -v gcloud &> /dev/null; then
                missing_tools+=("gcloud-cli")
            fi
            if ! command -v terraform &> /dev/null && [[ ! " ${missing_tools[@]} " =~ " terraform " ]]; then
                missing_tools+=("terraform")
            fi
            ;;
    esac
    
    if [ ${#missing_tools[@]} -eq 0 ]; then
        print_success "All required dependencies are available"
        return 0
    else
        print_warning "Missing tools: ${missing_tools[*]}"
        echo ""
        print_info "Installation instructions:"
        for tool in "${missing_tools[@]}"; do
            case $tool in
                "git")
                    echo "  📥 Git: https://git-scm.com/downloads"
                    ;;
                "aws-cli")
                    echo "  🔶 AWS CLI: brew install awscli"
                    ;;
                "azure-cli")
                    echo "  🔷 Azure CLI: brew install azure-cli"
                    ;;
                "gcloud-cli")
                    echo "  🟡 GCloud CLI: https://cloud.google.com/sdk/docs/install"
                    ;;
                "terraform")
                    echo "  🏗️  Terraform: brew install terraform"
                    ;;
                "curl")
                    echo "  📡 Curl: brew install curl"
                    ;;
            esac
        done
        return 1
    fi
}

# Setup local development environment
setup_dev() {
    print_info "Setting up local development environment..."
    
    # Create necessary directories if they don't exist
    mkdir -p components assets/images styles scripts
    
    # Check if main files exist
    if [ ! -f "index.html" ]; then
        print_warning "index.html not found in current directory"
        print_info "Make sure you're running this from the project root"
    fi
    
    # Check for alternative HTTP servers
    local server_started=false
    
    # Try Python 3 first
    if command -v python3 &> /dev/null; then
        print_info "Starting local development server with Python 3..."
        print_info "Your portfolio will be available at: http://localhost:8000"
        print_info "Press Ctrl+C to stop the server"
        python3 -m http.server 8000
        server_started=true
    # Try Python 2
    elif command -v python &> /dev/null; then
        print_info "Starting local development server with Python 2..."
        print_info "Your portfolio will be available at: http://localhost:8000"
        print_info "Press Ctrl+C to stop the server"
        python -m SimpleHTTPServer 8000
        server_started=true
    # Try Node.js
    elif command -v npx &> /dev/null; then
        print_info "Starting local development server with Node.js..."
        print_info "Your portfolio will be available at: http://localhost:8000"
        print_info "Press Ctrl+C to stop the server"
        npx http-server -p 8000
        server_started=true
    # Try PHP
    elif command -v php &> /dev/null; then
        print_info "Starting local development server with PHP..."
        print_info "Your portfolio will be available at: http://localhost:8000"
        print_info "Press Ctrl+C to stop the server"
        php -S localhost:8000
        server_started=true
    fi
    
    if [ "$server_started" = false ]; then
        print_warning "No suitable HTTP server found."
        print_info "Install one of the following:"
        echo "  • Python: python3 -m http.server 8000"
        echo "  • Node.js: npx http-server -p 8000"
        echo "  • PHP: php -S localhost:8000"
        echo "  • Or use any other local server of your choice"
    fi
}

# Initialize cloud infrastructure
init_infrastructure() {
    local cloud=$1
    
    if ! validate_cloud "$cloud"; then
        return 1
    fi
    
    print_cloud_header "$cloud"
    print_info "Initializing $cloud infrastructure..."
    
    case $cloud in
        $CLOUD_AWS)
            init_aws
            ;;
        $CLOUD_AZURE)
            init_azure
            ;;
        $CLOUD_GCP)
            init_gcp
            ;;
    esac
}

# AWS initialization
init_aws() {
    print_info "Initializing AWS infrastructure..."
    
    cd devops/aws/terraform
    
    # Copy example variables if terraform.tfvars doesn't exist
    if [ ! -f "terraform.tfvars" ]; then
        print_info "Creating terraform.tfvars from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit devops/aws/terraform/terraform.tfvars with your specific values"
        cd - > /dev/null
        return 1
    fi
    
    # Initialize Terraform
    terraform init
    
    print_success "AWS Terraform initialized successfully"
    cd - > /dev/null
}

# Azure initialization
init_azure() {
    print_info "Initializing Azure infrastructure..."
    
    cd devops/azure/bicep
    
    # Check if parameters file exists
    if [ ! -f "main.parameters.json" ]; then
        print_error "main.parameters.json not found"
        cd - > /dev/null
        return 1
    fi
    
    # Validate Bicep template
    if command -v az &> /dev/null; then
        print_info "Validating Bicep template..."
        az bicep build --file main.bicep
        print_success "Bicep template validation passed"
    else
        print_warning "Azure CLI not found. Cannot validate Bicep template."
        print_info "Install Azure CLI: brew install azure-cli"
    fi
    
    print_success "Azure Bicep initialized successfully"
    print_info "Edit devops/azure/bicep/main.parameters.json for your configuration"
    cd - > /dev/null
}

# GCP initialization
init_gcp() {
    print_info "Initializing GCP infrastructure..."
    
    cd devops/gcp/terraform
    
    # Copy example variables if terraform.tfvars doesn't exist
    if [ ! -f "terraform.tfvars" ]; then
        print_info "Creating terraform.tfvars from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit devops/gcp/terraform/terraform.tfvars with your specific values"
        print_warning "Don't forget to set your GCP project ID!"
        cd - > /dev/null
        return 1
    fi
    
    # Initialize Terraform
    terraform init
    
    print_success "GCP Terraform initialized successfully"
    cd - > /dev/null
}

# Plan infrastructure deployment
plan_infrastructure() {
    local cloud=$1
    
    if ! validate_cloud "$cloud"; then
        return 1
    fi
    
    print_cloud_header "$cloud"
    print_info "Planning $cloud infrastructure deployment..."
    
    case $cloud in
        $CLOUD_AWS)
            plan_aws
            ;;
        $CLOUD_AZURE)
            plan_azure
            ;;
        $CLOUD_GCP)
            plan_gcp
            ;;
    esac
}

# AWS planning
plan_aws() {
    cd devops/aws/terraform
    
    if [ ! -f "terraform.tfvars" ]; then
        print_error "terraform.tfvars not found. Run 'init aws' first."
        cd - > /dev/null
        return 1
    fi
    
    terraform plan
    cd - > /dev/null
}

# Azure planning
plan_azure() {
    cd devops/azure/bicep
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI not found. Install it first: brew install azure-cli"
        cd - > /dev/null
        return 1
    fi
    
    print_info "Creating deployment what-if analysis..."
    print_warning "Make sure you're logged in: az login"
    
    # This would show what resources would be created
    # az deployment group what-if --resource-group YOUR_RG --template-file main.bicep --parameters main.parameters.json
    print_info "Run this command after setting up your resource group:"
    echo "az deployment group what-if --resource-group YOUR_RG --template-file main.bicep --parameters main.parameters.json"
    
    cd - > /dev/null
}

# GCP planning
plan_gcp() {
    cd devops/gcp/terraform
    
    if [ ! -f "terraform.tfvars" ]; then
        print_error "terraform.tfvars not found. Run 'init gcp' first."
        cd - > /dev/null
        return 1
    fi
    
    terraform plan
    cd - > /dev/null
}

# Deploy infrastructure
deploy_infrastructure() {
    local cloud=$1
    
    if ! validate_cloud "$cloud"; then
        return 1
    fi
    
    print_cloud_header "$cloud"
    print_warning "This will create $cloud resources which may incur costs."
    read -p "Do you want to continue? (y/N): " confirm
    
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        case $cloud in
            $CLOUD_AWS)
                deploy_aws
                ;;
            $CLOUD_AZURE)
                deploy_azure
                ;;
            $CLOUD_GCP)
                deploy_gcp
                ;;
        esac
    else
        print_info "Deployment cancelled"
    fi
}

# AWS deployment
deploy_aws() {
    cd devops/aws/terraform
    terraform apply
    
    print_success "AWS infrastructure deployed successfully!"
    print_info "Add the output values to your GitHub repository secrets"
    
    echo ""
    print_info "Important values for GitHub Actions:"
    terraform output github_actions_access_key_id
    echo "AWS_SECRET_ACCESS_KEY: (sensitive - check terraform output)"
    terraform output -raw s3_bucket_name
    terraform output -raw cloudfront_distribution_id
    
    cd - > /dev/null
}

# Azure deployment
deploy_azure() {
    cd devops/azure/bicep
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI not found. Install it first: brew install azure-cli"
        cd - > /dev/null
        return 1
    fi
    
    print_info "Make sure you're logged in and have selected the right subscription:"
    echo "az login"
    echo "az account set --subscription YOUR_SUBSCRIPTION_ID"
    echo ""
    print_info "Create a resource group and deploy:"
    echo "az group create --name dmac-portfolio-rg --location eastus"
    echo "az deployment group create --resource-group dmac-portfolio-rg --template-file main.bicep --parameters main.parameters.json"
    
    cd - > /dev/null
}

# GCP deployment
deploy_gcp() {
    cd devops/gcp/terraform
    
    print_info "Make sure you're authenticated with GCP:"
    echo "gcloud auth login"
    echo "gcloud config set project YOUR_PROJECT_ID"
    echo ""
    
    terraform apply
    
    print_success "GCP infrastructure deployed successfully!"
    print_info "Add the output values to your GitHub repository secrets"
    
    cd - > /dev/null
}

# Show cloud status
show_status() {
    local cloud=${1:-"all"}
    
    print_header
    print_info "Multi-Cloud Portfolio Status"
    echo ""
    
    if [[ $cloud == "all" || $cloud == $CLOUD_AWS ]]; then
        print_cloud_header $CLOUD_AWS
        if [ -f "devops/aws/terraform/terraform.tfstate" ]; then
            print_success "AWS infrastructure deployed"
            cd devops/aws/terraform
            if command -v terraform &> /dev/null; then
                echo "Website URL: $(terraform output -raw website_url 2>/dev/null || echo 'Unknown')"
            fi
            cd - > /dev/null
        else
            print_warning "AWS infrastructure not deployed"
        fi
        echo ""
    fi
    
    if [[ $cloud == "all" || $cloud == $CLOUD_AZURE ]]; then
        print_cloud_header $CLOUD_AZURE
        if command -v az &> /dev/null && az account show &> /dev/null; then
            print_success "Azure CLI authenticated"
            # Could check for deployed resources here
        else
            print_warning "Azure CLI not authenticated"
        fi
        echo ""
    fi
    
    if [[ $cloud == "all" || $cloud == $CLOUD_GCP ]]; then
        print_cloud_header $CLOUD_GCP
        if [ -f "devops/gcp/terraform/terraform.tfstate" ]; then
            print_success "GCP infrastructure deployed"
            cd devops/gcp/terraform
            if command -v terraform &> /dev/null; then
                echo "Website URL: $(terraform output -raw website_url 2>/dev/null || echo 'Unknown')"
            fi
            cd - > /dev/null
        else
            print_warning "GCP infrastructure not deployed"
        fi
        echo ""
    fi
}

# Show help
show_help() {
    print_header
    echo "Usage: $0 [command] [cloud-provider]"
    echo ""
    echo "Cloud Providers:"
    echo "  aws         Amazon Web Services"
    echo "  azure       Microsoft Azure"
    echo "  gcp         Google Cloud Platform"
    echo ""
    echo "Commands:"
    echo "  check [cloud]           Check if required tools are installed"
    echo "  dev                     Start local development server"
    echo "  init [cloud]            Initialize infrastructure for cloud provider"
    echo "  plan [cloud]            Plan infrastructure deployment"
    echo "  deploy [cloud]          Deploy infrastructure to cloud provider"
    echo "  status [cloud]          Show deployment status"
    echo "  help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 check                # Check all dependencies"
    echo "  $0 check aws           # Check AWS dependencies only"
    echo "  $0 dev                 # Start local development"
    echo "  $0 init aws            # Initialize AWS infrastructure"
    echo "  $0 plan gcp            # Plan GCP deployment"
    echo "  $0 deploy azure        # Deploy to Azure"
    echo "  $0 status              # Show all cloud status"
    echo ""
    echo "🔶 AWS Setup:"
    echo "  1. Install AWS CLI: brew install awscli"
    echo "  2. Configure: aws configure"
    echo "  3. Initialize: $0 init aws"
    echo "  4. Deploy: $0 deploy aws"
    echo ""
    echo "🔷 Azure Setup:"
    echo "  1. Install Azure CLI: brew install azure-cli"
    echo "  2. Login: az login"
    echo "  3. Initialize: $0 init azure"
    echo "  4. Deploy manually (see instructions)"
    echo ""
    echo "🟡 GCP Setup:"
    echo "  1. Install GCloud CLI: https://cloud.google.com/sdk/docs/install"
    echo "  2. Login: gcloud auth login"
    echo "  3. Set project: gcloud config set project YOUR_PROJECT_ID"
    echo "  4. Initialize: $0 init gcp"
    echo "  5. Deploy: $0 deploy gcp"
    echo ""
}

# Main script logic
main() {
    local command=${1:-help}
    local cloud=${2:-}
    
    case $command in
        "check")
            print_header
            check_dependencies "$cloud"
            ;;
        "dev")
            print_header
            setup_dev
            ;;
        "init")
            if [ -z "$cloud" ]; then
                print_error "Please specify a cloud provider: aws, azure, or gcp"
                show_help
                return 1
            fi
            print_header
            init_infrastructure "$cloud"
            ;;
        "plan")
            if [ -z "$cloud" ]; then
                print_error "Please specify a cloud provider: aws, azure, or gcp"
                show_help
                return 1
            fi
            print_header
            plan_infrastructure "$cloud"
            ;;
        "deploy")
            if [ -z "$cloud" ]; then
                print_error "Please specify a cloud provider: aws, azure, or gcp"
                show_help
                return 1
            fi
            print_header
            deploy_infrastructure "$cloud"
            ;;
        "status")
            show_status "$cloud"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run the main function with all arguments
main "$@"
