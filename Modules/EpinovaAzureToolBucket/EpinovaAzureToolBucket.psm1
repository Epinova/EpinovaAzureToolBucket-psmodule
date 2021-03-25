<#


.DESCRIPTION
    Help functions for Epinova DXP vs Azure Portal.
#>

Set-StrictMode -Version Latest

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
        Write-Host "Your new user has been created and can connect to the target database."
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

Export-ModuleMember -Function @( 'New-EpiserverCmsResourceGroup', 'Get-EpiserverCmsConnectionStrings', 'Add-AzureDatabaseUser' )