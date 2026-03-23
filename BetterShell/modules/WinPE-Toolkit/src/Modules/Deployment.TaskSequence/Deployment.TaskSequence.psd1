@{
    RootModule        = 'Deployment.TaskSequence.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '6a1af9ad-4c3e-4b9f-a986-3d93d2fa7f4f'
    Author            = 'Better11 Toolkit'
    CompanyName       = 'Better11'
    PowerShellVersion = '5.1'
    Description       = 'Task sequence orchestration for the Better11 deployment toolkit.'
    RequiredModules   = @(
        'Deployment.Core',
        'Deployment.Imaging',
        'Deployment.Drivers',
        'Deployment.Packages',
        'Deployment.Optimization',
        'Deployment.Health'
    )
    FunctionsToExport = @(
        'Get-TaskSequenceCatalog',
        'Get-TaskSequence',
        'Invoke-TaskSequence',
        'Invoke-TaskStep'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}

