Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

$SubscriptionId = "x802f980-979x-1111-axx7-3bbxxfcb7x99"
$ResourceGroupName = "rg-sprit-1231hjkjia-inte"
$StorageAccountName = "stsprit1231hjkjiainte"
$StorageAccountContainer = "sitemedia"

$FilePath = "C:\dev\temp\_blobDownloads\epicms_Integration_20221027082506.bacpac"
$BlobName = "epicms_Integration_20221027082506.bacpac"

# Override with real settings
. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_SendBlob.ps1

#Get-InstalledModule Az.Storage

#Send-Blob -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -FilePath $FilePath -BlobName $BlobName

$StorageAccountContainer = "mysitemedia"
$FilePath = "E:\dev\temp\_blobDownloads\9f39343b014a4ec985ec35a7c9e18d7d\5539c3361529443baaf9a7746b6ee21c.jpg"
$BlobName = "9f39343b014a4ec985ec35a7c9e18d7d\5539c3361529443baaf9a7746b6ee21c.jpg"
Send-Blob -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -FilePath $FilePath -BlobName $BlobName

#Get-InstalledModule Az.Storage