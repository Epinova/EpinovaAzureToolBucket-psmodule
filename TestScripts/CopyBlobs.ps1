Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

$SubscriptionId = "e872f180-979f-4374-aff7-3bbcffcb7f89"
$SourceResourceGroupName = "bwoffshoreintra"
$SourceStorageAccountName = "bwoffshoreintra"
$SourceContainerName = "mysitemedia"

$DestinationResourceGroupName = "bwoffshore"
$DestinationStorageAccountName = "bwoffshore"
$DestinationContainerName = "mysitemedia-intra"

Copy-Blobs -SubscriptionId $SubscriptionId -SourceResourceGroupName $SourceResourceGroupName -SourceStorageAccountName $SourceStorageAccountName -SourceContainerName $SourceContainerName -DestinationResourceGroupName $DestinationResourceGroupName -DestinationStorageAccountName $DestinationStorageAccountName -DestinationContainerName $DestinationContainerName 


# Connect-AzAccount -SubscriptionId $SubscriptionId

# $sourceStorageAccount = Get-AzStorageAccount -ResourceGroupName $sourceResourceGroup -Name $sourceStorageAccountName 
# $sourceContext = $sourceStorageAccount.Context 

# $destinationStorageAccount = Get-AzStorageAccount -ResourceGroupName $destinationResourceGroup -Name $destinationStorageAccountName 
# $destinationContext = $destinationStorageAccount.Context 

# Get-AzStorageBlob -Container $sourceContainerName -Context $sourceContext | Start-AzStorageBlobCopy -DestContainer $destinationContainerName  -Context $destinationContext
