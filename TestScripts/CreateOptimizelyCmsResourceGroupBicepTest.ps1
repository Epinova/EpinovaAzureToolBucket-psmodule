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

# Override with real settings
. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_NewOptimizelyCmsResourceGroupBicep.ps1

New-OptimizelyCmsResourceGroupBicep -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -Environment $Environment -DatabaseLogin $DatabaseLogin -DatabasePassword $DatabasePassword -Tags $Tags -CmsVersion $CmsVersion -Location $Location
