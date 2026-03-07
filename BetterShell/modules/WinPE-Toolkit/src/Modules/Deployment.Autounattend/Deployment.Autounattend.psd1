@{
    RootModule        = 'Deployment.Autounattend.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '4c9b4f64-0479-4a2f-86d2-14101e5b49b9'
    Author            = 'Better11 Toolkit'
    CompanyName       = 'Better11'
    PowerShellVersion = '5.1'
    Description       = 'Unattended setup (autounattend.xml) generator with interactive TUI.'
    RequiredModules   = @('Deployment.Core')
    FunctionsToExport = @(
        'New-AutounattendXml',
        'Start-AutounattendWizard'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}

