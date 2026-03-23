@{
    RootModule = 'Preflight.psm1'
    ModuleVersion = '0.1.0'
    GUID = '33333333-3333-4333-8333-333333333333'
    Author = 'Windows Automation Workspace'
    CompanyName = 'Windows Automation Workspace'
    Copyright = '(c) 2024 Windows Automation Workspace. All rights reserved.'
    Description = 'Environment checks for Better11 Suite.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Get-Better11PreflightReport','Test-Better11Preflight')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Better11', 'Preflight', 'Validation')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Preflight checks for Better11 Suite'
        }
    }
}
