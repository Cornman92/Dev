@{
    RootModule        = 'Deployment.DSC.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'e2f3a4b5-c6d7-8e9f-0a1b-2c3d4e5f6a7b'
    Author            = 'Better11 Toolkit'
    CompanyName       = 'Better11'
    PowerShellVersion = '5.1'
    Description       = 'DSC (Desired State Configuration) integration for post-deployment configuration management.'
    RequiredModules   = @('Deployment.Core')
    FunctionsToExport = @(
        'Export-ToDscConfiguration',
        'Compile-DscConfiguration',
        'Apply-DscConfiguration',
        'Test-DscConfiguration'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}

