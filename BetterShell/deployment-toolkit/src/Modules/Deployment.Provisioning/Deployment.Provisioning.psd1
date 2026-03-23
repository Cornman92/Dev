@{
    RootModule        = 'Deployment.Provisioning.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '734df7e8-7f31-4fbc-bbdb-7cce16e4fd1a'
    Author            = 'Better11 Toolkit'
    CompanyName       = 'Better11'
    PowerShellVersion = '5.1'
    Description       = 'Provisioning package (PPKG) builder and installer helpers.'
    RequiredModules   = @('Deployment.Core')
    FunctionsToExport = @(
        'New-AppCaptureProvisioningPackage',
        'Install-ProvisioningPackageLocal',
        'Add-ProvisioningPackageToOfflineImage'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}

