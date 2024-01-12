@description('Lowercase letters, numbers')
@minLength(1)
@maxLength(30)
param projectName string

@description('Environment name')
@allowed([
  'inte'
  'prep'
  'prod'
])
param environmentName string

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

@allowed([
  'v8.0'
  'v7.0'
  'v6.0'
  'v5.0'
  'v4.8'
])
param netVersion string

param appSettings array = []

param useApplicationInsight bool

@secure()
param databaseConnectionStrings object

param storageName string
param storageId string
param storageApiVersion string

var epiServerAzureBlobs = 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${listkeys(storageId, storageApiVersion).keys[0].value}'

param serviceBusId string
param serviceBusName string
param serviceBusApiVersion string

var endpoint = '${serviceBusId}/AuthorizationRules/RootManageSharedAccessKey'
var serviceBusConnectionString = 'Endpoint=sb://${serviceBusName}.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=${listKeys(endpoint, serviceBusApiVersion).primaryKey}'

var suffix = toLower('${projectName}-${environmentName}')

resource appPlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: 'plan-${suffix}'
  location: resourceGroup().location
  kind: netVersion != 'v4.8' ? 'linux' : 'windows'
  sku: {
    name: appPlanSku
    capacity: skuCapacity
  }
  properties: {
    reserved: netVersion != 'v4.8' ? true : false
  }
}

var databaseConnectionStringsArray = [for item in items(databaseConnectionStrings): {
  name: item.key
  connectionString: item.value
  type: 'SQLAzure'
}]

resource web 'Microsoft.Web/sites@2022-09-01' = {
  name: 'app-${suffix}'
  location: resourceGroup().location
  properties: {
    serverFarmId: appPlan.id
    siteConfig: {
      linuxFxVersion: netVersion != 'v4.8' ? 'DOTNETCORE|8.0' : null
      netFrameworkVersion: netVersion
      http20Enabled: true
      webSocketsEnabled: true
      connectionStrings: concat([
        {
          name: 'EPiServerAzureBlobs'
          connectionString: epiServerAzureBlobs
          type: 'Custom'
        }
        {
          name: 'EPiServerAzureEvents'
          connectionString: serviceBusConnectionString
          type: 'Custom'
        }
      ], databaseConnectionStringsArray)
    }
  }
}

resource ai 'Microsoft.Insights/components@2020-02-02' = if (useApplicationInsight) {
  name: 'ai-${suffix}'
  location: resourceGroup().location
  kind: 'web'
  tags: {
    'hidden-link:${web.id}': 'Resource'
  }
  properties: {
    Application_Type: 'web'
  }
}

var environments = {
  'inte': 'Integration'
  'prep': 'PreProduction'
  'prod': 'Production'
}

var aiAppsettings = useApplicationInsight ? [
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: reference(ai.id).InstrumentationKey
  }
  {
    name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
    value: '~2'
  }
  {
    name: 'XDT_MicrosoftApplicationInsights_Mode'
    value: 'recommended'
  }
] : []

resource webAppSettings 'Microsoft.Web/sites/config@2021-02-01' = {
  name: '${web.name}/web'
  properties: {
    appSettings: concat([
      {
        name: 'ASPNETCORE_ENVIRONMENT'
        value: environments[environmentName]
      }
      {
        name: 'EnvironmentName'
        value: environments[environmentName]
      }
      {
        name: 'episerver:EnvironmentName'
        value: environments[environmentName]
      }
    ], aiAppsettings, appSettings)
  }
}

// param notifyEmails array = []
// param notifySMSs array = []
// param extraPingUrls array = []

// var useMonitorAlerts = !empty(notifyEmails) || !empty(notifySMSs)

// var timeout = 120
// var webTestConfigStart = '<WebTest name="webtest-ping-${suffix}" Enabled="True" CssProjectStructure="" CssIteration="" Timeout="${timeout}" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale="">'
// var itemsConfigStart = '<Items>'

// var testWebUrl = '<Request  Method="GET" Version="1.1" Url="${web.properties.defaultHostName}" ThinkTime="0" Timeout="300" ParseDependentRequests="True" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" />'
// var testItems = [for pingUrl in extraPingUrls: '<Request  Method="GET" Version="1.1" Url="${pingUrl}" ThinkTime="0" Timeout="300" ParseDependentRequests="True" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" />']

// var itemsConfigEnd = '</Items>'
// var webTestConfigEnd = '</WebTest>'

// resource pingWebtest 'Microsoft.Insights/webtests@2015-05-01' = if (useApplicationInsight && useMonitorAlerts) {
//   name: 'webtest-ping-${suffix}'
//   location: resourceGroup().location
//   properties: {
//     Name: 'webtest-ping-${suffix}'
//     Description: 'Ping test'
//     Kind: 'ping'
//     Enabled: true
//     Frequency: 300
//     Timeout: timeout
//     RetryEnabled: true
//     Locations: [
//       {
//         Id: 'emea-gb-db3-azr'
//       }
//       {
//         Id: 'emea-nl-ams-azr'
//       }
//     ]
//     Configuration: {
//       WebTest: '${webTestConfigStart}${itemsConfigStart}${testWebUrl}${testItems}${itemsConfigEnd}${webTestConfigEnd}'
//     }
//     SyntheticMonitorId: 'webtest-ping-${suffix}'
//   }
//   tags: {
//     'hidden-link:${ai.id}': 'Resource'
//   }
// }

// resource actionGroup 'Microsoft.Insights/actionGroups@2021-09-01' = if (useApplicationInsight && useMonitorAlerts) {
//   name: 'ag-${suffix}'
//   location: 'global'
//   properties: {
//     enabled: true
//     groupShortName: '${take(projectName, 7)}-${environmentName}'
//     emailReceivers: [for notifyEmail in notifyEmails: {
//       name: notifyEmail.name
//       emailAddress: notifyEmail.emailAddress
//       useCommonAlertSchema: true
//     }]
//     smsReceivers: [for notifySMS in notifySMSs: {
//       name: notifySMS.name
//       countryCode: notifySMS.countryCode
//       phoneNumber: notifySMS.phoneNumber
//     }]
//   }
// }

// resource pingAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (useApplicationInsight && useMonitorAlerts) {
//   name: 'alert-ping-${suffix}'
//   location: 'global'
//   properties: {
//     description: 'Alert for web test'
//     severity: 1
//     enabled: true
//     scopes: [
//       ai.id
//       pingWebtest.id
//     ]
//     evaluationFrequency: 'PT1M'
//     windowSize: 'PT5M'
//     criteria: {
//       'odata.type': 'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'
//       webTestId: pingWebtest.id
//       componentId: ai.id
//       failedLocationCount: 2
//     }
//     actions: [
//       {
//         actionGroupId: actionGroup.id
//       }
//     ]
//   }
//   tags: {
//     'hidden-link:${ai.id}': 'Resource'
//     'hidden-link:${pingWebtest.id}': 'Resource'
//   }
// }
