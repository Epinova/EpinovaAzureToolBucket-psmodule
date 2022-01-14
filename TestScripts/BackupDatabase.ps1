Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

$SubscriptionId = "x802f980-979x-1111-axx7-3bbxxfcb7x99"
$ResourceGroupName = "rg-sprit-1231hjkjia-inte"
$SqlServerName = "sql-sprit-1231hjkjia-inte" #Optional
$SqlDatabaseName = "sqldb-sprit-1231hjkjia-opticms-inte"
$SqlDatabaseLogin = "sql-sprit-1231hjkjia-inte-sa"
$SqlDatabasePassword = "!v#N9njeMFW7N^XK"
$StorageAccountName = "" #Optional
$StorageAccountContainer = "db-backups" #Optional

. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_BackupDatabase.ps1

Backup-Database -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlDatabaseLogin $SqlDatabaseLogin -SqlDatabasePassword $SqlDatabasePassword -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer
