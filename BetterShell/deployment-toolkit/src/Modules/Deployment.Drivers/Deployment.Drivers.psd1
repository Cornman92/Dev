@{
    RootModule        = 'Deployment.Drivers.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '4d11d3c3-d9fa-4a2e-b9a8-157680b6f91e'
    Author            = 'Better11 Toolkit'
    CompanyName       = 'Better11'
    PowerShellVersion = '5.1'
    Description       = 'Hardware detection and driver pack management for Better11 deployment toolkit.'
    RequiredModules   = @('Deployment.Core')
    FunctionsToExport = @(
        'Get-HardwareProfile',
        'Get-DriverCatalog',
        'Find-DriverPacksForHardware',
        'Add-DriversToOfflineWindows',
        'Add-DriversToMountedImage'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}

