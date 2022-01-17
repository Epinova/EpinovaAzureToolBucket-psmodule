Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
#Remove-Module -Name "Az" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

$sqlServer = "project1-dev.database.windows.net"
$sqlServerUsername = "project1-sa"
$sqlServerPassword = "@wes0mep@ssw0rd"
$targetDatabase = "project1-cms-dev"
$newUsername = "project1dbuser"
$newPassword = "mynew@wes0mep@ssw0rd"
$newUserPermission = "db_owner"

# Override with real settings
. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_AddAzureDatabaseUser.ps1

Add-AzureDatabaseUser -SqlServer $sqlServer -SqlServerUsername $sqlServerUsername -SqlServerPassword $sqlServerPassword -TargetDatabase $targetDatabase -NewUsername $newUsername -NewPassword $newPassword  -NewUserPermission $newUserPermission