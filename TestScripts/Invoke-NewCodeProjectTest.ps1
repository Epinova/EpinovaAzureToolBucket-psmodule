#Set-Location E:\dev\EpinovaAzureToolBucket-psmodule\TestScripts


$OrganizationName = "Epinova-Sweden"
$RootFolder = "e:\dev\"
$ProjectName = "myNewProject"
#$RepositoryName = "MyNewProjectCMS"
$RootGitBranchName = "master"

#Write-Host "Create $ProjectName folder"
#New-Item -Path $RootFolder -Name $ProjectName -ItemType "directory" -Force

$projectFolder = $RootFolder + $ProjectName
Set-Location $projectFolder

# Install Optimizely CMS dotnet templates
dotnet new -i EPiServer.Templates
# List installed tools in console
dotnet tool list -g
# Create a dotnet project from the template
dotnet new epi-alloy-mvc

az login

# Commit the dotnet project into git.
git init .
git add --all
git commit -m "Add CMSv12 AlloyMVC to repo"
$gitremoteurl = "https://dev.azure.com/$OrganizationName/$ProjectName/_git/$ProjectName"
$gitremoteurl
git remote add origin $gitremoteurl
git push origin $RootGitBranchName

Set-Location E:\dev\EpinovaAzureToolBucket-psmodule\TestScripts