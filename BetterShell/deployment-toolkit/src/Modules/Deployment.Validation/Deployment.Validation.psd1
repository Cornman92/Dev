@{
    RootModule        = 'Deployment.Validation.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a8b9c0d1-e2f3-4a5b-6c7d-8e9f0a1b2c3d'
    Author            = 'Better11 Toolkit'
    CompanyName       = 'Better11'
    PowerShellVersion = '5.1'
    Description       = 'Pre-flight validation and prerequisite checking for Better11 deployment toolkit.'
    RequiredModules   = @('Deployment.Core')
    FunctionsToExport = @(
        'Test-DeploymentPrerequisites',
        'Test-WimFile',
        'Test-DriverCatalog',
        'Test-AppCatalog',
        'Test-TaskSequence',
        'Test-HardwareCompatibility'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}

