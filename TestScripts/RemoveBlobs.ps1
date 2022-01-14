Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

$SubscriptionId = "x802f980-979x-1111-axx7-3bbxxfcb7x99"
$ResourceGroupName = "rg-sprit-1231hjkjia-inte"
$StorageAccountName = "stsprit1231hjkjiainte"
$ContainerName = "sitemedia"

# Override with real settings
. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_RemoveBlobs.ps1

Remove-Blobs -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ContainerName $ContainerName


