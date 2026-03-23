@{
    RootModule        = 'Deployment.Integration.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'c0d1e2f3-a4b5-6c7d-8e9f-0a1b2c3d4e5f'
    Author            = 'Better11 Toolkit'
    CompanyName       = 'Better11'
    PowerShellVersion = '5.1'
    Description       = 'Integration with MDT and SCCM for enterprise deployment scenarios.'
    RequiredModules   = @('Deployment.Core', 'Deployment.TaskSequence')
    FunctionsToExport = @(
        'Export-ToMdt',
        'Import-FromMdt',
        'Sync-WithSccm',
        'Convert-MdtTaskSequence',
        'Convert-SccmTaskSequence'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}

