# 🚀 Portfolio Deployment Checklist

## ✅ **What You Need to Provide**

### **1. Azure Account Setup (5 minutes)**
```bash
# Install Azure CLI (if not installed)
brew install azure-cli

# Login to Azure
az login

# Check your subscription
az account show
```

### **2. GitHub Repository Setup**
- ✅ **Repository**: You already have it at `https://github.com/developedbydmac/dmac-portfolio`
- ✅ **Branch**: Using `main` branch (already configured)
- ⚠️ **GitHub Secrets**: You'll need to add these after deployment

### **3. Domain Configuration (Optional)**
Your current setup in `main.parameters.json`:
- **Custom Domain**: `resume.dmac.dev` 
- **Note**: You'll need to own this domain or change it to your domain

### **4. Personalization Required**
Update these files with YOUR information:

#### **A. Basic Info (`main.parameters.json`)**
```json
{
  "siteName": { "value": "YOUR-NAME-portfolio" },
  "customDomain": { "value": "your-domain.com" },
  "repositoryUrl": { "value": "https://github.com/YOUR-USERNAME/dmac-portfolio" }
}
```

#### **B. Website Content**
Files you should personalize:
- `index.html` - Your name, title, description
- `resume.html` - Your work experience, skills, education
- `projects.html` - Your actual projects
- `assets/images/` - Your photos and project images
- `assets/DMacOpsResume25.pdf` - Your actual resume PDF

## 🚀 **Deployment Options**

### **Option 1: One-Command Deploy (Recommended)**
```bash
# Install Azure Developer CLI
curl -fsSL https://aka.ms/install-azd.sh | bash

# Deploy everything
azd up
```

### **Option 2: Manual Step-by-Step**
```bash
# 1. Create resource group
az group create --name dmac-portfolio-rg --location eastus2

# 2. Deploy infrastructure
az deployment group create \
  --resource-group dmac-portfolio-rg \
  --template-file devops/azure/bicep/main.bicep \
  --parameters devops/azure/bicep/main.parameters.json

# 3. Get deployment outputs for GitHub secrets
az deployment group show \
  --resource-group dmac-portfolio-rg \
  --name main \
  --query properties.outputs
```

## 📋 **Required Information Checklist**

### **Azure Subscription Info**
- [ ] **Subscription ID**: Run `az account show --query id -o tsv`
- [ ] **Tenant ID**: Run `az account show --query tenantId -o tsv`

### **Personal Information**
- [ ] **Your Name**: For website headers and titles
- [ ] **Your Email**: For contact forms
- [ ] **Your LinkedIn**: For social links
- [ ] **Your GitHub**: For project links
- [ ] **Your Resume**: PDF file for download
- [ ] **Your Projects**: Descriptions and screenshots

### **Domain (Optional)**
- [ ] **Custom Domain**: If you want `yourname.com` instead of `*.azurestaticapps.net`
- [ ] **Domain Verification**: You'll need to add DNS records

## 💰 **Cost Expectations**

### **Free Tier (Perfect for Testing)**
- **Static Web Apps**: Free
- **Azure Functions**: 1M executions free
- **Cosmos DB**: 400 RU/s free
- **Total**: $0/month

### **Production Tier (Recommended)**
- **Static Web Apps**: $9/month
- **Azure Functions**: $0-5/month
- **Cosmos DB**: $1-10/month
- **Application Insights**: $2-15/month
- **Total**: $12-39/month

## 🔧 **After Deployment Setup**

### **1. GitHub Actions Secrets**
Add these to your GitHub repository secrets:
```bash
# Get these after deployment
AZURE_STATIC_WEB_APPS_API_TOKEN
AZURE_FUNCTIONAPP_PUBLISH_PROFILE
AZURE_CREDENTIALS
```

### **2. Custom Domain Setup (If Using)**
```bash
# Add custom domain to Static Web App
az staticwebapp hostname set \
  --name YOUR-STATIC-WEB-APP-NAME \
  --hostname your-domain.com
```

### **3. Content Updates**
- Upload your actual resume PDF
- Replace sample project images
- Update all personal information
- Test contact form functionality

## 🎯 **Quick Start Summary**

**Minimum Required:**
1. Azure account with subscription
2. Update `main.parameters.json` with your info
3. Run `azd up`
4. Personalize website content

**Your URLs After Deployment:**
- **Auto-generated**: `your-site-name-swa-abc123.azurestaticapps.net`
- **Custom domain**: `your-domain.com` (if configured)

## 🆘 **Need Help?**

If you get stuck:
1. Check `devops/azure/README.md` for detailed instructions
2. Run diagnostics: `az deployment group validate`
3. View logs: `az functionapp log tail`

---

**Ready to deploy?** Just run `azd up` and Azure will guide you through the process! 🚀
