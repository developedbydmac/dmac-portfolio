// infrastructure/main.bicep
@description('Name of the static web app')
param staticWebAppName string = 'dmac-portfolio-${uniqueString(resourceGroup().id)}'

@description('Location for all resources')
param location string = resourceGroup().location

@description('GitHub repository URL')
param repositoryUrl string = 'https://github.com/developedbydmac/dmac-portfolio'

@description('GitHub branch to deploy from')
param branch string = 'main'

@description('SKU for the static web app')
@allowed(['Free', 'Standard'])
param sku string = 'Standard'

// Static Web App
resource staticWebApp 'Microsoft.Web/staticSites@2022-03-01' = {
  name: staticWebAppName
  location: location
  tags: {
    Environment: 'Production'
    Owner: 'D Mac'
    Project: 'Portfolio'
  }
  sku: {
    name: sku
    tier: sku
  }
  properties: {
    repositoryUrl: repositoryUrl
    branch: branch
    buildProperties: {
      appLocation: '/'
      apiLocation: 'api'
      outputLocation: 'dist'
    }
    allowConfigFileUpdates: true
    enterpriseGradeCdnStatus: 'Enabled'
  }
}

// Cosmos DB Account for visitor counter
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: '${staticWebAppName}-cosmos'
  location: location
  tags: {
    Environment: 'Production'
    Owner: 'D Mac'
    Project: 'Portfolio'
  }
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

// Cosmos DB Database
resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  parent: cosmosAccount
  name: 'PortfolioDB'
  properties: {
    resource: {
      id: 'PortfolioDB'
    }
  }
}

// Cosmos DB Container
resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: cosmosDatabase
  name: 'VisitorCount'
  properties: {
    resource: {
      id: 'VisitorCount'
      partitionKey: {
        paths: ['/id']
        kind: 'Hash'
      }
    }
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${staticWebAppName}-insights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${staticWebAppName}-logs'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Key Vault for secrets
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: '${staticWebAppName}-kv'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    enableRbacAuthorization: true
  }
}

// Store Cosmos DB connection string in Key Vault
resource cosmosConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'CosmosDBConnectionString'
  properties: {
    value: cosmosAccount.listConnectionStrings().connectionStrings[0].connectionString
  }
}

// Outputs
output staticWebAppDefaultHostname string = staticWebApp.properties.defaultHostname
output staticWebAppName string = staticWebApp.name
output cosmosEndpoint string = cosmosAccount.properties.documentEndpoint
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output keyVaultUri string = keyVault.properties.vaultUri
