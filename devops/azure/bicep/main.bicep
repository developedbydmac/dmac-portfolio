// D Mac Portfolio - Azure Infrastructure using Bicep
// This template creates Azure resources for hosting a static portfolio website

targetScope = 'resourceGroup'

@description('Name of the project')
param projectName string = 'dmac-portfolio'

@description('Environment name (e.g., dev, staging, prod)')
param environment string = 'prod'

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Custom domain name (optional)')
param customDomain string = ''

@description('Enable CDN endpoint')
param enableCdn bool = true

@description('Storage account tier')
@allowed(['Standard_LRS', 'Standard_GRS', 'Standard_RAGRS'])
param storageAccountType string = 'Standard_LRS'

// Variables
var resourceSuffix = uniqueString(resourceGroup().id)
var storageAccountName = '${projectName}${environment}${resourceSuffix}'
var cdnProfileName = '${projectName}-${environment}-cdn'
var cdnEndpointName = '${projectName}-${environment}-endpoint'

// Common tags
var commonTags = {
  Project: projectName
  Environment: environment
  ManagedBy: 'bicep'
  Owner: 'D Mac'
  CloudProvider: 'azure'
}

// Storage Account for static website hosting
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: commonTags
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// Enable static website hosting
resource staticWebsite 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'HEAD', 'OPTIONS']
          allowedHeaders: ['*']
          exposedHeaders: ['*']
          maxAgeInSeconds: 3600
        }
      ]
    }
  }
}

// $web container for static website
resource webContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: staticWebsite
  name: '$web'
  properties: {
    publicAccess: 'Blob'
  }
}

// CDN Profile
resource cdnProfile 'Microsoft.Cdn/profiles@2023-05-01' = if (enableCdn) {
  name: cdnProfileName
  location: 'Global'
  tags: commonTags
  sku: {
    name: 'Standard_Microsoft'
  }
  properties: {}
}

// CDN Endpoint
resource cdnEndpoint 'Microsoft.Cdn/profiles/endpoints@2023-05-01' = if (enableCdn) {
  parent: cdnProfile
  name: cdnEndpointName
  location: 'Global'
  tags: commonTags
  properties: {
    originHostHeader: '${storageAccountName}.z13.web.${az.environment().suffixes.storage}'
    isHttpAllowed: false
    isHttpsAllowed: true
    queryStringCachingBehavior: 'IgnoreQueryString'
    origins: [
      {
        name: 'origin1'
        properties: {
          hostName: '${storageAccountName}.z13.web.${az.environment().suffixes.storage}'
          httpPort: 80
          httpsPort: 443
          originHostHeader: '${storageAccountName}.z13.web.${az.environment().suffixes.storage}'
          priority: 1
          weight: 1000
          enabled: true
        }
      }
    ]
    deliveryPolicy: {
      rules: [
        {
          name: 'Global'
          order: 0
          conditions: []
          actions: [
            {
              name: 'CacheExpiration'
              parameters: {
                typeName: 'DeliveryRuleCacheExpirationActionParameters'
                cacheBehavior: 'SetIfMissing'
                cacheType: 'All'
                cacheDuration: '1.00:00:00'
              }
            }
            {
              name: 'ModifyResponseHeader'
              parameters: {
                typeName: 'DeliveryRuleHeaderActionParameters'
                headerAction: 'Append'
                headerName: 'Strict-Transport-Security'
                value: 'max-age=31536000; includeSubDomains'
              }
            }
          ]
        }
        {
          name: 'AssetsCache'
          order: 1
          conditions: [
            {
              name: 'UrlPath'
              parameters: {
                typeName: 'DeliveryRuleUrlPathMatchConditionParameters'
                operator: 'BeginsWith'
                matchValues: ['/assets/']
                transforms: ['Lowercase']
              }
            }
          ]
          actions: [
            {
              name: 'CacheExpiration'
              parameters: {
                typeName: 'DeliveryRuleCacheExpirationActionParameters'
                cacheBehavior: 'Override'
                cacheType: 'All'
                cacheDuration: '365.00:00:00'
              }
            }
          ]
        }
        {
          name: 'HtmlCache'
          order: 2
          conditions: [
            {
              name: 'UrlFileExtension'
              parameters: {
                typeName: 'DeliveryRuleUrlFileExtensionMatchConditionParameters'
                operator: 'Equal'
                matchValues: ['html', 'htm']
                transforms: ['Lowercase']
              }
            }
          ]
          actions: [
            {
              name: 'CacheExpiration'
              parameters: {
                typeName: 'DeliveryRuleCacheExpirationActionParameters'
                cacheBehavior: 'Override'
                cacheType: 'All'
                cacheDuration: '0.00:05:00'
              }
            }
          ]
        }
      ]
    }
  }
}

// Custom domain (optional)
resource customDomainResource 'Microsoft.Cdn/profiles/endpoints/customDomains@2023-05-01' = if (enableCdn && !empty(customDomain)) {
  parent: cdnEndpoint
  name: replace(customDomain, '.', '-')
  properties: {
    hostName: customDomain
  }
}

// Service Principal for GitHub Actions (placeholder - needs to be created separately)
// Note: This would typically be created via Azure CLI or PowerShell
// az ad sp create-for-rbac --name "dmac-portfolio-github-actions" --role contributor --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group}

// Outputs
output storageAccountName string = storageAccount.name
output storageAccountWebEndpoint string = storageAccount.properties.primaryEndpoints.web
output cdnEndpointUrl string = enableCdn ? 'https://${cdnEndpointName}.azureedge.net' : ''
output cdnEndpointName string = enableCdn ? cdnEndpointName : ''
output cdnProfileName string = enableCdn ? cdnProfileName : ''
output resourceGroupName string = resourceGroup().name
output deploymentInstructions string = '''

🚀 D Mac Portfolio Azure Deployment Complete!

Next Steps:
1. Create a Service Principal for GitHub Actions:
   az ad sp create-for-rbac --name "dmac-portfolio-github-actions" --role contributor --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name} --sdk-auth

2. Add these secrets to your GitHub repository:
   - AZURE_CREDENTIALS: {output from step 1}
   - AZURE_SUBSCRIPTION_ID: {your-subscription-id}
   - AZURE_RESOURCE_GROUP: ${resourceGroup().name}
   - AZURE_STORAGE_ACCOUNT: ${storageAccount.name}
   - AZURE_CDN_PROFILE: ${enableCdn ? cdnProfileName : 'N/A'}
   - AZURE_CDN_ENDPOINT: ${enableCdn ? cdnEndpointName : 'N/A'}

3. Your website will be available at:
   Storage: ${storageAccount.properties.primaryEndpoints.web}
   CDN: ${enableCdn ? 'https://${cdnEndpointName}.azureedge.net' : 'N/A'}

4. Push to your main branch to trigger the deployment pipeline!

'''
