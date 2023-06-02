@description('Lowercase letters, numbers')
@minLength(1)
@maxLength(54)
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

param ownFirewallRules array = []

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
param sku string = 'Free'

@description('Describes the performance level for SQL Databse Collation')
param SQL_DatabaseCollation string = 'SQL_Latin1_General_CP1_CI_AS'

param sqlDatabaseNames array

var skus = {
  Free: {
    name: 'Free'
    tier: 'Free'
    capacity: 5
  }
  Basic: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  S0: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 10
  }
  S1: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 20
  }
  P1: {
    name: 'Premium'
    tier: 'Premium'
    capacity: 125
  }
  P2: {
    name: 'Premium'
    tier: 'Premium'
    capacity: 250
  }
  GP_Gen4_1: {
    name: 'GP_Gen4'
    tier: 'GeneralPurpose'
    capacity: 1
  }
  GP_S_Gen5_1: {
    name: 'GP_S_Gen5_1'
    tier: 'GeneralPurpose'
    capacity: 1
  }
  GP_Gen5_2: {
    name: 'GP_Gen5'
    tier: 'GeneralPurpose'
    capacity: 2
  }
  GP_S_Gen5_2: {
    name: 'GP_S_Gen5_2'
    tier: 'GeneralPurpose'
    capacity: 2
  }
  BC_Gen4_1: {
    name: 'BC_Gen4'
    tier: 'BusinessCritical'
    capacity: 1
  }
  BC_Gen5_4: {
    name: 'BC_Gen5'
    tier: 'BusinessCritical'
    capacity: 4
  }
}

var firewallRules = concat([
  {
    name: 'AllowAllWindowsAzureIps'
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
], ownFirewallRules)

resource sqlServer 'Microsoft.Sql/servers@2021-05-01-preview' = {
  location: resourceGroup().location
  name: toLower('sql-${projectName}-${environmentName}')
  properties: {
    administratorLogin: sqlserverAdminLogin
    administratorLoginPassword: sqlserverAdminLoginPassword
    version: '12.0'
  }
  tags: {
    displayName: 'SQL-Server'
  }

  resource sqlDatabases 'databases@2021-05-01-preview' = [for sqlDatabaseName in sqlDatabaseNames: {
    name: toLower('sqldb-${projectName}-${sqlDatabaseName}-${environmentName}')
    location: resourceGroup().location
    sku: {
      name: skus[sku].name
      tier: skus[sku].tier
      capacity: skus[sku].capacity
    }
    properties: {
      collation: SQL_DatabaseCollation
      minCapacity: 1
    }
    tags: {
      displayName: 'SQL-Database'
    }
  }]

  resource fwRule 'firewallRules@2021-05-01-preview' = [for firewallRule in firewallRules: {
    name: firewallRule.name
    properties: {
      startIpAddress: firewallRule.startIpAddress
      endIpAddress: firewallRule.endIpAddress
    }
  }]
}

output fullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName