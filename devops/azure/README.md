# Azure Infrastructure for D Mac Portfolio

## 🔷 **Azure Resources**

This Bicep template creates:

- **Storage Account** with static website hosting
- **Azure CDN** for global content delivery
- **Custom domain support** (optional)
- **Managed SSL certificates**

## 📋 **Prerequisites**

1. Azure CLI installed: `brew install azure-cli`
2. Azure subscription
3. Bicep CLI (comes with Azure CLI)

## 🚀 **Deployment Steps**

### 1. Login to Azure
```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2. Create Resource Group
```bash
az group create --name dmac-portfolio-rg --location eastus
```

### 3. Configure Parameters
Edit `main.parameters.json`:
```json
{
  "projectName": { "value": "dmac-portfolio" },
  "environment": { "value": "prod" },
  "customDomain": { "value": "your-domain.com" },
  "enableCdn": { "value": true }
}
```

### 4. Deploy Infrastructure
```bash
# Validate template
az deployment group validate \
  --resource-group dmac-portfolio-rg \
  --template-file main.bicep \
  --parameters main.parameters.json

# Deploy
az deployment group create \
  --resource-group dmac-portfolio-rg \
  --template-file main.bicep \
  --parameters main.parameters.json
```

### 5. Create Service Principal for GitHub Actions
```bash
az ad sp create-for-rbac \
  --name "dmac-portfolio-github-actions" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/dmac-portfolio-rg \
  --sdk-auth
```

## 🔧 **GitHub Actions Setup**

Add these secrets to your GitHub repository:

- `AZURE_CREDENTIALS` - Output from service principal creation
- `AZURE_SUBSCRIPTION_ID` - Your Azure subscription ID
- `AZURE_RESOURCE_GROUP` - dmac-portfolio-rg
- `AZURE_STORAGE_ACCOUNT` - Storage account name from deployment
- `AZURE_CDN_PROFILE` - CDN profile name
- `AZURE_CDN_ENDPOINT` - CDN endpoint name

## 💰 **Estimated Costs**

- **Storage Account**: $1-3/month
- **Azure CDN**: $2-8/month
- **DNS Zone**: $0.50/month (if using custom domain)

**Total: ~$3-12/month**

## 🌐 **Features**

- ✅ Static website hosting
- ✅ Global CDN with edge caching
- ✅ Custom domain support
- ✅ Managed SSL certificates
- ✅ CORS configuration
- ✅ Gzip compression
- ✅ Security headers

## 🔍 **Monitoring**

View your resources in:
- Azure Portal → Resource Groups → dmac-portfolio-rg
- Monitor CDN metrics and logs
- Set up alerts for performance and costs

## 🚀 **Manual Content Upload**

```bash
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
