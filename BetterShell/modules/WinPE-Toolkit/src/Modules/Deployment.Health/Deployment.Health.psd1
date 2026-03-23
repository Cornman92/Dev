@{
    RootModule        = 'Deployment.Health.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'c9d8a0a2-a05b-4b79-9a4f-bef353940178'
    Author            = 'Better11 Toolkit'
    CompanyName       = 'Better11'
    PowerShellVersion = '5.1'
    Description       = 'Health snapshotting, comparison, and diagnostics export for Better11 deployment toolkit.'
    RequiredModules   = @('Deployment.Core')
    FunctionsToExport = @(
        'New-HealthSnapshot',
        'Compare-HealthSnapshot',
        'New-SystemRestorePointSafe',
        'Export-DeployDiagnostics'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}

