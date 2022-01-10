Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

$SubscriptionId = "e872f180-979f-4374-aff7-3bbcffcb7f89"
$ResourceGroupName = "bwoffshore"
$SqlServerName = "bwoffshore-sqlserver" #Optional
$SqlDatabaseName = "dbBwoIntra_Copy"
$SqlDatabaseLogin = "epinova-sa"
$SqlDatabasePassword = "kGjQ6Y2ylOnVBzZcrw9qVRbKtvkcpzX"
$StorageAccountName = "" #Optional
$StorageAccountContainer = "db-backups" #Optional

Backup-Database -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlDatabaseLogin $SqlDatabaseLogin -SqlDatabasePassword $SqlDatabasePassword -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer
