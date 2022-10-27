# Import-BacpacDatabase
Import a bacpac file, from storageaccount container, to a database in Azure.  

## Prerequisite
### Nedded Azure services
Service which is mandatory is Azure Storage Account and Azure SQL Server, on which bacpac files will be imported to.  
### PowerShellGet
Since PowerShell Gallery is involved, you need to have PowerShellGet installed. Instructions how to install PowerShellGet (https://docs.microsoft.com/en-us/powershell/scripting/gallery/installing-psget?view=powershell-7.1).
### Blob container
A blob container with the name that you specified in the StorageAccount where the blob will be stored.
### Access rights in Azure
Account/Service Prinicipal under which script will work should have proper permission (Contributor) assigned to storage account.

## Instructions
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
$StorageAccountName = "stove1231hjkjiadev"
$StorageAccountContainer = "db-backups"
$BacpacFilename = "C:\dev\temp\_blobDownloads\epicms_Integration_20221027082506.bacpac"
$SqlServerName = "your-sql-server"
$SqlDatabaseName = "your-sql-databasename"
$SqlDatabaseLogin = "sa"
$SqlDatabasePassword = "l#tm#inmyd@tabaseplease!"
$RunDatabaseBackup = $true
$SqlSku = "Basic"

Import-BacpacDatabase -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -BacpacFilename $BacpacFilename -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlDatabaseLogin $SqlDatabaseLogin -SqlDatabasePassword $Password -RunDatabaseBackup $RunDatabaseBackup -SqlSku $SqlSku
```


[<< Back](/README.md)