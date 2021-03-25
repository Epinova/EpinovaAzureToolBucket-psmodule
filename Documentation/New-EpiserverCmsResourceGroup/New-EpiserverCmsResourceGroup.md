# New-EpiserverCmsResourceGroup
Create a Episerver CMS resource group in Azure.  
![Example of created resource group in Azure](Documentation/ResourceGroupInAzure2.jpg)  

## PARAMETERS 
### SubscriptionId
Your Azure SubscriptionId that you want to create the new resource group in.

### ResourceGroupName
The client secret used to access the project.  
Don´t put in any special characters and stuff. It could end up with errors because of the Azure portal naming convention.  
_**Note: Storage account name must be between 3 and 24 characters in length and use numbers and lower-case letters only.**_

### DatabasePassword
The password to your database that will be generated. You need to follow the password policy. More information about [Password policy in Azure AD](https://docs.microsoft.com/en-us/previous-versions/azure/jj943764(v=azure.100)?redirectedfrom=MSDN)  
The password will be transformed to a SecureString in the function.

### Tags
The tags that will be set on the resource group when it is created. We are using the following tags for our projects. These are recommended by Microsoft. You can read more in the [Resource naming and tagging decision guide](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)  
Ex: 
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
```

### ResourceGroupLocation
The location where the resource group should be hosted. Default = "westeurope". You can get a complete list of location by using ```Get-AzureRmLocation |Format-Table```.

### ArmTemplateUri
The location where we can find your custom ARM template to use in this script. Default = https://raw.githubusercontent.com/Epinova/EpinovaAzureToolBucket-psmodule/main/ArmTemplates/epinova-azure-basic-episerver-cms.json   
If you don´t want to use the Epinova ARM template that is used by default, you can always take a copy of the https://raw.githubusercontent.com/Epinova/EpinovaAzureToolBucket-psmodule/main/ArmTemplates/epinova-azure-basic-episerver-cms.json and make your own ARM template. You can now specify your own ARM template when execute ```New-EpiserverCmsResourceGroup``` with the parameter: ```-ArmTemplateUri = 'https://raw.githubusercontent.com/yourrepository/arm-templates/main/azure-episerver-cms.json'```

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

[<< Back](..\..\Readme.md)