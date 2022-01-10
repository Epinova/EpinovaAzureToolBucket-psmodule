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

# Invoke-AzureDatabaseCopy -SubscriptionId $SubscriptionId -SourceResourceGroupName $SourceResourceGroupName -SourceSqlServerName $SourceSqlServerName -SourceSqlDatabaseName $SourceSqlDatabaseName -DestinationResourceGroupName $DestinationResourceGroupName -DestinationSqlServerName $DestinationSqlServerName -DestinationSqlDatabaseName $DestinationSqlDatabaseName -DestinationRunDatabaseBackup $DestinationRunDatabaseBackup 


$SubscriptionId = "e872f180-979f-4374-aff7-3bbcffcb7f89"
$SourceResourceGroupName = "bwoffshoreintra"
$SourceSqlServerName = "bwoffshoreintra-sqlserver"
$SourceSqlDatabaseName = "dbBwoIntra"
$DestinationResourceGroupName = "bwoffshore"
$DestinationSqlServerName = "bwoffshore-sqlserver"
$DestinationSqlDatabaseName = "dbBwoIntra_Copy"
$DestinationRunDatabaseBackup = $true
$DestinationSqlDatabaseLogin = "epinova-sa"
$DestinationSqlDatabasePassword = "kGjQ6Y2ylOnVBzZcrw9qVRbKtvkcpzX"
$DestinationStorageAccount = ""
$DestinationStorageAccountContainer = "db-backups"

Invoke-AzureDatabaseCopy -SubscriptionId $SubscriptionId -SourceResourceGroupName $SourceResourceGroupName -SourceSqlServerName $SourceSqlServerName -SourceSqlDatabaseName $SourceSqlDatabaseName -DestinationResourceGroupName $DestinationResourceGroupName -DestinationSqlServerName $DestinationSqlServerName -DestinationSqlDatabaseName $DestinationSqlDatabaseName -DestinationRunDatabaseBackup $DestinationRunDatabaseBackup -DestinationSqlDatabaseLogin $DestinationSqlDatabaseLogin -DestinationSqlDatabasePassword $DestinationSqlDatabasePassword -DestinationStorageAccount $DestinationStorageAccount -DestinationStorageAccountContainer $DestinationStorageAccountContainer 

