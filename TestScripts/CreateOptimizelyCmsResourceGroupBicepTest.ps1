Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose


$Tags = @{
    "Environment"="dev";
    "Owner"="ove.lartelius@epinova.se";
    "App"="Optimizely";
    "Client"="Client name";
    "Project"="Project name";
    "ManagedBy"="Ove Lartelius";
    "Cost"="Internal";
    "Department"="IT";
    "Expires"=""; # Or set a date yyyy-MM-dd
}

$SubscriptionId = ""
$ResourceGroupName = "deletemenow1235"
$DatabasePassword = ""
$Environment = "inte" # inte|prep|prod
$DatabaseLogin = "somelogin"
$CmsVersion = "12" # 11|12
$Location = "westeurope"
$SqlSku = "Basic"
$AppPlanSku = "F1"

# Override with real settings
. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_NewOptimizelyCmsResourceGroupBicep.ps1

#New-OptimizelyCmsResourceGroupBicep -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -Environment $Environment -DatabaseLogin $DatabaseLogin -DatabasePassword $DatabasePassword -Tags $Tags -CmsVersion $CmsVersion -Location $Location
New-OptimizelyCmsResourceGroupBicep -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -Environment $Environment -DatabaseLogin $DatabaseLogin -DatabasePassword $DatabasePassword -Tags $Tags -CmsVersion $CmsVersion -Location $Location -UseApplicationInsight $false -SqlSku $SqlSku -AppPlanSku $AppPlanSku


#New-OptimizelyCmsResourceGroupBicep -SubscriptionId 'cd828bde-d193-4fdb-b3ef-929ab15e4ec9' -ResourceGroupName 'test' -Environment 'inte' -DatabaseLogin 'testdbuser' -DatabasePassword 'KXIN_rhxh3holt_s8it' -CmsVersion '11' -Tags $Tags -Location 'westeurope' -UseApplicationInsight $true
