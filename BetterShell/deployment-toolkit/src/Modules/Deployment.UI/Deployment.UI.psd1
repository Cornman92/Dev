@{
    RootModule        = 'Deployment.UI.psm1'
    ModuleVersion     = '2.0.0'
    GUID              = 'c90a27f2-3dea-4a67-8c97-03c7fbc68932'
    Author            = 'Better11 Toolkit'
    CompanyName       = 'Better11'
    PowerShellVersion = '5.1'
    Description       = 'Console-based control center UI for Better11 deployment toolkit.'
    RequiredModules   = @(
        'Deployment.Core',
        'Deployment.Imaging',
        'Deployment.TaskSequence',
        'Deployment.Drivers',
        'Deployment.Autounattend',
        'Deployment.Provisioning',
        'Deployment.Health'
    )
    FunctionsToExport = @(
        'Start-DeployCenter',
        'Start-DeployConsole'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}

