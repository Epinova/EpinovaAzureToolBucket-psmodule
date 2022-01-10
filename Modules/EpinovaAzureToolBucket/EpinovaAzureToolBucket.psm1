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
    $sqlServer = Get-AzResource -ResourceGroupName $ResourceGroupName | Where-Object { $_.ResourceType -eq "Microsoft.Sql/servers"}
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
            Will only work if connection to Azure aleasy exist.
    
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

function Invoke-AzureDatabaseBackup{
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
        $storageAccount = Get-DefaultStorageAccount -ResourceGroupName $ResourceGroupName
        $storageAccountName = $storageAccount.StorageAccountName
    } else {
        $storageAccount = Get-DefaultStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
        $storageAccountName = $storageAccount.StorageAccountName
    }
    Write-Host "Found StorageAccount '$storageAccountName'"
    if ($null -eq $StorageAccountContainer -or "" -eq $StorageAccountContainer){
        $storageContainer = Get-StorageAccountContainer -StorageAccount $storageAccount -ContainerName $StorageAccountContainer
        $storageContainerName = $storageContainer.Name
    } else {
        $storageContainerName = $StorageAccountContainer
    }
    Write-Host "Found StorageAccount container '$storageContainerName'"
    
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
    Write-Host "--- THE END ---"
}

Export-ModuleMember -Function @( 'New-OptimizelyCmsResourceGroup', 'Get-OptimizelyCmsConnectionStrings', 'New-EpiserverCmsResourceGroup', 'Get-EpiserverCmsConnectionStrings', 'Add-AzureDatabaseUser', 'Invoke-AzureDatabaseBackup' )