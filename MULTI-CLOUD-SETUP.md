# D Mac Portfolio - Multi-Cloud Setup Guide

## 🌟 **Multi-Cloud Portfolio is Ready!**

Your portfolio is now configured to deploy to **AWS**, **Azure**, and **GCP**! Here's your complete setup:

### 📁 **New Multi-Cloud Structure**

```
dmac-portfolio/
├── devops/
│   ├── aws/                    # Amazon Web Services
│   │   └── terraform/         # AWS infrastructure as code
│   ├── azure/                 # Microsoft Azure  
│   │   └── bicep/            # Azure infrastructure as code
│   ├── gcp/                   # Google Cloud Platform
│   │   └── terraform/        # GCP infrastructure as code
│   └── scripts/
│       ├── deploy.sh         # Original AWS-only script
│       └── multi-cloud-deploy.sh  # NEW: Multi-cloud script
├── .github/workflows/
│   ├── deploy.yml           # AWS deployment
│   ├── deploy-azure.yml     # Azure deployment  
│   └── deploy-gcp.yml       # GCP deployment
└── [your existing files...]
```

## 🚀 **Quick Start Guide**

### **1. Use the Multi-Cloud Script**

```bash
# Check what tools you need for each cloud
./devops/scripts/multi-cloud-deploy.sh check

# Start local development
./devops/scripts/multi-cloud-deploy.sh dev

# Initialize a specific cloud
./devops/scripts/multi-cloud-deploy.sh init aws
./devops/scripts/multi-cloud-deploy.sh init azure  
./devops/scripts/multi-cloud-deploy.sh init gcp

# Plan deployments
./devops/scripts/multi-cloud-deploy.sh plan aws
./devops/scripts/multi-cloud-deploy.sh plan gcp

# Deploy to clouds (when you have credentials)
./devops/scripts/multi-cloud-deploy.sh deploy aws
./devops/scripts/multi-cloud-deploy.sh deploy azure
./devops/scripts/multi-cloud-deploy.sh deploy gcp

# Check deployment status
./devops/scripts/multi-cloud-deploy.sh status
```

## ☁️ **Cloud Setup Instructions**

### 🔶 **AWS Setup** (Ready to use!)
```bash
# 1. Install AWS CLI
brew install awscli

# 2. Configure credentials
aws configure

# 3. Initialize and deploy
./devops/scripts/multi-cloud-deploy.sh init aws
./devops/scripts/multi-cloud-deploy.sh deploy aws
```

### 🔷 **Azure Setup** (When you get Azure credentials)
```bash
# 1. Install Azure CLI
brew install azure-cli

# 2. Login to Azure
az login

# 3. Create resource group
az group create --name dmac-portfolio-rg --location eastus

# 4. Deploy infrastructure
cd devops/azure/bicep
az deployment group create \
  --resource-group dmac-portfolio-rg \
  --template-file main.bicep \
  --parameters main.parameters.json
```

### 🟡 **GCP Setup** (When you get GCP credentials)
```bash
# 1. Install Google Cloud CLI
# Download from: https://cloud.google.com/sdk/docs/install

# 2. Login and set project
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# 3. Initialize and deploy
./devops/scripts/multi-cloud-deploy.sh init gcp
./devops/scripts/multi-cloud-deploy.sh deploy gcp
```

## 🎯 **What Each Cloud Provides**

| Feature | AWS | Azure | GCP |
|---------|-----|-------|-----|
| **Static Hosting** | S3 | Storage Account | Cloud Storage |
| **CDN** | CloudFront | Azure CDN | Cloud CDN |
| **DNS** | Route53 | Azure DNS | Cloud DNS |
| **SSL** | Certificate Manager | Managed Certificates | Managed SSL |
| **Cost (estimated)** | $2-15/month | $3-12/month | $1-8/month |

## 🤖 **Automated CI/CD**

Each cloud has its own GitHub Actions workflow:

- **AWS**: Triggers on changes to AWS files or main content
- **Azure**: Triggers on changes to Azure files or main content  
- **GCP**: Triggers on changes to GCP files or main content

### **GitHub Secrets Needed**

**For AWS:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `S3_BUCKET`
- `CLOUDFRONT_DISTRIBUTION_ID`

**For Azure:**
- `AZURE_CREDENTIALS`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_RESOURCE_GROUP`
- `AZURE_STORAGE_ACCOUNT`
- `AZURE_CDN_PROFILE`
- `AZURE_CDN_ENDPOINT`

**For GCP:**
- `GCP_PROJECT_ID`
- `GCP_SA_KEY`
- `GCP_BUCKET_NAME`
- `GCP_BACKEND_BUCKET`

## 🌐 **Planned URLs**

Once deployed, your portfolio will be available at:

- **AWS**: `https://your-cloudfront-domain.cloudfront.net`
- **Azure**: `https://your-storage-account.z13.web.core.windows.net`
- **GCP**: `https://your-load-balancer-ip` or custom domain

## 📊 **Marketing Strategy Ready**

Each deployment includes cloud-specific pages:
- `/aws-info.html` - Showcases AWS features
- `/azure-info.html` - Showcases Azure integration
- `/gcp-info.html` - Showcases GCP cost-efficiency

## 🔧 **Customization Options**

### **Add Custom Domains**
Update these files with your domain:
- `devops/aws/terraform/terraform.tfvars`
- `devops/azure/bicep/main.parameters.json`
- `devops/gcp/terraform/terraform.tfvars`

### **Modify Costs and Performance**
Each cloud has configurable options for:
- Cache TTL settings
- Storage classes
- CDN configurations
- SSL policies

## 🆘 **When You're Ready to Deploy**

1. **Get your cloud credentials** from AWS, Azure, and/or GCP
2. **Run the dependency check**: `./devops/scripts/multi-cloud-deploy.sh check`
3. **Initialize your chosen cloud(s)**: `./devops/scripts/multi-cloud-deploy.sh init aws`
4. **Configure the settings** in the respective `terraform.tfvars` or `parameters.json` files
5. **Deploy**: `./devops/scripts/multi-cloud-deploy.sh deploy aws`
6. **Set up GitHub Actions** with the secrets from the deployment outputs

## 🎉 **You're Ready!**

Your portfolio now has **enterprise-grade, multi-cloud DevOps** setup that will impress any potential employer or client. You can:

✅ Deploy to any major cloud provider  
✅ Compare costs and performance across clouds  
✅ Show expertise in AWS, Azure, AND GCP  
✅ Demonstrate advanced DevOps practices  
✅ Market yourself as a cloud-agnostic expert  

**This setup positions you as a true multi-cloud professional!** 🚀

---

**Need help?** Check the detailed documentation in each `devops/[cloud]/` folder or run the help command:
```bash
./devops/scripts/multi-cloud-deploy.sh help
```
