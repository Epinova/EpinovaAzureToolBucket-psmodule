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

# Override with real settings
. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_NewOptimizelyCmsResourceGroup.ps1

New-OptimizelyCmsResourceGroup -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -DatabasePassword $DatabasePassword -Tags $Tags #-ArmTemplateUri ‘https://raw.githubusercontent.com/yourrepository/arm-templates/main/azure-optimizely-cms.json’