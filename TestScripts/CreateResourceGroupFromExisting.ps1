Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

$subscriptionId = "e872f180-979f-4374-aff7-3bbcffcb7f89" #Epinova-Sweden-Inte
$ExistingResourceGroupName = "rg-ove6-cyss6lix3f4wi-inte"
$NewResourceGroupName = "rg-ove6-cyss6lix3f4wix-inte"
$NewResourceGroupLocation = "swedencentral"

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

$existingResourceGroup = Get-AzResourceGroup -Name $ExistingResourceGroupName
Write-Output "Found existing resource group $NewResourceGroupName"
$existingResourceGroupTags = $existingResourceGroup.Tags
$tagsString = $existingResourceGroupTags | Out-String
Write-Output "Tags: $tagsString"

# Create 
Write-Output "Create new Azure ResourceGroup -Name $NewResourceGroupName -Location $NewResourceGroupLocation"
New-AzResourceGroup -Name $NewResourceGroupName -Location $NewResourceGroupLocation -Tag $existingResourceGroupTags