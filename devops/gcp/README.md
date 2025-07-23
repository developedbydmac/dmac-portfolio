# GCP Infrastructure for D Mac Portfolio

## 🟡 **Google Cloud Platform Resources**

This Terraform configuration creates comprehensive GCP resources equivalent to Azure setup:

- **Cloud Storage + Cloud CDN** for static website hosting (Azure Static Web Apps)
- **Cloud Functions** for API endpoints (Azure Functions)
- **Firestore** for data storage (Cosmos DB)
- **Global Load Balancer** for traffic routing and SSL
- **Secret Manager** for secure credential storage (Key Vault)
- **Cloud Monitoring & Logging** for observability (Application Insights)

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
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable firestore.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com

# Configure Application Default Credentials for Terraform
gcloud auth application-default login
```

### 2. Configure Terraform Variables
Copy and edit the variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
# Basic Configuration
project_id       = "your-gcp-project-id"
project_name     = "dmac-portfolio"
environment      = "prod"
region           = "us-east1"
zone             = "us-east1-a"
bucket_location  = "US"

# Optional: Custom domain
domain_name = "your-domain.com"  # Leave empty for default global IP
```

### 3. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply changes
terraform apply
```

## 🏗️ **Infrastructure Components**

### **Static Website Hosting**
- **Cloud Storage Bucket**: Hosts static files (HTML, CSS, JS, images)
- **Global Load Balancer**: Routes traffic with SSL termination
- **Cloud CDN**: Global content delivery with caching
- **Managed SSL Certificate**: Automatic HTTPS certificates

### **API Functions (Cloud Functions)**
- **Visits Function**: Tracks and returns visitor count
- **Contact Function**: Handles contact form submissions
- **HTTP Triggers**: RESTful endpoints with CORS support

### **Database (Firestore)**
- **Native Mode**: Document-based NoSQL database
- **Collections**: Stores visitor counts and contact messages
- **Transactions**: Atomic operations for data consistency

### **Security & Secrets**
- **Secret Manager**: Stores API keys and sensitive configuration
- **Service Accounts**: Least-privilege access for Cloud Functions
- **IAM Roles**: Fine-grained permission management

### **Monitoring (Cloud Operations)**
- **Cloud Logging**: Centralized logging for all services
- **Cloud Monitoring**: Custom dashboard with metrics
- **Alerting**: Performance and error monitoring

## 🔗 **Service Equivalencies**

| Azure Service | GCP Equivalent | Purpose |
|---------------|----------------|---------|
| Static Web Apps | Cloud Storage + CDN | Static hosting + CDN |
| Azure Functions | Cloud Functions | Serverless compute |
| Cosmos DB | Firestore | NoSQL database |
| Key Vault | Secret Manager | Secret storage |
| Application Insights | Cloud Monitoring | Monitoring & logging |
| Managed Identity | Service Accounts | Service authentication |

## 📊 **Cost Estimates (Monthly)**

| Service | Usage | Estimated Cost |
|---------|-------|----------------|
| Cloud Storage | 1GB storage, 10K operations | $0.02 |
| Cloud CDN | 1GB egress, 10K requests | $0.08 |
| Global Load Balancer | 1 forwarding rule | $18.00 |
| Cloud Functions | 100K invocations, 256MB | $0.40 |
| Firestore | 10K reads/writes, 1GB storage | $0.36 |
| Secret Manager | 1 secret, 100 access operations | $0.06 |
| Cloud Monitoring | Basic monitoring | $0.00 |
| **Total** | | **~$18.92/month** |

*Note: Load Balancer cost is the main expense for global availability*

## 🔧 **API Endpoints**

After deployment, your API endpoints will be:
```
POST https://{function-url}/api/visits   # Visitor count
POST https://{function-url}/api/contact  # Contact form
```

Get function URLs with:
```bash
terraform output visits_function_url
terraform output contact_function_url
```

## 📈 **Monitoring & Logs**

### Cloud Monitoring Dashboard
Access your monitoring dashboard at:
```bash
# Get dashboard URL
terraform output monitoring_dashboard_url
```

### View Logs
```bash
# Cloud Function logs
gcloud logging read "resource.type=cloud_function AND resource.labels.function_name:dmac-portfolio" --limit 50

# Real-time logs
gcloud logging tail "resource.type=cloud_function"
```

## 🔐 **Security Best Practices**

- ✅ **No hardcoded credentials** - Uses Service Accounts and Secret Manager
- ✅ **HTTPS everywhere** - Global Load Balancer enforces SSL/TLS
- ✅ **Least privilege** - IAM roles grant minimal required permissions
- ✅ **Encryption at rest** - All services use Google's encryption
- ✅ **Audit logging** - Cloud Audit Logs track all API calls

## 🚀 **Deployment Commands**

```bash
# Quick deployment
terraform apply -auto-approve

# Update functions only
terraform apply -target=google_cloudfunctions_function.visits_function -target=google_cloudfunctions_function.contact_function

# Destroy infrastructure
terraform destroy

# View all outputs
terraform output
```

## 🔍 **Troubleshooting**

### Common Issues

1. **API not enabled**:
   ```bash
   gcloud services list --enabled
   gcloud services enable cloudfunctions.googleapis.com
   ```

2. **Function deployment fails**:
   ```bash
   # Check source code exists
   ls -la devops/gcp/functions/*/
   
   # Verify function source
   gcloud functions describe visits-function --region=us-east1
   ```

3. **Firestore permission denied**:
   ```bash
   # Check service account permissions
   gcloud projects get-iam-policy YOUR_PROJECT_ID
   ```

### Debug Commands
```bash
# Test Cloud Function
gcloud functions call visits-function --region=us-east1 --data='{}'

# Check storage bucket
gsutil ls -la gs://your-bucket-name

# Validate load balancer
gcloud compute url-maps describe portfolio-url-map-XXXXX --global
```

## 📚 **Additional Resources**

- [Cloud Functions Best Practices](https://cloud.google.com/functions/docs/bestpractices)
- [Cloud Storage Static Website Hosting](https://cloud.google.com/storage/docs/hosting-static-website)
- [Firestore Documentation](https://cloud.google.com/firestore/docs)
- [Cloud Monitoring Best Practices](https://cloud.google.com/monitoring/best-practices)

---

**Next Steps**: Configure your frontend application to use the Cloud Function endpoints for visitor counting and contact form submission.
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
