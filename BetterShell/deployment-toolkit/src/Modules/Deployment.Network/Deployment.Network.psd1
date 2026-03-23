@{
    RootModule        = 'Deployment.Network.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'b9c0d1e2-f3a4-5b6c-7d8e-9f0a1b2c3d4e'
    Author            = 'Better11 Toolkit'
    CompanyName       = 'Better11'
    PowerShellVersion = '5.1'
    Description       = 'Network deployment support for PXE boot and WDS integration.'
    RequiredModules   = @('Deployment.Core')
    FunctionsToExport = @(
        'Initialize-PxeBoot',
        'Configure-WdsServer',
        'Deploy-OverNetwork',
        'Test-NetworkDeployment'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}

