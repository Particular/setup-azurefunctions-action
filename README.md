# setup-azurefunctions-action

This action handles the setup and teardown of an Azure Functions app for running tests, including the storage account and App Service Plan necessary for the Functions app to run.

## Usage

```yaml
      - name: Setup Functions App
        id: setup-functions
        uses: Particular/setup-azurefunctions-action@v2.0.0
        with:
          azure-credentials: ${{ secrets.AZURE_ACI_CREDENTIALS }}
          tag: PackageName
```

The result of the action is expressed in output variables, which requires the workflow to provide an `id` as shown above. Given the id `setup-functions` as above, the output variables provided can be accessed as:

* `${{ steps.setup-functions.outputs.app-name}}` - The app name, which can be used with the [azure/webapps-deploy action](https://github.com/azure/webapps-deploy).
* `${{ steps.setup-functions.outputs.publish-profile }}` - The publish profile of the created Functions app, which can be used with the [azure/webapps-deploy action](https://github.com/azure/webapps-deploy).
* `${{ steps.setup-functions.outputs.hostname }}` - The created Functions app host name, which can be used to construct URLs
* `${{ steps.setup-functions.outputs.azure-functions-tools-module-path }}` - The path to the `AzureFunctionsTools` PowerShell module shipped with this action, used to promote environment variables to the running app after creation (see below).

## Promoting environment variables to a running app

Environment variables passed via `env-vars-to-promote` are applied as App Settings when the Functions app is provisioned. Variables that are not set at that point are skipped with a warning, so values produced by a parallel step can be promoted after the app is running.

The action ships a PowerShell module (`AzureFunctionsTools`) that encapsulates the promotion, mirroring how `setup-wsl-action` exports `WslTools`. Import it from the `azure-functions-tools-module-path` output and call `Set-FunctionAppSettings`:

```yaml
      - name: Promote environment variables to Functions app
        run: |
          Import-Module '${{ steps.setup-functions.outputs.azure-functions-tools-module-path }}' -Force
          Set-FunctionAppSettings -AppName '${{ steps.setup-functions.outputs.app-name }}' -EnvVarNames 'AzureWebJobsServiceBus'
```

This pairs with running `setup-azureservicebus-action` and this action in a GitHub Actions `parallel:` block: once the block completes, the Service Bus connection string is in the runner environment and the Functions app is running, so the connection string can be pushed into App Settings before deployment.

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE).

## Development

Open the folder in Visual Studio Code. If you don't already have them, you will be prompted to install remote development extensions. After installing them, and re-opening the folder in a container, do the following:

Log into Azure

```bash
az login
az account set --subscription SUBSCRIPTION_ID
```

When changing `index.mjs`, either run `npm run dev` beforehand, which will watch the file for changes and automatically compile it, or run `npm run prepare` afterwards.

## Testing

### With PowerShell

To test the setup action set the required environment variables and execute `setup.ps1` with the desired parameters. Note that the `-Suffix` parameter is meant to be a numerical suffix (e.g. a random number) that is appended to common prefixes for the storage account, app service plan, and functions app.

```bash
$Env:RESOURCE_GROUP_OVERRIDE=yourResourceGroup
$Env:REGION_OVERRIDE=yourRegion
# Replace the principal ID with the appropriate principal ID that you used to log into AZ CLI
$azureCredentials = @"
{
     "principalId": "a28b36b8-2243-494e-9028-0e94df179913",
   }
"@
.\setup.ps1 -Suffix "0001" -Tag local-testing -AzureCredentials $azureCredentials
```

To test the cleanup action set the required environment variables and execute `cleanup.ps1` with the desired parameters.

```bash
$Env:RESOURCE_GROUP_OVERRIDE=yourResourceGroup
.\cleanup.ps1 -Suffix "0001"
```
