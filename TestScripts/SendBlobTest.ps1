Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

$SubscriptionId = "x802f980-979x-1111-axx7-3bbxxfcb7x99"
$ResourceGroupName = "rg-sprit-1231hjkjia-inte"
$StorageAccountName = "stsprit1231hjkjiainte"
$ContainerName = "sitemedia"
$FilePath = "E:\dev\temp\_blobDownloads\epicms_Integration_20221021145233.bacpac"

# Override with real settings
. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_SendBlob.ps1

Send-Blob -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ContainerName $ContainerName -FilePath $FilePath


