# Backup-Database
Backup Azure Sql database and store BACPAC file in storage account container.

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
$ResourceGroupName = "rg-ove-1231hjkjia-dev"
$SqlServerName = "sql-ove-1231hjkjia-dev" #Optional
$SqlDatabaseName = "sqldb-ove-1231hjkjia-opticms-dev"
$SqlDatabaseLogin = "sql-ove-1231hjkjia-dev-sa"
$SqlDatabasePassword = "kGxxXXXxxXzZcrw9qVXxxXxxxXXcpzX"
$StorageAccountName = "" #Optional
$StorageAccountContainer = "db-backups" #Optional

Backup-Database -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlDatabaseLogin $SqlDatabaseLogin -SqlDatabasePassword $SqlDatabasePassword -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer
```

[<< Back](/README.md)