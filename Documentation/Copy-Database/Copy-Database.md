# Copy-Database
Copy a database from one place to another. If the destination database exist it will be 'overwritten'. You can decide if you want to make a backup of the destination database before it is dropped.  

## Prerequisite
### Nedded Azure services
The only service which is mandatory (besides two Azure SQL Servers) is Azure Storage Account, on which bacpac files will be stored. It's up to you how you will configure this storage, as there aren't any specific requirement.  
### PowerShellGet
Since PowerShell Gallery is involved, you need to have PowerShellGet installed. Instructions how to install PowerShellGet (https://docs.microsoft.com/en-us/powershell/scripting/gallery/installing-psget?view=powershell-7.1).
### Sql server firewall rules
You need to open the firewall so that the script has access to communicate with the Sql Server.
### Blob container
A blob container with the name 'db-backups' in the StorageAccount where the BACPAC file will be stored.
### Access rights in Azure
Account/Service Prinicipal under which script will work should have proper permission (Contributor) assigned to storage account.

## Create Azure database user login
1.	First open up PowerShell prompt as an administrator.
2.	Start type 
```powershell
Set-ExecutionPolicy -Scope CurrentUser Unrestricted
```
This is to remove warnings if your environment does not trust these scripts.  
3.	Then install the EpinovaAzureToolBucket. 
```powershell
Install-Module EpinovaAzureToolBucket -Scope CurrentUser -Force
```  
4.	Add the code below and make the changes needed to fit your context.
```powershell
$SubscriptionId = "e8xxx180-9xxf-4xx4-axx7-3xxxffxx7fxx"
$SourceResourceGroupName = "rg-ove-1231hjkjia-dev"
$SourceSqlServerName = "sql-ove-1231hjkjia-dev"
$SourceSqlDatabaseName = "sqldb-ove-1231hjkjia-opticms-dev"
$DestinationResourceGroupName = "rg-ove-1231hjkjia-prep"
$DestinationSqlServerName = "sql-ove-1231hjkjia-prep"
$DestinationSqlDatabaseName = "sqldb-ove-1231hjkjia-opticms-prep"
$DestinationRunDatabaseBackup = $true
$DestinationSqlDatabaseLogin = "sql-ove-1231hjkjia-dev-sa"
$DestinationSqlDatabasePassword = "kGxxXXXxxXzZcrw9qVXxxXxxxXXcpzX"
$DestinationStorageAccount = ""
$DestinationStorageAccountContainer = "db-backups"

Copy-Database -SubscriptionId $SubscriptionId -SourceResourceGroupName $SourceResourceGroupName -SourceSqlServerName $SourceSqlServerName 
    -SourceSqlDatabaseName $SourceSqlDatabaseName -DestinationResourceGroupName $DestinationResourceGroupName -DestinationSqlServerName $DestinationSqlServerName 
    -DestinationSqlDatabaseName $DestinationSqlDatabaseName -DestinationRunDatabaseBackup $DestinationRunDatabaseBackup 
    -DestinationSqlDatabaseLogin $DestinationSqlDatabaseLogin -DestinationSqlDatabasePassword $DestinationSqlDatabasePassword 
    -DestinationStorageAccount $DestinationStorageAccount -DestinationStorageAccountContainer $DestinationStorageAccountContainer 
```

[<< Back](/README.md)