# D Mac Portfolio - Multi-Cloud DevOps & Infrastructure

This directory contains all the DevOps and CI/CD configuration for deploying the D Mac Portfolio to **AWS**, **Azure**, and **Google Cloud Platform**.

## � **Multi-Cloud Architecture**

Deploy your portfolio to any or all major cloud providers:

| Cloud Provider | Services Used | Estimated Cost |
|----------------|---------------|----------------|
| 🔶 **AWS** | S3, CloudFront, Route53, Certificate Manager | $2-15/month |
| 🔷 **Azure** | Storage Account, Azure CDN, Azure DNS | $3-12/month |
| 🟡 **GCP** | Cloud Storage, Cloud CDN, Load Balancer, Cloud DNS | $1-8/month |

## 🚀 **Quick Start**

### **Use the Multi-Cloud Deploy Script**
```bash
# Check dependencies for all clouds
./devops/scripts/multi-cloud-deploy.sh check

# Or check for specific cloud
./devops/scripts/multi-cloud-deploy.sh check aws
./devops/scripts/multi-cloud-deploy.sh check azure
./devops/scripts/multi-cloud-deploy.sh check gcp

# Start local development
./devops/scripts/multi-cloud-deploy.sh dev

# Initialize cloud infrastructure
./devops/scripts/multi-cloud-deploy.sh init aws
./devops/scripts/multi-cloud-deploy.sh init azure
./devops/scripts/multi-cloud-deploy.sh init gcp

# Deploy to cloud (when you have credentials)
./devops/scripts/multi-cloud-deploy.sh deploy aws
./devops/scripts/multi-cloud-deploy.sh deploy azure
./devops/scripts/multi-cloud-deploy.sh deploy gcp
```

## 📁 Directory Structure

```
devops/
├── aws/                     # Amazon Web Services
│   └── terraform/          # AWS infrastructure as code
│       ├── main.tf         # AWS resources (S3, CloudFront, Route53)
│       ├── variables.tf    # Configuration variables
│       ├── outputs.tf      # Deployment outputs
│       └── terraform.tfvars.example
├── azure/                  # Microsoft Azure
│   └── bicep/             # Azure infrastructure as code
│       ├── main.bicep     # Azure resources (Storage, CDN, DNS)
│       └── main.parameters.json
├── gcp/                    # Google Cloud Platform
│   └── terraform/         # GCP infrastructure as code
│       ├── main.tf        # GCP resources (Storage, CDN, DNS)
│       ├── variables.tf   # Configuration variables
│       ├── outputs.tf     # Deployment outputs
│       └── terraform.tfvars.example
├── scripts/               # Deployment and utility scripts
│   ├── deploy.sh         # Original AWS-only script
│   ├── multi-cloud-deploy.sh  # Multi-cloud deployment script
│   ├── setup-aws.sh      # AWS configuration helper
│   └── setup-github.sh   # GitHub secrets setup
└── README.md             # This file

.github/workflows/
├── deploy.yml            # AWS deployment pipeline
├── deploy-azure.yml      # Azure deployment pipeline
└── deploy-gcp.yml        # GCP deployment pipeline
```

## 🚀 Quick Start

### Prerequisites

1. **AWS Account** - You'll need an AWS account
2. **AWS CLI** - Install and configure with your credentials
3. **Terraform** - Install Terraform CLI
4. **Git** - For version control and GitHub Actions

### 1. Install Dependencies

```bash
# Install AWS CLI (macOS)
brew install awscli

# Install Terraform (macOS)
brew install terraform

# Configure AWS CLI
aws configure
```

### 2. Initialize Infrastructure

```bash
# Make the deployment script executable
chmod +x devops/scripts/deploy.sh

# Check dependencies
./devops/scripts/deploy.sh check

# Initialize Terraform
./devops/scripts/deploy.sh init
```

### 3. Configure Your Deployment

Edit `devops/terraform/terraform.tfvars`:

```hcl
# AWS Configuration
aws_region = "us-east-1"
environment = "prod"

# Project Configuration
project_name = "dmac-portfolio"

# Domain Configuration (optional)
# domain_name = "your-domain.com"

# Additional configuration...
```

### 4. Deploy Infrastructure

```bash
# Plan the deployment (review what will be created)
./devops/scripts/deploy.sh plan

# Deploy the infrastructure
./devops/scripts/deploy.sh deploy-infra
```

### 5. Set Up GitHub Actions

After deploying infrastructure, add these secrets to your GitHub repository:

1. Go to your GitHub repository → Settings → Secrets and variables → Actions
2. Add the following secrets:
   - `AWS_ACCESS_KEY_ID` - From Terraform output
   - `AWS_SECRET_ACCESS_KEY` - From Terraform output  
   - `AWS_REGION` - Your AWS region (e.g., us-east-1)
   - `S3_BUCKET` - From Terraform output
   - `CLOUDFRONT_DISTRIBUTION_ID` - From Terraform output

### 6. Deploy Your Website

```bash
# Deploy website content manually
./devops/scripts/deploy.sh deploy

# Or push to main branch to trigger automatic deployment
git add .
git commit -m "Deploy portfolio"
git push origin main
```

## 🔧 Available Commands

```bash
# Development
./devops/scripts/deploy.sh dev              # Start local development server
./devops/scripts/deploy.sh check            # Check dependencies

# Infrastructure
./devops/scripts/deploy.sh init             # Initialize Terraform
./devops/scripts/deploy.sh plan             # Plan infrastructure changes
./devops/scripts/deploy.sh deploy-infra     # Deploy AWS infrastructure

# Content Deployment
./devops/scripts/deploy.sh deploy           # Deploy website content

# Cleanup
./devops/scripts/deploy.sh destroy          # Destroy infrastructure (⚠️ DANGEROUS)
```

## 🌐 CI/CD Pipeline

The GitHub Actions workflow (`deploy.yml`) automatically:

1. **Build & Test** - Validates HTML, CSS, and assets
2. **Deploy** - Syncs content to S3 and invalidates CloudFront cache
3. **Performance Check** - Runs Lighthouse audits

### Pipeline Triggers

- **Push to main/master** - Full deployment
- **Pull requests** - Build and test only
- **Manual trigger** - Available in GitHub Actions tab

## 💰 Cost Estimation

Typical monthly costs for a portfolio website:

- **S3** - $1-5 (depending on storage and requests)
- **CloudFront** - $1-10 (depending on traffic)
- **Route53** - $0.50 (if using custom domain)
- **Certificate Manager** - Free

**Total estimated cost: $2-15/month**

## 🔒 Security Features

- S3 bucket encryption at rest
- CloudFront HTTPS enforcement
- IAM roles with minimal required permissions
- Secure secrets management via GitHub Actions

## 🔧 Customization

### Custom Domain

To use your own domain:

1. Set `domain_name` in `terraform.tfvars`
2. Deploy infrastructure
3. Update your domain's nameservers to the Route53 values from Terraform output

### Performance Optimization

The setup includes:
- Gzip compression via CloudFront
- Optimal caching headers
- Image optimization recommendations
- Lighthouse performance monitoring

### Multi-Environment Support

To deploy multiple environments (dev, staging, prod):

1. Create separate `terraform.tfvars` files
2. Use different S3 bucket names and CloudFront distributions
3. Set up separate GitHub environments with different secrets

## 🆘 Troubleshooting

### Common Issues

1. **AWS credentials not configured**
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret, and region
   ```

2. **Terraform state conflicts**
   ```bash
   cd devops/terraform
   terraform force-unlock <lock-id>
   ```

3. **CloudFront cache not updating**
   - Cache invalidation can take 5-15 minutes
   - Force refresh with Ctrl+F5 or Cmd+Shift+R

4. **GitHub Actions failing**
   - Check that all required secrets are set
   - Verify AWS permissions for the IAM user

### Getting Help

- Check AWS CloudFormation console for stack events
- Review GitHub Actions logs for deployment issues
- Use `terraform plan` to preview changes before applying

## 📚 Additional Resources

- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/s3/latest/userguide/WebsiteHosting.html)
- [AWS CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

**Created with ✨ by D Mac** - Where Technology Meets Magic
