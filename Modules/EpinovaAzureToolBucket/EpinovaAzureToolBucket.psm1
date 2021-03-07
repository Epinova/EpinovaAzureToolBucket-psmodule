<#


.DESCRIPTION
    Help functions for Epinova DXP vs Azure Portal.
#>

Set-StrictMode -Version Latest

# PRIVATE METHODS

# END PRIVATE METHODS

function New-EpiserverCmsResourceGroup{
    <#
    .SYNOPSIS
        Create a Episerver CMS resource group in Azure.

    .DESCRIPTION
        Create a Episerver CMS resource group in Azure.

    .PARAMETER SubscriptionId
        Your Azure SubscriptionId that you want to create the new resource group in.

    .PARAMETER ResourceGroupName
        The client secret used to access the project.

    .PARAMETER DatabasePassword
        The password to your database that will be generated. You need to follow the password policy. More information: https://docs.microsoft.com/en-us/previous-versions/azure/jj943764(v=azure.100)?redirectedfrom=MSDN

    .PARAMETER Tags
        The tags that will be set on the resource group when it is created. 
        Ex: $resourceGroupTags = @{
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

    .PARAMETER ResourceGroupLocation
        The location where the resource group should be hosted. Default = "westeurope". You can get a complete list of location by using "Get-AzureRmLocation |Format-Table".

    .PARAMETER ArmTemplateUri
        The location where we can find your custom ARM template to use in this script. Default = https://raw.githubusercontent.com/ovelartelius/epinova-arm-templates/main/epinova-azure-episerver-cms.json

    .EXAMPLE
        New-EpiserverCmsResourceGroup -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -DatabasePassword $DatabasePassword -Tags $Tags

    .EXAMPLE
        New-EpiserverCmsResourceGroup -SubscriptionId '95a9fd36-7851-4918-b8c9-f146a219982c' -ResourceGroupName 'mycoolwebsite' -DatabasePassword 'KXIN_rhxh3holt_s8it' -Tags @{ "Environment"="dev";"Owner"="ove.lartelius@epinova.se";"App"="Episerver";"Client"="Client name";"Project"="Project name";"ManagedBy"="Ove Lartelius";"Cost"="Internal";"Department"="IT";"Expires"="";  } -ResourceGroupLocation = "westeurope" -ArmTemplateUri = "https://raw.githubusercontent.com/yourrepository/arm-templates/main/azure-episerver-cms.json" 

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SubscriptionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DatabasePassword,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [hashtable] $Tags,

        [Parameter(Mandatory = $false)]
        [string] $ResourceGroupLocation = "westeurope",

        [Parameter(Mandatory = $false)]
        [string] $ArmTemplateUri = "https://raw.githubusercontent.com/ovelartelius/epinova-arm-templates/main/epinova-azure-episerver-cms.json"

    )

    Write-Host "New-EpiserverCmsResourceGroup - Inputs:----------"
    Write-Host "SubscriptionId:            $SubscriptionId"
    Write-Host "ResourceGroupName:         $ResourceGroupName"
    Write-Host "DatabasePassword:          **** (it is a secret...)"
    Write-Host "Tags:                      $Tags"
    Write-Host "ResourceGroupLocation:     $ResourceGroupLocation"
    Write-Host "ARMTemplateUri:            $ArmTemplateUri"
    Write-Host "------------------------------------------------"

    $databasePasswordSecureString = ConvertTo-SecureString $DatabasePassword -AsPlainText -Force

    ##############################################################

    # Login to Azure
    Connect-AzAccount -SubscriptionId $SubscriptionId

    # Try to get the resource group with the specified name
    Get-AzResourceGroup -Name $ResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
    # Check if the resource group already exist
    if ($notPresent){
        Write-Host "Resource group $ResourceGroupName does not exist."
    } else {
        # The Resource group $resourceGroupName already exists. Throw error and exit.
        Write-Error "Resource group $ResourceGroupName already exists."
        exit
    }

    # Create resource group
    if ($Tags.Count -eq 0) {
        New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation
    } else {
        New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Tag $Tags
        
        # Set tags on resource group
        $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName
        New-AzTag -ResourceId $resourceGroup.ResourceId -Tag $Tags
    }

    # Create resources from deployment template
    New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri https://raw.githubusercontent.com/ovelartelius/epinova-arm-templates/main/epinova-azure-episerver-cms.json -sqlserverAdminLoginPassword $databasePasswordSecureString

}

function Get-EpiserverCmsConnectionStrings{
    <#
    .SYNOPSIS
        Get and print the connection strings for specified resource group.

    .DESCRIPTION
        Get and print the connection strings for specified resource group.

    .PARAMETER SubscriptionId
        Your Azure SubscriptionId that holds the resource group.

    .PARAMETER ResourceGroupName
        The name of the resource group.

    .PARAMETER DatabasePassword
        The password to your database. The password that you specified when you created the database.

    .PARAMETER DatabaseName
        If you have used your own ARM template. You may have used another database name then Epinovas example template. Then specify the name of the database.

    .EXAMPLE
        Get-EpiserverCmsConnectionStrings -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -DatabasePassword $DatabasePassword

    .EXAMPLE
        Get-EpiserverCmsConnectionStrings -SubscriptionId "95a9fd36-7851-4918-b8c9-f146a219982c" -ResourceGroupName $ResourceGroupName -DatabasePassword $DatabasePassword

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SubscriptionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DatabasePassword,

        [Parameter(Mandatory = $false)]
        [string] $DatabaseName = ""

    )

    Write-Host "Get-EpiserverCmsConnectionStrings - Inputs:----------"
    Write-Host "SubscriptionId:            $SubscriptionId"
    Write-Host "ResourceGroupName:         $ResourceGroupName"
    Write-Host "DatabasePassword:          **** (it is a secret...)"
    Write-Host "-----------------------------------------------------"

    # Login to Azure
    Connect-AzAccount -SubscriptionId $subscriptionId

    $servicebusName = "$resourceGroupName-servicebus"
    $servicebusKeys = Get-AzServiceBusKey -ResourceGroup $resourceGroupName -NamespaceName $servicebusName -AuthorizationRuleName "RootManageSharedAccessKey"
    #$servicebusKeys
    if ($null -ne $servicebusKeys){
        Write-Host "<add name=""EPiServerAzureEvents"" connectionString=""$($servicebusKeys.PrimaryConnectionString)"" />"
    } else {
        Write-Warning "Could not find connection string for servicebus with the name $servicebusName in resource group $resourceGroupName."
    }
    


    $storageAccount = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $resourceGroupName
    if ($null -ne $storageAccount){
        Write-Host "<add name=""EPiServerAzureBlobs"" connectionString=""DefaultEndpointsProtocol=https;AccountName=$resourceGroupName;AccountKey=$($storageAccount[0].Value);EndpointSuffix=core.windows.net"" />"
    } else {
        Write-Warning "Could not find connection string for storage account with the name $resourceGroupName in resource group $resourceGroupName."
    }

    $sqlServerName = "$resourceGroupName-sqlserver"
    if ($DatabaseName -eq ""){
        $sqlDatabaseName = "$($resourceGroupName)epicms"
    } else {
        $sqlDatabaseName = $DatabaseName
    }
    
    Write-Host "<add name=""EPiServerDB"" connectionString=""Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$resourceGroupName-sa;Password=$databasePassword;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"" providerName=""System.Data.SqlClient"" />"
}

Export-ModuleMember -Function @( 'New-EpiserverCmsResourceGroup', 'Get-EpiserverCmsConnectionStrings' )