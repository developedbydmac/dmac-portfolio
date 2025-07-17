# GCP Infrastructure for D Mac Portfolio

## 🟡 **Google Cloud Resources**

This Terraform configuration creates:

- **Cloud Storage bucket** for static website hosting
- **Cloud CDN** with global load balancer
- **Cloud DNS** for custom domain (optional)
- **Managed SSL certificates**
- **IAM service account** for GitHub Actions

## 📋 **Prerequisites**

1. Google Cloud CLI: Download from https://cloud.google.com/sdk/docs/install
2. Terraform: `brew install terraform`
3. GCP Project with billing enabled
4. Enable required APIs

## 🚀 **Setup Steps**

### 1. Configure GCP
```bash
# Login to GCP
gcloud auth login

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable storage.googleapis.com
gcloud services enable dns.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable certificatemanager.googleapis.com

# Configure Application Default Credentials for Terraform
gcloud auth application-default login
```

### 2. Configure Terraform
Copy and edit the variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
project_id = "your-gcp-project-id"
project_name = "dmac-portfolio"
environment = "prod"
region = "us-central1"
domain_name = "your-domain.com"  # Optional
```

### 3. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Deploy
terraform apply
```

## 🔧 **GitHub Actions Setup**

After deployment, get the service account key:
```bash
# Get the base64 encoded service account key
terraform output -raw service_account_key
```

Add these secrets to your GitHub repository:

- `GCP_PROJECT_ID` - Your GCP project ID
- `GCP_SA_KEY` - Service account key (from terraform output)
- `GCP_BUCKET_NAME` - Cloud Storage bucket name
- `GCP_BACKEND_BUCKET` - Backend bucket name for load balancer

## 💰 **Estimated Costs**

- **Cloud Storage**: $0.02-2/month
- **Cloud CDN**: $0.50-4/month  
- **Load Balancer**: $2-3/month
- **Cloud DNS**: $0.20/month (if using custom domain)

**Total: ~$1-8/month** (Most cost-effective option!)

## 🌐 **Features**

- ✅ Static website hosting with versioning
- ✅ Global CDN with edge caching
- ✅ HTTP to HTTPS redirect
- ✅ Custom domain with managed SSL
- ✅ Global load balancer
- ✅ Gzip compression
- ✅ Carbon-neutral hosting

## 📊 **Performance Benefits**

- **Global Edge Locations**: 200+ locations worldwide
- **Smart Caching**: Intelligent cache policies per file type
- **Auto-scaling**: Handles traffic spikes automatically
- **Green Hosting**: Carbon-neutral infrastructure

## 🔍 **Monitoring**

View your resources in:
- GCP Console → Cloud Storage
- GCP Console → Network Services → Load Balancing
- GCP Console → Network Services → Cloud CDN
- GCP Console → Network Services → Cloud DNS

## 🚀 **Manual Content Upload**

```bash
# Upload files manually
gsutil -m rsync -r -d /path/to/your/files gs://YOUR_BUCKET_NAME/

# Set cache headers
gsutil -m setmeta -h "Cache-Control:public, max-age=31536000" gs://YOUR_BUCKET_NAME/assets/**
gsutil -m setmeta -h "Cache-Control:public, max-age=300" gs://YOUR_BUCKET_NAME/*.html

# Invalidate CDN cache
gcloud compute url-maps invalidate-cdn-cache YOUR_URL_MAP --path "/*"
```

## 🔄 **Updates and Maintenance**

```bash
# Update infrastructure
terraform plan
terraform apply

# View current state
terraform show

# Destroy everything (⚠️ DANGEROUS)
terraform destroy
```

## 🚀 **Advanced Features**

### Custom Error Pages
The setup includes:
- Custom 404 pages
- Proper redirects for single-page applications
- SEO-friendly URLs

### Security
- HTTPS enforcement
- Security headers
- IAM with minimal permissions
- Secure service account keys

### Performance
- Intelligent caching based on file types
- Gzip compression
- HTTP/2 support
- Global edge caching

## 💡 **Cost Optimization Tips**

1. **Use regional storage** for lower costs if global access isn't needed
2. **Monitor Cloud CDN usage** and adjust cache policies
3. **Use lifecycle policies** to delete old file versions
4. **Enable compression** to reduce bandwidth costs

## 🌍 **Global Reach**

GCP's global network provides:
- 200+ edge locations
- 25+ regions
- 76+ zones
- Direct connections to major ISPs

Perfect for a global portfolio audience! 🌟
