# Azure Infrastructure for D Mac Portfolio

## 🔷 **Azure Resources**

This comprehensive Azure setup creates:

### **Core Infrastructure**
- **Azure Static Web Apps** with custom domain support
- **Azure Functions** for serverless API endpoints
- **Cosmos DB** for visitor tracking and contact messages
- **Application Insights** for monitoring and analytics
- **Key Vault** for secure secrets management

### **DevOps & CI/CD**
- **GitHub Actions** workflows with security scanning
- **Azure DevOps** pipelines with multi-stage deployment
- **Infrastructure as Code** using Bicep templates
- **Automated testing** and health checks

### **Security & Monitoring**
- **Trivy security scanning** for vulnerabilities
- **Checkov** infrastructure security validation
- **Application monitoring** with custom alerts
- **CORS policies** and security headers

## 📋 **Prerequisites**

1. **Azure CLI**: `brew install azure-cli`
2. **Azure subscription** with owner permissions
3. **GitHub repository** with deployment tokens
4. **Node.js 18+** for Azure Functions development

## 🚀 **Deployment Options**

### Option 1: Azure Developer CLI (Recommended)
```bash
# Install azd
curl -fsSL https://aka.ms/install-azd.sh | bash

# Initialize and deploy
azd init
azd up
```

### Option 2: Manual Bicep Deployment

### 1. Login to Azure
```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2. Create Resource Group
```bash
az group create --name dmac-portfolio-rg --location eastus2
```

### 3. Configure Parameters
Edit `main.parameters.json`:
```json
{
  "siteName": { "value": "dmac-portfolio" },
  "location": { "value": "eastus2" },
  "repositoryUrl": { "value": "https://github.com/developedbydmac/dmac-portfolio" },
  "branch": { "value": "main" },
  "customDomain": { "value": "resume.dmac.dev" }
}
```

### 4. Deploy Infrastructure
```bash
# Validate template
az deployment group validate \
  --resource-group dmac-portfolio-rg \
  --template-file bicep/main.bicep \
  --parameters bicep/main.parameters.json

# Deploy
az deployment group create \
  --resource-group dmac-portfolio-rg \
  --template-file bicep/main.bicep \
  --parameters bicep/main.parameters.json
```

### 5. Configure GitHub Actions
```bash
# Create service principal for GitHub Actions
az ad sp create-for-rbac \
  --name "dmac-portfolio-github-actions" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/dmac-portfolio-rg \
  --sdk-auth

# Get Static Web App deployment token
az staticwebapp secrets list \
  --name dmac-portfolio-swa \
  --query "properties.apiKey" \
  --output tsv
```

## 🔧 **GitHub Actions Setup**

Add these secrets to your GitHub repository:

### Required Secrets
- `AZURE_STATIC_WEB_APPS_API_TOKEN` - Static Web App deployment token
- `AZURE_FUNCTIONAPP_PUBLISH_PROFILE` - Function App publish profile
- `AZURE_CREDENTIALS` - Service principal credentials for infrastructure deployment

### Optional Secrets
- `COSMOS_DB_ENDPOINT` - Cosmos DB endpoint URL
- `COSMOS_DB_KEY` - Cosmos DB access key
- `APPLICATION_INSIGHTS_KEY` - Application Insights instrumentation key

## 🔍 **API Endpoints**

Your deployed Azure Functions will provide:

- `GET /api/visits` - Visitor counter with analytics
- `POST /api/contact` - Contact form submission handler
- Health checks and monitoring endpoints

## 💰 **Estimated Costs**

### Production Environment
- **Static Web Apps (Standard)**: $9/month
- **Azure Functions (Consumption)**: $0-5/month
- **Cosmos DB (Serverless)**: $1-10/month
- **Application Insights**: $2-15/month
- **Key Vault**: $1/month

**Total: ~$13-40/month** (scales with usage)

### Free Tier Option
- **Static Web Apps (Free)**: $0/month
- **Azure Functions (Free tier)**: $0/month (1M executions)
- **Cosmos DB (Free tier)**: $0/month (400 RU/s, 5GB)

**Total: $0/month** (with limitations)

## 🌐 **Features**

### Core Features
- ✅ Serverless static website hosting
- ✅ Azure Functions API backend
- ✅ Real-time visitor tracking
- ✅ Contact form with database storage
- ✅ Custom domain with managed SSL
- ✅ Global CDN with edge caching

### DevOps Features
- ✅ Infrastructure as Code (Bicep)
- ✅ Multi-stage CI/CD pipelines
- ✅ Security scanning (Trivy + Checkov)
- ✅ Automated testing and health checks
- ✅ Application monitoring and alerts

### Security Features
- ✅ Managed identities for secure access
- ✅ Key Vault for secrets management
- ✅ CORS policies and security headers
- ✅ Network security and access controls

## 🔍 **Monitoring & Observability**

### Application Insights Dashboards
- Performance metrics and response times
- User analytics and visitor patterns  
- Error tracking and debugging
- Custom telemetry and events

### Health Monitoring
- Automated health checks in CI/CD
- Custom alerts for downtime/errors
- Performance monitoring and optimization
- Cost tracking and budget alerts

### Access Your Resources
- **Azure Portal**: Resource Groups → dmac-portfolio-rg
- **Static Web App**: Check deployment status and custom domains
- **Functions**: Monitor executions and performance
- **Cosmos DB**: Query data and monitor usage
- **Application Insights**: View analytics and set up alerts

## 🚨 **Troubleshooting**

### Common Issues
- **Custom domain SSL**: May take 24-48 hours to provision
- **Functions cold start**: Use warmup triggers for better performance
- **Cosmos DB throttling**: Monitor RU consumption and scale as needed
- **CORS errors**: Verify Static Web App CORS configuration

### Debug Commands
```bash
# Check deployment status
az deployment group show --resource-group dmac-portfolio-rg --name main

# View Static Web App status
az staticwebapp show --name dmac-portfolio-swa --resource-group dmac-portfolio-rg

# Monitor Function App logs
az functionapp log tail --name dmac-portfolio-functions --resource-group dmac-portfolio-rg

# Query Cosmos DB
az cosmosdb sql query --account-name dmac-portfolio-cosmos --database-name PortfolioDB --container-name VisitorCount --query-text "SELECT * FROM c"
```
# Upload files manually
az storage blob upload-batch \
  --destination '$web' \
  --source /path/to/your/files \
  --account-name YOUR_STORAGE_ACCOUNT

# Purge CDN cache
az cdn endpoint purge \
  --resource-group dmac-portfolio-rg \
  --profile-name YOUR_CDN_PROFILE \
  --name YOUR_CDN_ENDPOINT \
  --content-paths "/*"
```

## 🔄 **Updates and Maintenance**

```bash
# Update infrastructure
az deployment group create \
  --resource-group dmac-portfolio-rg \
  --template-file main.bicep \
  --parameters main.parameters.json

# Delete everything (⚠️ DANGEROUS)
az group delete --name dmac-portfolio-rg --yes
```
