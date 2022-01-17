Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

$SubscriptionId = ""
$ResourceGroupName = "deletemenow1235"
$DatabasePassword = ""

# Override with real settings
. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_GetEpiserverCmsConnectionStrings.ps1

Get-EpiserverCmsConnectionStrings -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -DatabasePassword $DatabasePassword