param (
    [string]$AppName,
    [string]$StorageName
)
$resourceGroup = $Env:RESOURCE_GROUP_OVERRIDE ?? "GitHubActions-RG"

echo "Cleaning up Functions App $AppName in resource group $resourceGroup"
#$ignore = az servicebus namespace delete --resource-group $resourceGroup --name $ASBName

echo "Cleaning up storage account $StorageName in resource group $resourceGroup"
#$ignore = TODO: