$SubscriptionId = "e872f180-979f-4374-aff7-3bbcffcb7f89"
$ResourceGroupName = "ove4"
$Environment = "inte"
$Location = "swedencentral"
$DatabaseLogin = "ovesa"
$DatabasePassword = "a6AX54xxwws3SC16"
$UseApplicationInsight = $false
$SqlSku = "Basic"
$AppPlanSku = "B1"

# Login to Azure
Connect-AzAccount -SubscriptionId $SubscriptionId

# 24-03-01T09:43:47.3627251Z New-OptimizelyCmsResourceGroupBicep - Inputs:----------
# 2024-03-01T09:43:47.3627714Z SubscriptionId:                  b8b29c02-f414-479e-a87f-acd2c7119aa7
# 2024-03-01T09:43:47.3627933Z ResourceGroupName:               ove3
# 2024-03-01T09:43:47.3628095Z Environment:                     inte
# 2024-03-01T09:43:47.3628288Z DatabaseLogin:                   ovesa
# 2024-03-01T09:43:47.3628474Z DatabasePassword:                a6AX54xxwws3SC16
# 2024-03-01T09:43:47.3628652Z Location:                        swedencentral
# 2024-03-01T09:43:47.3628824Z CmsVersion:                      12
# 2024-03-01T09:43:47.3628965Z Tags:                            
# 2024-03-01T09:43:47.3629118Z Name                           Value
# 2024-03-01T09:43:47.3629331Z ----                           -----
# 2024-03-01T09:43:47.3629479Z Environment                    inte
# 2024-03-01T09:43:47.3629725Z Expires                        2024-04-01
# 2024-03-01T09:43:47.3629891Z Project                        Ove test
# 2024-03-01T09:43:47.3630076Z ManagedBy                      ove.lartelius@epinova.se
# 2024-03-01T09:43:47.3630261Z App                            Optimizely CMS
# 2024-03-01T09:43:47.3630431Z Owner                          ove.lartelius@epinova.se
# 2024-03-01T09:43:47.3630605Z Cost                           Epinova
# 2024-03-01T09:43:47.3631018Z Client                         Epinova
# 2024-03-01T09:43:47.3631169Z Department                     DevOps
# 2024-03-01T09:43:47.3631254Z 
# 2024-03-01T09:43:47.3631305Z 
# 2024-03-01T09:43:47.3646728Z UseApplicationInsight:           True
# 2024-03-01T09:43:47.3646959Z SqlSku:                          Basic
# 2024-03-01T09:43:47.3647123Z AppPlanSku:                      B1
# 2024-03-01T09:43:47.3647286Z UseDeviceAuthentication:         False

[hashtable] $Tags = @{
    ManagedBy = "ove.lartelius@epinova.se"
    Environment = "inte"
    Expires = "2024-04-01"
    Project = "Ove test"
    App = "Optimizely CMS"
    Owner = "ove.lartelius@epinova.se"
    Cost = "Epinova"
    Client = "Epinova"
    Department = "DevOps"
}

$Parameters = @{
    "projectName"                 = $ResourceGroupName
    "environmentName"             = $Environment
    "location"                    = $Location
    "sqlserverAdminLogin"         = $DatabaseLogin
    "sqlserverAdminLoginPassword" = $DatabasePassword #$databasePasswordSecureString
    "useApplicationInsight"       = $UseApplicationInsight
    "tags"                        = $Tags
};

if ($false -eq [string]::IsNullOrEmpty($SqlSku)) {
    $Parameters = $Parameters + @{ "sqlSku" = $SqlSku}
}

if ($false -eq [string]::IsNullOrEmpty($AppPlanSku)){
    $Parameters = $Parameters + @{ "appPlanSku" = $AppPlanSku }
}


# $Parameters = @{
#     "projectName"                 = "ovestest"
#     "environmentName"             = "inte"
#     "location"                    = $Location
#     "tags"                        = $Tags
# };

$bicepFile = "$PSScriptRoot\..\Modules\EpinovaAzureToolBucket\cms12.bicep"
Write-Host "Use bicep: $bicepFile"

# Create resources from deployment template
New-AzDeployment -Location $Location -TemplateFile $bicepFile -TemplateParameterObject $Parameters