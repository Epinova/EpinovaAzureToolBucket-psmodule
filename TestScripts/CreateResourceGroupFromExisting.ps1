Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

$subscriptionId = "e872f180-979f-4374-aff7-3bbcffcb7f89" #Epinova-Sweden-Inte
$existingResourceGroupName = "rg-ove6-cyss6lix3f4wi-inte"
$newResourceGroupName = "rg-ove6-cyss6lix3f4wix-inte"
$newLocation = "swedencentral"

$azureConnection = $null
if($null -eq $azureConnection -or $null -eq $azureConnection.Account){
    try{
        $azureConnection = Connect-AzAccount -SubscriptionId $subscriptionId
        Write-Host "Connected to subscription $subscriptionId"
    }
    catch {
        $message = $_.Exception.message
        Write-Error $message
        exit
    }
}
$azureConnection

$azureContext = Set-AzContext –SubscriptionId $subscriptionId
$azureContext

$existingResourceGroup = Get-AzResourceGroup -Name $existingResourceGroupName
Write-Output "Found existing resource group $newResourceGroupName"
$existingResourceGroupTags = $existingResourceGroup.Tags
$tagsString = $existingResourceGroupTags | Out-String
Write-Output "Tags: $tagsString"

# Create 
Write-Output "Create new Azure ResourceGroup -Name $newResourceGroupName -Location $newLocation"
New-AzResourceGroup -Name $newResourceGroupName -Location $newLocation -Tag $existingResourceGroupTags