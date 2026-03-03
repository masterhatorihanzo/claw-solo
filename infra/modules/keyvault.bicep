@description('Azure region')
param location string = resourceGroup().location

@secure()
@description('OpenClaw secrets as JSON string')
param openclawSecrets string

@description('Resource tags')
param tags object = {}

var kvName = toLower('oc${uniqueString(resourceGroup().id)}kv')

resource kv 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: kvName
  location: location
  tags: tags
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enableRbacAuthorization: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2024-11-01' = {
  name: 'openclaw-secrets'
  parent: kv
  properties: {
    value: openclawSecrets
  }
}

output keyVaultName string = kv.name
output keyVaultId string = kv.id
output secretName string = secret.name
