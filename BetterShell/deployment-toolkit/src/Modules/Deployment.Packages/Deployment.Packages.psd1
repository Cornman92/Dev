@{
    RootModule        = 'Deployment.Packages.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '7b9abaf2-74b4-4a52-914e-2c6710c9f4fb'
    Author            = 'Better11 Toolkit'
    CompanyName       = 'Better11'
    PowerShellVersion = '5.1'
    Description       = 'Application and configuration package deployment for Better11 deployment toolkit.'
    RequiredModules   = @('Deployment.Core')
    FunctionsToExport = @(
        'Get-AppCatalog',
        'Get-AppSet',
        'Test-AppInstalled',
        'Install-AppPackage',
        'Install-AppSet'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}

