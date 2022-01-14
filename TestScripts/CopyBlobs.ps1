Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

$SubscriptionId = "x802f980-979x-1111-axx7-3bbxxfcb7x99"
$SourceResourceGroupName = "rg-sprit-1231hjkjia-prod"
$SourceStorageAccountName = "stsprit1231hjkjiaprod"
$SourceContainerName = "sitemedia"

$DestinationResourceGroupName = "rg-sprit-1231hjkjia-inte"
$DestinationStorageAccountName = "stsprit1231hjkjiainte"
$DestinationContainerName = "sitemedia"

# Override with real settings
. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_CopyBlobs.ps1

Copy-Blobs -SubscriptionId $SubscriptionId -SourceResourceGroupName $SourceResourceGroupName -SourceStorageAccountName $SourceStorageAccountName -SourceContainerName $SourceContainerName -DestinationResourceGroupName $DestinationResourceGroupName -DestinationStorageAccountName $DestinationStorageAccountName -DestinationContainerName $DestinationContainerName 


# Connect-AzAccount -SubscriptionId $SubscriptionId

# $sourceStorageAccount = Get-AzStorageAccount -ResourceGroupName $sourceResourceGroup -Name $sourceStorageAccountName 
# $sourceContext = $sourceStorageAccount.Context 

# $destinationStorageAccount = Get-AzStorageAccount -ResourceGroupName $destinationResourceGroup -Name $destinationStorageAccountName 
# $destinationContext = $destinationStorageAccount.Context 

# Get-AzStorageBlob -Container $sourceContainerName -Context $sourceContext | Start-AzStorageBlobCopy -DestContainer $destinationContainerName  -Context $destinationContext
