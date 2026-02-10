param (
    [string]$Suffix,
    [string]$PublishProfileEnvName,
    [string]$tagName,
    [string]$azureCredentials
)

$credentials = $azureCredentials | ConvertFrom-Json

$resourceGroup = $Env:RESOURCE_GROUP_OVERRIDE ?? "GitHubActions-RG"

$StorageName = 'pswfunc' + $Suffix
$AppName = 'psw-functionapp-' + $Suffix
$PlanName = 'psw-functionsplan-' + $Suffix

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
$storage = az storage account create --name $StorageName --location $region --resource-group $resourceGroup --sku Standard_LRS --tags $packageTag $runnerOsTag $dateTag | ConvertFrom-Json
if (-not $?) {
    throw "Unable to set up storage account"
}

Write-Output "Creating app service plan $PlanName in resource group $resourceGroup (This can take a while.)"
# Functions can't use SHARED, and Y1 for consumption not supported by Azure CLI https://github.com/Azure/azure-cli/issues/8388
$plan = az appservice plan create --name $PlanName --resource-group $resourceGroup --location $region --sku B1 --tags $packageTag $runnerOsTag $dateTag | ConvertFrom-Json
if (-not $?) {
    throw "Unable to set up app service plan"
}

Write-Output "Creating Azure Functions App $AppName (This can take a while.)"
$app = az functionapp create --name $AppName --resource-group $resourceGroup --storage-account $StorageName --plan $PlanName --functions-version "4" --disable-app-insights true --tags $packageTag $runnerOsTag $dateTag | ConvertFrom-Json
$hostname = $app.defaultHostName
Write-Output "Functions app host is $hostname"
if (-not $?) {
    throw "Unable to set up Functions app"
}

Write-Output "Assigning roles to Azure Functions App $AppName"
az role assignment create --assignee $credentials.principalId --role "Website Contributor" --scope $details.id > $null
if (-not $?) {
    throw "Unable to assign roles to app"
}

Write-Output "Getting publish profile"
$publishProfileJson = az functionapp deployment list-publishing-profiles --name $AppName --resource-group $resourceGroup
if (-not $?) {
    throw "Unable to get publish profile"
}

Write-Output "::add-mask::$publishProfileJson"
Write-Output "$PublishProfileEnvName=$publishProfileJson" | Out-File -FilePath $Env:GITHUB_ENV -Encoding utf-8 -Append
