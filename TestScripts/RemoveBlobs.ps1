Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

$SubscriptionId = "e872f180-979f-4374-aff7-3bbcffcb7f89"
$ResourceGroupName = "bwoffshore"
$StorageAccountName = "bwoffshore"
$ContainerName = "mysitemedia-intra"
$MaxBlobToRemove = 1
Remove-Blobs -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ContainerName $ContainerName -MaxBlobToRemove $MaxBlobToRemove

$SubscriptionId = "e872f180-979f-4374-aff7-3bbcffcb7f89"
$ResourceGroupName = "bwoffshore"
$ContainerName = "mysitemedia-intra"
Remove-Blobs -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -ContainerName $ContainerName

