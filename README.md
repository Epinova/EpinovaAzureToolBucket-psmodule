# EpinovaAzureToolBucket-psmodule
Powershell module contain functions for createing Optimizely (aka Episerver) CMS in Azure.  
Note: This is a very early stage and has only been tested on Epinovas Azure portal. So there can be exceptions in your environment which we have not taken into account. Just so you know!  

[How to create resource groups example](Documentation/CreateResourceGroup/CreateResourceGroup.md)

## New-OptimizelyCmsResourceGroup
Create a Optimizely CMS resource group in Azure.  
[Documentation](Documentation/New-OptimizelyCmsResourceGroup/New-OptimizelyCmsResourceGroup.md)


## Get-OptimizelyCmsConnectionStrings
Get and print the connection strings for specified resource group.  
[Documentation](Documentation/Get-OptimizelyCmsConnectionStrings/Get-OptimizelyCmsConnectionStrings.md)

## Add-AzureDatabaseUser
Create a database user for a specific database on a Azure SQL Server instance.  
[Documentation](Documentation/Add-AzureDatabaseUser/Add-AzureDatabaseUser.md)

## Backup-Database
Backup/Export a database and store BACPAC in storage account container.  
[Documentation](Documentation/Backup-Database/Backup-Database.md)

## Invoke-AzureDatabaseCopy
Copy a database from one place to another. If the destination database exist it will be 'overwritten'. You can decide if you want to make a backup of the destination database before it is dropped.  
[Documentation](Documentation/Invoke-AzureDatabaseCopy/Invoke-AzureDatabaseCopy.md)

## Remove-Blobs
Remove all blobs from a StorageAccount container.  
[Documentation](Documentation/Remove-Blobs/Remove-Blobs.md)

## Copy-Blobs
Copy all blobs from a StorageAccount container to another.  
[Documentation](Documentation/Copy-Blobs/Copy-Blobs.md)

## Old
## New-EpiserverCmsResourceGroup
Create a Episerver CMS resource group in Azure.  
[Documentation](Documentation/New-EpiserverCmsResourceGroup/New-EpiserverCmsResourceGroup.md)
  
## Get-EpiserverCmsConnectionStrings
Get and print the connection strings for specified resource group.  
[Documentation](Documentation/Get-EpiserverCmsConnectionStrings/Get-EpiserverCmsConnectionStrings.md)
