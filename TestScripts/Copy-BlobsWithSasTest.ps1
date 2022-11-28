Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

#$SourceSasLink = "https://bofl01mstr5pe8minte.blob.core.windows.net/mysitemedia?sv=2018-03-28&sr=c&sig=1kafFnmaf0brWZtTAy03LPT%2Bn177Tgfdit4h5x6u0XA%3D&st=2022-11-27T19%3A09%3A14Z&se=2022-11-27T21%3A09%3A14Z&sp=rl"
#$SourceContainerName = "mysitemedia"

$SourceSasLink = "https://bofl01mstr5pe8m.blob.core.windows.net/bacpacs/epicms_Integration_20221128191021.bacpac?sv=2018-03-28&sr=b&sig=Ql8nDVGTqYAv7U2LbY%2F3brUUvWbDBaYkVHjVTZp4uNc%3D&st=2022-11-28T19%3A14%3A26Z&se=2022-11-29T19%3A14%3A26Z&sp=r"
$SourceContainerName = "bacpacs"


$DestinationSubscriptionId = "x802f980-979x-1111-axx7-3bbxxfcb7x99"
$DestinationResourceGroupName = "rg-sprit-1231hjkjia-inte"
$DestinationStorageAccountName = "stsprit1231hjkjiainte"
$DestinationContainerName = "sitemedia"

# Override with real settings
. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_Copy-BlobsWithSas.ps1

#Copy-BlobsWithSas -SourceSasLink $SourceSasLink -SourceContainerName $SourceContainerName -DestinationSubscriptionId $DestinationSubscriptionId -DestinationResourceGroupName $DestinationResourceGroupName -DestinationStorageAccountName $DestinationStorageAccountName -DestinationContainerName $DestinationContainerName 
#Copy-BlobsWithSas -SourceSasLink $SourceSasLink -SourceContainerName $SourceContainerName -DestinationSubscriptionId $DestinationSubscriptionId -DestinationResourceGroupName $DestinationResourceGroupName -DestinationStorageAccountName $DestinationStorageAccountName -DestinationContainerName $DestinationContainerName -CleanBeforeCopy $true
Copy-BlobsWithSas -SourceSasLink $SourceSasLink -DestinationSubscriptionId $DestinationSubscriptionId -DestinationResourceGroupName $DestinationResourceGroupName -DestinationStorageAccountName $DestinationStorageAccountName -DestinationContainerName $DestinationContainerName -CleanBeforeCopy $true