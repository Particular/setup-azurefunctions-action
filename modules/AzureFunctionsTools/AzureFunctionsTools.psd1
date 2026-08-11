@{
    RootModule        = 'AzureFunctionsTools.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'D9DC5074-CEA7-4AD9-9471-30ADC52D9AA0'
    Author            = 'Particular Software'
    Description       = 'Azure Functions helper functions for the setup-azurefunctions-action GitHub Action.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Set-FunctionAppSettings')
    FileList          = @('AzureFunctionsTools.psm1')
}
