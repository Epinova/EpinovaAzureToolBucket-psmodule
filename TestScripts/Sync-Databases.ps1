Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
#Import-Module -Name C:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

$SourceSubscriptionId = "x802f980-979x-1111-axx7-3bbxxfcb7x99"
$SourceResourceGroupName = "rg-sprit-1231hjkjia-prod"
$SourceSqlServerName = "sql-sprit-1231hjkjia-prod"
$SourceSqlDatabaseName = "sqldb-sprit-1231hjkjia-opticms-prod"
$SourceSqlDatabaseLogin = "sql-sprit-1231hjkjia-inte-sa"
$SourceSqlDatabasePassword = "!v#N9njeMFW7N^XK"
$SourceStorageAccount = ""
$SourceStorageAccountContainer = "db-backups"


$DestinationResourceGroupName = "rg-sprit-1231hjkjia-inte"
$DestinationSqlServerName = "sql-sprit-1231hjkjia-inte"
$DestinationSqlDatabaseName = "sqldb-sprit-1231hjkjia-opticms-inte"
$DestinationRunDatabaseBackup = $true
$DestinationSqlDatabaseLogin = "sql-sprit-1231hjkjia-inte-sa"
$DestinationSqlDatabasePassword = "!v#N9njeMFW7N^XK"
$DestinationStorageAccount = ""
$DestinationStorageAccountContainer = "db-backups"
$SqlSku = "Basic"

. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_SyncDatabases.ps1

    #Connect-AzureSubscriptionAccount
    # TEMP code START----------------------------------------------------------------------
    $azureConnection = $null
    if($null -eq $azureConnection -or $null -eq $azureConnection.Account){
        try{
            $azureConnection = Connect-AzAccount -SubscriptionId $SourceSubscriptionId
            Write-Host "Connected to subscription $SourceSubscriptionId"
        }
        catch {
            $message = $_.Exception.message
            Write-Error $message
            exit
        }
    }
    $azureConnection
    # TEMP code END----------------------------------------------------------------------

    #if ($null -eq $SourceSqlServerName -or "" -eq $SourceSqlServerName) {
    #     $SourceSqlServerName = Get-DefaultSqlServer -ResourceGroupName $SourceResourceGroupName
    #}
    #Write-Host "Found source SqlServer '$SourceSqlServerName'"

    # if ($null -eq $DestinationSqlServerName -or "" -eq $DestinationSqlServerName) {
    #     $DestinationSqlServerName = Get-DefaultSqlServer -ResourceGroupName $DestinationSqlServerName
    # }
    # Write-Host "Found destination SqlServer '$DestinationSqlServerName'"

    # $destinationDatabaseExist = $false
    # try {
    #     $destinationDatabaseResult = Get-AzSqlDatabase -ResourceGroupName $DestinationResourceGroupName -ServerName $DestinationSqlServerName -DatabaseName $DestinationSqlDatabaseName -ErrorAction SilentlyContinue
    #     if ($null -ne $destinationDatabaseResult) {
    #         $destinationDatabaseExist = $true
    #         Write-Host "Destination database $DestinationSqlDatabaseName exist."
    #     } else {
    #         Write-Host "Destination database $DestinationSqlDatabaseName does not exist."
    #     }
    # } catch {
    #     Write-Host "Destination database $DestinationSqlDatabaseName does not exist."
    #     $error.clear()
    # }

    # Write-Host "Invoke-AzureDatabaseCopy - Inputs:----------"
    # Write-Host "SubscriptionId:                     $SubscriptionId"
    # Write-Host "SourceResourceGroupName:            $SourceResourceGroupName"
    # Write-Host "SourceSqlServerName:                $SourceSqlServerName"
    # Write-Host "SourceSqlDatabaseName:              $SourceSqlDatabaseName"
    # Write-Host "DestinationResourceGroupName:       $DestinationResourceGroupName"
    # Write-Host "DestinationSqlServerName:           $DestinationSqlServerName"
    # Write-Host "DestinationSqlDatabaseName:         $DestinationSqlDatabaseName"
    # Write-Host "DestinationRunDatabaseBackup:       $DestinationRunDatabaseBackup"
    # Write-Host "DestinationSqlDatabaseLogin:        $DestinationSqlDatabaseLogin"
    # Write-Host "DestinationSqlDatabasePassword:     **** (it is a secret...)"
    # Write-Host "DestinationDatabaseExist:           $destinationDatabaseExist"
    # Write-Host "DestinationStorageAccount:          $DestinationStorageAccount"
    # Write-Host "DestinationStorageAccountContainer: $DestinationStorageAccountContainer"
    # Write-Host "SqlSku:                             $SqlSku"
    # Write-Host "------------------------------------------------"

    # if ($true -eq $destinationDatabaseExist -and $true -eq $DestinationRunDatabaseBackup) {
    #     $missingParam = $false
    #     if($null -eq $DestinationSqlDatabaseLogin -or "" -eq $DestinationSqlDatabaseLogin) {
    #         Write-Warning "You want to make a destination database backup and missing the -DestinationSqlDatabaseLogin param."
    #         $missingParam = $true
    #     }
    #     if($null -eq $DestinationSqlDatabasePassword -or "" -eq $DestinationSqlDatabasePassword) {
    #         Write-Warning "You want to make a destination database backup and missing the DestinationSqlDatabasePassword param."
    #         $missingParam = $true
    #     }

    #     if ($true -eq $missingParam) {
    #         Write-Error "Parameters is missing."
    #         exit
    #     }

    #     Backup-Database -SubscriptionId $SubscriptionId -ResourceGroupName $DestinationResourceGroupName -SqlServerName $DestinationSqlServerName -SqlDatabaseName $DestinationSqlDatabaseName -SqlDatabaseLogin $DestinationSqlDatabaseLogin -SqlDatabasePassword $DestinationSqlDatabasePassword -StorageAccountName $DestinationStorageAccount -StorageAccountContainer $DestinationStorageAccountContainer
    # }

    # # Drop destination database if exist
    # if ($true -eq $destinationDatabaseExist) {
    #     Unpublish-Database -ResourceGroupName $DestinationResourceGroupName -SqlServerName $DestinationSqlServerName -SqlDatabaseName $DestinationSqlDatabaseName
    # }

    # # Copy the source database to destination database
    # Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
    # Write-Host "Start copying database '$SourceSqlDatabaseName' to '$DestinationSqlDatabaseName'."
    # $databaseCopy = New-AzSqlDatabaseCopy -ResourceGroupName $SourceResourceGroupName -ServerName $SourceSqlServerName -DatabaseName $SourceSqlDatabaseName -CopyResourceGroupName $DestinationResourceGroupName -CopyServerName $DestinationSqlServerName -CopyDatabaseName $DestinationSqlDatabaseName
    # $databaseCopy

    # Write-Host "--------------------------------------------------------------"

    # # Check the SKU on destination database after copy. 
    # $destinationDatabaseResult = Get-AzSqlDatabase -ResourceGroupName $DestinationResourceGroupName -ServerName $DestinationSqlServerName -DatabaseName $DestinationSqlDatabaseName
    # $destinationDatabaseResult

    # Write-Host "--------------------------------------------------------------"
    
    # if ($false -eq [string]::IsNullOrEmpty($SqlSku)) {
    #     Set-AzSqlDatabase -ResourceGroupName $DestinationResourceGroupName -DatabaseName $DestinationSqlDatabaseName -ServerName $DestinationSqlServerName -RequestedServiceObjectiveName $SqlSku #-Edition "Standard"
    # }
    # Write-Host "--------------------------------------------------------------"

    # # Check the SKU on destination database after copy. 
    # $destinationDatabaseResult = Get-AzSqlDatabase -ResourceGroupName $DestinationResourceGroupName -ServerName $DestinationSqlServerName -DatabaseName $DestinationSqlDatabaseName
    # $destinationDatabaseResult
