@{
    RootModule        = 'Deployment.Imaging.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '22f4a534-3f4d-4b3d-9c60-5cd4f9827e66'
    Author            = 'Better11 Toolkit'
    CompanyName       = 'Better11'
    PowerShellVersion = '5.1'
    Description       = 'Disk layout and image apply utilities for the Better11 deployment toolkit.'
    RequiredModules   = @('Deployment.Core')
    FunctionsToExport = @(
        'Get-DeployDisk',
        'Get-DeployDiskLayout',
        'New-DeployDiskLayout',
        'Invoke-ImageApply',
        'New-BootConfig'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}

