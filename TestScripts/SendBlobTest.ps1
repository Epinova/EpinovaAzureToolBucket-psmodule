Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name C:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

$SubscriptionId = "x802f980-979x-1111-axx7-3bbxxfcb7x99"
$ResourceGroupName = "rg-sprit-1231hjkjia-inte"
$StorageAccountName = "stsprit1231hjkjiainte"
$StorageAccountContainer = "sitemedia"

$FilePath = "C:\dev\temp\_blobDownloads\epicms_Integration_20221027082506.bacpac"

# Override with real settings
. C:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_SendBlob.ps1

Get-InstalledModule Az.Storage

Send-Blob -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -FilePath $FilePath

Get-InstalledModule Az.Storage