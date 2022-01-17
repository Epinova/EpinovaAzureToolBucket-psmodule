Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

# $SubscriptionId = "e872f180-979f-4374-aff7-3bbcffcb7f89"
# $SourceResourceGroupName = "bwoffshoreintra"
# $SourceSqlServerName = "bwoffshoreintra-sqlserver"
# $SourceSqlDatabaseName = "dbBwoIntra"
# $DestinationResourceGroupName = "bwoffshore"
# $DestinationSqlServerName = "bwoffshore-sqlserver"
# $DestinationSqlDatabaseName = "dbBwoIntra_Copy"
# $DestinationRunDatabaseBackup = $false

# Copy-Database -SubscriptionId $SubscriptionId -SourceResourceGroupName $SourceResourceGroupName -SourceSqlServerName $SourceSqlServerName -SourceSqlDatabaseName $SourceSqlDatabaseName -DestinationResourceGroupName $DestinationResourceGroupName -DestinationSqlServerName $DestinationSqlServerName -DestinationSqlDatabaseName $DestinationSqlDatabaseName -DestinationRunDatabaseBackup $DestinationRunDatabaseBackup 


$SubscriptionId = "x802f980-979x-1111-axx7-3bbxxfcb7x99"
$SourceResourceGroupName = "rg-sprit-1231hjkjia-prod"
$SourceSqlServerName = "sql-sprit-1231hjkjia-prod"
$SourceSqlDatabaseName = "sqldb-sprit-1231hjkjia-opticms-prod"
$DestinationResourceGroupName = "rg-sprit-1231hjkjia-inte"
$DestinationSqlServerName = "sql-sprit-1231hjkjia-inte"
$DestinationSqlDatabaseName = "sqldb-sprit-1231hjkjia-opticms-inte"
$DestinationRunDatabaseBackup = $true
$DestinationSqlDatabaseLogin = "sql-sprit-1231hjkjia-inte-sa"
$DestinationSqlDatabasePassword = "!v#N9njeMFW7N^XK"
$DestinationStorageAccount = ""
$DestinationStorageAccountContainer = "db-backups"

. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_CopyDatabase.ps1

Copy-Database -SubscriptionId $SubscriptionId -SourceResourceGroupName $SourceResourceGroupName -SourceSqlServerName $SourceSqlServerName -SourceSqlDatabaseName $SourceSqlDatabaseName -DestinationResourceGroupName $DestinationResourceGroupName -DestinationSqlServerName $DestinationSqlServerName -DestinationSqlDatabaseName $DestinationSqlDatabaseName -DestinationRunDatabaseBackup $DestinationRunDatabaseBackup -DestinationSqlDatabaseLogin $DestinationSqlDatabaseLogin -DestinationSqlDatabasePassword $DestinationSqlDatabasePassword -DestinationStorageAccount $DestinationStorageAccount -DestinationStorageAccountContainer $DestinationStorageAccountContainer 

