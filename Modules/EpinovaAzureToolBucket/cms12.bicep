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

@description('The login can\'t include SQL Identifiers or System names like admin, sa and root. Login can\'t contain non alphanumeric characters. Login can\'t begin with numbers or symbols')
@secure()
param sqlserverAdminLogin string

@description('Password for sql server. The password does not contain the account name of the user. The password is at least eight characters long. The password contains characters from three of the following four categories: Latin uppercase letters (A through Z), Latin lowercase letters (a through z), Base 10 digits (0 through 9), Non-alphanumeric characters such as: exclamation point (!), dollar sign ($), number sign (#), or percent (%). Passwords can be up to 128 characters long. Use passwords that are as long and complex as possible. Min leght 8, max length 128')
@secure()
param sqlserverAdminLoginPassword string

param firewallRules array = []

@allowed([
  'Free'
  'Basic'
  'S0'
  'S1'
  'P1'
  'P2'
  'GP_Gen4_1'
  'GP_S_Gen5_1'
  'GP_Gen5_2'
  'GP_S_Gen5_2'
  'BC_Gen4_1'
  'BC_Gen5_4 '
])
param sqlSku string = 'Basic'

@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P4'
])
@description('The service plan size')
param appPlanSku string = 'F1'

@minValue(1)
param skuCapacity int = 1

param appSettings array = []

param useApplicationInsight bool = false

param tags object = {}

var uniqueName = take(toLower('${projectName}-${uniqueString('${subscription().id}${projectName}')}'), 19)

param location string // = deployment().location

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: toLower('rg-${uniqueName}-${environmentName}')
  location: location
  tags: tags
}

//Removing locks for now seems to be a limit
// module lock 'Modules/lock.bicep' = if (environmentName == 'prod') {
//   name: 'lock'
//   params: {
//     environmentName: environmentName
//     projectName: uniqueName
//   }
//   scope: resourceGroup
// }

var episerverDbName = 'opticms'

module sql 'Modules/sql.bicep' = {
  name: 'sql'
  params: {
    environmentName: environmentName
    sqlDatabaseNames: [
      episerverDbName
    ]
    sku: sqlSku
    projectName: uniqueName
    sqlserverAdminLogin: sqlserverAdminLogin
    sqlserverAdminLoginPassword: sqlserverAdminLoginPassword
    ownFirewallRules: firewallRules
    location: location
  }
  scope: resourceGroup
}

module servicebus 'Modules/servicebus.bicep' = {
  name: 'servicebus'
  params: {
    environmentName: environmentName
    projectName: uniqueName
    location: location
  }
  scope: resourceGroup
}
module storage 'Modules/storage.bicep' = {
  name: 'storage'
  params: {
    environmentName: environmentName
    projectName: replace(uniqueName, '-', '')
    location: location
  }
  scope: resourceGroup
}

module web 'Modules/web.bicep' = {
  name: 'web'
  params: {
    appSettings: appSettings
    netVersion: 'v7.0'
    useApplicationInsight: useApplicationInsight
    environmentName: environmentName
    databaseConnectionStrings: {
      EPiServerDB: 'Server=tcp:${sql.outputs.fullyQualifiedDomainName},1433;Initial Catalog=sqldb-${projectName}-${episerverDbName}-${environmentName};User Id=${sqlserverAdminLogin};Password=${sqlserverAdminLoginPassword};Trusted_Connection=False;Encrypt=True;Connection Timeout=30;MultipleActiveResultSets=True'
    }
    serviceBusId: servicebus.outputs.id
    serviceBusName: servicebus.outputs.name
    serviceBusApiVersion: servicebus.outputs.apiVersion
    projectName: uniqueName
    storageApiVersion: storage.outputs.apiVersion
    storageId: storage.outputs.id
    storageName: storage.outputs.name
    appPlanSku: appPlanSku
    skuCapacity: skuCapacity
    location: location
  }
  dependsOn: [
    storage
    servicebus
    sql
  ]
  scope: resourceGroup
}
