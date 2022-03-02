Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

$OrganizationName = "Epinova-Sweden"
$ProjectName = "myNewProject"
$ProjectDescription = "This is my new project"

New-AzureDevOpsProject -OrganizationName $OrganizationName -ProjectName $ProjectName -ProjectDescription $ProjectDescription -Verbose