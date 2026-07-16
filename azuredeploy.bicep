// Deploys the Azure Batch environment for this lab: a Batch account with a linked
// Storage account used for application, input, and output data.

@description('Prefix for generated resource names.')
param namePrefix string = 'batlab'

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Object ID of the principal that runs the sample app and needs blob data access. Defaults to the deploying user.')
param appPrincipalId string = deployer().objectId

var suffix = uniqueString(resourceGroup().id)
var storageAccountName = toLower('${namePrefix}${suffix}')
var batchAccountName = toLower('${namePrefix}ba${suffix}')
var storageBlobDataContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: length(storageAccountName) > 24 ? substring(storageAccountName, 0, 24) : storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
    allowBlobPublicAccess: false
  }
}

resource batch 'Microsoft.Batch/batchAccounts@2024-07-01' = {
  name: length(batchAccountName) > 24 ? substring(batchAccountName, 0, 24) : batchAccountName
  location: location
  properties: {
    autoStorage: {
      storageAccountId: storage.id
    }
    poolAllocationMode: 'BatchService'
    publicNetworkAccess: 'Enabled'
  }
}

resource blobDataRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, appPrincipalId, storageBlobDataContributor)
  scope: storage
  properties: {
    roleDefinitionId: storageBlobDataContributor
    principalId: appPrincipalId
  }
}

output batchAccountName string = batch.name
output batchAccountUrl string = 'https://${batch.properties.accountEndpoint}'
output storageAccountName string = storage.name
