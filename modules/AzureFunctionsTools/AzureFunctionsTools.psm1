function Set-FunctionAppSettings {
    <#
    .SYNOPSIS
        Sets App Settings on a running Azure Functions app from environment variables on the runner.

    .DESCRIPTION
        Reads each named environment variable from the runner process environment and applies it
        as an App Setting on the specified Azure Functions app using the Azure CLI. Missing
        environment variables are skipped with a warning so the function can be used to promote
        values that are produced by an earlier step, for example the Service Bus connection string
        exported by setup-azureservicebus-action.

    .PARAMETER AppName
        The name of the Azure Functions app to update.

    .PARAMETER EnvVarNames
        One or more names of environment variables to promote to App Settings.

    .PARAMETER ResourceGroup
        The resource group containing the Functions app. Defaults to the RESOURCE_GROUP_OVERRIDE
        environment variable or 'GitHubActions-RG'.

    .EXAMPLE
        Set-FunctionAppSettings -AppName 'psw-functionapp-123' -EnvVarNames 'AzureWebJobsServiceBus'
    #>
    param(
        [Parameter(Mandatory = $true)][string]$AppName,
        [Parameter(Mandatory = $true)][string[]]$EnvVarNames,
        [string]$ResourceGroup = ($env:RESOURCE_GROUP_OVERRIDE ?? 'GitHubActions-RG')
    )

    $names = @($EnvVarNames | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($names.Count -eq 0) {
        Write-Output "No environment variable names provided"
        return
    }

    $settings = [ordered]@{}
    foreach ($name in $names) {
        $value = [Environment]::GetEnvironmentVariable($name)
        if ([string]::IsNullOrWhiteSpace($value)) {
            Write-Warning "Environment variable '$name' is not set; skipping promotion to Functions app settings."
            continue
        }
        Write-Output "::add-mask::$value"
        $settings[$name] = $value
    }

    if ($settings.Count -eq 0) {
        Write-Output "No app settings to set on Functions app $AppName"
        return
    }

    $settingsFile = Join-Path ([System.IO.Path]::GetTempPath()) ("functions-settings-" + [guid]::NewGuid().ToString("N") + ".json")
    $settings | ConvertTo-Json | Out-File -FilePath $settingsFile -Encoding utf8
    try {
        az functionapp config appsettings set --name $AppName --resource-group $ResourceGroup --settings "@$settingsFile" > $null
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to set app settings on Functions app $AppName"
        }
        Write-Output "Updated app settings on Functions app ${AppName}: $($settings.Keys -join ', ')"
    }
    finally {
        Remove-Item -Path $settingsFile -Force -ErrorAction SilentlyContinue
    }
}

Export-ModuleMember -Function Set-FunctionAppSettings
