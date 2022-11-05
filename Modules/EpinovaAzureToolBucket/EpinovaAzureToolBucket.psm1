<#
.DESCRIPTION
    Help functions for Epinova DXP vs Azure Portal.
#>

Set-StrictMode -Version Latest

$azureConnection = $null

# PRIVATE METHODS
 
function Test-AzureSqlConnection {
    param(
        [Parameter(Mandatory)]
        [string]$ServerName,

        [Parameter(Mandatory)]
        [string]$DatabaseName,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )
    $result = $false
    $userName = $Credential.UserName
    $password = $Credential.GetNetworkCredential().Password
    $connectionString = "Server=tcp:$ServerName,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$userName;Password=$password;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
    try {
        $sqlConnection.Open()
        ## This will run if the Open() method does not throw an exception
        $result = $true
        #Write-Host "Connection to database works :)"
    } catch {
        Write-Error $Error[0]
        $result = $false
    } finally {

        ## Close the connection when we're done
        $sqlConnection.Dispose()
    }
    return $result
}

function Invoke-DatabaseExecuteNonQueryCommand{
    param(
        [Parameter(Mandatory)]
        [string]$ServerName,

        [Parameter(Mandatory)]
        [string]$DatabaseName,

        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [Parameter(Mandatory)]
        [string]$Command
    )
    $result = $false
        $userName = $Credential.UserName
        $password = $Credential.GetNetworkCredential().Password
        $connectionString = "Server=tcp:$ServerName,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$userName;Password=$password;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString

        $cmd = New-Object System.Data.SqlClient.SqlCommand
        $cmd.Connection = $sqlConnection
        $cmd.CommandTimeout = 0
        $cmd.CommandText = $Command

    try {

        $sqlConnection.Open()
        $cmd.ExecuteNonQuery() # | Out-Null
        $result = $true
    } catch {
        #$Error
        #$_.Exception.Message
        Write-Warning $_.Exception.Message
        #Write-Warning $Error[0]
        Write-Warning $Command
        $result = $false
    } finally {
        ## Close the connection when we're done
        $sqlConnection.Dispose()
        $cmd.Dispose()
    }
    return $result

}

function Get-DefaultSqlServer{
<#
    .SYNOPSIS
        List all resources for a resource group and grab the first SqlServer it can find.

    .DESCRIPTION
        List all resources for a resource group and grab the first SqlServer it can find.  
        Will only work if connection to Azure aleasy exist.

    .PARAMETER ResourceGroupName
        The resource group where we will look for the SqlServer.

    .EXAMPLE
        Get-DefaultSqlServer -ResourceGroupName $ResourceGroupName

    #>
    param(
        [Parameter(Mandatory)]
        [string]$ResourceGroupName
    )
    $sqlServer = (Get-AzResource -ResourceGroupName $ResourceGroupName | Where-Object { $_.ResourceType -eq "Microsoft.Sql/servers"} | Select-Object -Property Name).Name
    if ($null -eq $sqlServer) {
        Write-Error "Could not find default SqlServer in ResourceGroup: $ResourceGroupName."
        exit
    }
    return $sqlServer
}

function Get-DefaultStorageAccount{
    <#
        .SYNOPSIS
            List all resources for a resource group and grab the first StorageAccount it can find.
    
        .DESCRIPTION
            List all resources for a resource group and grab the first StorageAccount it can find.  
            Will only work if connection to Azure already exist.
    
        .PARAMETER ResourceGroupName
            The resource group where we will look for the StorageAccount.

        .PARAMETER StorageAccountName
            The name of the StorageAccount.

        .EXAMPLE
            Get-DefaultStorageAccount -ResourceGroupName $ResourceGroupName
    
        #>
        param(
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]$ResourceGroupName,

            [Parameter(Mandatory = $false)]
            [string] $StorageAccountName
        )
        if ($null -eq $StorageAccountName -or "" -eq $StorageAccountName) {
            $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName
            #$storageAccount #For debuging
            if ($storageAccount -is [array]){
                if ($storageAccount.Count -ne 1) {
                    if ($storageAccount.Count -gt 1) {
                        Write-Warning "Found more then 1 StorageAccount in ResourceGroup: $ResourceGroupName."
                    }
                    if ($storageAccount.Count -eq 0) {
                        Write-Warning "Could not find a StorageAccount in ResourceGroup: $ResourceGroupName."
                    }
                    exit
                }
            }
        } else {
            $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
            if ($null -eq $storageAccount) {
                Write-Error "Did not find StorageAccount in ResourceGroup: $ResourceGroupName."
                exit
            }
        }
        return $storageAccount
}

function Get-StorageAccountContainer{
    <#
        .SYNOPSIS
            Get the container for the specified StorageAccount.
    
        .DESCRIPTION
            Get the container for the specified StorageAccount.  
            Will only work if connection to Azure aleasy exist.

        .PARAMETER StorageAccount
            The StorageAccount where the container should exist.

        .PARAMETER ContainerName
            The container name.
    
        .EXAMPLE
            Get-StorageAccountContainer -StorageAccount $StorageAccount -ContainerName $ContainerName

        .EXAMPLE
            $storageAccount = Get-DefaultStorageAccount ResourceGroupName $ResourceGroupName
            Get-StorageAccountContainer -StorageAccount $storageAccount -ContainerName $ContainerName

        #>
        param(
            [Parameter(Mandatory)]
            [object]$StorageAccount,
            [Parameter(Mandatory)]
            [string]$ContainerName
        )
        $storageContainer = Get-AzRmStorageContainer -StorageAccount $StorageAccount -ContainerName $ContainerName
        #$storageContainer
        if ($null -eq $storageContainer) {
            Write-Warning "Could not find a StorageAccount container '$($storageContainer.Name)' in ResourceGroup: $($StorageAccount.ResourceGroupName))."
            exit
        } else {
            Write-Host "Connected to destination StorageAccount container $($storageContainer.Name)"
        }

        return $storageContainer
}

function Connect-AzureSubscriptionAccount{
    if($null -eq $azureConnection -or $null -eq $azureConnection.Account){
        try{
            $azureConnection = Connect-AzAccount -SubscriptionId $SubscriptionId
            Write-Host "Connected to subscription $SubscriptionId"
        }
        catch {
            $message = $_.Exception.message
            Write-Error $message
            exit
        }
    }
}

function Unpublish-Database{
    <#
    .SYNOPSIS
        Drop/Unpublish a database.

    .DESCRIPTION
        Drop/Unpublish a database.

    .PARAMETER ResourceGroupName
        The resource group where the sql database exist in.

    .PARAMETER SqlServerName
        The SQL server where the database exist in.

    .PARAMETER SqlDatabaseName
        The SQL server database that you want to drop.

    .EXAMPLE
        Unpublish-Database -ResourceGroupName $ResourceGroupName -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName

    #>
    param(
        [Parameter(Mandatory)]
        [object]$ResourceGroupName,
        [Parameter(Mandatory)]
        [string]$SqlServerName,
        [Parameter(Mandatory)]
        [string]$SqlDatabaseName
    )    
    # Drop destination database if exist
    Write-Host "Start droping destination database '$SqlDatabaseName'."
    Remove-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $SqlDatabaseName
    Write-Host "Droped destination database '$SqlDatabaseName'."
}

# END PRIVATE METHODS
function New-OptimizelyCmsResourceGroup{
    <#
    .SYNOPSIS
        Create a Optimizely CMS resource group in Azure.

    .DESCRIPTION
        Create a Optimizely CMS resource group in Azure.

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
        "App"="Optimizely";
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
        The location where we can find your custom ARM template to use in this script. Default = https://raw.githubusercontent.com/Epinova/EpinovaAzureToolBucket-psmodule/main/ArmTemplates/epinova-azure-basic-optimizely-cms.json

    .EXAMPLE
        New-OptimizelyCmsResourceGroup -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -DatabasePassword $DatabasePassword -Tags $Tags

    .EXAMPLE
        New-OptimizelyCmsResourceGroup -SubscriptionId '95a9fd36-7851-4918-b8c9-f146a219982c' -ResourceGroupName 'mycoolwebsite' -DatabasePassword 'KXIN_rhxh3holt_s8it' -Tags @{ "Environment"="dev";"Owner"="ove.lartelius@epinova.se";"App"="Optimizely";"Client"="Client name";"Project"="Project name";"ManagedBy"="Ove Lartelius";"Cost"="Internal";"Department"="IT";"Expires"="";  } -ResourceGroupLocation = "westeurope" -ArmTemplateUri = "https://raw.githubusercontent.com/yourrepository/arm-templates/main/azure-optimizely-cms.json" 

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
        [string] $ArmTemplateUri = "https://raw.githubusercontent.com/Epinova/EpinovaAzureToolBucket-psmodule/main/ArmTemplates/epinova-azure-basic-optimizely-cms.json"

    )

    $tagsString = $Tags | Out-String

    Write-Host "New-OptimizelyCmsResourceGroup - Inputs:----------"
    Write-Host "SubscriptionId:            $SubscriptionId"
    Write-Host "ResourceGroupName:         $ResourceGroupName"
    Write-Host "DatabasePassword:          **** (it is a secret...)"
    Write-Host "ResourceGroupLocation:     $ResourceGroupLocation"
    Write-Host "ARMTemplateUri:            $ArmTemplateUri"
    Write-Host "Tags:                      $tagsString"
    Write-Host "------------------------------------------------"

    $databasePasswordSecureString = ConvertTo-SecureString $DatabasePassword -AsPlainText -Force

    ##############################################################

    # Login to Azure
    Connect-AzAccount -SubscriptionId $SubscriptionId

    # Try to get the resource group with the specified name
    Get-AzResourceGroup -Name $ResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
    # Check if the resource group already exist
    if ($notPresent){
        Write-Host "Resource group $ResourceGroupName does not exist. We should be able to create it."
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

    Get-AzResourceGroup -Name $ResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
    if ($notPresent){
        Write-Error "Resource group $ResourceGroupName could not be created. Will cancel resource group deployment."
        exit
    } else {
        # Create resources from deployment template
        New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri $ArmTemplateUri -sqlserverAdminLoginPassword $databasePasswordSecureString
    }

}

function New-OptimizelyCmsResourceGroupBicep {
    <#
    .SYNOPSIS
        Create a Optimizely CMS resource group in Azure.
    .DESCRIPTION
        Create a Optimizely CMS resource group in Azure.
    .PARAMETER SubscriptionId
        Your Azure SubscriptionId that you want to create the new resource group in.
    .PARAMETER ResourceGroupName
        The client secret used to access the project.
    .PARAMETER Environment
        The type of environment that you want to create. Please select one of the following: inte|prep|prod
    .PARAMETER DatabaseLogin
        The username of database login object.
    .PARAMETER DatabasePassword
        The password to your database that will be generated. You need to follow the password policy. More information: https://docs.microsoft.com/en-us/previous-versions/azure/jj943764(v=azure.100)?redirectedfrom=MSDN
    .PARAMETER CmsVersion
        The CMS version that you want to run on the resource group. Please select one of the following: 11|12
        If 11 is selected a "windows" like webapp is created. If 12 it will be a Linux.
    .PARAMETER Tags
        The tags that will be set on the resource group when it is created. 
        Ex: $resourceGroupTags = @{
            "Environment"="dev";
            "Owner"="ove.lartelius@epinova.se";
            "App"="Optimizely";
            "Client"="Customer AB";
            "Project"="External Website 2021";
            "ManagedBy"="ove.lartelius@epinova.se";
            "Cost"="internal";
            "Department"="IT";
            "Expires"="2030-01-01";
        }
    .PARAMETER Location
        The location where the resource group should be hosted. Default = "westeurope". You can get a complete list of location by using "Get-AzureRmLocation |Format-Table".
    .PARAMETER UseApplicationInsight
        If ApplicationInsight should be setup in the resource group or not.
    .PARAMETER SqlSku
        Specifies which SQL SKU you want to generate. If not specified it will create a "basic" SQL Server. Allowed SKU 'Free', 'Basic', 'S0', 'S1', 'P1', 'P2', 'GP_Gen4_1', 'GP_S_Gen5_1', 'GP_Gen5_2', 'GP_S_Gen5_2', 'BC_Gen4_1', 'BC_Gen5_4'
    .PARAMETER AppPlanSku
        Specifies which AppPlan SKU you want to generate. If not specified it will create a "F1" plan will be created. Allowed SKU 'F1', 'D1', 'B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1', 'P2', 'P3', 'P4'
    .EXAMPLE
        New-OptimizelyCmsResourceGroupBicep -SubscriptionId '95a9fd36-7851-4918-b8c9-f146a219982c' -ResourceGroupName 'mycoolwebsite' -Environment "inte" -DatabaseLogin "databasedbuser" -DatabasePassword 'KXIN_rhxh3holt_s8it' -CmsVersion "12" -Tags @{ "Environment"="dev";"Owner"="ove.lartelius@epinova.se";"App"="Optimizely";"Client"="Client name";"Project"="Project name";"ManagedBy"="Ove Lartelius";"Cost"="Internal";"Department"="IT";"Expires"="";  } -Location = "westeurope" -UseApplicationInsight $true 
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
        [string] $Environment,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DatabaseLogin,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DatabasePassword,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $CmsVersion,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [hashtable] $Tags,

        [Parameter(Mandatory = $false)]
        [string] $Location = "westeurope",

        [Parameter(Mandatory = $false)]
        [bool] $UseApplicationInsight = $false,

        [Parameter(Mandatory = $false)]
        [bool] $UseDeviceAuthentication = $false,

        [Parameter(Mandatory = $false)]
        [string] $SqlSku,

        [Parameter(Mandatory = $false)]
        [string] $AppPlanSku

    )

    $TagsString = $Tags | Out-String
    
    #$databasePasswordSecureString = ConvertTo-SecureString $DatabasePassword -AsPlainText -Force | Out-String

    Write-Host "New-OptimizelyCmsResourceGroupBicep - Inputs:----------"
    Write-Host "SubscriptionId:                  $SubscriptionId"
    Write-Host "ResourceGroupName:               $ResourceGroupName"
    Write-Host "Environment:                     $Environment"
    Write-Host "DatabaseLogin:                   $DatabaseLogin"
    #Write-Host "DatabasePassword:                $databasePasswordSecureString"
    Write-Host "DatabasePassword:                $DatabasePassword"
    Write-Host "Location:                        $Location"
    Write-Host "CmsVersion:                      $CmsVersion"
    Write-Host "Tags:                            $TagsString"
    Write-Host "UseApplicationInsight:           $UseApplicationInsight"
    Write-Host "SqlSku:                          $SqlSku"
    Write-Host "AppPlanSku:                      $AppPlanSku"
    Write-Host "------------------------------------------------"


    ##############################################################

    # Login to Azure
    if ($UseDeviceAuthentication) {
        Connect-AzAccount -SubscriptionId $SubscriptionId -UseDeviceAuthentication
    } else {
        Connect-AzAccount -SubscriptionId $SubscriptionId
    }
    

    $Parameters = @{
        "projectName"                 = $ResourceGroupName
        "environmentName"             = $Environment
        "sqlserverAdminLogin"         = $DatabaseLogin
        "sqlserverAdminLoginPassword" = $DatabasePassword #$databasePasswordSecureString
        "useApplicationInsight"       = $UseApplicationInsight
        "tags"                        = $Tags
    };

    if ($false -eq [string]::IsNullOrEmpty($SqlSku)) {
        $Parameters = $Parameters + @{ "sqlSku" = $SqlSku}
    }

    if ($false -eq [string]::IsNullOrEmpty($AppPlanSku)){
        $Parameters = $Parameters + @{ "appPlanSku" = $AppPlanSku }
    }

    $bicepFile = "$PSScriptRoot\cms$CmsVersion.bicep"
    Write-Host "Use bicep: $bicepFile"

    # Create resources from deployment template
    New-AzDeployment -Location $Location -TemplateFile $bicepFile -TemplateParameterObject $Parameters
}

function Get-OptimizelyCmsConnectionStrings{
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
        Get-OptimizelyCmsConnectionStrings -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -DatabasePassword $DatabasePassword

    .EXAMPLE
        Get-OptimizelyCmsConnectionStrings -SubscriptionId "95a9fd36-7851-4918-b8c9-f146a219982c" -ResourceGroupName $ResourceGroupName -DatabasePassword $DatabasePassword

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
        $sqlDatabaseName = "$($resourceGroupName)opticms"
    } else {
        $sqlDatabaseName = $DatabaseName
    }
    
    Write-Host "<add name=""EPiServerDB"" connectionString=""Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$resourceGroupName-sa;Password=$databasePassword;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"" providerName=""System.Data.SqlClient"" />"
}

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
        The location where we can find your custom ARM template to use in this script. Default = https://raw.githubusercontent.com/Epinova/EpinovaAzureToolBucket-psmodule/main/ArmTemplates/epinova-azure-basic-episerver-cms.json

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
        [string] $ArmTemplateUri = "https://raw.githubusercontent.com/Epinova/EpinovaAzureToolBucket-psmodule/main/ArmTemplates/epinova-azure-basic-episerver-cms.json"

    )

    Write-Host "New-EpiserverCmsResourceGroup - Inputs:----------"
    Write-Host "SubscriptionId:            $SubscriptionId"
    Write-Host "ResourceGroupName:         $ResourceGroupName"
    Write-Host "DatabasePassword:          **** (it is a secret...)"
    Write-Host "Tags:                      $Tags"
    Write-Host "ResourceGroupLocation:     $ResourceGroupLocation"
    Write-Host "ARMTemplateUri:            $ArmTemplateUri"
    Write-Host "------------------------------------------------"
    Write-Warning "You should start using New-OptimizelyCmsResourceGroup"

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
    Write-Warning "You should start using Get-OptimizelyCmsConnectionStrings"

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

function Add-AzureDatabaseUser{
    <#
    .SYNOPSIS
        Create a database user for a specific database on a Azure SQL Server instance.

    .DESCRIPTION
        Create a database user for a specific database on a Azure SQL Server instance.

    .PARAMETER SqlServer
        The Azure SQL Server that you want to connect to. Example: mycompany-dev.database.windows.net

    .PARAMETER SqlServerUsername
        The username for your SQL Server administrator account.

    .PARAMETER SqlServerPassword
        The Password for your SQL Server administrator account.

    .PARAMETER TargetDatabase
        The database where you want to create a login/user..

    .PARAMETER NewUsername
        The username for the new user that you want to create in the target database.

    .PARAMETER NewPassword
        The password for the new user that you want to create in the target database.

    .PARAMETER NewUserPermission
        The role that the new user/login will have on the database. Example: db_owner

    .EXAMPLE
        Add-AzureDatabaseUser -SqlServer $SqlServer -SqlServerUsername $SqlServerUsername -SqlServerPassword $SqlServerPassword -TargetDatabase $TargetDatabase -NewUsername $NewUsername -NewPassword $NewPassword -NewUserPermission $NewUserPermission

    .EXAMPLE
        Add-AzureDatabaseUser -SqlServer "project1-dev.database.windows.net" -SqlServerUsername "project1-sa" -SqlServerPassword "@wes0mep@ssw0rd" -TargetDatabase "project1-cms-dev" -NewUsername "project1dbuser" -NewPassword "mynew@wes0mep@ssw0rd" -NewUserPermission "db_owner"

        Example connections string: Server=tcp:project1-dev.database.windows.net,1433;Initial Catalog=project1-cms-dev;Persist Security Info=False;User ID=project1-sa;Password=@wes0mep@ssw0rd;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SqlServer,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SqlServerUsername,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SqlServerPassword,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $TargetDatabase,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $NewUsername,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $NewPassword,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $NewUserPermission

    )

    Write-Host "Add-AzureDatabaseUser - Inputs:----------"
    Write-Host "SqlServer:           $SqlServer"
    Write-Host "SqlServerUsername:   $SqlServerUsername"
    Write-Host "SqlServerPassword:   $SqlServerPassword"
    Write-Host "TargetDatabase:      $TargetDatabase"
    Write-Host "NewUsername:         $NewUsername"
    Write-Host "NewPassword:         $NewPassword"
    Write-Host "NewUserPermission:   $NewUserPermission"
    Write-Host "-----------------------------------------"

    if ($NewUsername.Contains("-")){
        Write-Error "NewUsername contains '-' chars. Please remove them and try again."
        exit
    }

    # Test the connection to the master database with the administrator account login
    $password = ConvertTo-SecureString $SqlServerPassword -AsPlainText -Force
    $credentials = New-Object PSCredential $SqlServerUsername, $password
    $testConnection = Test-AzureSqlConnection -ServerName $SqlServer -DatabaseName "master" -Credential $credentials

    if ($true -eq $testConnection) {
        Write-Host "Connection to SQL Server is working."
    } else {
        Write-Error "Connection to SQL Server is not working."
        exit
    }

    Write-Host " "
    $command = "CREATE LOGIN $NewUsername WITH password='$NewPassword'"
    $createUserResult = Invoke-DatabaseExecuteNonQueryCommand -ServerName $SqlServer -DatabaseName "master" -Credential $credentials -Command $command

    if ($false -eq $createUserResult) {
        Write-Error "Could not create the login."
        exit
    }

    $command = "CREATE USER $NewUsername FROM LOGIN $NewUsername"
    $createUserResult = Invoke-DatabaseExecuteNonQueryCommand -ServerName $SqlServer -DatabaseName $TargetDatabase -Credential $credentials -Command $command

    if ($false -eq $createUserResult) {
        Write-Error "Could not create the user."
        exit
    }

    $command = "EXEC sp_addrolemember '$NewUserPermission', '$NewUsername'"
    $createUserResult = Invoke-DatabaseExecuteNonQueryCommand -ServerName $SqlServer -DatabaseName $TargetDatabase -Credential $credentials -Command $command
    
    if ($true -eq $createUserResult) {
        Write-Host "Your new user has been created."
    } else {
        Write-Error "Could not set permission for the new user/login."
        exit
    }
    Write-Host " "
    $password = ConvertTo-SecureString $newPassword -AsPlainText -Force
    $newCredentials = New-Object PSCredential $newUsername, $password
    $testNewUserResult = Test-AzureSqlConnection -ServerName $sqlServer -DatabaseName $targetDatabase -Credential $newCredentials

    if ($true -eq $testNewUserResult) {
        Write-Host "Connection to target database with new user succedded."
        Write-Host " "
        Write-Host "Result:----------------------------"
        Write-Host "SqlServer:        $sqlServer"
        Write-Host "Database:         $targetDatabase"
        Write-Host "Username:         $newUsername"
        Write-Host "Password:         $newPassword"
        Write-Host "ConnectionString: <add name=`"EPiServerDB`" connectionString=`"Server=tcp:$sqlServer,1433;Initial Catalog=$targetDatabase;Persist Security Info=False;User ID=$newUsername;Password=$newPassword;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;`" providerName=`"System.Data.SqlClient`" />"
        Write-Host "--- JOBS DONE! ---"
    } else {
        Write-Warning "The user has been created but we can not login with the new user information. Please look into the problem and figure out why."
        exit
    }
    Write-Host "--- THE END ---"
}

function Backup-Database{
    <#
    .SYNOPSIS
        Backup a database and store in storage account container.

    .DESCRIPTION
        Backup a database and store in storage account container.

    .PARAMETER SubscriptionId
        Your Azure SubscriptionId where the database exist that you want to backup.

    .PARAMETER ResourceGroupName
        The resource group name where the database exist that you want to backup.

    .PARAMETER SqlServerName
        The Sql Server that contain the database that you want to backup. If empty we will try to find the first SqlServer resource in the specified resource group.

    .PARAMETER SqlDatabaseName
        Name of the database that should be backed up.

    .PARAMETER SqlDatabaseLogin
        Administrator username for the SqlServer.

    .PARAMETER SqlDatabasePassword
        Administrator password for the SqlServer.

    .PARAMETER StorageAccountName
        The StorageAccount that should hold the BACPAC file after backup. If empty we will try to find the first StorageAccount resource in the specified resource group.

    .PARAMETER StorageAccountContainer
        The StorageAccount container name that should hold the BACPAC file after backup. If empty we will try to find the container with name "db-backups".

    .EXAMPLE
        Invoke-AzureDatabaseBackup -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlDatabaseLogin $SqlDatabaseLogin -SqlDatabasePassword $SqlDatabasePassword -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SubscriptionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $false)]
        [string] $SqlServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SqlDatabaseName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SqlDatabaseLogin,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SqlDatabasePassword,

        [Parameter(Mandatory = $false)]
        [string] $StorageAccountName,

        [Parameter(Mandatory = $false)]
        [string] $StorageAccountContainer
    )

    $securePassword = ConvertTo-SecureString -String $SqlDatabasePassword -AsPlainText -Force
    $sqlCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SqlDatabaseLogin, $securePassword

    Connect-AzureSubscriptionAccount

    if ($null -eq $StorageAccountName -or "" -eq $StorageAccountName){
        Write-Host "StorageAccount is not set. We will try to find a storage account."
        $storageAccount = Get-DefaultStorageAccount -ResourceGroupName $ResourceGroupName
        $storageAccountName = $storageAccount.StorageAccountName
        Write-Host "Found StorageAccount '$storageAccountName'"
    } else {
        $storageAccount = Get-DefaultStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
        $storageAccountName = $storageAccount.StorageAccountName
    }
    
    if ($null -eq $StorageAccountContainer -or "" -eq $StorageAccountContainer){
        Write-Host "StorageAccount container is not set. We will try to find a container."
        $storageContainer = Get-StorageAccountContainer -StorageAccount $storageAccount -ContainerName $StorageAccountContainer
        $storageContainerName = $storageContainer.Name
        Write-Host "Found StorageAccount container '$storageContainerName'"
    } else {
        $storageContainerName = $StorageAccountContainer
    }
    
    
    if ($null -eq $SqlServerName -or "" -eq $SqlServerName) {
        $SqlServerName = Get-DefaultSqlServer -ResourceGroupName $ResourceGroupName
    }
    Write-Host "Found SqlServer '$SqlServerName'"
    
    # Fix some information about the destination storage account
    $bacpacFilename = $SqlDatabaseName + "_" + (Get-Date).ToString("yyyy-MM-dd-HH-mm") + ".bacpac"
    $storageKeyType = "StorageAccessKey"
    $storageKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $storageAccountName)| Where-Object {$_.KeyName -eq "key2"}
    $baseStorageUri = "https://" + $storageAccountName + ".blob.core.windows.net"
    $bacpacUri = $baseStorageUri + "/" + $storageContainerName + "/" + $bacpacFilename
    
    Write-Host "Invoke-AzureDatabaseBackup - Inputs:----------"
    Write-Host "SubscriptionId:            $SubscriptionId"
    Write-Host "ResourceGroupName:         $ResourceGroupName"
    Write-Host "SqlServerName:             $SqlServerName"
    Write-Host "SqlDatabaseName:           $SqlDatabaseName"
    Write-Host "ResourceGroupName:         $ResourceGroupName"
    Write-Host "SqlDatabaseLogin:          $SqlDatabaseLogin"
    Write-Host "SqlDatabasePassword:       **** (it is a secret...)"
    Write-Host "StorageAccountName:        $storageAccountName"
    Write-Host "StorageAccountContainer:   $storageContainerName"
    Write-Host "StorageKey:                $($storageKey.Value))"
    Write-Host "Bacpac file:               $bacpacFilename"
    Write-Host "Bacpac URI:                $bacpacUri"
    Write-Host "------------------------------------------------"
    
    # Do a database backup of the destination database.
    $exportRequest = New-AzSqlDatabaseExport -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $SqlDatabaseName -StorageKeyType $storageKeyType -StorageKey $storageKey.Value -StorageUri $bacpacUri -AdministratorLogin $sqlCredentials.UserName -AdministratorLoginPassword $sqlCredentials.Password
    if ($null -ne $exportRequest) {
        $operationStatusLink = $exportRequest.OperationStatusLink
        $operationStatusLink
        $exportStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $operationStatusLink
        [Console]::Write("Exporting.")
        $lastStatusMessage = ""
        while ($exportStatus.Status -eq "InProgress")
        {
            Start-Sleep -s 10
            $exportStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $operationStatusLink
            if ($lastStatusMessage -ne $exportStatus.StatusMessage) {
                $lastStatusMessage = $exportStatus.StatusMessage
                $progress = $lastStatusMessage.Replace("Running, Progress = ", "")
                [Console]::Write($progress)
            }
            [Console]::Write(".")
        }
        [Console]::WriteLine("")
        $exportStatus
        Write-Host "Database '$SqlDatabaseName' is backed up. '$bacpacUri'"
    } else {
        Write-Error "Could not start backup of $SqlDatabaseName"
        exit
    }
}

function Copy-Database{
    <#
    .SYNOPSIS
        Copy a database from one place to another.

    .DESCRIPTION
        Copy a database from one place to another. If the destination database exist it will be 'overwritten'. You can decide if you want to make a backup of the destination database before it is dropped.

    .PARAMETER SubscriptionId
        Your Azure SubscriptionId where the databases exist that you want to copy.

    .PARAMETER SourceResourceGroupName
        The resource group name where the source database exist that we want to copy.

    .PARAMETER SourceSqlServerName
        The Sql Server that contain the database that you want to copy. If empty we will try to find the first SqlServer resource in the specified source resource group.

    .PARAMETER SourceSqlDatabaseName
        Name of the database that should be copied.

    .PARAMETER DestinationResourceGroupName
        The resource group name where the destination database should be copied to.

    .PARAMETER DestinationSqlServerName
        The destination Sql server name. If empty we will try to find the first SqlServer resource in the specified destination resource group.

    .PARAMETER DestinationSqlDatabaseName
        The destination database name.

    .PARAMETER DestinationRunDatabaseBackup
        If the destination database exist and this param is true a backup of the database will be made first.

    .PARAMETER DestinationSqlDatabaseLogin
        Destination Sql server administrator username. Only needed if you want to make a backup of destination database.

    .PARAMETER DestinationSqlDatabasePassword
        Destination Sql server administrator password. Only needed if you want to make a backup of destination database.

    .PARAMETER DestinationStorageAccountName
        The StorageAccount that should hold the BACPAC file for backup. If empty we will try to find the first StorageAccount resource in the specified destination resource group.

    .PARAMETER DestinationStorageAccountContainer
        The StorageAccount container name that should hold the BACPAC file backup. If empty we will try to find the container with name "db-backups".

    .PARAMETER SqlSku
        Specifies which SQL SKU you want to generate. If not specified it will create a "basic" SQL Server. Allowed SKU 'Free', 'Basic', 'S0', 'S1', 'P1', 'P2', 'GP_Gen4_1', 'GP_S_Gen5_1', 'GP_Gen5_2', 'GP_S_Gen5_2', 'BC_Gen4_1', 'BC_Gen5_4'

    .EXAMPLE
        Invoke-AzureDatabaseCopy -SubscriptionId $SubscriptionId -SourceResourceGroupName $SourceResourceGroupName -SourceSqlServerName $SourceSqlServerName -SourceSqlDatabaseName $SourceSqlDatabaseName -DestinationResourceGroupName $DestinationResourceGroupName -DestinationSqlServerName $DestinationSqlServerName -DestinationSqlDatabaseName $DestinationSqlDatabaseName -DestinationRunDatabaseBackup $DestinationRunDatabaseBackup 

    .EXAMPLE
        Invoke-AzureDatabaseCopy -SubscriptionId $SubscriptionId -SourceResourceGroupName $SourceResourceGroupName -SourceSqlServerName $SourceSqlServerName -SourceSqlDatabaseName $SourceSqlDatabaseName -DestinationResourceGroupName $DestinationResourceGroupName -DestinationSqlServerName $DestinationSqlServerName -DestinationSqlDatabaseName $DestinationSqlDatabaseName -DestinationRunDatabaseBackup $DestinationRunDatabaseBackup -DestinationSqlDatabaseLogin $DestinationSqlDatabaseLogin -DestinationSqlDatabasePassword $DestinationSqlDatabasePassword -DestinationStorageAccount $DestinationStorageAccount -DestinationStorageAccountContainer $DestinationStorageAccountContainer 
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SubscriptionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SourceResourceGroupName,

        [Parameter(Mandatory = $false)]
        [string] $SourceSqlServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SourceSqlDatabaseName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DestinationResourceGroupName,

        [Parameter(Mandatory = $false)]
        [string] $DestinationSqlServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DestinationSqlDatabaseName,

        [Parameter(Mandatory = $true)]
        [bool] $DestinationRunDatabaseBackup,

        [Parameter(Mandatory = $false)]
        [string] $DestinationSqlDatabaseLogin,

        [Parameter(Mandatory = $false)]
        [string] $DestinationSqlDatabasePassword,

        [Parameter(Mandatory = $false)]
        [string] $DestinationStorageAccount,

        [Parameter(Mandatory = $false)]
        [string] $DestinationStorageAccountContainer,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Free', 'Basic', 'S0', 'S1', 'P1', 'P2', 'GP_Gen4_1', 'GP_S_Gen5_1', 'GP_Gen5_2', 'GP_S_Gen5_2', 'BC_Gen4_1', 'BC_Gen5_4')]
        [string] $SqlSku = "Basic"
    )

    Connect-AzureSubscriptionAccount

    if ($null -eq $SourceSqlServerName -or "" -eq $SourceSqlServerName) {
        $SourceSqlServerName = Get-DefaultSqlServer -ResourceGroupName $SourceResourceGroupName
    }
    Write-Host "Found source SqlServer '$SourceSqlServerName'"

    if ($null -eq $DestinationSqlServerName -or "" -eq $DestinationSqlServerName) {
        $DestinationSqlServerName = Get-DefaultSqlServer -ResourceGroupName $DestinationSqlServerName
    }
    Write-Host "Found destination SqlServer '$DestinationSqlServerName'"

    $destinationDatabaseExist = $false
    try {
        $destinationDatabaseResult = Get-AzSqlDatabase -ResourceGroupName $DestinationResourceGroupName -ServerName $DestinationSqlServerName -DatabaseName $DestinationSqlDatabaseName -ErrorAction SilentlyContinue
        if ($null -ne $destinationDatabaseResult) {
            $destinationDatabaseExist = $true
            Write-Host "Destination database $DestinationSqlDatabaseName exist."
        } else {
            Write-Host "Destination database $DestinationSqlDatabaseName does not exist."
        }
    } catch {
        Write-Host "Destination database $DestinationSqlDatabaseName does not exist."
        $error.clear()
    }

    Write-Host "Invoke-AzureDatabaseCopy - Inputs:----------"
    Write-Host "SubscriptionId:                     $SubscriptionId"
    Write-Host "SourceResourceGroupName:            $SourceResourceGroupName"
    Write-Host "SourceSqlServerName:                $SourceSqlServerName"
    Write-Host "SourceSqlDatabaseName:              $SourceSqlDatabaseName"
    Write-Host "DestinationResourceGroupName:       $DestinationResourceGroupName"
    Write-Host "DestinationSqlServerName:           $DestinationSqlServerName"
    Write-Host "DestinationSqlDatabaseName:         $DestinationSqlDatabaseName"
    Write-Host "DestinationRunDatabaseBackup:       $DestinationRunDatabaseBackup"
    Write-Host "DestinationSqlDatabaseLogin:        $DestinationSqlDatabaseLogin"
    Write-Host "DestinationSqlDatabasePassword:     **** (it is a secret...)"
    Write-Host "DestinationDatabaseExist:           $destinationDatabaseExist"
    Write-Host "DestinationStorageAccount:          $DestinationStorageAccount"
    Write-Host "DestinationStorageAccountContainer: $DestinationStorageAccountContainer"
    Write-Host "SqlSku:                             $SqlSku"
    Write-Host "------------------------------------------------"

    if ($true -eq $destinationDatabaseExist -and $true -eq $DestinationRunDatabaseBackup) {
        $missingParam = $false
        if($null -eq $DestinationSqlDatabaseLogin -or "" -eq $DestinationSqlDatabaseLogin) {
            Write-Warning "You want to make a destination database backup and missing the -DestinationSqlDatabaseLogin param."
            $missingParam = $true
        }
        if($null -eq $DestinationSqlDatabasePassword -or "" -eq $DestinationSqlDatabasePassword) {
            Write-Warning "You want to make a destination database backup and missing the DestinationSqlDatabasePassword param."
            $missingParam = $true
        }

        if ($true -eq $missingParam) {
            Write-Error "Parameters is missing."
            exit
        }

        Backup-Database -SubscriptionId $SubscriptionId -ResourceGroupName $DestinationResourceGroupName -SqlServerName $DestinationSqlServerName -SqlDatabaseName $DestinationSqlDatabaseName -SqlDatabaseLogin $DestinationSqlDatabaseLogin -SqlDatabasePassword $DestinationSqlDatabasePassword -StorageAccountName $DestinationStorageAccount -StorageAccountContainer $DestinationStorageAccountContainer
    }

    # Drop destination database if exist
    if ($true -eq $destinationDatabaseExist) {
        Unpublish-Database -ResourceGroupName $DestinationResourceGroupName -SqlServerName $DestinationSqlServerName -SqlDatabaseName $DestinationSqlDatabaseName
    }

    # Copy the source database to destination database
    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
    Write-Host "Start copying database '$SourceSqlDatabaseName' to '$DestinationSqlDatabaseName'."
    $databaseCopy = New-AzSqlDatabaseCopy -ResourceGroupName $SourceResourceGroupName -ServerName $SourceSqlServerName -DatabaseName $SourceSqlDatabaseName -CopyResourceGroupName $DestinationResourceGroupName -CopyServerName $DestinationSqlServerName -CopyDatabaseName $DestinationSqlDatabaseName
    $databaseCopy

    Write-Host "--------------------------------------------------------------"

    # Check the SKU on destination database after copy. 
    $destinationDatabaseResult = Get-AzSqlDatabase -ResourceGroupName $DestinationResourceGroupName -ServerName $DestinationSqlServerName -DatabaseName $DestinationSqlDatabaseName
    $destinationDatabaseResult

    Write-Host "--------------------------------------------------------------"
    
    if ($false -eq [string]::IsNullOrEmpty($SqlSku)) {
        Set-AzSqlDatabase -ResourceGroupName $DestinationResourceGroupName -DatabaseName $DestinationSqlDatabaseName -ServerName $DestinationSqlServerName -RequestedServiceObjectiveName $SqlSku #-Edition "Standard"
        #try {
        #    $databaseCopy = New-AzSqlDatabaseCopy -ResourceGroupName $SourceResourceGroupName -ServerName $SourceSqlServerName -DatabaseName $SourceSqlDatabaseName -CopyResourceGroupName $DestinationResourceGroupName -CopyServerName $DestinationSqlServerName -CopyDatabaseName $DestinationSqlDatabaseName -ServiceObjectiveName $SqlSku
        #} catch {
        #    $errorMessage = $_.ErrorDetails
        #    if ($errorMessage -contains "does not support the sku") {
        #        Write-Error "Database '$SourceSqlDatabaseName' is NOT copied to '$DestinationSqlDatabaseName'."
        #    } else {
        #        Write-Warning $errorMessage
        #    }
        #}
    } #else {
    #    $databaseCopy = New-AzSqlDatabaseCopy -ResourceGroupName $SourceResourceGroupName -ServerName $SourceSqlServerName -DatabaseName $SourceSqlDatabaseName -CopyResourceGroupName $DestinationResourceGroupName -CopyServerName $DestinationSqlServerName -CopyDatabaseName $DestinationSqlDatabaseName
    #    Write-Host "Database '$SourceSqlDatabaseName' is copied to '$DestinationSqlDatabaseName'."
    #}
    Write-Host "--------------------------------------------------------------"

    # Check the SKU on destination database after copy. 
    $destinationDatabaseResult = Get-AzSqlDatabase -ResourceGroupName $DestinationResourceGroupName -ServerName $DestinationSqlServerName -DatabaseName $DestinationSqlDatabaseName
    $destinationDatabaseResult


}

function Remove-Blobs{
    <#
    .SYNOPSIS
        Remove all blobs found in the specified StorageAccount container.

    .DESCRIPTION
        Remove all blobs found in the specified StorageAccount container.

    .PARAMETER SubscriptionId
        Your Azure SubscriptionId where we can find your StorageAccount.

    .PARAMETER ResourceGroupName
        The resource group name where the blobs are that you want to remove.

    .PARAMETER StorageAccountName
        The StorageAccount name where the blobs are that you want to remove.

    .PARAMETER ContainerName
        The container name where the blobs are that you want to remove.

    .EXAMPLE
        Remove-Blobs -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ContainerName $ContainerName

    .EXAMPLE
        Remove-Blobs -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -ContainerName $ContainerName
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
        [string] $StorageAccountName,

        [Parameter(Mandatory = $true)]
        [string] $ContainerName
    )

    Connect-AzureSubscriptionAccount

    Write-Host "Remove-Blobs - Inputs:----------"
    Write-Host "SubscriptionId:         $SubscriptionId"
    Write-Host "ResourceGroupName:      $ResourceGroupName"
    Write-Host "StorageAccountName:     $StorageAccountName"
    Write-Host "ContainerName:          $ContainerName"
    Write-Host "------------------------------------------------"

    $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName 
    $context = $storageAccount.Context 

    (Get-AzStorageBlob -Container $ContainerName -Context $context | Sort-Object -Property LastModified -Descending) | Remove-AzStorageBlob
      
    Write-Host "Remove-Blobs finished"
}

function Copy-Blobs{
    <#
    .SYNOPSIS
        Copy all blobs from a StorageAccount container to another.

    .DESCRIPTION
        Copy all blobs from a StorageAccount container to another.

    .PARAMETER SubscriptionId
        Your Azure SubscriptionId where we can find your blobs.

    .PARAMETER SourceResourceGroupName
        The resource group name where the blobs are that we want to copy.

    .PARAMETER SourceStorageAccountName
        The StorageAccount name where the blobs are that we want to copy.

    .PARAMETER SourceContainerName
        The container name where the blobs are that we want to copy.

    .PARAMETER DestinationResourceGroupName
        The destination group name where the blobs should be moved.

    .PARAMETER DestinationStorageAccountName
        The destination StorageAccount where the blobs should be moved.

    .PARAMETER DestinationContainerName
        The destination container name where the blobs should be moved.

    .PARAMETER CleanBeforeCopy
        Set to true if you want thw script to remove all blobs in destination container before we start copy over all blobs.

    .EXAMPLE
        Copy-Blobs -SubscriptionId $SubscriptionId -SourceResourceGroupName $SourceResourceGroupName -SourceStorageAccountName $SourceStorageAccountName -SourceContainerName $SourceContainerName -DestinationResourceGroupName $DestinationResourceGroupName -DestinationStorageAccountName $DestinationStorageAccountName -DestinationContainerName $DestinationContainerName 
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SubscriptionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SourceResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string] $SourceStorageAccountName,

        [Parameter(Mandatory = $true)]
        [string] $SourceContainerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DestinationResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string] $DestinationStorageAccountName,

        [Parameter(Mandatory = $true)]
        [string] $DestinationContainerName,

        [Parameter(Mandatory = $false)]
        [bool] $CleanBeforeCopy
    )

    Connect-AzureSubscriptionAccount

    Write-Host "Copy-Blobs - Inputs:----------------------------"
    Write-Host "SubscriptionId:                 $SubscriptionId"
    Write-Host "SourceResourceGroupName:        $SourceResourceGroupName"
    Write-Host "SourceStorageAccountName:       $SourceStorageAccountName"
    Write-Host "SourceContainerName:            $SourceContainerName"
    Write-Host "DestinationResourceGroupName:   $DestinationResourceGroupName"
    Write-Host "DestinationStorageAccountName:  $DestinationStorageAccountName"
    Write-Host "DestinationContainerName:       $DestinationContainerName"
    Write-Host "CleanBeforeCopy:                $CleanBeforeCopy"
    Write-Host "------------------------------------------------"

    $sourceStorageAccount = Get-AzStorageAccount -ResourceGroupName $SourceResourceGroupName -Name $SourceStorageAccountName 
    $sourceContext = $sourceStorageAccount.Context 

    $destinationStorageAccount = Get-AzStorageAccount -ResourceGroupName $DestinationResourceGroupName -Name $DestinationStorageAccountName 
    $destinationContext = $destinationStorageAccount.Context 

    if ($true -eq $CleanBeforeCopy){
        Write-Host "Start remove all blobs in $DestinationContainerName."    
        (Get-AzStorageBlob -Container $DestinationContainerName -Context $destinationContext | Sort-Object -Property LastModified -Descending) | Remove-AzStorageBlob
        Write-Host "All blobs in $DestinationContainerName should be removed."    
    }

    Write-Host "Start copy blobs"
    Get-AzStorageBlob -Container $SourceContainerName -Context $sourceContext | Start-AzStorageBlobCopy -DestContainer $DestinationContainerName  -Context $destinationContext -Force
    Write-Host "Copy-Blobs finished"
}

function New-AzureDevOpsProject{
    <#
    .SYNOPSIS
        Create a project in Azure DevOps.

    .DESCRIPTION
        Create a project in Azure DevOps.
        Git repo, scrum process, visibility private

    .PARAMETER OrganizationName
        The name of the organization where the new project should be created. Ex if the URL to your Azure DevOps is https://dev.azure.com/your-company. The the OrganisationName is 'your-company'

    .PARAMETER ProjectName
        The name of the project that should be created.

    .PARAMETER ProjectDescription
        The description of the project.

    .EXAMPLE
        New-AzureDevOpsProject -OrganizationName $OrganizationName -ProjectName $ProjectName -ProjectDescription $ProjectDescription

    .EXAMPLE
        New-AzureDevOpsProject -OrganizationName "your-company" -ProjectName "MyCoolProject" -ProjectDescription "Cool project contains cool code..."

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectDescription

    )

    Write-Host "New-AzureDevOpsProject - Inputs:----------"
    Write-Host "OrganizationName:    $OrganizationName"
    Write-Host "ProjectName:         $ProjectName"
    Write-Host "ProjectDescription:  $ProjectDescription"
    Write-Host "-----------------------------------------"

    az --version

    az login

    $organizationId = "https://dev.azure.com/$OrganizationName"

    az devops project create --name $ProjectName --description $ProjectDescription --org $organizationId --process Scrum --source-control git --visibility private --verbose

    az devops project show --org $organizationId --project $ProjectName

    Write-Host "--- THE END ---"
}

function Send-Blob{
    <#
    .SYNOPSIS
        Send a blob to a container in Azure
    .DESCRIPTION
        Send a blob to a container in Azure

    .PARAMETER SubscriptionId
        Your Azure SubscriptionId where you wan to upload the blob.

    .PARAMETER ResourceGroupName
        The resource group name where the blob should be uploaded.

    .PARAMETER StorageAccountName
        The StorageAccount name where the blob should be uploaded.

    .PARAMETER StorageAccountContainer
        The container name where the blob should be uploaded.

    .PARAMETER FilePath
        The full file path to the blob that should be uploaded to Azure.

    .PARAMETER FilePath
        The blob name that should get when uploaded to Azure. If you specify 'foldername\filename.txt' it will create a folder with the name 'foldername' where it will put the 'filename.txt' file.

    .EXAMPLE
        Send-Blob -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -FilePath $filePath -BlobName $BlobName

    .EXAMPLE
        Send-Blob -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -FilePath $filePath -BlobName $BlobName

    .EXAMPLE
        $result = Send-Blob -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -FilePath $filePath -BlobName $BlobName

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SubscriptionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $false)]
        [string] $StorageAccountName,

        [Parameter(Mandatory = $false)]
        [string] $StorageAccountContainer,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $FilePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $BlobName
    )

    Connect-AzureSubscriptionAccount

    if ($null -eq $StorageAccountName -or "" -eq $StorageAccountName){
        Write-Host "StorageAccount is not set. We will try to find a storage account."
        $storageAccount = Get-DefaultStorageAccount -ResourceGroupName $ResourceGroupName
        $storageAccountName = $storageAccount.StorageAccountName
        Write-Host "Found StorageAccount '$storageAccountName'"
    } else {
        $storageAccount = Get-DefaultStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
        $storageAccountName = $storageAccount.StorageAccountName
    }

    if ($null -eq $StorageAccountContainer -or "" -eq $StorageAccountContainer){
        Write-Host "StorageAccount container is not set. We will try to find a container."
        $storageContainer = Get-StorageAccountContainer -StorageAccount $storageAccount -ContainerName $StorageAccountContainer
        $storageContainerName = $storageContainer.Name
        Write-Host "Found StorageAccount container '$storageContainerName'"
    } else {
        $storageContainerName = $StorageAccountContainer
    }
    

    Write-Host "Send-Blob - Inputs:----------------------------"
    Write-Host "SubscriptionId:           $SubscriptionId"
    Write-Host "ResourceGroupName:        $ResourceGroupName"
    Write-Host "StorageAccountName:       $StorageAccountName"
    Write-Host "StorageAccountContainer:  $StorageAccountContainer"
    Write-Host "FilePath:                 $FilePath"
    Write-Host "BlobName:                 $BlobName"
    Write-Host "------------------------------------------------"

    $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccountName 

    if ($null -ne $storageAccount){
        Write-Host "Start upload blob $BlobName" 
        Set-AzStorageBlobContent -Container $storageContainerName -File $FilePath -Blob $BlobName -Context $storageAccount.context -Force
        Write-Host "Blob uploaded"
    } else {
        Write-Error "Could not connect to StorageAccount: $storageAccountName"
    }

    return $BlobName
}

function Send-BlobAsConnected{
    <#
    .SYNOPSIS
        Send a blob to a container in Azure
    .DESCRIPTION
        Send a blob to a container in Azure

    .PARAMETER ResourceGroupName
        The resource group name where the blob should be uploaded.

    .PARAMETER StorageAccountName
        The StorageAccount name where the blob should be uploaded.

    .PARAMETER StorageAccountContainer
        The container name where the blob should be uploaded.

    .PARAMETER FilePath
        The full file path to the blob that should be uploaded to Azure.

    .PARAMETER FilePath
        The blob name that should get when uploaded to Azure. If you specify 'foldername\filename.txt' it will create a folder with the name 'foldername' where it will put the 'filename.txt' file.

    .EXAMPLE
        Send-Blob -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -FilePath $filePath -BlobName $BlobName

    .EXAMPLE
        Send-Blob -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -FilePath $filePath -BlobName $BlobName

    .EXAMPLE
        $result = Send-Blob -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -FilePath $filePath -BlobName $BlobName

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $false)]
        [string] $StorageAccountName,

        [Parameter(Mandatory = $false)]
        [string] $StorageAccountContainer,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $FilePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $BlobName
    )

    if ($null -eq $StorageAccountName -or "" -eq $StorageAccountName){
        Write-Host "StorageAccount is not set. We will try to find a storage account."
        $storageAccount = Get-DefaultStorageAccount -ResourceGroupName $ResourceGroupName
        $storageAccountName = $storageAccount.StorageAccountName
        Write-Host "Found StorageAccount '$storageAccountName'"
    } else {
        $storageAccount = Get-DefaultStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
        $storageAccountName = $storageAccount.StorageAccountName
    }
    

    if ($null -eq $StorageAccountContainer -or "" -eq $StorageAccountContainer){
        Write-Host "StorageAccount container is not set. We will try to find a container."
        $storageContainer = Get-StorageAccountContainer -StorageAccount $storageAccount -ContainerName $StorageAccountContainer
        $storageContainerName = $storageContainer.Name
        Write-Host "Found StorageAccount container '$storageContainerName'"
    } else {
        $storageContainerName = $StorageAccountContainer
    }

    Write-Host "Send-BlobAsConnected - Inputs:----------------------------"
    Write-Host "ResourceGroupName:        $ResourceGroupName"
    Write-Host "StorageAccountName:       $StorageAccountName"
    Write-Host "StorageAccountContainer:  $StorageAccountContainer"
    Write-Host "FilePath:                 $FilePath"
    Write-Host "BlobName:                 $BlobName"
    Write-Host "------------------------------------------------"

    $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccountName 

    if ($null -ne $storageAccount){
        Write-Host "Start upload blob $BlobName" 
        Set-AzStorageBlobContent -Container $storageContainerName -File $FilePath -Blob $BlobName -Context $storageAccount.context -Force
        Write-Host "Blob uploaded"
    } else {
        Write-Error "Could not connect to StorageAccount: $storageAccountName"
    }

    return $BlobName
}

function Import-BacpacDatabase{
    <#
    .SYNOPSIS
        Import a bacpac file, from storageaccount container, to a database in Azure.
    .DESCRIPTION
        Import a bacpac file, from storageaccount container, to a database in Azure.

    .PARAMETER SubscriptionId
        Your Azure SubscriptionId where your resources are located.

    .PARAMETER ResourceGroupName
        The resource group contains the Azure SQL Server and storage account where the bacpac file is loacated.

    .PARAMETER StorageAccountName
        The StorageAccount name where the bacpac file is located.

    .PARAMETER StorageAccountContainer
        The container name where the bacpac file is located.

    .PARAMETER BacpacFilename
        The name on the bacpac file.

    .PARAMETER SqlServerName
        The name on Azure SQL Server that contains the database.

    .PARAMETER SqlDatabaseName
        The name on the database that will be generated from the bacpac.

    .PARAMETER SqlDatabaseLogin
        The sa login to the Azure SQL Server.

    .PARAMETER SqlDatabasePassword
        The password for the login to the Azure SQL Server.

    .PARAMETER RunDatabaseBackup


    .PARAMETER SqlSku
        Specifies which SQL SKU you want to generate. If not specified it will create a "basic" SQL Server. Allowed SKU 'Free', 'Basic', 'S0', 'S1', 'P1', 'P2', 'GP_Gen4_1', 'GP_S_Gen5_1', 'GP_Gen5_2', 'GP_S_Gen5_2', 'BC_Gen4_1', 'BC_Gen5_4'

    .EXAMPLE
        Import-BacpacDatabase -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -BacpacFilename $BacpacFilename -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlDatabaseLogin $SqlDatabaseLogin -SqlDatabasePassword $SqlDatabasePassword -RunDatabaseBackup $RunDatabaseBackup -SqlSku $SqlSku

    .EXAMPLE
        Import-BacpacDatabase -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountContainer $StorageAccountContainer -BacpacFilename $BacpacFilename -SqlDatabaseName $SqlDatabaseName -SqlDatabaseLogin $SqlDatabaseLogin -SqlDatabasePassword $SqlDatabasePassword -RunDatabaseBackup $RunDatabaseBackup -SqlSku $SqlSku

    #>
    [cmdletbinding()]
     param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SubscriptionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $false)]
        [string] $StorageAccountName,

        [Parameter(Mandatory = $false)]
        [string] $StorageAccountContainer,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $BacpacFilename,

        [Parameter(Mandatory = $false)]
        [string] $SqlServerName,
 
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SqlDatabaseName,
 
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SqlDatabaseLogin,
 
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SqlDatabasePassword,

        [Parameter(Mandatory = $true)]
        [bool] $RunDatabaseBackup,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Free', 'Basic', 'S0', 'S1', 'P1', 'P2', 'GP_Gen4_1', 'GP_S_Gen5_1', 'GP_Gen5_2', 'GP_S_Gen5_2', 'BC_Gen4_1', 'BC_Gen5_4')]
        [string] $SqlSku = "Basic"
    )

    Connect-AzureSubscriptionAccount

    if ($null -eq $StorageAccountName -or "" -eq $StorageAccountName){
        Write-Host "StorageAccount is not set. We will try to find a storage account."
        $storageAccount = Get-DefaultStorageAccount -ResourceGroupName $ResourceGroupName
        $storageAccountName = $storageAccount.StorageAccountName
        Write-Host "Found StorageAccount '$storageAccountName'"
    } else {
        $storageAccount = Get-DefaultStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
        $storageAccountName = $storageAccount.StorageAccountName
    }
    

    if ($null -eq $StorageAccountContainer -or "" -eq $StorageAccountContainer){
        Write-Host "StorageAccount container is not set. We will try to find a container."
        $storageContainer = Get-StorageAccountContainer -StorageAccount $storageAccount -ContainerName $StorageAccountContainer
        $storageContainerName = $storageContainer.Name
        Write-Host "Found StorageAccount container '$storageContainerName'"
    } else {
        $storageContainerName = $StorageAccountContainer
    }
    
    
    if ($null -eq $SqlServerName -or "" -eq $SqlServerName) {
        $SqlServerName = Get-DefaultSqlServer -ResourceGroupName $ResourceGroupName
    }
    Write-Host "Found SqlServer '$SqlServerName'"


    $databaseExist = $false
    try {
        $databaseResult = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $SqlDatabaseName -ErrorAction SilentlyContinue
        if ($null -ne $databaseResult) {
            $databaseExist = $true
            Write-Host "Destination database $SqlDatabaseName exist. We need to drop it to continue."
        } else {
            Write-Host "Destination database $SqlDatabaseName does not exist. We will create it."
        }
    } catch {
        Write-Host "Destination database $SqlDatabaseName does not exist. We will create it."
        $error.clear()
    }

    Write-Host "Import-BacpacDatabase - Inputs:-----------------"
    Write-Host "SubscriptionId:           $SubscriptionId"
    Write-Host "ResourceGroupName:        $ResourceGroupName"
    Write-Host "StorageAccountName:       $storageAccountName"
    Write-Host "StorageAccountContainer:  $storageContainerName"
    Write-Host "BacpacFilename:           $BacpacFilename"
    Write-Host "SqlServerName:            $SqlServerName"
    Write-Host "SqlDatabaseName:          $SqlDatabaseName"
    Write-Host "SqlDatabaseLogin:         $SqlDatabaseLogin"
    Write-Host "SqlDatabasePassword:      **** (it is a secret...)"
    Write-Host "SqlSku:                   $SqlSku"
    Write-Host "------------------------------------------------"

    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
 
    if ($true -eq $databaseExist -and $true -eq $RunDatabaseBackup) {
        Backup-Database -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlDatabaseLogin $SqlDatabaseLogin -SqlDatabasePassword $SqlDatabasePassword -StorageAccountName $storageAccountName -StorageAccountContainer $StorageAccountContainer

        Unpublish-Database -ResourceGroupName $ResourceGroupName -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName
    }
    
    $importRequest = New-AzSqlDatabaseImport -ResourceGroupName $ResourceGroupName `
     -ServerName $SqlServerName `
     -DatabaseName $SqlDatabaseName `
     -DatabaseMaxSizeBytes 10GB `
     -StorageKeyType "StorageAccessKey" `
     -StorageKey $(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -StorageAccountName $storageAccountName).Value[0] `
     -StorageUri "https://$storageAccountName.blob.core.windows.net/$storageContainerName/$BacpacFilename" `
     -Edition "Standard" `
     -ServiceObjectiveName "S3" `
     -AdministratorLogin "$SqlDatabaseLogin" `
     -AdministratorLoginPassword $(ConvertTo-SecureString -String $SqlDatabasePassword -AsPlainText -Force)
 
    # Check import status and wait for the import to complete
    $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
    [Console]::Write("Importing")
    $lastStatusMessage = ""
    while ($importStatus.Status -eq "InProgress")
    {
        Start-Sleep -s 10
        $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
        if ($lastStatusMessage -ne $importStatus.StatusMessage) {
            $lastStatusMessage = $importStatus.StatusMessage
            $progress = $lastStatusMessage.Replace("Running, Progress = ", "")
            [Console]::Write($progress)
        }
        [Console]::Write(".")
    }
    [Console]::WriteLine("")
    $importStatus
    Write-Host "Database '$SqlDatabaseName' is imported."

    # Check the SKU on destination database after copy. 
    $databaseResult = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $SqlDatabaseName
    $databaseResult
 
    # Scale down to S0 after import is complete
    Set-AzSqlDatabase -ResourceGroupName $ResourceGroupName -DatabaseName $SqlDatabaseName -ServerName $SqlServerName -RequestedServiceObjectiveName $SqlSku #-Edition "Standard"
 }

 Export-ModuleMember -Function @( 'New-OptimizelyCmsResourceGroup', 'New-OptimizelyCmsResourceGroupBicep', 'Get-OptimizelyCmsConnectionStrings', 'New-EpiserverCmsResourceGroup', 'Get-EpiserverCmsConnectionStrings', 'Add-AzureDatabaseUser', 'Backup-Database', 'Copy-Database', 'Import-BacpacDatabase', 'Remove-Blobs', 'Copy-Blobs', 'New-AzureDevOpsProject', 'Send-Blob', 'Send-BlobAsConnected' )