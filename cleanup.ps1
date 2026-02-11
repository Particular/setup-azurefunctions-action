param (
    [string]$Suffix
)
$resourceGroup = $Env:RESOURCE_GROUP_OVERRIDE ?? "GitHubActions-RG"

$StorageName = 'pswfunc' + $Suffix
$AppName = 'psw-functionapp-' + $Suffix
$PlanName = 'psw-functionsplan-' + $Suffix

echo "Cleaning up Functions App $AppName in resource group $resourceGroup"
#az functionapp delete --resource-group $resourceGroup --name $AppName > $null

echo "Cleaning up App Service Plan $PlanName in resource group $resourceGroup"
#az appservice plan delete --resource-group $resourceGroup --name $PlanName --yes > $null

echo "Cleaning up storage account $StorageName in resource group $resourceGroup"
#az storage account delete --name $StorageName --resource-group $resourceGroup --yes > $null