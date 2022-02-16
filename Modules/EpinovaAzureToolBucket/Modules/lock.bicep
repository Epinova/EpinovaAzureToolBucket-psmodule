@description('Lowercase letters, numbers')
@minLength(1)
@maxLength(78)
param projectName string

@description('Environment name')
@allowed([
  'inte'
  'prep'
  'prod'
])
param environmentName string

resource resourceGroupLock 'Microsoft.Authorization/locks@2017-04-01' = {
  name: toLower('rgLock-${projectName}-${environmentName}')
  properties: {
    level: 'CanNotDelete'
    notes: 'Resource group and its resources should not be deleted.'
  }
}
