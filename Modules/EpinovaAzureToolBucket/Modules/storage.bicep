targetScope='subscription'

@description('Lowercase letters, numbers')
@minLength(1)
@maxLength(18)
param projectName string

@description('Environment name')
@allowed([
  'inte'
  'prep'
  'prod'
])
param environmentName string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param sku string = 'Standard_LRS'

param containersToCreate array = [
  {
    name: 'mysitemedia'
    publicAccess: 'None'
  }
  {
    name: 'db-backups'
    publicAccess: 'None'
  }
]
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: toLower('st${projectName}${environmentName}')
  location: resourceGroup().location
  sku: {
    name: sku
  }
  kind: 'StorageV2'

  resource blob 'blobServices@2023-01-01' = {
    name: 'default'

    resource containers 'containers@2023-01-01' = [for container in containersToCreate: {
      name: container.name
      properties: {
        publicAccess: container.publicAccess
      }
    }]
  }
}

output name string = storage.name
output id string = storage.id
output apiVersion string = storage.apiVersion
