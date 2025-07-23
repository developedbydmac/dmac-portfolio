# AWS Infrastructure for D Mac Portfolio

## 🔶 **Amazon Web Services Resources**

This Terraform configuration creates comprehensive AWS resources equivalent to Azure setup:

- **S3 + CloudFront** for static website hosting (Azure Static Web Apps)
- **Lambda Functions** for API endpoints (Azure Functions)
- **DynamoDB** for data storage (Cosmos DB)
- **API Gateway** for RESTful APIs
- **Secrets Manager** for secure credential storage (Key Vault)
- **CloudWatch** for monitoring and logging (Application Insights)

## 📋 **Prerequisites**

1. AWS CLI: `brew install awscli`
2. Terraform: `brew install terraform`
3. AWS Account with appropriate permissions
4. AWS credentials configured

## 🚀 **Setup Steps**

### 1. Configure AWS Credentials
```bash
# Configure AWS CLI
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 2. Configure Terraform Variables
Copy and edit the variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
# Basic Configuration
project_name = "dmac-portfolio"
environment  = "prod"
aws_region   = "us-east-1"

# Optional: Custom domain
domain_name = "your-domain.com"  # Leave empty for CloudFront default domain
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
- **S3 Bucket**: Hosts static files (HTML, CSS, JS, images)
- **CloudFront CDN**: Global content delivery with HTTPS
- **Origin Access Control**: Secure S3 access from CloudFront only

### **API Functions (Lambda)**
- **Visits Function**: Tracks and returns visitor count
- **Contact Function**: Handles contact form submissions
- **API Gateway**: RESTful endpoints for Lambda functions

### **Database (DynamoDB)**
- **Portfolio Table**: Stores visitor counts and contact messages
- **Pay-per-request**: Serverless billing model
- **Encryption**: Server-side encryption enabled

### **Security & Secrets**
- **Secrets Manager**: Stores API keys and sensitive configuration
- **IAM Roles**: Least-privilege access for Lambda functions
- **CORS**: Properly configured for frontend access

### **Monitoring (CloudWatch)**
- **Log Groups**: Centralized logging for Lambda functions
- **Dashboard**: Visual metrics for functions and CloudFront
- **Retention**: 14-day log retention for cost optimization

## 🔗 **Service Equivalencies**

| Azure Service | AWS Equivalent | Purpose |
|---------------|----------------|---------|
| Static Web Apps | S3 + CloudFront | Static hosting + CDN |
| Azure Functions | Lambda + API Gateway | Serverless compute |
| Cosmos DB | DynamoDB | NoSQL database |
| Key Vault | Secrets Manager | Secret storage |
| Application Insights | CloudWatch | Monitoring & logging |
| Managed Identity | IAM Roles | Service authentication |

## 📊 **Cost Estimates (Monthly)**

| Service | Usage | Estimated Cost |
|---------|-------|----------------|
| S3 Standard | 1GB storage, 10K requests | $0.25 |
| CloudFront | 1GB transfer, 10K requests | $0.15 |
| Lambda | 100K requests, 512MB, 3s avg | $0.20 |
| API Gateway | 100K requests | $0.35 |
| DynamoDB | Pay-per-request, light usage | $0.25 |
| Secrets Manager | 1 secret | $0.40 |
| CloudWatch | Basic monitoring | $0.50 |
| **Total** | | **~$2.10/month** |

## 🔧 **API Endpoints**

After deployment, your API endpoints will be:
```
POST https://{api-gateway-url}/prod/visits   # Visitor count
POST https://{api-gateway-url}/prod/contact  # Contact form
```

## 📈 **Monitoring & Logs**

### CloudWatch Dashboard
Access your monitoring dashboard at:
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards
```

### View Logs
```bash
# Lambda function logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/dmac-portfolio"

# Tail logs in real-time
aws logs tail /aws/lambda/dmac-portfolio-functions-visits --follow
```

## 🔐 **Security Best Practices**

- ✅ **No hardcoded credentials** - Uses IAM roles and Secrets Manager
- ✅ **HTTPS only** - CloudFront enforces SSL/TLS
- ✅ **Least privilege** - IAM policies grant minimal required permissions
- ✅ **Encryption at rest** - S3, DynamoDB, and Secrets Manager encrypted
- ✅ **VPC not required** - Serverless architecture reduces attack surface

## 🚀 **Deployment Commands**

```bash
# Quick deployment
terraform apply -auto-approve

# Destroy infrastructure
terraform destroy

# View outputs
terraform output

# Update Lambda functions only
terraform apply -target=aws_lambda_function.visits_function -target=aws_lambda_function.contact_function
```

## 🔍 **Troubleshooting**

### Common Issues

1. **Lambda deployment fails**:
   ```bash
   # Ensure function files exist
   ls -la devops/aws/lambda/*/index.js
   ```

2. **S3 bucket name conflict**:
   ```bash
   # Generate new bucket name
   terraform taint aws_s3_bucket.portfolio_bucket
   terraform apply
   ```

3. **API Gateway CORS issues**:
   - Verify Lambda functions return proper CORS headers
   - Check API Gateway configuration in AWS Console

### Debug Commands
```bash
# Test Lambda function locally
aws lambda invoke --function-name dmac-portfolio-functions-visits-prod response.json

# Check S3 website configuration
aws s3api get-bucket-website --bucket your-bucket-name

# Validate CloudFront distribution
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID
```

## 📚 **Additional Resources**

- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)

---

**Next Steps**: Configure your frontend application to use the API Gateway endpoints for visitor counting and contact form submission.
