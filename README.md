# EpinovaAzureToolBucket-psmodule
Powershell module contain functions for createing Episerver CMS in Azure.

# New-EpiserverCmsResourceGroup
Create a Episerver CMS resource group in Azure.  
![Example of created resource group in Azure](ResourceGroupInAzure.jpg)  
## PARAMETERS 
### SubscriptionId
Your Azure SubscriptionId that you want to create the new resource group in.

### ResourceGroupName
The client secret used to access the project.

### DatabasePassword
The password to your database that will be generated. You need to follow the password policy. More information about [Password policy in Azure AD](https://docs.microsoft.com/en-us/previous-versions/azure/jj943764(v=azure.100)?redirectedfrom=MSDN)  
The password will be transformed to a SecureString in the function.

### Tags
The tags that will be set on the resource group when it is created. We are using the following tags for our projects. These are recommended by Microsoft. You can read more in the [Resource naming and tagging decision guide](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)  
Ex: 
```powershell
$resourceGroupTags = @{
    "Environment"="dev";
    "Owner"="ove.lartelius@epinova.se";
    "App"="Episerver";
    "Client"="Customer AB";
    "Project"="External Website 2021";
    "ManagedBy"="ove.lartelius@epinova.se";
    "Cost"="internal";
    "Department"="IT";
    "Expires"="2030-01-01";
    }
```

### ResourceGroupLocation
The location where the resource group should be hosted. Default = "westeurope". You can get a complete list of location by using "Get-AzureRmLocation |Format-Table".

### ArmTemplateUri
The location where we can find your custom ARM template to use in this script. Default = https://raw.githubusercontent.com/ovelartelius/epinova-arm-templates/main/epinova-azure-episerver-cms.json

## Examples
### Example 1
```powershell
$SubscriptionId = "95a9fd36-7851-4918-b8c9-f146a219982c"
$ResourceGroupName = "mycoolwebsite"
$DatabasePassword = "KXIN_rhxh3holt_s8it"
$Tags = @{
    "Environment"="dev";
    "Owner"="ove.lartelius@epinova.se";
    "App"="Episerver";
    "Client"="Customer AB";
    "Project"="External Website 2021";
    "ManagedBy"="ove.lartelius@epinova.se";
    "Cost"="internal";
    "Department"="IT";
    "Expires"="2030-01-01";
    }
New-EpiserverCmsResourceGroup -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -DatabasePassword $DatabasePassword -Tags $Tags
```

### Example 2
```powershell
$Tags = @{
    "Environment"="dev";
    "Owner"="ove.lartelius@epinova.se";
    "App"="Episerver";
    "Client"="Customer AB";
    "Project"="External Website 2021";
    "ManagedBy"="ove.lartelius@epinova.se";
    "Cost"="internal";
    "Department"="IT";
    "Expires"="2030-01-01";
    }
New-EpiserverCmsResourceGroup -SubscriptionId '95a9fd36-7851-4918-b8c9-f146a219982c' -ResourceGroupName 'mycoolwebsite' -DatabasePassword 'KXIN_rhxh3holt_s8it' -Tags $resourceGroupTags -ResourceGroupLocation = "westeurope" -ArmTemplateUri = "https://raw.githubusercontent.com/yourrepository/arm-templates/main/azure-episerver-cms.json" 
```

### Example 3
```powershell
New-EpiserverCmsResourceGroup -SubscriptionId '95a9fd36-7851-4918-b8c9-f146a219982c' -ResourceGroupName 'mycoolwebsite' -DatabasePassword 'KXIN_rhxh3holt_s8it' -Tags @{ "Environment"="dev";"Owner"="ove.lartelius@epinova.se";"App"="Episerver";"Client"="Client name";"Project"="Project name";"ManagedBy"="Ove Lartelius";"Cost"="Internal";"Department"="IT";"Expires"="";  } -ResourceGroupLocation = "westeurope" -ArmTemplateUri = "https://raw.githubusercontent.com/yourrepository/arm-templates/main/azure-episerver-cms.json" 
```


# Get-EpiserverCmsConnectionStrings
Get and print the connection strings for specified resource group.  
![Example of connection strings for a resource group](ConnectionStringsResult.jpg)  
## Parameters
### SubscriptionId
Your Azure SubscriptionId that holds the resource group.

### ResourceGroupName
The name of the resource group.

### DatabasePassword
The password to your database. The password that you specified when you created the database.

### DatabaseName
If you have used your own ARM template. You may have used another database name then Epinovas example template. Then specify the name of the database.

### Examples
#### Example 1
```powershell
$SubscriptionId = "95a9fd36-7851-4918-b8c9-f146a219982c"
$ResourceGroupName = "mycoolwebsite"
$DatabasePassword = "KXIN_rhxh3holt_s8it"
Get-EpiserverCmsConnectionStrings -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -DatabasePassword $DatabasePassword
```

#### Example 2
```powershell
Get-EpiserverCmsConnectionStrings -SubscriptionId "95a9fd36-7851-4918-b8c9-f146a219982c" -ResourceGroupName $ResourceGroupName -DatabasePassword $DatabasePassword
```

# How to get Subscription ID
## Powershell
You can use powershell to get the subscription you are connected to.  
```powershell
Get-AzSubscription
```
[Read more about Get-AzSubscription @ doc.microsoft](https://docs.microsoft.com/en-us/powershell/module/az.accounts/get-azsubscription?view=azps-5.6.0)
## Manually
![Obtain Azure Subscription ID](ObtainAzureSubscriptionID.jpg)  
