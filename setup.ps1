param (
    [string]$AppName,
    [string]$StorageName,
    [string]$PublishProfileEnvName,
    [string]$tagName,
    [string]$azureCredentials
)

$credentials = $azureCredentials | ConvertFrom-Json

$resourceGroup = $Env:RESOURCE_GROUP_OVERRIDE ?? "GitHubActions-RG"

if ($Env:REGION_OVERRIDE) {
    $region = $Env:REGION_OVERRIDE
}
else {
    Write-Output "Getting the Azure region in which this workflow is running..."
    $hostInfo = curl --silent -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | ConvertFrom-Json
    $region = $hostInfo.compute.location
}
Write-Output "Actions agent running in Azure region $region"

$packageTag = "Package=$tagName"
$runnerOsTag = "RunnerOS=$($Env:RUNNER_OS)"
$dateTag = "Created=$(Get-Date -Format "yyyy-MM-dd")"

Write-Output "Creating storage account $StorageName in resource group $resourceGroup (This can take a while.)"
$storageResult = az storage account create --name $StorageName --location "$region" --resourceGroup $resourceGroup --sku Standard_LRS --tags $packageTag $runnerOsTag $dateTag | ConvertFrom-Json
echo ($storageResult | ConvertTo-Json)

Write-Output "Creating Azure Functions App $AppName (This can take a while.)"
$appDetails = az functionapp create --name $AppName --storage-account $StorageName --consumption-plan-location $region --resource-group $resourceGroup --functionsVersion "4"

# Write-Output "Assigning roles to Azure Service Bus namespace $ASBName"
# az role assignment create --assignee $credentials.principalId --role "Azure Service Bus Data Owner" --scope $details.id > $null

# Write-Output "Getting publish profile"
# #$keys = az servicebus namespace authorization-rule keys list --resource-group $resourceGroup --namespace-name $ASBName --name RootManageSharedAccessKey | ConvertFrom-Json
# #$connectString = $keys.primaryConnectionString
# #Write-Output "::add-mask::$connectString"

# Write-Output "Getting connection string without manage rights"
# az servicebus namespace authorization-rule create --resource-group $resourceGroup --namespace-name $ASBName --name RootNoManageSharedAccessKey --rights Send Listen > $null
# $noManageKeys = az servicebus namespace authorization-rule keys list --resource-group $resourceGroup --namespace-name $ASBName --name RootNoManageSharedAccessKey | ConvertFrom-Json
# $noManageConnectString = $noManageKeys.primaryConnectionString
# Write-Output "::add-mask::$noManageConnectString"
# $noManageConnectionStringName = "$($connectionStringName)_Restricted"

# Write-Output "$connectionStringName=$connectString" | Out-File -FilePath $Env:GITHUB_ENV -Encoding utf-8 -Append
# Write-Output "$noManageConnectionStringName=$noManageConnectString" | Out-File -FilePath $Env:GITHUB_ENV -Encoding utf-8 -Append
