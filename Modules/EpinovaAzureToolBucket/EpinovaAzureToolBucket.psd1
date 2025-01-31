@{
    RootModule        = 'EpinovaAzureToolBucket.psm1'
    ModuleVersion     = '0.17.0'
    GUID              = 'ebd0d848-0687-4de0-8538-c8bccc3b22ae'
    Author            = 'Ove Lartelius'
    CompanyName       = 'Epinova AB'
    Copyright         = '(c) 2021 Epinova AB. All rights reserved.'
    Description       = 'Module contain help functions for the Azure Portal.'
    PowerShellVersion = '5.1'
    FunctionsToExport = 'New-ResourceGroupTagsFromExisting', 'New-OptimizelyCmsResourceGroup', 'New-OptimizelyCmsResourceGroupBicep', 'Get-OptimizelyCmsConnectionStrings', 'New-EpiserverCmsResourceGroup', 'Get-EpiserverCmsConnectionStrings', 'Add-AzureDatabaseUser', 'Backup-Database', 'Copy-Database', 'Copy-DatabaseBetweenSubscriptions', 'Import-BacpacDatabase', "Remove-Blobs", "Copy-Blobs", "Copy-BlobsWithSas", "New-AzureDevOpsProject", "Send-Blob", "Send-BlobAsConnected"
    CmdletsToExport   = @()
    AliasesToExport   = @()
}