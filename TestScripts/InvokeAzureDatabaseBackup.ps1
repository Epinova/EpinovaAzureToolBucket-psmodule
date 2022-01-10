Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

#$azureConnection = $null

# function Get-DefaultSqlServer{
#     <#
#         .SYNOPSIS
#             List all resources for a resource group and grab the first SqlServer it can find.
    
#         .DESCRIPTION
#             List all resources for a resource group and grab the first SqlServer it can find.  
#             Will only work if connection to Azure aleasy exist.
    
#         .PARAMETER ResourceGroupName
#             The resource group where we will look for the SqlServer.
    
#         .EXAMPLE
#             Get-DefaultSqlServer -ResourceGroupName $ResourceGroupName
    
#         #>
#         param(
#             [Parameter(Mandatory)]
#             [string]$ResourceGroupName
#         )
#         $sqlServer = Get-AzResource -ResourceGroupName $ResourceGroupName | Where-Object { $_.ResourceType -eq "Microsoft.Sql/servers"}
#         if ($null -eq $sqlServer) {
#             Write-Warning "Could not find default SqlServer in ResourceGroup: $ResourceGroupName."
#             exit
#         }
#         return $sqlServer
#     }
    
#     function Get-DefaultStorageAccount{
#         <#
#             .SYNOPSIS
#                 List all resources for a resource group and grab the first StorageAccount it can find.
        
#             .DESCRIPTION
#                 List all resources for a resource group and grab the first StorageAccount it can find.  
#                 Will only work if connection to Azure aleasy exist.
        
#             .PARAMETER ResourceGroupName
#                 The resource group where we will look for the StorageAccount.
        
#             .EXAMPLE
#                 Get-DefaultStorageAccount -ResourceGroupName $ResourceGroupName
        
#             #>
#             param(
#                 [Parameter(Mandatory)]
#                 [string]$ResourceGroupName
#             )
#             $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName
#             #$storageAccount #For debuging
#             if ($storageAccount.Count -ne 1) {
#                 if ($storageAccount.Count -gt 1) {
#                     Write-Warning "Found more then 1 StorageAccount in destination ResourceGroup: $ResourceGroupName."
#                 }
#                 if ($storageAccount.Count -eq 0) {
#                     Write-Warning "Could not find a StorageAccount in destination ResourceGroup: $ResourceGroupName."
#                 }
#                 exit
#             }
#             return $storageAccount
#     }

#     function Get-StorageAccountContainer{
#         <#
#             .SYNOPSIS
#                 Get the container for the specified StorageAccount.
        
#             .DESCRIPTION
#                 Get the container for the specified StorageAccount.  
#                 Will only work if connection to Azure aleasy exist.
    
#             .PARAMETER StorageAccount
#                 The StorageAccount where the container should exist.
    
#             .PARAMETER ContainerName
#                 The container name.
        
#             .EXAMPLE
#                 Get-StorageAccountContainer -StorageAccount $StorageAccount -ContainerName $ContainerName
    
#             .EXAMPLE
#                 $storageAccount = Get-DefaultStorageAccount ResourceGroupName $ResourceGroupName
#                 Get-StorageAccountContainer -StorageAccount $storageAccount -ContainerName $ContainerName
    
#             #>
#             param(
#                 [Parameter(Mandatory)]
#                 [object]$StorageAccount,
#                 [Parameter(Mandatory)]
#                 [string]$ContainerName
#             )
#             $storageContainer = Get-AzRmStorageContainer -StorageAccount $StorageAccount -ContainerName $ContainerName
#             #$storageContainer
#             if ($null -eq $storageContainer) {
#                 Write-Warning "Could not find a StorageAccount container '$($storageContainer.Name)' in ResourceGroup: $($StorageAccount.ResourceGroupName))."
#                 exit
#             } else {
#                 Write-Host "Connected to destination StorageAccount container $($storageContainer.Name)"
#             }
    
#             return $storageContainer
#     }
    
#     function Connect-AzureSubscriptionAccount{
#         if($null -eq $azureConnection.Account){
#             try{
#                 $azureConnection = Connect-AzAccount -SubscriptionId $SubscriptionId
#                 Write-Host "Connected to subscription $SubscriptionId"
#             }
#             catch {
#                 $message = $_.Exception.message
#                 Write-Host $message
#                 exit
#             }
#         }
#     }
    
# $sqlServer = "project1-dev.database.windows.net"
# $sqlServerUsername = "project1-sa"
# $sqlServerPassword = "@wes0mep@ssw0rd"
# $targetDatabase = "project1-cms-dev"
# $newUsername = "project1dbuser"
# $newPassword = "mynew@wes0mep@ssw0rd"
# $newUserPermission = "db_owner"
# Add-AzureDatabaseUser -SqlServer $sqlServer -SqlServerUsername $sqlServerUsername -SqlServerPassword $sqlServerPassword -TargetDatabase $targetDatabase -NewUsername $newUsername -NewPassword $newPassword  -NewUserPermission $newUserPermission
$SubscriptionId = "e872f180-979f-4374-aff7-3bbcffcb7f89"
$ResourceGroupName = "bwoffshore"
$SqlServerName = "bwoffshore-sqlserver" #Optional
$SqlDatabaseName = "dbBwoIntra_Copy"
$SqlDatabaseLogin = "epinova-sa"
$SqlDatabasePassword = "kGjQ6Y2ylOnVBzZcrw9qVRbKtvkcpzX"
$StorageAccountName = "" #Optional
$StorageAccountContainer = "db-backups" #Optional

Invoke-AzureDatabaseBackup -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlDatabaseLogin $SqlDatabaseLogin -SqlDatabasePassword $SqlDatabasePassword -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer

# Connect-AzureSubscriptionAccount

# if ($null -eq $StorageAccountName -or "" -eq $StorageAccountName){
#     $storageAccount = Get-DefaultStorageAccount -ResourceGroupName $ResourceGroupName
#     $storageAccountName = $storageAccount.StorageAccountName
# } else {
#     $storageAccountName = $StorageAccountName
# }
# Write-Host "Found StorageAccount '$storageAccountName'"
# if ($null -eq $StorageAccountContainer -or "" -eq $StorageAccountContainer){
#     $storageContainer = Get-StorageAccountContainer -StorageAccount $storageAccount -ContainerName $StorageAccountContainer
#     $storageContainerName = $storageContainer.Name
# } else {
#     $storageContainerName = $StorageAccountContainer
# }
# Write-Host "Found StorageAccount container '$storageContainerName'"

# if ($null -eq $SqlServerName -or "" -eq $SqlServerName) {
#     $SqlServerName = Get-DefaultSqlServer -ResourceGroupName $ResourceGroupName
# }
# Write-Host "Found SqlServer '$SqlServerName'"

# # Fix some information about the destination storage account
# $bacpacFilename = $SqlDatabaseName + "_" + (Get-Date).ToString("yyyy-MM-dd-HH-mm") + ".bacpac"
# $storageKeyType = "StorageAccessKey"
# $storageKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $storageAccountName)| Where-Object {$_.KeyName -eq "key2"}
# $baseStorageUri = "https://" + $storageAccountName + ".blob.core.windows.net"
# $bacpacUri = $baseStorageUri + "/" + $storageContainerName + "/" + $bacpacFilename

# Write-Host "Invoke-AzureDatabaseBackup - Inputs:----------"
# Write-Host "SubscriptionId:            $SubscriptionId"
# Write-Host "ResourceGroupName:         $ResourceGroupName"
# Write-Host "SqlServerName:             $SqlServerName"
# Write-Host "SqlDatabaseName:           $SqlDatabaseName"
# Write-Host "ResourceGroupName:         $ResourceGroupName"
# Write-Host "SqlDatabaseLogin:          $SqlDatabaseLogin"
# Write-Host "SqlDatabasePassword:       **** (it is a secret...)"
# Write-Host "ResourceGroupLocation:     $ResourceGroupLocation"
# Write-Host "StorageAccountName:        $storageAccountName"
# Write-Host "StorageAccountContainer:   $storageContainerName"
# Write-Host "StorageKey:                $($storageKey.Value))"
# Write-Host "Bacpac file:               $bacpacFilename"
# Write-Host "Bacpac URI:                $bacpacUri"
# Write-Host "------------------------------------------------"



# # Do a database backup of the destination database.
# $exportRequest = New-AzSqlDatabaseExport -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $SqlDatabaseName -StorageKeyType $storageKeyType -StorageKey $storageKey.Value -StorageUri $bacpacUri -AdministratorLogin $sqlCredentials.UserName -AdministratorLoginPassword $sqlCredentials.Password
# if ($null -ne $exportRequest) {
#     $operationStatusLink = $exportRequest.OperationStatusLink
#     $operationStatusLink
#     $exportStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $operationStatusLink
#     [Console]::Write("Exporting.")
#     $lastStatusMessage = ""
#     while ($exportStatus.Status -eq "InProgress")
#     {
#         Start-Sleep -s 10
#         $exportStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $operationStatusLink
#         if ($lastStatusMessage -ne $exportStatus.StatusMessage) {
#             $lastStatusMessage = $exportStatus.StatusMessage
#             $progress = $lastStatusMessage.Replace("Running, Progress = ", "")
#             [Console]::Write($progress)
#         }
#         [Console]::Write(".")
#     }
#     [Console]::WriteLine("")
#     $exportStatus
#     Write-Host "Database '$SqlDatabaseName' is backed up. '$bacpacUri'"
# } else {
#     Write-Error "Could not start backup of $SqlDatabaseName"
#     exit
# }
# Write-Host "--- THE END ---"
