@description('Lowercase letters, numbers')
@minLength(1)
@maxLength(43)
param projectName string

@description('Environment name')
@allowed([
  'inte'
  'prep'
  'prod'
])
param environmentName string

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

resource servicebus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: toLower('sb-${projectName}-${environmentName}')
  location: resourceGroup().location
  tags: {
    displayName: 'ServiceBus'
  }
  sku: {
    name: sku
    tier: sku
  }
  properties: {}
}

output id string = servicebus.id
output name string = servicebus.name
output apiVersion string = servicebus.apiVersion
