targetScope = 'subscription'

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

var uniqueName = take(toLower('${projectName}-${uniqueString('${subscription().id}${projectName}')}'), 19)

param location string = deployment().location

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: toLower('rg-${uniqueName}-${environmentName}')
  location: location
}
